import 'dart:async';

import 'package:desarrollo/configuracion/configuracion_recorrido_cliente.dart';
import 'package:desarrollo/controlador/controlador_recorrido.dart';
import 'package:desarrollo/controlador/servicio_estado_recorrido.dart';
import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/ambito_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/anfitrion_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/colocacion_tarjeta_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/estilos_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/pintor_foco_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/registro_marcas_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/tarjeta_paso_recorrido.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_recorrido.dart';

const _claveUid = 'manolegal.recorrido.cliente.v1.uid-1';

const _claveBuscador = Key('buscador-real');
const _claveFiltros = Key('filtros-falso');
const _claveTarjeta = Key('tarjeta-falsa');
const _claveInsignia = Key('insignia-falsa');
const _claveVerPerfil = Key('ver-perfil-falso');

ModeloPasoRecorrido _paso(String id) {
  return ConfiguracionRecorridoCliente.pasos.firstWhere((p) => p.id == id);
}

void main() {
  late AlmacenMemoria almacen;
  late RegistroMarcasRecorrido registro;
  late ControladorRecorrido controlador;
  late ScrollController scroll;

  /// La pantalla de fondo es un contenido largo con los elementos que el
  /// recorrido señala. Estos notificadores permiten cambiarlo en pleno
  /// recorrido, como lo hacen los resultados que llegan tarde.
  late ValueNotifier<bool> hayTarjeta;
  late ValueNotifier<bool> insigniaVisible;
  late ValueNotifier<bool> cargando;
  late ValueNotifier<int> generacionBuscador;

  /// Cuántas veces se pulsó el botón «Filtros falso» del fondo.
  var pulsaciones = 0;

  setUp(() {
    // Sin red en las pruebas: el título usa la tipografía del tema.
    EstilosRecorrido.usarTipografiaDeMarca = false;
    almacen = AlmacenMemoria();
    registro = RegistroMarcasRecorrido();
    scroll = ScrollController();
    hayTarjeta = ValueNotifier(true);
    insigniaVisible = ValueNotifier(true);
    cargando = ValueNotifier(false);
    generacionBuscador = ValueNotifier(0);
    pulsaciones = 0;
    controlador = ControladorRecorrido(
      pasos: ConfiguracionRecorridoCliente.pasos,
      servicio: ServicioEstadoRecorridoLocal(almacen: almacen),
      vista: registro,
      obtenerUid: () => 'uid-1',
      esperaBuscador: const Duration(milliseconds: 30),
      esperaResultados: const Duration(milliseconds: 30),
      intervaloSondeo: const Duration(milliseconds: 1),
    );
    addTearDown(() {
      EstilosRecorrido.usarTipografiaDeMarca = true;
      controlador.dispose();
      scroll.dispose();
      hayTarjeta.dispose();
      insigniaVisible.dispose();
      cargando.dispose();
      generacionBuscador.dispose();
    });
  });

  Widget tarjetaFalsa() {
    return MarcaRecorrido(
      id: MarcaRecorridoId.tarjeta,
      child: Container(
        key: _claveTarjeta,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: insigniaVisible,
              builder: (context, visible, _) => Visibility(
                visible: visible,
                maintainState: true,
                child: const MarcaRecorrido(
                  id: MarcaRecorridoId.insignia,
                  child: Text('Verificado', key: _claveInsignia),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: MarcaRecorrido(
                id: MarcaRecorridoId.verPerfil,
                child: ElevatedButton(
                  key: _claveVerPerfil,
                  onPressed: () {},
                  child: const Text('Ver perfil falso'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget contenido() {
    return SingleChildScrollView(
      controller: scroll,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 700),
            ValueListenableBuilder<int>(
              valueListenable: generacionBuscador,
              // Con otra clave la marca se recrea, como al cruzar los 900 px.
              builder: (context, generacion, _) => MarcaRecorrido(
                key: ValueKey(generacion),
                id: MarcaRecorridoId.buscador,
                child: const SizedBox(
                  key: _claveBuscador,
                  height: 72,
                  width: double.infinity,
                  child: Center(child: Text('Buscador real')),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: MarcaRecorrido(
                id: MarcaRecorridoId.filtros,
                child: ElevatedButton(
                  key: _claveFiltros,
                  onPressed: () => pulsaciones++,
                  child: const Text('Filtros falso'),
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: cargando,
              builder: (context, cargandoAhora, _) => cargandoAhora
                  ? const MarcaRecorrido(
                      id: MarcaRecorridoId.cargandoResultados,
                      child: SizedBox(
                        height: 40,
                        child: Center(child: Text('Cargando falso')),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<bool>(
              valueListenable: hayTarjeta,
              builder: (context, hay, _) =>
                  hay ? tarjetaFalsa() : const SizedBox.shrink(),
            ),
            const SizedBox(height: 900),
          ],
        ),
      ),
    );
  }

  Widget aplicacion({double escalaTexto = 1, bool reducirMovimiento = false}) {
    return MaterialApp(
      builder: (context, hijo) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(escalaTexto),
          disableAnimations: reducirMovimiento,
        ),
        child: hijo!,
      ),
      home: Scaffold(
        body: AnfitrionRecorrido(
          controlador: controlador,
          registro: registro,
          child: contenido(),
        ),
      ),
    );
  }

  Future<void> montar(
    WidgetTester tester, {
    Size tamano = const Size(390, 844),
    double escalaTexto = 1,
    bool reducirMovimiento = false,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      aplicacion(
        escalaTexto: escalaTexto,
        reducirMovimiento: reducirMovimiento,
      ),
    );
  }

  /// Muestra la bienvenida y deja terminar su fundido de entrada. Mientras la
  /// capa está transparente, su semántica no existe: por eso se espera a que
  /// termine antes de mirarla.
  Future<void> iniciar(WidgetTester tester) async {
    await controlador.iniciarSiCorresponde();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  /// Lo que un lector de pantalla recorrería, unido en un texto. Se usa el
  /// recorrido simulado y no `find.bySemanticsLabel` para comprobar que algo NO
  /// está: ese buscador mira la semántica que cada render object guardó, que
  /// puede ser de un cuadro en el que el elemento todavía no estaba excluido.
  String etiquetasDeSemantica(WidgetTester tester) {
    return tester.semantics
        .simulatedAccessibilityTraversal()
        // El texto de ayuda de un botón (su tooltip) también se anuncia.
        .expand((SemanticsNode nodo) => [nodo.label, nodo.tooltip])
        .where((texto) => texto.isNotEmpty)
        .join('\n');
  }

  /// Un toque del usuario y todo lo que desencadena (desplazamientos y
  /// fundidos incluidos).
  Future<void> pulsar(WidgetTester tester, String texto) async {
    await tester.tap(find.text(texto));
    await tester.pumpAndSettle();
  }

  /// Avanza un paso sin pasar por el botón: para recorridos largos donde el
  /// layout, y no el toque, es lo que se comprueba.
  Future<void> avanzar(WidgetTester tester) async {
    unawaited(controlador.siguiente());
    await tester.pumpAndSettle();
  }

  PintorFocoRecorrido pintor(WidgetTester tester) {
    return tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((pintura) => pintura.painter)
        .whereType<PintorFocoRecorrido>()
        .single;
  }

  Rect tarjeta(WidgetTester tester) {
    return tester.getRect(find.byType(TarjetaPasoRecorrido));
  }

  /// El hueco pintado envuelve al elemento sin agrandarlo (el pintor le suma su
  /// holgura al dibujar). Vale mientras el elemento esté a más de 8 px del borde
  /// del área visible, que es como lo deja el desplazamiento del recorrido.
  void expectCerca(Rect? real, Rect esperado) {
    expect(real, isNotNull);
    expect(real!.left, closeTo(esperado.left, 1), reason: '$real vs $esperado');
    expect(real.top, closeTo(esperado.top, 1), reason: '$real vs $esperado');
    expect(
      real.right,
      closeTo(esperado.right, 1),
      reason: '$real vs $esperado',
    );
    expect(
      real.bottom,
      closeTo(esperado.bottom, 1),
      reason: '$real vs $esperado',
    );
  }

  bool estaDentro(Rect recto, Rect area) {
    return recto.left >= area.left - 0.5 &&
        recto.top >= area.top - 0.5 &&
        recto.right <= area.right + 0.5 &&
        recto.bottom <= area.bottom + 0.5;
  }

  group('aparición', () {
    testWidgets('no hay nada en pantalla hasta que el controlador lo decide', (
      tester,
    ) async {
      await montar(tester);

      expect(find.byType(TarjetaPasoRecorrido), findsNothing);
      final velos = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((pintura) => pintura.painter)
          .whereType<PintorFocoRecorrido>();
      expect(velos, isEmpty);
    });

    testWidgets('la bienvenida aparece centrada, con el foco en «Comenzar»', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);

      expect(controlador.visible, isTrue);
      expect(find.text('Bienvenido a ManoLegal'), findsOneWidget);
      expect(find.text(_paso('bienvenida').descripcion), findsOneWidget);
      expect(find.text('Saltar tutorial'), findsOneWidget);
      expect(find.text('Comenzar'), findsOneWidget);
      expect(find.byTooltip('Cerrar recorrido'), findsOneWidget);
      expect(find.textContaining('PASO'), findsNothing);
      expect(pintor(tester).hueco, isNull);

      final recto = tarjeta(tester);
      expect(recto.width, 358);
      expect(recto.center.dx, closeTo(195, 1));
      expect(recto.center.dy, closeTo(422, 1));

      final comenzar = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Comenzar'),
      );
      expect(comenzar.focusNode!.hasPrimaryFocus, isTrue);
    });

    testWidgets('empezar y terminar no vuelve a montar la pantalla de fondo', (
      tester,
    ) async {
      await montar(tester);
      final antes = tester.element(find.text('Buscador real'));

      await iniciar(tester);
      expect(
        identical(tester.element(find.text('Buscador real')), antes),
        isTrue,
      );

      await controlador.omitir();
      await tester.pumpAndSettle();
      expect(
        identical(tester.element(find.text('Buscador real')), antes),
        isTrue,
      );
    });
  });

  group('paso a paso', () {
    testWidgets(
      '«Comenzar» lleva al primer paso y desplaza el buscador a la vista',
      (tester) async {
        await montar(tester);
        await iniciar(tester);
        expect(scroll.offset, 0);

        await pulsar(tester, 'Comenzar');

        expect(find.text('PASO 1 DE 5'), findsOneWidget);
        expect(find.text('Busca abogados'), findsOneWidget);
        expect(find.text(_paso('buscador').descripcion), findsOneWidget);
        expect(find.text('Anterior'), findsNothing);
        expect(scroll.offset, greaterThan(0));

        final objetivo = tester.getRect(find.byKey(_claveBuscador));
        expect(objetivo.top, greaterThanOrEqualTo(0));
        expect(objetivo.bottom, lessThanOrEqualTo(844));
        final hueco = pintor(tester).hueco;
        expectCerca(hueco, objetivo);
        expect(pintor(tester).apertura, 1);
        expect(
          tarjeta(tester).overlaps(hueco!.inflate(PintorFocoRecorrido.holgura)),
          isFalse,
        );
      },
    );

    testWidgets('recorre los cinco pasos señalando cada elemento real', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');

      final esperados = [
        ('PASO 1 DE 5', 'Busca abogados', _claveBuscador),
        ('PASO 2 DE 5', 'Filtra los resultados', _claveFiltros),
        ('PASO 3 DE 5', 'Conoce a cada abogado', _claveTarjeta),
        ('PASO 4 DE 5', 'Ver perfil', _claveVerPerfil),
        ('PASO 5 DE 5', 'Abogados verificados', _claveInsignia),
      ];
      for (final (indice, esperado) in esperados.indexed) {
        final (etiqueta, titulo, clave) = esperado;
        if (indice > 0) await pulsar(tester, 'Siguiente');

        expect(find.text(etiqueta), findsOneWidget, reason: titulo);
        expect(find.text(titulo), findsOneWidget, reason: titulo);
        final hueco = pintor(tester).hueco;
        expectCerca(hueco, tester.getRect(find.byKey(clave)));
        final recto = tarjeta(tester);
        expect(
          recto.overlaps(hueco!.inflate(PintorFocoRecorrido.holgura)),
          isFalse,
          reason: titulo,
        );
        expect(
          estaDentro(recto, const Rect.fromLTWH(0, 0, 390, 844)),
          isTrue,
          reason: titulo,
        );
      }

      await pulsar(tester, 'Siguiente');
      expect(find.text('Listo'), findsOneWidget);
      expect(pintor(tester).hueco, isNull);
      expect(find.textContaining('PASO'), findsNothing);
    });

    testWidgets('«Anterior» vuelve al paso previo y no existe en el primero', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');
      expect(find.text('Anterior'), findsNothing);

      await pulsar(tester, 'Siguiente');
      expect(find.text('PASO 2 DE 5'), findsOneWidget);
      expect(find.text('Anterior'), findsOneWidget);

      await pulsar(tester, 'Anterior');

      expect(find.text('PASO 1 DE 5'), findsOneWidget);
      expectCerca(
        pintor(tester).hueco,
        tester.getRect(find.byKey(_claveBuscador)),
      );
      expect(find.text('Anterior'), findsNothing);
    });

    testWidgets(
      'en el teléfono el paso de los filtros habla del botón «Filtros»',
      (tester) async {
        await montar(tester);
        await iniciar(tester);
        await pulsar(tester, 'Comenzar');

        await pulsar(tester, 'Siguiente');

        expect(find.text(_paso('filtros').descripcionMovil!), findsOneWidget);
        expect(find.text(_paso('filtros').descripcion), findsNothing);
      },
    );

    testWidgets('en escritorio el paso de los filtros habla del panel', (
      tester,
    ) async {
      await montar(tester, tamano: const Size(1024, 768));
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');

      await pulsar(tester, 'Siguiente');

      expect(find.text(_paso('filtros').descripcion), findsOneWidget);
      expect(find.text(_paso('filtros').descripcionMovil!), findsNothing);
    });

    testWidgets(
      'el último paso es el cierre; «Comenzar» lo da por completado',
      (tester) async {
        await montar(tester);
        await iniciar(tester);
        await pulsar(tester, 'Comenzar');
        for (var i = 0; i < 5; i++) {
          await pulsar(tester, 'Siguiente');
        }

        expect(find.text('Listo'), findsOneWidget);
        expect(find.text(_paso('cierre').descripcion), findsOneWidget);
        expect(find.byIcon(Icons.task_alt), findsOneWidget);
        expect(find.text('Anterior'), findsOneWidget);
        expect(find.text('Saltar tutorial'), findsNothing);
        expect(find.text('Siguiente'), findsNothing);
        expect(pintor(tester).hueco, isNull);

        await pulsar(tester, 'Comenzar');

        expect(controlador.visible, isFalse);
        expect(almacen.datos, {_claveUid: 'completado'});
        expect(find.byType(TarjetaPasoRecorrido), findsNothing);
      },
    );

    testWidgets('desde el cierre, «Anterior» vuelve al último paso señalado', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');
      for (var i = 0; i < 5; i++) {
        await pulsar(tester, 'Siguiente');
      }

      await pulsar(tester, 'Anterior');

      expect(find.text('PASO 5 DE 5'), findsOneWidget);
      expectCerca(
        pintor(tester).hueco,
        tester.getRect(find.byKey(_claveInsignia)),
      );
    });

    testWidgets(
      'mientras se desplaza se ocultan la tarjeta y el hueco, y no reciben toques',
      (tester) async {
        await montar(tester);
        await iniciar(tester);

        await tester.tap(find.text('Comenzar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(controlador.preparando, isTrue);
        expect(pintor(tester).hueco, isNull);
        expect(find.byType(TarjetaPasoRecorrido).hitTestable(), findsNothing);

        await tester.pumpAndSettle();

        expect(controlador.preparando, isFalse);
        expect(pintor(tester).hueco, isNotNull);
        expect(find.byType(TarjetaPasoRecorrido).hitTestable(), findsOneWidget);
      },
    );

    testWidgets(
      'el hueco se abre con un fundido en lugar de aparecer de golpe',
      (tester) async {
        await montar(tester);
        await iniciar(tester);
        await tester.tap(find.text('Comenzar'));
        await tester.pump();

        final aperturas = <double>[];
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          if (pintor(tester).hueco != null) {
            aperturas.add(pintor(tester).apertura);
          }
        }

        expect(aperturas, isNotEmpty);
        expect(
          aperturas.any((a) => a > 0 && a < 1),
          isTrue,
          reason: '$aperturas',
        );
        expect(aperturas.last, 1);
      },
    );

    testWidgets(
      'el texto del paso se anuncia como región en vivo y el título como encabezado',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await montar(tester);
        await iniciar(tester);

        expect(
          tester.getSemantics(find.text('Bienvenido a ManoLegal')),
          matchesSemantics(label: 'Bienvenido a ManoLegal', isHeader: true),
        );
        expect(
          tester.getSemantics(find.text(_paso('bienvenida').descripcion)),
          matchesSemantics(
            label: _paso('bienvenida').descripcion,
            isLiveRegion: true,
          ),
        );

        semantica.dispose();
      },
    );
  });

  group('teclado', () {
    testWidgets('la flecha derecha avanza y la izquierda retrocede', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);

      // En la bienvenida, avanzar es «Comenzar».
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('PASO 1 DE 5'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('PASO 2 DE 5'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('PASO 1 DE 5'), findsOneWidget);

      // Antes del primer paso no hay nada: no vuelve a la bienvenida.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('PASO 1 DE 5'), findsOneWidget);
      expect(controlador.visible, isTrue);
    });

    testWidgets('la flecha derecha en el cierre no termina el recorrido', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');
      for (var i = 0; i < 5; i++) {
        await pulsar(tester, 'Siguiente');
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(find.text('Listo'), findsOneWidget);
      expect(controlador.visible, isTrue);
      expect(almacen.escrituras, isEmpty);
    });

    testWidgets('Esc cierra el recorrido y lo recuerda como omitido', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(controlador.visible, isFalse);
      expect(find.byType(TarjetaPasoRecorrido), findsNothing);
      expect(almacen.datos, {_claveUid: 'omitido'});
      expect(tester.takeException(), isNull);
    });

    testWidgets('Esc también cierra si el foco no está en un botón', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      final comenzar = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Comenzar'),
      );
      expect(comenzar.focusNode!.hasPrimaryFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(controlador.visible, isFalse);
      expect(almacen.datos, {_claveUid: 'omitido'});
    });

    testWidgets('Enter sobre «Saltar tutorial» salta el recorrido, no avanza', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');
      await pulsar(tester, 'Siguiente');
      expect(find.text('PASO 2 DE 5'), findsOneWidget);

      final saltar = Focus.of(tester.element(find.text('Saltar tutorial')));
      saltar.requestFocus();
      await tester.pump();
      expect(saltar.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(controlador.visible, isFalse);
      expect(find.text('PASO 3 DE 5'), findsNothing);
      expect(almacen.datos, {_claveUid: 'omitido'});
    });

    testWidgets('Enter sobre «Comenzar», que ya tiene el foco, avanza', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('PASO 1 DE 5'), findsOneWidget);
    });

    testWidgets('el foco acompaña al botón principal en cada paso', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');

      for (var i = 0; i < 3; i++) {
        final siguiente = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Siguiente'),
        );
        expect(
          siguiente.focusNode!.hasPrimaryFocus,
          isTrue,
          reason: 'paso ${i + 1}',
        );
        await pulsar(tester, 'Siguiente');
      }
    });

    testWidgets(
      'Tab da vueltas dentro de la tarjeta y el fondo no recibe el foco',
      (tester) async {
        await montar(tester);
        final fondo = Focus.of(tester.element(find.text('Filtros falso')));
        expect(fondo.canRequestFocus, isTrue);

        await iniciar(tester);
        expect(fondo.canRequestFocus, isFalse);

        for (var i = 0; i < 8; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final foco = FocusManager.instance.primaryFocus;
          expect(foco, isNotNull, reason: 'Tab ${i + 1}');
          expect(
            foco!.context!
                .findAncestorWidgetOfExactType<TarjetaPasoRecorrido>(),
            isNotNull,
            reason: 'Tab ${i + 1}',
          );
        }
        expect(fondo.hasFocus, isFalse);

        await controlador.omitir();
        await tester.pumpAndSettle();
        expect(fondo.canRequestFocus, isTrue);
      },
    );
  });

  group('cerrar', () {
    testWidgets('la X cierra y lo recuerda como omitido', (tester) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');

      await tester.tap(find.byTooltip('Cerrar recorrido'));
      await tester.pumpAndSettle();

      expect(controlador.visible, isFalse);
      expect(almacen.datos, {_claveUid: 'omitido'});
      expect(find.byType(TarjetaPasoRecorrido), findsNothing);
    });

    testWidgets(
      '«Saltar tutorial» cierra desde la bienvenida y lo recuerda como omitido',
      (tester) async {
        await montar(tester);
        await iniciar(tester);

        await pulsar(tester, 'Saltar tutorial');

        expect(controlador.visible, isFalse);
        expect(almacen.datos, {_claveUid: 'omitido'});
        expect(scroll.offset, 0);
      },
    );

    testWidgets(
      'el botón atrás del sistema cierra el recorrido en lugar de salir',
      (tester) async {
        await montar(tester);
        await iniciar(tester);
        await pulsar(tester, 'Comenzar');

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(controlador.visible, isFalse);
        expect(almacen.datos, {_claveUid: 'omitido'});
        expect(find.byType(TarjetaPasoRecorrido), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('cerrar en el cierre cuenta como completado', (tester) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');
      for (var i = 0; i < 5; i++) {
        await pulsar(tester, 'Siguiente');
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(almacen.datos, {_claveUid: 'completado'});
    });

    testWidgets('al cerrar, el fondo vuelve a responder', (tester) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Saltar tutorial');

      await tester.tap(find.text('Filtros falso'));
      await tester.pump();

      expect(pulsaciones, 1);
    });
  });

  group('fondo bloqueado', () {
    testWidgets('los toques no llegan al fondo, tampoco sobre el hueco', (
      tester,
    ) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');
      await pulsar(tester, 'Siguiente');
      expect(find.text('PASO 2 DE 5'), findsOneWidget);

      // El centro del botón del fondo queda justo en el hueco.
      final centro = tester.getCenter(find.byKey(_claveFiltros));
      expectCerca(
        pintor(tester).hueco,
        tester.getRect(find.byKey(_claveFiltros)),
      );
      await tester.tapAt(centro);
      await tester.pump();

      expect(pulsaciones, 0);
      expect(controlador.visible, isTrue);
    });

    testWidgets('tocar el velo no cierra el recorrido', (tester) async {
      await montar(tester);
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');

      await tester.tapAt(const Offset(5, 5));
      await tester.tapAt(const Offset(385, 20));
      await tester.pumpAndSettle();

      expect(controlador.visible, isTrue);
      expect(find.text('PASO 1 DE 5'), findsOneWidget);
      expect(almacen.escrituras, isEmpty);
    });

    testWidgets('el fondo sale del lector de pantalla y vuelve al cerrar', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(tester);
      expect(etiquetasDeSemantica(tester), contains('Buscador real'));
      expect(etiquetasDeSemantica(tester), contains('Filtros falso'));

      await iniciar(tester);
      var etiquetas = etiquetasDeSemantica(tester);
      expect(etiquetas, isNot(contains('Buscador real')));
      expect(etiquetas, isNot(contains('Filtros falso')));
      expect(etiquetas, contains('Bienvenido a ManoLegal'));
      expect(etiquetas, contains('Cerrar recorrido'));

      await pulsar(tester, 'Comenzar');
      etiquetas = etiquetasDeSemantica(tester);
      expect(etiquetas, contains('Paso 1 de 5'));
      expect(etiquetas, isNot(contains('Buscador real')));

      await controlador.omitir();
      await tester.pumpAndSettle();
      etiquetas = etiquetasDeSemantica(tester);
      expect(etiquetas, contains('Buscador real'));
      expect(etiquetas, contains('Filtros falso'));
      expect(etiquetas, isNot(contains('Paso 1 de 5')));
      expect(etiquetas, isNot(contains('Cerrar recorrido')));

      semantica.dispose();
    });

    testWidgets(
      'la capa no hereda el controlador de desplazamiento de la ruta',
      (tester) async {
        await montar(tester);
        // En Android la ruta ofrece un controlador primario a sus pantallas.
        expect(
          PrimaryScrollController.maybeOf(
            tester.element(find.byType(Scaffold)),
          ),
          isNotNull,
        );

        await iniciar(tester);

        expect(
          PrimaryScrollController.maybeOf(
            tester.element(find.byType(TarjetaPasoRecorrido)),
          ),
          isNull,
        );
      },
    );
  });

  group('desplazamiento de Inicio', () {
    testWidgets('al terminar vuelve a donde estaba', (tester) async {
      await montar(tester);
      scroll.jumpTo(50);
      await tester.pump();
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');
      await pulsar(tester, 'Siguiente');
      expect(scroll.offset, greaterThan(100));

      await tester.tap(find.byTooltip('Cerrar recorrido'));
      await tester.pumpAndSettle();

      expect(scroll.offset, 50);
    });

    testWidgets('al saltar desde la bienvenida no se mueve', (tester) async {
      await montar(tester);
      scroll.jumpTo(50);
      await tester.pump();
      await iniciar(tester);

      await pulsar(tester, 'Saltar tutorial');

      expect(scroll.offset, 50);
    });
  });

  group('reducir movimiento', () {
    testWidgets('todo ocurre sin animaciones', (tester) async {
      await montar(tester, reducirMovimiento: true);
      await controlador.iniciarSiCorresponde();
      await tester.pump();
      expect(find.text('Bienvenido a ManoLegal'), findsOneWidget);

      await tester.tap(find.text('Comenzar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('PASO 1 DE 5'), findsOneWidget);
      expect(scroll.offset, greaterThan(0));
      expectCerca(
        pintor(tester).hueco,
        tester.getRect(find.byKey(_claveBuscador)),
      );
      expect(pintor(tester).apertura, 1);
      expect(controlador.preparando, isFalse);

      await tester.tap(find.text('Siguiente'));
      await tester.pump();
      await tester.pump();

      expect(find.text('PASO 2 DE 5'), findsOneWidget);
      expectCerca(
        pintor(tester).hueco,
        tester.getRect(find.byKey(_claveFiltros)),
      );
    });

    testWidgets('al terminar, Inicio vuelve a su sitio de inmediato', (
      tester,
    ) async {
      await montar(tester, reducirMovimiento: true);
      scroll.jumpTo(50);
      await tester.pump();
      await controlador.iniciarSiCorresponde();
      await tester.pump();
      await tester.tap(find.text('Comenzar'));
      await tester.pump();
      await tester.pump();
      expect(scroll.offset, greaterThan(100));

      await controlador.omitir();

      expect(scroll.offset, 50);
    });
  });

  group('sin tarjetas de abogados', () {
    testWidgets('son 3 pasos y la verificación va centrada, sin hueco', (
      tester,
    ) async {
      hayTarjeta.value = false;
      await montar(tester);
      await iniciar(tester);

      await pulsar(tester, 'Comenzar');
      expect(find.text('PASO 1 DE 3'), findsOneWidget);
      await pulsar(tester, 'Siguiente');
      expect(find.text('PASO 2 DE 3'), findsOneWidget);
      await pulsar(tester, 'Siguiente');

      expect(find.text('PASO 3 DE 3'), findsOneWidget);
      expect(find.text('Abogados verificados'), findsOneWidget);
      expect(
        find.text(_paso('verificacion').descripcionSinMarca!),
        findsOneWidget,
      );
      expect(find.text(_paso('verificacion').descripcion), findsNothing);
      expect(pintor(tester).hueco, isNull);
      final recto = tarjeta(tester);
      expect(recto.center.dx, closeTo(195, 1));
      expect(recto.center.dy, closeTo(422, 1));

      await pulsar(tester, 'Siguiente');
      expect(find.text('Listo'), findsOneWidget);
    });

    testWidgets(
      'si llegan las tarjetas, el paso se desplaza hasta la insignia',
      (tester) async {
        hayTarjeta.value = false;
        await montar(tester);
        await iniciar(tester);
        await pulsar(tester, 'Comenzar');
        await pulsar(tester, 'Siguiente');
        await pulsar(tester, 'Siguiente');
        expect(
          find.text(_paso('verificacion').descripcionSinMarca!),
          findsOneWidget,
        );
        expect(pintor(tester).hueco, isNull);

        // Llegan los abogados mientras el cliente está en este paso.
        hayTarjeta.value = true;
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('PASO 3 DE 3'), findsOneWidget);
        expect(find.text(_paso('verificacion').descripcion), findsOneWidget);
        expect(
          find.text(_paso('verificacion').descripcionSinMarca!),
          findsNothing,
        );
        expectCerca(
          pintor(tester).hueco,
          tester.getRect(find.byKey(_claveInsignia)),
        );
      },
    );

    testWidgets(
      'si la marca vuelve a verse con el mismo dueño, el paso la señala',
      (tester) async {
        insigniaVisible.value = false;
        await montar(tester);
        await iniciar(tester);
        await pulsar(tester, 'Comenzar');
        for (var i = 0; i < 4; i++) {
          await pulsar(tester, 'Siguiente');
        }
        expect(find.text('PASO 5 DE 5'), findsOneWidget);
        expect(
          find.text(_paso('verificacion').descripcionSinMarca!),
          findsOneWidget,
        );
        expect(pintor(tester).hueco, isNull);

        insigniaVisible.value = true;
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text(_paso('verificacion').descripcion), findsOneWidget);
        expectCerca(
          pintor(tester).hueco,
          tester.getRect(find.byKey(_claveInsignia)),
        );
      },
    );
  });

  group('espera de resultados', () {
    testWidgets(
      'mientras cargan los abogados, «Comenzar» muestra un indicador y espera',
      (tester) async {
        cargando.value = true;
        await montar(tester);
        await iniciar(tester);

        await tester.tap(find.text('Comenzar'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Comenzar'), findsNothing);
        expect(find.text('Bienvenido a ManoLegal'), findsOneWidget);
        expect(controlador.preparando, isTrue);

        // El botón no responde mientras tanto.
        await tester.tap(
          find.byType(CircularProgressIndicator),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 3));
        expect(controlador.pasoActual!.id, 'bienvenida');

        cargando.value = false;
        // Primero se va el indicador del fondo; el sondeo lo nota en el cuadro
        // siguiente.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 5));
        await tester.pumpAndSettle();

        expect(find.text('PASO 1 DE 5'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'si la carga no termina, sigue pasado el límite con lo que haya',
      (tester) async {
        cargando.value = true;
        await montar(tester);
        await iniciar(tester);
        await tester.tap(find.text('Comenzar'));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 60));
        await tester.pumpAndSettle();

        expect(find.text('PASO 1 DE 5'), findsOneWidget);
        expect(
          registro.estaDisponible(MarcaRecorridoId.cargandoResultados),
          isTrue,
        );
      },
    );

    testWidgets('cerrar mientras espera no deja nada pendiente', (
      tester,
    ) async {
      cargando.value = true;
      await montar(tester);
      await iniciar(tester);
      await tester.tap(find.text('Comenzar'));
      await tester.pump();

      await tester.tap(find.byTooltip('Cerrar recorrido'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controlador.visible, isFalse);
      expect(almacen.datos, {_claveUid: 'omitido'});
      expect(find.byType(TarjetaPasoRecorrido), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('marcas que se recrean', () {
    testWidgets(
      'si la marca del paso se recrea, vuelve a desplazarse hasta ella',
      (tester) async {
        await montar(tester);
        await iniciar(tester);
        await pulsar(tester, 'Comenzar');
        final desplazamiento = scroll.offset;
        expect(desplazamiento, greaterThan(0));

        var preparado = false;
        controlador.addListener(
          () => preparado = preparado || controlador.preparando,
        );
        // El contenido se vuelve a montar arriba del todo, como al cruzar los 900 px.
        scroll.jumpTo(0);
        generacionBuscador.value++;
        await tester.pump();
        await tester.pumpAndSettle();

        expect(preparado, isTrue);
        expect(controlador.preparando, isFalse);
        expect(scroll.offset, closeTo(desplazamiento, 1));
        expect(find.text('PASO 1 DE 5'), findsOneWidget);
        expectCerca(
          pintor(tester).hueco,
          tester.getRect(find.byKey(_claveBuscador)),
        );
      },
    );
  });

  group('tamaños de pantalla', () {
    // Las pruebas dibujan el texto con la fuente de prueba, cuyas letras miden
    // lo mismo que su alto: unas 2,2 veces más anchas que Roboto o Inter. Por
    // eso aquí «150 %» ya es una exigencia muy superior a la real, y en el
    // 200 % de un teléfono de 320 px la tarjeta se superpone al elemento para
    // que quepan la cabecera, unas líneas y los botones.
    const casos = <(Size, double)>[
      (Size(320, 568), 1),
      (Size(375, 667), 1),
      (Size(390, 844), 1),
      (Size(430, 932), 1),
      (Size(600, 960), 1),
      (Size(768, 1024), 1),
      (Size(1024, 768), 1),
      (Size(1280, 800), 1),
      (Size(1440, 900), 1),
      (Size(1920, 1080), 1),
      (Size(320, 568), 1.5),
      (Size(320, 640), 2),
      (Size(1440, 900), 2),
    ];

    for (final (tamano, escala) in casos) {
      final etiqueta =
          '${tamano.width.toInt()}×${tamano.height.toInt()}'
          '${escala == 1 ? '' : ' con el texto al ${(escala * 100).round()} %'}';

      testWidgets('a $etiqueta cada paso cabe en pantalla y no desborda', (
        tester,
      ) async {
        await montar(tester, tamano: tamano, escalaTexto: escala);
        await iniciar(tester);
        final pantalla = Offset.zero & tamano;
        final seguro = pantalla.deflate(16);

        void verificar(String paso) {
          final recto = tarjeta(tester);
          expect(
            estaDentro(recto, seguro),
            isTrue,
            reason: '$paso: $recto fuera de $seguro',
          );
          expect(tester.takeException(), isNull, reason: paso);

          // Los botones y la X quedan enteros dentro de la tarjeta, y esta
          // dentro de la pantalla: si el texto no cabe, es el texto el que se
          // desplaza, no los botones.
          final controles = find.descendant(
            of: find.byType(TarjetaPasoRecorrido),
            matching: find.byWidgetPredicate(
              (w) => w is ButtonStyleButton || w is IconButton,
            ),
          );
          expect(controles, findsWidgets, reason: paso);
          for (final control in controles.evaluate()) {
            final recto = tester.getRect(find.byWidget(control.widget));
            expect(
              estaDentro(recto, tarjeta(tester)),
              isTrue,
              reason: '$paso: botón $recto fuera de la tarjeta',
            );
            expect(
              estaDentro(recto, pantalla),
              isTrue,
              reason: '$paso: botón $recto fuera de la pantalla',
            );
          }

          // Si la tarjeta no va superpuesta, no tapa el hueco.
          final hueco = pintor(tester).hueco;
          if (hueco == null) return;
          final agrandado = hueco.inflate(PintorFocoRecorrido.holgura);
          final colocacion = tester
              .renderObject<RenderDisposicionTarjetaRecorrido>(
                find.byType(DisposicionTarjetaRecorrido),
              )
              .colocacion!;
          if (colocacion.lado != LadoTarjetaRecorrido.superpuesta) {
            expect(
              recto.overlaps(agrandado),
              isFalse,
              reason: '$paso: $recto tapa $agrandado',
            );
          }
        }

        verificar('bienvenida');
        while (controlador.pasoActual!.tipo != TipoPasoRecorrido.cierre) {
          await avanzar(tester);
          verificar(controlador.pasoActual!.id);
        }
        expect(controlador.pasoActual!.id, 'cierre');
      });
    }

    testWidgets(
      'al redimensionar a mitad del recorrido, el hueco y la tarjeta siguen al elemento',
      (tester) async {
        await montar(tester, tamano: const Size(1024, 768));
        await iniciar(tester);
        await pulsar(tester, 'Comenzar');
        expect(pintor(tester).hueco!.width, closeTo(992, 1));

        tester.view.physicalSize = const Size(390, 844);
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final hueco = pintor(tester).hueco;
        expectCerca(hueco, tester.getRect(find.byKey(_claveBuscador)));
        expect(hueco!.width, closeTo(358, 1));
        final recto = tarjeta(tester);
        expect(
          estaDentro(recto, const Rect.fromLTRB(16, 16, 374, 828)),
          isTrue,
          reason: '$recto',
        );
        expect(find.text('PASO 1 DE 5'), findsOneWidget);
      },
    );

    testWidgets('al cruzar los 900 px cambia el texto de los filtros', (
      tester,
    ) async {
      await montar(tester, tamano: const Size(1024, 768));
      await iniciar(tester);
      await pulsar(tester, 'Comenzar');
      await pulsar(tester, 'Siguiente');
      expect(find.text(_paso('filtros').descripcion), findsOneWidget);

      tester.view.physicalSize = const Size(390, 844);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text(_paso('filtros').descripcionMovil!), findsOneWidget);

      tester.view.physicalSize = const Size(1024, 768);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text(_paso('filtros').descripcion), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'al desmontar la pantalla con el recorrido visible no hay errores',
      (tester) async {
        await montar(tester);
        await iniciar(tester);
        await pulsar(tester, 'Comenzar');
        expect(find.byType(TarjetaPasoRecorrido), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        expect(find.byType(TarjetaPasoRecorrido), findsNothing);
        expect(tester.takeException(), isNull);
        // El recorrido no se guarda: si la pantalla se cierra a mitad, volverá.
        expect(almacen.escrituras, isEmpty);
      },
    );
  });

  group('botones siempre a la vista', () {
    // Antes de fijar los botones dentro de la tarjeta, en un teléfono bajo el
    // texto empujaba «Siguiente» fuera de la parte visible de la tarjeta. Con
    // este ajuste, tocar fuera de la pantalla es un error y no un aviso.
    setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
    tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

    const casos = <(Size, double)>[
      (Size(320, 568), 1),
      (Size(320, 568), 1.5),
      (Size(320, 640), 1),
      // Con el texto al 200 %, la cabecera y los botones fijos no cabían en
      // el poco espacio que quedaba junto al elemento y «Siguiente» se cortaba.
      (Size(320, 640), 2),
      (Size(360, 640), 1),
      (Size(375, 667), 1),
    ];

    for (final (tamano, escala) in casos) {
      final etiqueta =
          '${tamano.width.toInt()}×${tamano.height.toInt()}'
          '${escala == 1 ? '' : ' con el texto al ${(escala * 100).round()} %'}';

      testWidgets(
        'a $etiqueta el botón principal de cada paso está entero en pantalla',
        (tester) async {
          await montar(tester, tamano: tamano, escalaTexto: escala);
          await iniciar(tester);
          final pantalla = Offset.zero & tamano;

          void principalEnPantalla(String texto, String paso) {
            final recto = tester.getRect(find.text(texto));
            expect(
              estaDentro(recto, pantalla),
              isTrue,
              reason: '$paso: «$texto» en $recto fuera de $pantalla',
            );
          }

          principalEnPantalla('Comenzar', 'bienvenida');
          await pulsar(tester, 'Comenzar');
          for (var i = 1; i <= 5; i++) {
            expect(find.text('PASO $i DE 5'), findsOneWidget);
            principalEnPantalla('Siguiente', 'paso $i');
            // Recorrerlo solo con toques demuestra que el botón se alcanza.
            await pulsar(tester, 'Siguiente');
          }

          expect(find.text('Listo'), findsOneWidget);
          principalEnPantalla('Comenzar', 'cierre');
          await pulsar(tester, 'Comenzar');
          expect(almacen.datos, {_claveUid: 'completado'});
        },
      );
    }
  });

  group('accesibilidad', () {
    for (final tamano in const [Size(390, 844), Size(1440, 900)]) {
      testWidgets(
        'los blancos táctiles miden al menos 48 dp y tienen etiqueta a ${tamano.width.toInt()} px',
        (tester) async {
          final semantica = tester.ensureSemantics();
          await montar(tester, tamano: tamano);
          await iniciar(tester);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

          await pulsar(tester, 'Comenzar');
          await pulsar(tester, 'Siguiente');
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

          semantica.dispose();
        },
      );
    }

    testWidgets(
      'cada paso se anuncia con su número y la tarjeta es un diálogo',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await montar(tester);
        await iniciar(tester);

        // La tarjeta es un diálogo: da nombre a la ruta y el lector de pantalla
        // anuncia «Recorrido guiado» al aparecer.
        expect(
          tester.getSemantics(find.byType(TarjetaPasoRecorrido)),
          isSemantics(
            label: 'Recorrido guiado',
            namesRoute: true,
            scopesRoute: true,
          ),
        );

        await pulsar(tester, 'Comenzar');
        var etiquetas = etiquetasDeSemantica(tester);
        expect(etiquetas, contains('Paso 1 de 5'));
        // El texto en mayúsculas se excluye: el lector no lo repite.
        expect(etiquetas, isNot(contains('PASO 1 DE 5')));

        await pulsar(tester, 'Siguiente');
        etiquetas = etiquetasDeSemantica(tester);
        expect(etiquetas, contains('Paso 2 de 5'));
        expect(etiquetas, isNot(contains('Paso 1 de 5')));

        semantica.dispose();
      },
    );
  });
}
