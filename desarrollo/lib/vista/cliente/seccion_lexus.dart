import 'package:flutter/material.dart';

import '../../controlador/controlador_dictado_lexus.dart';
import '../../controlador/controlador_lexus.dart';
import '../../controlador/servicio_conversaciones_lexus_visitante.dart';
import '../../modelo/modelo_paso_recorrido.dart';
import '../compartido/widgets/recorrido/ambito_recorrido.dart';
import '../tema/tema_app.dart';
import 'widgets/lexus/aviso_lexus.dart';
import 'widgets/lexus/barra_entrada_lexus.dart';
import 'widgets/lexus/burbuja_mensaje_lexus.dart';
import 'widgets/lexus/encabezado_lexus.dart';
import 'widgets/lexus/estilos_lexus.dart';
import 'widgets/lexus/indicador_escribiendo_lexus.dart';
import 'widgets/lexus/introduccion_lexus.dart';
import 'widgets/lexus/panel_lateral_lexus.dart';
import 'widgets/lexus/textos_dictado_lexus.dart';

/// Parte de la altura que la cabecera con el aviso y la barra de entrada
/// pueden ocupar como máximo, cada una.
const double _fraccionMaximaDeCromo = 0.4;
const double _anchoPanelLateral = 300;

/// Por debajo de este alto (un teléfono en horizontal) el aviso usa su versión
/// breve: la completa no cabría junto a la cabecera.
const double _altoBajo = 560;
const double _separacionPanel = 32;

const String _avisoHistorialNoDisponible =
    'No se pudo guardar la conversación. Seguirá disponible mientras no '
    'cierres la app.';

/// Sección "Lexus": chat de orientación jurídica inicial con IA.
///
/// Diseño adaptable por ancho (ver [EstilosLexus]): chat a pantalla completa
/// en teléfonos, columna centrada en tabletas y, desde 1100 px, tarjeta de
/// chat junto a un panel que explica qué hace y qué no hace Lexus.
///
/// La conversación vive en [ControladorLexus], que la guarda en la cuenta de
/// la persona y retoma la más reciente al abrir. Si el historial no está
/// disponible, la conversación sigue solo en memoria y se avisa una vez.
class SeccionLexus extends StatefulWidget {
  const SeccionLexus({
    super.key,
    this.crearControlador,
    this.crearDictado,
    this.alRequerirCuenta,
  });

  /// Modo visitante (web, sin sesión). Si no es `null`, la sección se ve
  /// igual pero enviar y dictar llaman a esto (para pedir una cuenta), y el
  /// historial no se carga ni se guarda: no hay a quién guardárselo.
  final VoidCallback? alRequerirCuenta;

  /// Permite a las pruebas inyectar un controlador con un servicio falso.
  @visibleForTesting
  final ControladorLexus Function()? crearControlador;

  /// Permite a las pruebas inyectar un dictado con grabadora y transcriptor
  /// falsos. Recibe la devolución de llamada que añade el texto al campo.
  @visibleForTesting
  final ControladorDictadoLexus Function(
    void Function(String texto) alTranscribir,
  )?
  crearDictado;

  @override
  State<SeccionLexus> createState() => _SeccionLexusState();
}

class _SeccionLexusState extends State<SeccionLexus> {
  late final ControladorLexus _controlador =
      (widget.crearControlador ?? _crearControladorPorDefecto)();

  /// El del visitante usa un historial que no lee ni escribe nada; sin él, el
  /// historial real fallaría por falta de sesión y avisaría de que no pudo
  /// guardar la conversación.
  ControladorLexus _crearControladorPorDefecto() {
    if (widget.alRequerirCuenta == null) return ControladorLexus();
    return ControladorLexus(
      conversaciones: ServicioConversacionesLexusVisitante(),
    );
  }

  /// Dictado por voz. Solo entrega texto al campo ([_agregarTranscripcion]);
  /// no conoce el controlador del chat y nunca envía.
  late final ControladorDictadoLexus _dictado =
      widget.crearDictado?.call(_agregarTranscripcion) ??
      ControladorDictadoLexus(alTranscribir: _agregarTranscripcion);

  /// Último fallo del dictado que ya se mostró.
  ErrorDictadoLexus? _errorDictadoMostrado;

