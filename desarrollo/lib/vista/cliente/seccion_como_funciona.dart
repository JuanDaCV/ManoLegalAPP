import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../controlador/controlador_como_funciona.dart';
import '../../modelo/modelo_capitulo_como_funciona.dart';
import '../../modelo/modelo_paso_recorrido.dart';
import '../compartido/plantilla_post_login.dart';
import '../compartido/widgets/recorrido/ambito_recorrido.dart';
import 'widgets/como_funciona/capitulo_como_funciona.dart';
import 'widgets/como_funciona/encabezado_como_funciona.dart';
import 'widgets/como_funciona/estilos_como_funciona.dart';
import 'widgets/como_funciona/fondo_como_funciona.dart';
import 'widgets/como_funciona/indice_capitulos.dart';
import 'widgets/como_funciona/medidas_como_funciona.dart';

/// Sección "Cómo funciona": una guía en seis videos breves sobre qué es
/// ManoLegal y cómo se usa.
///
/// Diseño adaptable: tarjetas en una columna en teléfonos, y en escritorio un
/// riel de capítulos fijo junto a escenas amplias (ver [MedidasComoFunciona]).
/// Los videos no se cargan hasta que el usuario toca uno, y solo hay uno
/// activo a la vez (ver [ControladorComoFunciona]).
class SeccionComoFunciona extends StatefulWidget {
  const SeccionComoFunciona({super.key, this.crearControlador});

  /// Permite a las pruebas inyectar un controlador con reproductores falsos:
  /// el real necesita la plataforma de video, que no existe en `flutter test`.
  @visibleForTesting
  final ControladorComoFunciona Function()? crearControlador;

  @override
  State<SeccionComoFunciona> createState() => _SeccionComoFuncionaState();
}

class _SeccionComoFuncionaState extends State<SeccionComoFunciona> {
  late final ControladorComoFunciona _controlador = (widget.crearControlador ?? ControladorComoFunciona.new)();

  /// Controlador de desplazamiento propio. En Android e iOS, una lista sin
  /// controlador adopta el de la ruta, que comparten las cuatro pestañas del
  /// panel: desplazar esta movería también a las demás.
  final ScrollController _scroll = ScrollController();
  final List<GlobalKey> _claves = List.generate(capitulosComoFunciona.length, (_) => GlobalKey());
  final List<FocusNode> _focos = List.generate(
    capitulosComoFunciona.length,
    (i) => FocusNode(debugLabel: 'Reproducir capítulo ${i + 1}'),
  );

  /// Capítulo que se está leyendo, para el riel (solo en pantalla ancha).
  final ValueNotifier<int> _capituloVisible = ValueNotifier<int>(0);

  /// Hasta que la pestaña se muestra por primera vez no se construye nada: el
  /// panel monta las cuatro secciones al iniciar, y decodificar seis portadas
  /// de una pestaña que nadie ha abierto sería trabajo perdido.
  bool _yaFueVisible = false;

