import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../controlador/controlador_recorrido.dart';
import '../../../../modelo/modelo_paso_recorrido.dart';
import '../../plantilla_post_login.dart';
import 'colocacion_tarjeta_recorrido.dart';
import 'estilos_recorrido.dart';
import 'pintor_foco_recorrido.dart';
import 'registro_marcas_recorrido.dart';
import 'tarjeta_paso_recorrido.dart';

/// Capa del recorrido guiado: oscurece la pantalla, deja un hueco sobre el
/// elemento real que se está explicando y muestra la tarjeta con el texto.
///
/// Vive en el `Overlay` de la ruta (ver `AnfitrionRecorrido`) y solo existe
/// mientras el recorrido está visible. Muestra lo que dice el
/// [ControladorRecorrido] y le devuelve las acciones del usuario; mide dónde
/// está el elemento en [RegistroMarcasRecorrido].
class CapaRecorrido extends StatefulWidget {
  const CapaRecorrido({
    super.key,
    required this.controlador,
    required this.registro,
  });

  final ControladorRecorrido controlador;
  final RegistroMarcasRecorrido registro;

  @override
  State<CapaRecorrido> createState() => _CapaRecorridoState();
}

class _CapaRecorridoState extends State<CapaRecorrido> {
  /// Ámbito de foco propio: Tab y Shift+Tab dan vueltas dentro de la tarjeta
  /// y no escapan hacia la pantalla oscurecida.
  final FocusScopeNode _ambitoFoco = FocusScopeNode(
    debugLabel: 'Recorrido guiado',
  );

  /// Botón principal («Comenzar» o «Siguiente»). Se enfoca de forma explícita
  /// al mostrar cada paso: el `autofocus` de un `FocusScope` no hace nada si
  /// su ámbito padre ya tiene un hijo con foco.
  final FocusNode _focoPrincipal = FocusNode(
    debugLabel: 'Botón principal del recorrido',
  );

  /// Entra con un fundido en lugar de aparecer de golpe.
  bool _aparecio = false;

  /// Hueco medido, en coordenadas de esta capa, y el paso al que pertenece.
  /// Sin el paso, el primer cuadro de un paso nuevo mostraría el hueco del
  /// anterior.
  String? _pasoMedido;
  Rect? _huecoMedido;

  /// Paso cuya marca se vigila y versión de esa marca la última vez que se
  /// miró (ver [_vigilarMarca]).
  String? _pasoVigilado;
  int _versionVigilada = 0;

  String? _pasoEnfocado;