  /// Controlador de desplazamiento propio: en Android e iOS, una lista sin
  /// controlador adopta el de la ruta, que comparten las pestañas del panel.
  final ScrollController _scroll = ScrollController();
  final TextEditingController _texto = TextEditingController();
  final FocusNode _foco = FocusNode(debugLabel: 'Consulta a Lexus');

  /// Mensajes que ya se mostraron: solo el primer montaje se anima.
  final Set<String> _vistos = {};
  int _cantidadAnterior = 0;
  bool _enviandoAnterior = false;
  bool _cargandoAnterior = false;

  /// El aviso de historial no disponible se muestra una sola vez.
  bool _avisoHistorialMostrado = false;

  /// Distribución usada en el último build (teléfono, columna o ancha). Al
  /// cambiar, la lista se reconstruye en otra posición del árbol y pierde el
  /// desplazamiento; se lleva al último mensaje para no dejar al usuario
  /// arriba de la conversación tras girar el teléfono o redimensionar.
  int? _distribucionAnterior;

  @override
  void initState() {
    super.initState();
    _cantidadAnterior = _controlador.mensajes.length;
    _cargandoAnterior = _controlador.cargando;
    _controlador.addListener(_alCambiarConversacion);
    _dictado.addListener(_alCambiarDictado);
  }

  @override
  void dispose() {
    _controlador.removeListener(_alCambiarConversacion);
    _dictado.removeListener(_alCambiarDictado);
    _scroll.dispose();
    _texto.dispose();
    _foco.dispose();
    _dictado.dispose();
    _controlador.dispose();
    super.dispose();
  }

  /// Añade al final del campo lo dictado, separado por un espacio, y deja el
  /// cursor al final. Nunca envía: la persona revisa el texto y envía a mano.
  void _agregarTranscripcion(String dictado) {
    if (!mounted) return;
    final actual = _texto.text;
    final separador = actual.isEmpty || RegExp(r'\s$').hasMatch(actual)
        ? ''
        : ' ';
    final nuevo = '$actual$separador$dictado';
    _texto.value = TextEditingValue(
      text: nuevo,
      selection: TextSelection.collapsed(offset: nuevo.length),
    );
    _foco.requestFocus();
  }

  /// Avisa de cada fallo nuevo del dictado: un diálogo con los pasos si falta
  /// el permiso del micrófono y un mensaje breve en los demás casos. El texto
  /// del campo no se toca.
  void _alCambiarDictado() {
    final error = _dictado.ultimoError;
    if (error == null || identical(error, _errorDictadoMostrado)) return;
    _errorDictadoMostrado = error;
    if (!mounted) return;
    if (error.tipo == TipoErrorDictadoLexus.permisoDenegado) {
      showDialog<void>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: const Text(TextosDictadoLexus.tituloPermiso),
          content: Text(TextosDictadoLexus.mensajeDeError(error)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(),
              child: const Text(TextosDictadoLexus.botonEntendido),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(TextosDictadoLexus.mensajeDeError(error))),
    );
  }

  void _alCambiarConversacion() {
    // Si el chat llega a su límite, la barra de entrada desaparece: un dictado
    // en curso ya no tendría dónde dejar el texto.
    if (_controlador.limiteAlcanzado) _dictado.cancelar();
    _avisarSiNoHayHistorial();
    final cantidad = _controlador.mensajes.length;
    final enviando = _controlador.enviando;
    final recienCargado = _cargandoAnterior && !_controlador.cargando;
    _cargandoAnterior = _controlador.cargando;
    if (recienCargado && _controlador.hayConversacion) {
      // Lo que se retoma ya estaba ahí: no se anima y se muestra el final.
      _vistos.addAll(_controlador.mensajes.map((m) => m.id));
      _desplazar(alFinal: true, saltar: true);
    } else if (cantidad < _cantidadAnterior) {
      _desplazar(alFinal: false);
    } else if (cantidad > _cantidadAnterior ||
        (enviando && !_enviandoAnterior)) {
      _desplazar(alFinal: true);
    }
    _cantidadAnterior = cantidad;
    _enviandoAnterior = enviando;
  }