  /// Si el último ancho visto era de escritorio (desde el umbral del panel).
  /// `null` hasta la primera lectura: la primera vez no hay nada que comparar.
  bool? _eraEscritorio;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_actualizarCapituloVisible);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = Visibility.of(context);
    if (visible) {
      _yaFueVisible = true;
    } else if (_yaFueVisible) {
      // Pestaña oculta: se pausa, pero no se libera ni se reanuda al volver.
      // No se mira TickerMode: la pantalla completa propia también lo apagaría
      // y el video no debe pausarse por abrirla.
      _controlador.pausar();
      if (_controlador.controlesDelNavegador && (_controlador.video?.value.hasError ?? false)) {
        _controlador.detener();
      }
    }

    // Cruzar el umbral del panel (escritorio frente a móvil) reubica la sección
    // en el árbol, y en Web el motor saca y vuelve a insertar el DOM del video:
    // el navegador, por especificación, pausa un elemento multimedia que sale
    // del documento. Se avisa al controlador para que reanude lo que sonaba.
    // Va después de la pausa por pestaña oculta: un video escondido no debe
    // reanudarse.
    final esEscritorio = MediaQuery.sizeOf(context).width >= anchoEscritorioPostLogin;
    if (_eraEscritorio != null && _eraEscritorio != esEscritorio) _controlador.reanudarTrasReubicar();
    _eraEscritorio = esEscritorio;
  }

  @override
  void dispose() {
    _scroll.removeListener(_actualizarCapituloVisible);
    _scroll.dispose();
    for (final foco in _focos) {
      foco.dispose();
    }
    _capituloVisible.dispose();
    _controlador.dispose();
    super.dispose();
  }

  /// Capítulo activo = el último cuyo borde superior ya pasó el 35% de la
  /// altura visible. Al llegar al final de la página gana el último capítulo,
  /// aunque no alcance esa línea.
  void _actualizarCapituloVisible() {
    if (!_scroll.hasClients) return;
    final posicion = _scroll.position;
    var activo = 0;
    if (posicion.maxScrollExtent > 0 && posicion.extentAfter < 1) {
      activo = _claves.length - 1;
    } else {
      final limite = posicion.pixels + posicion.viewportDimension * 0.35;
      for (var i = 0; i < _claves.length; i++) {
        final caja = _claves[i].currentContext?.findRenderObject();
        if (caja is! RenderBox || !caja.attached) continue;
        final inicio = RenderAbstractViewport.maybeOf(caja)?.getOffsetToReveal(caja, 0).offset;
        if (inicio != null && inicio <= limite) activo = i;
      }
    }
    if (_capituloVisible.value != activo) _capituloVisible.value = activo;
  }

  Future<void> _irACapitulo(int indice) async {
    final activo = _controlador.capituloActivo;
    if (activo != null && activo.numero != capitulosComoFunciona[indice].numero) {
      unawaited(_controlador.pausar());
    }
    final contexto = _claves[indice].currentContext;
    if (contexto == null) return;
    await Scrollable.ensureVisible(
      contexto,
      duration: EstilosComoFunciona.duracion(context, const Duration(milliseconds: 450)),
      curve: Curves.easeInOutCubic,
      alignment: 0,
    );
    if (!mounted) return;
    // Un foco sin montar guarda la petición y la cumple cuando vuelve a
    // montarse: si el capítulo ya tiene un video, robaría el foco más tarde.
    final foco = _focos[indice];
    if (foco.parent != null) foco.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    if (!_yaFueVisible) return const SizedBox.expand();
    return LayoutBuilder(
      builder: (context, restricciones) {
        final medidas = MedidasComoFunciona.de(ancho: restricciones.maxWidth, alto: restricciones.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            const FondoComoFunciona(),
            CustomScrollView(
              controller: _scroll,
              slivers: medidas.modo == ModoComoFunciona.ancho
                  ? _construirSliversAnchos(medidas)
                  : _construirSlivers(medidas),
            ),
          ],
        );
      },
    );
  }

  Widget _capitulo(int indice, MedidasComoFunciona medidas) {
    final capitulo = CapituloComoFunciona(
      capitulo: capitulosComoFunciona[indice],
      medidas: medidas,
      controlador: _controlador,
      focoReproducir: _focos[indice],
      // Alterna: capítulos impares con el contorno a la derecha, pares a la izquierda.
      contornoALaDerecha: indice.isEven,
    );
    // El recorrido guiado explica un capítulo, no todos: el primero.
    return indice == 0 ? MarcaRecorrido(id: MarcaRecorridoId.comoFuncionaCapitulo, child: capitulo) : capitulo;
  }

  /// El encabezado es la marca de arranque del recorrido: existe en los dos
  /// diseños en cuanto la sección se ve por primera vez.
  Widget _encabezado(MedidasComoFunciona medidas) {
    return MarcaRecorrido(
      id: MarcaRecorridoId.comoFuncionaEncabezado,
      child: EncabezadoComoFunciona(medidas: medidas, alIrACapitulo: _irACapitulo),
    );
  }

  /// Teléfono y tableta: encabezado, índice de números y las tarjetas.
  List<Widget> _construirSlivers(MedidasComoFunciona medidas) {
    final compacto = medidas.modo == ModoComoFunciona.compacto;
    final separacion = compacto ? 20.0 : 28.0;
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(medidas.rellenoHorizontal, compacto ? 16 : 24, medidas.rellenoHorizontal, 32),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _encabezado(medidas),
              const SizedBox(height: 16),
              // Mismo id que el riel de escritorio: nunca están los dos a la vez.
              MarcaRecorrido(
                id: MarcaRecorridoId.comoFuncionaIndice,
                child: ChipsCapitulos(capitulos: capitulosComoFunciona, alSeleccionar: _irACapitulo),
              ),
              // Cada tarjeta lleva media separación arriba y media abajo: al
              // saltar a un capítulo queda aire sobre él, no pegado al borde.
              SizedBox(height: 20 - separacion / 2),
              for (var i = 0; i < capitulosComoFunciona.length; i++)
                KeyedSubtree(
                  key: _claves[i],
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: separacion / 2),
                    child: _capitulo(i, medidas),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  /// Escritorio: encabezado y, debajo, el riel fijo junto a las escenas.
  ///
  /// El riel es un `PinnedHeaderSliver` dentro de un `SliverCrossAxisGroup`:
  /// se queda arriba mientras se recorren los capítulos y, al terminar el
  /// grupo, el último capítulo lo empuja hacia arriba en vez de quedar encima
  /// del pie de la página.
  List<Widget> _construirSliversAnchos(MedidasComoFunciona medidas) {
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(medidas.margen, 24, medidas.margen, 0),
        sliver: SliverToBoxAdapter(child: _encabezado(medidas)),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 40)),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(medidas.margen, 0, medidas.margen, 64),
        sliver: SliverCrossAxisGroup(
          slivers: [
            SliverConstrainedCrossAxis(
              maxExtent: medidas.anchoRiel,
              sliver: PinnedHeaderSliver(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ConstrainedBox(
                    // 24 px de aire arriba y otros tantos abajo. El mínimo evita una
                    // restricción negativa si la sección se aloja en un espacio ínfimo.
                    constraints: BoxConstraints(maxHeight: math.max(120, medidas.alto - 48)),
                    child: MarcaRecorrido(
                      id: MarcaRecorridoId.comoFuncionaIndice,
                      child: RielCapitulos(
                        capitulos: capitulosComoFunciona,
                        capituloVisible: _capituloVisible,
                        alSeleccionar: _irACapitulo,
                        compacto: medidas.rielCompacto,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverCrossAxisExpanded(
              flex: 1,
              sliver: SliverPadding(
                padding: EdgeInsets.only(left: medidas.separacionRiel),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < capitulosComoFunciona.length; i++)
                        KeyedSubtree(key: _claves[i], child: _capitulo(i, medidas)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