  @override
  void initState() {
    super.initState();
    widget.controlador.addListener(_alCambiarControlador);
    _enfocarSiCorresponde();
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (mounted) setState(() => _aparecio = true);
    });
    binding.addPostFrameCallback(_medir);
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_alCambiarControlador);
    _ambitoFoco.dispose();
    _focoPrincipal.dispose();
    super.dispose();
  }

  void _alCambiarControlador() {
    if (!mounted) return;
    // Se mide ya, antes del próximo cuadro: así el hueco del paso nuevo está
    // listo cuando se dibuja y puede animarse desde el del paso anterior.
    setState(_sincronizarMedida);
    _enfocarSiCorresponde();
  }

  void _sincronizarMedida() {
    final paso = widget.controlador.pasoActual;
    _pasoMedido = paso?.id;
    _huecoMedido = _medirHueco(paso);
  }

  /// Rectángulo del elemento que señala [paso], en coordenadas de esta capa.
  Rect? _medirHueco(ModeloPasoRecorrido? paso) {
    final marca = paso?.marca;
    if (marca == null) return null;
    final global = widget.registro.rectoGlobal(marca);
    final capa = context.findRenderObject();
    if (global == null ||
        capa is! RenderBox ||
        !capa.attached ||
        !capa.hasSize) {
      return null;
    }
    return global.shift(-capa.localToGlobal(Offset.zero));
  }

  /// Mide el elemento después de cada cuadro, porque se mueve (se
  /// desplaza la pantalla, se redimensiona la ventana). El callback se vuelve
  /// a registrar a sí mismo pero nunca pide un cuadro: si nada se redibuja, no
  /// hay nada nuevo que medir. Solo hace `setState` si el objetivo se movió.
  void _medir(Duration _) {
    if (!mounted) return;
    final paso = widget.controlador.pasoActual;
    _vigilarMarca(paso);
    final nuevo = _medirHueco(paso);
    if (_pasoMedido != paso?.id || _cambioSignificativo(_huecoMedido, nuevo)) {
      setState(() {
        _pasoMedido = paso?.id;
        _huecoMedido = nuevo;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback(_medir);
  }

  /// Más de medio píxel: por debajo es ruido de redondeo y no vale la pena
  /// redibujar.
  bool _cambioSignificativo(Rect? a, Rect? b) {
    if (a == null || b == null) return a != b;
    return (a.left - b.left).abs() > 0.5 ||
        (a.top - b.top).abs() > 0.5 ||
        (a.right - b.right).abs() > 0.5 ||
        (a.bottom - b.bottom).abs() > 0.5;
  }

  /// Si la marca del paso actual cambió de dueño (el elemento se recreó, como
  /// al cruzar el ancho de escritorio), el hueco ya no apunta a nada y la
  /// pantalla ya no está donde se había desplazado: se vuelve a preparar el
  /// paso. No se hace mientras ya se está preparando; la versión se mira de
  /// nuevo al terminar.
  void _vigilarMarca(ModeloPasoRecorrido? paso) {
    final marca = paso?.marca;
    if (paso == null || marca == null) {
      _pasoVigilado = null;
      return;
    }
    final version = widget.registro.version(marca);
    if (_pasoVigilado != paso.id) {
      _pasoVigilado = paso.id;
      _versionVigilada = version;
      return;
    }
    if (version != _versionVigilada && !widget.controlador.preparando) {
      _versionVigilada = version;
      widget.controlador.reprepararPasoActual();
      return;
    }
    // La marca volvió con el mismo dueño (por ejemplo, su pestaña volvió a
    // verse, o llegaron los resultados): el paso estaba centrado y ahora
    // puede señalarla.
    if (!widget.controlador.marcaPresente &&
        !widget.controlador.preparando &&
        widget.registro.estaDisponible(marca)) {
      widget.controlador.reprepararPasoActual();
    }
  }

  /// Lleva el foco al botón principal cuando aparece un paso nuevo.
  void _enfocarSiCorresponde() {
    final controlador = widget.controlador;
    final paso = controlador.pasoActual;
    if (paso == null || controlador.preparando || _pasoEnfocado == paso.id) {
      return;
    }
    _pasoEnfocado = paso.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focoPrincipal.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controlador = widget.controlador;
    final paso = controlador.pasoActual;
    if (paso == null) return const SizedBox.shrink();

    final esMovil = MediaQuery.sizeOf(context).width < anchoEscritorioPostLogin;
    final relleno = MediaQuery.paddingOf(context);
    final preparando = controlador.preparando;
    // En la bienvenida la tarjeta se queda: ahí «Comenzar» muestra su
    // indicador mientras se espera a los resultados.
    final ocultarTarjeta =
        preparando && paso.tipo != TipoPasoRecorrido.bienvenida;
    final conHueco =
        !preparando && paso.marca != null && controlador.marcaPresente;
    final objetivo = conHueco && _pasoMedido == paso.id ? _huecoMedido : null;

    final tarjeta = IgnorePointer(
      ignoring: ocultarTarjeta,
      child: AnimatedOpacity(
        opacity: ocultarTarjeta ? 0 : 1,
        duration: EstilosRecorrido.duracion(
          context,
          const Duration(milliseconds: 180),
        ),
        child: AnimatedSwitcher(
          duration: EstilosRecorrido.duracion(
            context,
            const Duration(milliseconds: 200),
          ),
          // Solo la tarjeta actual: la saliente no debe quedar debajo ni
          // compartir el nodo de foco del botón principal.
          layoutBuilder: (actual, anteriores) =>
              actual ?? const SizedBox.shrink(),
          child: Semantics(
            key: ValueKey(paso.id),
            container: true,
            explicitChildNodes: true,
            scopesRoute: true,
            namesRoute: true,
            label: 'Recorrido guiado',
            child: TarjetaPasoRecorrido(
              paso: paso,
              descripcion: paso.descripcionPara(
                esMovil: esMovil,
                conMarca: controlador.marcaPresente,
              ),
              numeroDePaso: controlador.numeroDePaso,
              totalPasos: controlador.totalPasos,
              preparando: preparando,
              puedeRetroceder: controlador.puedeRetroceder,
              // En el cierre el botón principal termina el recorrido; en el
              // resto avanza.
              alSiguiente: paso.tipo == TipoPasoRecorrido.cierre
                  ? controlador.finalizar
                  : controlador.siguiente,
              alAnterior: controlador.anterior,
              alSaltar: controlador.omitir,
              alCerrar: controlador.cerrarPorUsuario,
              focoPrincipal: _focoPrincipal,
            ),
          ),
        ),
      ),
    );

    // De afuera hacia adentro: sin desplazamiento primario (las flechas y la
    // rueda no deben mover Inicio por debajo), tipografía propia (la capa
    // vive fuera del Scaffold), «atrás» de Android = cerrar, y atajos.
    return PrimaryScrollController.none(
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: EstilosRecorrido.cuerpo(),
          child: PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) controlador.cerrarPorUsuario();
            },
            // Solo Esc y las flechas. Enter y Espacio NO se enlazan: deben
            // activar el botón que tenga el foco (Enter sobre «Saltar
            // tutorial» salta, no avanza).
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.escape):
                    controlador.cerrarPorUsuario,
                const SingleActivator(LogicalKeyboardKey.arrowRight):
                    controlador.siguiente,
                const SingleActivator(LogicalKeyboardKey.arrowLeft):
                    controlador.anterior,
              },
              child: FocusScope(
                node: _ambitoFoco,
                child: AnimatedOpacity(
                  opacity: _aparecio ? 1 : 0,
                  duration: EstilosRecorrido.duracion(
                    context,
                    const Duration(milliseconds: 250),
                  ),
                  child: _HuecoAnimado(
                    objetivo: objetivo,
                    pasoId: paso.id,
                    tarjeta: tarjeta,
                    constructor: (context, hueco, apertura, tarjeta) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Bloquea toques y rueda en toda la pantalla, también
                          // sobre el hueco. No usa `ModalBarrier` porque suena
                          // al tocarlo.
                          Listener(
                            behavior: HitTestBehavior.opaque,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.basic,
                              child: ExcludeSemantics(
                                child: CustomPaint(
                                  painter: PintorFocoRecorrido(
                                    hueco: hueco,
                                    apertura: apertura,
                                  ),
                                  size: Size.infinite,
                                ),
                              ),
                            ),
                          ),
                          DisposicionTarjetaRecorrido(
                            relleno: relleno,
                            // Se mide desde el borde visible del hueco, no
                            // desde el del elemento.
                            hueco: hueco?.inflate(PintorFocoRecorrido.holgura),
                            child: tarjeta,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Anima el hueco al pasar de un paso a otro.
///
/// Solo se anima el cambio de un paso a otro cuando hay hueco en los dos. Si
/// el hueco se mueve dentro del mismo paso (la ventana se redimensionó),
/// salta: así no queda rezagado respecto al elemento. Cuando el hueco aparece
/// donde antes no había (al terminar de desplazarse hacia un paso), se abre
/// con un fundido en lugar de aparecer de golpe.
class _HuecoAnimado extends StatefulWidget {
  const _HuecoAnimado({
    required this.objetivo,
    required this.pasoId,
    required this.tarjeta,
    required this.constructor,
  });

  /// Hueco al que se debe llegar, o `null` si no hay.
  final Rect? objetivo;
  final String pasoId;

  /// Se construye una sola vez y se pasa a [constructor]: no se reconstruye
  /// en cada cuadro de la animación, solo cambia su posición.
  final Widget tarjeta;

  /// Recibe el hueco a pintar y su [apertura] (de 0, velo entero, a 1, hueco
  /// abierto).
  final Widget Function(
    BuildContext context,
    Rect? hueco,
    double apertura,
    Widget tarjeta,
  )
  constructor;

  @override
  State<_HuecoAnimado> createState() => _HuecoAnimadoState();
}

class _HuecoAnimadoState extends State<_HuecoAnimado>
    with TickerProviderStateMixin {
  late final AnimationController _animacion = AnimationController(vsync: this);
  late final AnimationController _aparicion = AnimationController(
    vsync: this,
    value: 1,
  );
  Rect? _desde;

  /// Hueco que se ve hacia [objetivo]: a medio camino mientras dura la
  /// animación.
  Rect? _visible(Rect? objetivo) {
    final desde = _desde;
    if (objetivo == null || desde == null || !_animacion.isAnimating) {
      return objetivo;
    }
    return Rect.lerp(
      desde,
      objetivo,
      Curves.easeOutCubic.transform(_animacion.value),
    );
  }

  @override
  void didUpdateWidget(_HuecoAnimado oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.objetivo == widget.objetivo &&
        oldWidget.pasoId == widget.pasoId) {
      return;
    }
    final antes = _visible(oldWidget.objetivo);
    final duracion = EstilosRecorrido.duracion(
      context,
      const Duration(milliseconds: 260),
    );
    if (oldWidget.objetivo == null &&
        widget.objetivo != null &&
        duracion > Duration.zero) {
      _aparicion.duration = duracion;
      _aparicion.forward(from: 0);
    }
    if (oldWidget.pasoId != widget.pasoId &&
        antes != null &&
        widget.objetivo != null &&
        duracion > Duration.zero) {
      _desde = antes;
      _animacion.duration = duracion;
      _animacion.forward(from: 0);
    } else {
      _desde = null;
      _animacion.stop();
    }
  }

  @override
  void dispose() {
    _animacion.dispose();
    _aparicion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animacion, _aparicion]),
      child: widget.tarjeta,
      builder: (context, tarjeta) => widget.constructor(
        context,
        _visible(widget.objetivo),
        Curves.easeOut.transform(_aparicion.value),
        tarjeta!,
      ),
    );
  }
}