  /// Avisa una sola vez de que la conversación ya no se está guardando.
  void _avisarSiNoHayHistorial() {
    if (_avisoHistorialMostrado || !_controlador.historialNoDisponible) return;
    _avisoHistorialMostrado = true;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text(_avisoHistorialNoDisponible)));
  }

  /// La lista es perezosa: su extensión máxima crece a medida que dibuja los
  /// mensajes que estaban fuera de pantalla, así que un solo salto se queda
  /// corto. Se repite unos pocos cuadros hasta llegar al final real.
  void _saltarAlFinal([int intentos = 4]) {
    if (!mounted || !_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
    if (intentos == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final posicion = _scroll.position;
      if (posicion.pixels < posicion.maxScrollExtent) {
        _saltarAlFinal(intentos - 1);
      }
    });
  }

  void _desplazar({required bool alFinal, bool saltar = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (alFinal && saltar) {
        _saltarAlFinal();
        return;
      }
      final destino = alFinal ? _scroll.position.maxScrollExtent : 0.0;
      if (saltar || MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(destino);
      } else {
        _scroll.animateTo(
          destino,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _llenarCampo(String frase) {
    _texto.value = TextEditingValue(
      text: frase,
      selection: TextSelection.collapsed(offset: frase.length),
    );
    _foco.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final compacto = ancho < EstilosLexus.anchoCompacto;
        final distribucion = ancho >= EstilosLexus.anchoPanelLateral
            ? 2
            : (compacto ? 0 : 1);
        if (_distribucionAnterior != null &&
            _distribucionAnterior != distribucion &&
            _controlador.hayConversacion) {
          _desplazar(alFinal: true, saltar: true);
        }
        _distribucionAnterior = distribucion;
        if (distribucion == 2) return _distribucionAncha();
        final chat = _columna(compacto: compacto);
        return ColoredBox(
          color: ColoresApp.grisClaro,
          child: compacto
              ? chat
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: EstilosLexus.anchoMaximoChat,
                    ),
                    child: chat,
                  ),
                ),
        );
      },
    );
  }

  /// Teléfono y tableta: cabecera azul, aviso, lista y barra de entrada.
  Widget _columna({required bool compacto}) {
    final margen = compacto ? 12.0 : 16.0;
    return LayoutBuilder(
      builder: (context, restricciones) {
        final tope = restricciones.maxHeight * _fraccionMaximaDeCromo;
        return Column(
          children: [
            _acotado(
              tope,
              Column(
                children: [
                  EncabezadoLexus(controlador: _controlador, sobreAzul: true),
                  _aviso(
                    compacto: compacto || restricciones.maxHeight < _altoBajo,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _lista(compacto: compacto, margen: margen),
            ),
            _acotado(
              tope,
              Padding(
                padding: EdgeInsets.fromLTRB(margen, 4, margen, 12),
                child: _barra(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Escritorio ancho: panel informativo a la izquierda y tarjeta de chat.
  Widget _distribucionAncha() {
    return ColoredBox(
      color: ColoresApp.grisClaro,
      child: Stack(
        children: [
          const Positioned.fill(child: RepaintBoundary(child: _FondoSuave())),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            // Panel y chat se centran como un solo bloque: separados, en
            // pantallas muy anchas quedaban en extremos opuestos.
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth:
                      _anchoPanelLateral +
                      _separacionPanel +
                      EstilosLexus.anchoMaximoChat,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: _anchoPanelLateral,
                      child: SingleChildScrollView(
                        primary: false,
                        child: PanelLateralLexus(),
                      ),
                    ),
                    const SizedBox(width: _separacionPanel),
                    Expanded(
                      child: DecoratedBox(
                        decoration: EstilosLexus.tarjeta(radio: 24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: LayoutBuilder(builder: _tarjetaDeChat),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaDeChat(BuildContext context, BoxConstraints restricciones) {
    final tope = restricciones.maxHeight * _fraccionMaximaDeCromo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _acotado(
          tope,
          Column(
            children: [
              EncabezadoLexus(controlador: _controlador, sobreAzul: false),
              Divider(
                height: 1,
                color: ColoresApp.grisTexto.withValues(alpha: 0.15),
              ),
              _aviso(compacto: restricciones.maxHeight < _altoBajo),
            ],
          ),
        ),
        Expanded(child: _lista(compacto: false, margen: 20)),
        _acotado(
          tope,
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: _barra(),
          ),
        ),
      ],
    );
  }

  /// El aviso es la marca de arranque del recorrido de Lexus: está en las
  /// dos distribuciones y, a diferencia de la introducción, también cuando ya
  /// hay conversación.
  Widget _aviso({required bool compacto}) {
    return MarcaRecorrido(
      id: MarcaRecorridoId.lexusAviso,
      child: AvisoLexus(compacto: compacto),
    );
  }

  /// Limita la altura de lo que rodea a la lista. Con el texto muy grande o
  /// una pantalla baja, cabecera, aviso y barra se comerían todo el espacio:
  /// así la conversación siempre conserva una parte, y lo que no cabe se
  /// desplaza.
  Widget _acotado(double alto, Widget hijo) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: alto),
      child: SingleChildScrollView(primary: false, child: hijo),
    );
  }

  Widget _barra() {
    return BarraEntradaLexus(
      controlador: _controlador,
      texto: _texto,
      foco: _foco,
      dictado: _dictado,
      alEnviar: () => _desplazar(alFinal: true),
      alRequerirCuenta: widget.alRequerirCuenta,
    );
  }

  Widget _lista({required bool compacto, required double margen}) {
    return ListenableBuilder(
      listenable: _controlador,
      builder: (context, _) {
        // El recorrido espera a que desaparezca este indicador para saber si
        // hay introducción con sugerencias que señalar.
        if (_controlador.cargando) {
          return const MarcaRecorrido(
            id: MarcaRecorridoId.lexusCargando,
            child: _CargandoConversacion(),
          );
        }
        final mensajes = _controlador.mensajes;
        final conIntroduccion = !_controlador.hayConversacion;
        final conIndicador = _controlador.enviando;
        final desfase = conIntroduccion ? 1 : 0;
        final total = desfase + mensajes.length + (conIndicador ? 1 : 0);

        return ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(margen, 8, margen, 12),
          itemCount: total,
          findChildIndexCallback: (clave) {
            if (clave is! ValueKey<String>) return null;
            if (clave.value == 'introduccion') {
              return conIntroduccion ? 0 : null;
            }
            if (clave.value == 'escribiendo') {
              return conIndicador ? total - 1 : null;
            }
            final indice = mensajes.indexWhere((m) => m.id == clave.value);
            return indice < 0 ? null : indice + desfase;
          },
          itemBuilder: (context, posicion) {
            if (conIntroduccion && posicion == 0) {
              return KeyedSubtree(
                key: const ValueKey('introduccion'),
                child: IntroduccionLexus(
                  controlador: _controlador,
                  alElegirSugerencia: _llenarCampo,
                  compacto: compacto,
                ),
              );
            }
            final indice = posicion - desfase;
            if (indice >= mensajes.length) {
              return const Padding(
                key: ValueKey('escribiendo'),
                padding: EdgeInsets.only(bottom: 12),
                child: IndicadorEscribiendoLexus(),
              );
            }
            final mensaje = mensajes[indice];
            return Padding(
              key: ValueKey(mensaje.id),
              padding: const EdgeInsets.only(bottom: 12),
              child: BurbujaMensajeLexus(
                mensaje: mensaje,
                controlador: _controlador,
                // `add` devuelve true solo la primera vez que se ve el mensaje.
                animar: _vistos.add(mensaje.id),
              ),
            );
          },
        );
      },
    );
  }
}

/// Indicador del área de la lista mientras se busca la conversación guardada.
class _CargandoConversacion extends StatelessWidget {
  const _CargandoConversacion();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: ColoresApp.azulTurqui,
          semanticsLabel: 'Cargando conversación',
        ),
      ),
    );
  }
}

/// Dos resplandores estáticos muy suaves detrás de la tarjeta de chat.
class _FondoSuave extends StatelessWidget {
  const _FondoSuave();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -160,
          left: -120,
          child: _Resplandor(
            diametro: 520,
            color: ColoresApp.azulTurqui.withValues(alpha: 0.05),
          ),
        ),
        Positioned(
          bottom: -200,
          right: -140,
          child: _Resplandor(
            diametro: 560,
            color: ColoresApp.dorado.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}

class _Resplandor extends StatelessWidget {
  const _Resplandor({required this.diametro, required this.color});

  final double diametro;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
