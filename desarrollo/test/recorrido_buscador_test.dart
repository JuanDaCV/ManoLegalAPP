import 'dart:async';

import 'package:desarrollo/configuracion/configuracion_recorrido_cliente.dart';
import 'package:desarrollo/controlador/controlador_busqueda_abogados.dart';
import 'package:desarrollo/controlador/controlador_recorrido.dart';
import 'package:desarrollo/controlador/servicio_estado_recorrido.dart';
import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:desarrollo/modelo/modelo_resultado_abogado.dart';
import 'package:desarrollo/modelo/ubicacion_cali.dart';
import 'package:desarrollo/vista/compartido/widgets/buscador_abogados.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/ambito_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/anfitrion_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/estilos_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/pintor_foco_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/registro_marcas_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/tarjeta_paso_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/tarjeta_abogado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_recorrido.dart';

/// Los widgets marcados con [id] que hay en el árbol.
Finder _marcas(MarcaRecorridoId id) {
  return find.byWidgetPredicate((w) => w is MarcaRecorrido && w.id == id);
}

/// El registrador privado que `MarcaRecorrido` agrega cuando hay un ámbito.
Finder _registradores() {
  return find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_RegistradorMarca',
  );
}

/// Ejecuta [cuerpo] recogiendo los errores que reporta el framework en lugar
/// de dejar que hagan fallar la prueba. Devuelve lo recogido.
Future<List<FlutterErrorDetails>> _recogerErrores(
  Future<void> Function() cuerpo,
) async {
  final errores = <FlutterErrorDetails>[];
  final original = FlutterError.onError;
  FlutterError.onError = errores.add;
  try {
    await cuerpo();
  } finally {
    FlutterError.onError = original;
  }
  return errores;
}

/// El panel de filtros de escritorio ya trae, desde antes del recorrido, un
/// aviso de depuración de Flutter: sus `CheckboxListTile` van dentro de un
/// contenedor blanco que tapa su fondo. No afecta al recorrido ni a la versión
/// publicada (solo existe con las aserciones activas); aquí se acepta ese
/// aviso, y solo ese, para poder probar el layout de escritorio.
void _esperarSoloElAvisoDeListTile(List<FlutterErrorDetails> errores) {
  for (final error in errores) {
    expect(
      error.exceptionAsString(),
      contains('ListTile background color or ink splashes may be invisible'),
    );
  }
}

/// Un abogado de prueba: lo mínimo que cambia de uno a otro en estas pruebas.
class _Abogado {
  const _Abogado(this.uid, this.nombre, {this.verificado = true});

  final String uid;
  final String nombre;
  final bool verificado;
}

void main() {
  late RegistroMarcasRecorrido registro;

  setUp(() {
    // Sin red en las pruebas: los títulos usan la tipografía del tema.
    BuscadorAbogados.usarTipografiaDeMarca = false;
    EstilosRecorrido.usarTipografiaDeMarca = false;
    registro = RegistroMarcasRecorrido();
  });

  tearDown(() {
    BuscadorAbogados.usarTipografiaDeMarca = true;
    EstilosRecorrido.usarTipografiaDeMarca = true;
  });

  /// Con una ubicación corta: la fuente de las pruebas dibuja cada letra del
  /// ancho de su altura, y «Ubicación no indicada» desbordaría la tarjeta de un
  /// teléfono, cosa que no pasa con la fuente real.
  PerfilPublicoFalso servicioCon(List<_Abogado> abogados) {
    return PerfilPublicoFalso([
      for (final a in abogados)
        perfilDePrueba(
          uid: a.uid,
          nombreCompleto: a.nombre,
          ubicacion: UbicacionCali.jamundi,
          verificado: a.verificado,
        ),
    ]);
  }

  /// El buscador real, con un servicio falso, dentro de un contenido que se
  /// desplaza. Por defecto bajo un ámbito de recorrido.
  Future<void> montar(
    WidgetTester tester,
    PerfilPublicoFalso servicio, {
    Size tamano = const Size(390, 844),
    bool esEscritorio = false,
    bool conAmbito = true,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // El buscador libera su controlador al desmontarse: aquí no se libera.
    final buscador = BuscadorAbogados(
      esEscritorio: esEscritorio,
      crearControlador: () =>
          ControladorBusquedaAbogados(servicioPerfilPublico: servicio),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: conAmbito
                  ? AmbitoRecorrido(registro: registro, child: buscador)
                  : buscador,
            ),
          ),
        ),
      ),
    );
    // Deja terminar la búsqueda falsa (se resuelve en microtareas).
    await tester.pump();
  }

  const dosVerificados = [
    _Abogado('a1', 'Abogada de Prueba Uno'),
    _Abogado('a2', 'Abogado de Prueba Dos'),
  ];

  group('sin abogados', () {
    testWidgets(
      'marca el buscador y los filtros, pero no la tarjeta, «Ver perfil» ni la insignia',
      (tester) async {
        await montar(tester, servicioCon(const []));

        expect(find.text('No hay abogados disponibles'), findsOneWidget);
        expect(registro.estaDisponible(MarcaRecorridoId.buscador), isTrue);
        expect(registro.estaDisponible(MarcaRecorridoId.filtros), isTrue);
        expect(registro.estaDisponible(MarcaRecorridoId.tarjeta), isFalse);
        expect(registro.estaDisponible(MarcaRecorridoId.verPerfil), isFalse);
        expect(registro.estaDisponible(MarcaRecorridoId.insignia), isFalse);
        expect(
          registro.estaDisponible(MarcaRecorridoId.cargandoResultados),
          isFalse,
        );
      },
    );

    testWidgets('con un error de búsqueda tampoco hay tarjetas que señalar', (
      tester,
    ) async {
      // El controlador deja constancia del error con `debugPrint`: se silencia
      // durante el montaje. Hay que devolverlo dentro de la prueba, porque el
      // framework comprueba que no cambió antes de ejecutar los `tearDown`.
      final original = debugPrint;
      debugPrint = (String? mensaje, {int? wrapWidth}) {};
      final servicio = servicioCon(dosVerificados)
        ..error = Exception('sin conexión');
      try {
        await montar(tester, servicio);
      } finally {
        debugPrint = original;
      }

      expect(find.text('No se pudo cargar la búsqueda'), findsOneWidget);
      expect(registro.estaDisponible(MarcaRecorridoId.buscador), isTrue);
      expect(registro.estaDisponible(MarcaRecorridoId.filtros), isTrue);
      expect(
        registro.estaDisponible(MarcaRecorridoId.cargandoResultados),
        isFalse,
      );
      expect(registro.estaDisponible(MarcaRecorridoId.tarjeta), isFalse);
      expect(registro.estaDisponible(MarcaRecorridoId.verPerfil), isFalse);
      expect(registro.estaDisponible(MarcaRecorridoId.insignia), isFalse);
    });
  });

  group('mientras cargan los resultados', () {
    testWidgets('marca el indicador de carga y todavía no hay tarjeta', (
      tester,
    ) async {
      final servicio = servicioCon(dosVerificados)..retener = Completer<void>();
      await montar(tester, servicio);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        registro.estaDisponible(MarcaRecorridoId.cargandoResultados),
        isTrue,
      );
      expect(registro.estaDisponible(MarcaRecorridoId.tarjeta), isFalse);

      servicio.retener!.complete();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        registro.estaDisponible(MarcaRecorridoId.cargandoResultados),
        isFalse,
      );
      expect(registro.estaDisponible(MarcaRecorridoId.tarjeta), isTrue);
    });

    testWidgets('el buscador y los filtros se marcan ya mientras carga', (
      tester,
    ) async {
      final servicio = servicioCon(dosVerificados)..retener = Completer<void>();
      await montar(tester, servicio);

      expect(registro.estaDisponible(MarcaRecorridoId.buscador), isTrue);
      expect(registro.estaDisponible(MarcaRecorridoId.filtros), isTrue);

      servicio.retener!.complete();
      await tester.pump();
    });
  });

  group('con abogados', () {
    testWidgets('marca la primera tarjeta, su «Ver perfil» y su insignia', (
      tester,
    ) async {
      await montar(tester, servicioCon(dosVerificados));

      expect(find.byType(TarjetaAbogado), findsNWidgets(2));
      for (final id in [
        MarcaRecorridoId.buscador,
        MarcaRecorridoId.filtros,
        MarcaRecorridoId.tarjeta,
        MarcaRecorridoId.verPerfil,
        MarcaRecorridoId.insignia,
      ]) {
        expect(registro.estaDisponible(id), isTrue, reason: id.name);
      }
    });

    testWidgets('solo la primera tarjeta registra marcas', (tester) async {
      await montar(tester, servicioCon(dosVerificados));

      // Hay dos tarjetas, dos insignias y dos botones, pero una sola marca de
      // cada: el recorrido explica una tarjeta, no todas.
      expect(find.text('Verificado'), findsNWidgets(2));
      expect(find.text('Ver perfil'), findsNWidgets(2));
      expect(_marcas(MarcaRecorridoId.tarjeta), findsOneWidget);
      expect(_marcas(MarcaRecorridoId.verPerfil), findsOneWidget);
      expect(_marcas(MarcaRecorridoId.insignia), findsOneWidget);
    });

    testWidgets('las marcas señalan los elementos de la primera tarjeta', (
      tester,
    ) async {
      await montar(tester, servicioCon(dosVerificados));

      final tarjetas = find.byType(TarjetaAbogado);
      final primera = tester.getRect(tarjetas.at(0));
      final segunda = tester.getRect(tarjetas.at(1));

      final marcaTarjeta = registro.rectoGlobal(MarcaRecorridoId.tarjeta)!;
      expect(marcaTarjeta.left, closeTo(primera.left, 1));
      expect(marcaTarjeta.top, closeTo(primera.top, 1));
      expect(marcaTarjeta.right, closeTo(primera.right, 1));
      expect(marcaTarjeta.bottom, closeTo(primera.bottom, 1));
      expect(marcaTarjeta.overlaps(segunda), isFalse);

      final insignia = registro.rectoGlobal(MarcaRecorridoId.insignia)!;
      expect(
        insignia.contains(tester.getCenter(find.text('Verificado').first)),
        isTrue,
      );
      expect(primera.contains(insignia.center), isTrue);

      final verPerfil = registro.rectoGlobal(MarcaRecorridoId.verPerfil)!;
      expect(
        verPerfil.contains(tester.getCenter(find.text('Ver perfil').first)),
        isTrue,
      );
      expect(primera.contains(verPerfil.center), isTrue);
    });

    testWidgets(
      'si la primera tarjeta no está verificada, no hay insignia que señalar',
      (tester) async {
        await montar(
          tester,
          servicioCon(const [
            _Abogado('a1', 'Abogada de Prueba Uno', verificado: false),
            _Abogado('a2', 'Abogado de Prueba Dos'),
          ]),
        );

        expect(registro.estaDisponible(MarcaRecorridoId.tarjeta), isTrue);
        expect(registro.estaDisponible(MarcaRecorridoId.verPerfil), isTrue);
        // La segunda sí está verificada, pero no es la que el recorrido explica.
        expect(find.text('Verificado'), findsOneWidget);
        expect(registro.estaDisponible(MarcaRecorridoId.insignia), isFalse);
      },
    );

    testWidgets('con un solo abogado marca igualmente su tarjeta', (
      tester,
    ) async {
      await montar(
        tester,
        servicioCon(const [_Abogado('a1', 'Abogada de Prueba Uno')]),
      );

      expect(_marcas(MarcaRecorridoId.tarjeta), findsOneWidget);
      expect(registro.estaDisponible(MarcaRecorridoId.tarjeta), isTrue);
    });
  });

  group('los filtros', () {
    testWidgets('en el teléfono se marca el botón «Filtros»', (tester) async {
      await montar(tester, servicioCon(dosVerificados));

      final boton = find.widgetWithText(OutlinedButton, 'Filtros');
      expect(boton, findsOneWidget);
      final marca = registro.rectoGlobal(MarcaRecorridoId.filtros)!;
      expect(marca.contains(tester.getCenter(boton)), isTrue);
      expect(marca.height, lessThan(80));
    });

    testWidgets('en escritorio se marca el panel de 280 px', (tester) async {
      final errores = await _recogerErrores(
        () => montar(
          tester,
          servicioCon(dosVerificados),
          tamano: const Size(1280, 900),
          esEscritorio: true,
        ),
      );
      _esperarSoloElAvisoDeListTile(errores);

      expect(find.widgetWithText(OutlinedButton, 'Filtros'), findsNothing);
      final marca = registro.rectoGlobal(MarcaRecorridoId.filtros)!;
      expect(marca.width, 280);
      expect(
        marca.contains(tester.getCenter(find.text('Especialidad'))),
        isTrue,
      );
      // La marca de los filtros es la única con ese id.
      expect(_marcas(MarcaRecorridoId.filtros), findsOneWidget);
    });

    testWidgets('en escritorio también se marca la primera tarjeta', (
      tester,
    ) async {
      final errores = await _recogerErrores(
        () => montar(
          tester,
          servicioCon(dosVerificados),
          tamano: const Size(1280, 900),
          esEscritorio: true,
        ),
      );
      _esperarSoloElAvisoDeListTile(errores);

      expect(_marcas(MarcaRecorridoId.tarjeta), findsOneWidget);
      expect(registro.estaDisponible(MarcaRecorridoId.verPerfil), isTrue);
      expect(registro.estaDisponible(MarcaRecorridoId.insignia), isTrue);
    });
  });

  group('una tarjeta suelta', () {
    const abogado = ModeloResultadoAbogado(
      uid: 'a1',
      nombreCompleto: 'Abogada de Prueba Uno',
      especialidad: 'Derecho civil',
      ubicacion: 'Cali',
      verificado: true,
      calificacion: 0,
    );

    Future<void> montarTarjeta(WidgetTester tester, {required bool marcar}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AmbitoRecorrido(
                registro: registro,
                child: TarjetaAbogado(
                  abogado: abogado,
                  esEscritorio: false,
                  onVerPerfil: () {},
                  marcarParaRecorrido: marcar,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('sin la bandera no registra nada, aunque haya ámbito', (
      tester,
    ) async {
      await montarTarjeta(tester, marcar: false);

      expect(find.byType(TarjetaAbogado), findsOneWidget);
      expect(find.byType(MarcaRecorrido), findsNothing);
      expect(registro.estaDisponible(MarcaRecorridoId.verPerfil), isFalse);
      expect(registro.estaDisponible(MarcaRecorridoId.insignia), isFalse);
      expect(registro.estaDisponible(MarcaRecorridoId.tarjeta), isFalse);
    });

    testWidgets(
      'con la bandera registra «Ver perfil» y la insignia, pero no la tarjeta',
      (tester) async {
        await montarTarjeta(tester, marcar: true);

        expect(registro.estaDisponible(MarcaRecorridoId.verPerfil), isTrue);
        expect(registro.estaDisponible(MarcaRecorridoId.insignia), isTrue);
        // La marca de la tarjeta entera la pone el buscador, no la tarjeta.
        expect(registro.estaDisponible(MarcaRecorridoId.tarjeta), isFalse);
      },
    );

    testWidgets(
      'con la bandera pero sin ámbito (Lexus, landing) no agrega nada',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TarjetaAbogado(
                  abogado: abogado,
                  esEscritorio: false,
                  onVerPerfil: () {},
                  marcarParaRecorrido: true,
                ),
              ),
            ),
          ),
        );

        expect(_registradores(), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('sin ámbito de recorrido', () {
    testWidgets('el buscador se dibuja igual que con él y no falla', (
      tester,
    ) async {
      final servicio = servicioCon(dosVerificados);
      await montar(tester, servicio);
      Rect rectoDe(Finder buscado) => tester.getRect(buscado.first);
      final conAmbito = [
        rectoDe(find.text('Buscar abogados')),
        rectoDe(find.byType(TextFormField)),
        rectoDe(find.widgetWithText(OutlinedButton, 'Filtros')),
        rectoDe(find.byType(TarjetaAbogado)),
        rectoDe(find.text('Ver perfil')),
      ];

      await tester.pumpWidget(const SizedBox());
      await montar(tester, servicio, conAmbito: false);

      expect(_registradores(), findsNothing);
      expect(find.text('Buscar abogados'), findsOneWidget);
      expect(find.text('Búsqueda'), findsOneWidget);
      expect(find.text('2 resultados encontrados'), findsOneWidget);
      expect(find.byType(TarjetaAbogado), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      final sinAmbito = [
        rectoDe(find.text('Buscar abogados')),
        rectoDe(find.byType(TextFormField)),
        rectoDe(find.widgetWithText(OutlinedButton, 'Filtros')),
        rectoDe(find.byType(TarjetaAbogado)),
        rectoDe(find.text('Ver perfil')),
      ];
      expect(sinAmbito, conAmbito);
    });

    testWidgets('sin ámbito las marcas no registran nada en ningún registro', (
      tester,
    ) async {
      await montar(tester, servicioCon(dosVerificados), conAmbito: false);

      for (final id in MarcaRecorridoId.values) {
        expect(registro.estaDisponible(id), isFalse, reason: id.name);
      }
    });
  });

  group('recorrido completo sobre el buscador real', () {
    late ControladorRecorrido controlador;
    late AlmacenMemoria almacen;

    setUp(() {
      almacen = AlmacenMemoria();
      controlador = ControladorRecorrido(
        pasos: ConfiguracionRecorridoCliente.pasos,
        servicio: ServicioEstadoRecorridoLocal(almacen: almacen),
        vista: registro,
        obtenerUid: () => 'uid-1',
        esperaBuscador: const Duration(milliseconds: 30),
        esperaResultados: const Duration(milliseconds: 30),
        intervaloSondeo: const Duration(milliseconds: 1),
      );
      addTearDown(controlador.dispose);
    });

    /// Lo que hace el panel del cliente: el buscador real, bajo un contenido
    /// largo (la bienvenida y el video de Inicio) y envuelto en el anfitrión
    /// del recorrido.
    Future<void> montarConRecorrido(
      WidgetTester tester,
      PerfilPublicoFalso servicio, {
      Size tamano = const Size(390, 844),
      bool esEscritorio = false,
    }) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnfitrionRecorrido(
              controlador: controlador,
              registro: registro,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 900),
                      BuscadorAbogados(
                        esEscritorio: esEscritorio,
                        crearControlador: () => ControladorBusquedaAbogados(
                          servicioPerfilPublico: servicio,
                        ),
                      ),
                      const SizedBox(height: 300),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await controlador.iniciarSiCorresponde();
      await tester.pump();
      await tester.pumpAndSettle();
    }

    PintorFocoRecorrido pintor(WidgetTester tester) {
      return tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((pintura) => pintura.painter)
          .whereType<PintorFocoRecorrido>()
          .single;
    }

    void expectHuecoEn(WidgetTester tester, Rect esperado) {
      final hueco = pintor(tester).hueco;
      expect(hueco, isNotNull);
      expect(
        hueco!.left,
        closeTo(esperado.left, 1),
        reason: '$hueco vs $esperado',
      );
      expect(
        hueco.top,
        closeTo(esperado.top, 1),
        reason: '$hueco vs $esperado',
      );
      expect(
        hueco.right,
        closeTo(esperado.right, 1),
        reason: '$hueco vs $esperado',
      );
      expect(
        hueco.bottom,
        closeTo(esperado.bottom, 1),
        reason: '$hueco vs $esperado',
      );
    }

    Future<void> pulsar(WidgetTester tester, String texto) async {
      await tester.tap(find.text(texto));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'señala cada elemento real, en orden, y el botón principal siempre se ve',
      (tester) async {
        await montarConRecorrido(tester, servicioCon(dosVerificados));
        const pantalla = Rect.fromLTWH(0, 0, 390, 844);
        expect(find.text('Bienvenido a ManoLegal'), findsOneWidget);

        await pulsar(tester, 'Comenzar');
        final pasos = [
          ('PASO 1 DE 5', MarcaRecorridoId.buscador),
          ('PASO 2 DE 5', MarcaRecorridoId.filtros),
          ('PASO 3 DE 5', MarcaRecorridoId.tarjeta),
          ('PASO 4 DE 5', MarcaRecorridoId.verPerfil),
          ('PASO 5 DE 5', MarcaRecorridoId.insignia),
        ];
        for (final (indice, (etiqueta, marca)) in pasos.indexed) {
          if (indice > 0) await pulsar(tester, 'Siguiente');

          expect(find.text(etiqueta), findsOneWidget);
          expectHuecoEn(tester, tester.getRect(_marcas(marca)));
          final siguiente = tester.getRect(find.text('Siguiente'));
          expect(
            pantalla.contains(siguiente.topLeft) &&
                pantalla.contains(siguiente.bottomRight),
            isTrue,
            reason: '$etiqueta: $siguiente',
          );
          final tarjeta = tester.getRect(find.byType(TarjetaPasoRecorrido));
          expect(
            tarjeta.overlaps(pintor(tester).hueco!.inflate(8)),
            isFalse,
            reason: etiqueta,
          );
        }

        // El paso de la tarjeta señala la primera, no la segunda.
        final tarjetas = find.byType(TarjetaAbogado);
        expect(
          tester.getRect(tarjetas.at(0)).top,
          lessThan(tester.getRect(tarjetas.at(1)).top),
        );

        await pulsar(tester, 'Siguiente');
        expect(find.text('Listo'), findsOneWidget);
        await pulsar(tester, 'Comenzar');
        expect(controlador.visible, isFalse);
        expect(almacen.datos, {
          'manolegal.recorrido.cliente.v1.uid-1': 'completado',
        });
      },
    );

    testWidgets('sin abogados son 3 pasos y la verificación va centrada', (
      tester,
    ) async {
      await montarConRecorrido(tester, servicioCon(const []));

      await pulsar(tester, 'Comenzar');
      expect(find.text('PASO 1 DE 3'), findsOneWidget);
      expectHuecoEn(tester, tester.getRect(_marcas(MarcaRecorridoId.buscador)));
      await pulsar(tester, 'Siguiente');
      expect(find.text('PASO 2 DE 3'), findsOneWidget);
      expectHuecoEn(tester, tester.getRect(_marcas(MarcaRecorridoId.filtros)));
      await pulsar(tester, 'Siguiente');

      expect(find.text('PASO 3 DE 3'), findsOneWidget);
      expect(find.text('Abogados verificados'), findsOneWidget);
      expect(pintor(tester).hueco, isNull);
      expect(
        find.textContaining('Los reconocerás por la insignia'),
        findsOneWidget,
      );
      final tarjeta = tester.getRect(find.byType(TarjetaPasoRecorrido));
      expect(tarjeta.center.dx, closeTo(195, 1));
      expect(tarjeta.center.dy, closeTo(422, 1));
    });

    testWidgets(
      'en escritorio el paso de los filtros deja la tarjeta junto al panel',
      (tester) async {
        final errores = await _recogerErrores(() async {
          await montarConRecorrido(
            tester,
            servicioCon(dosVerificados),
            tamano: const Size(1280, 900),
            esEscritorio: true,
          );
          await pulsar(tester, 'Comenzar');
          await pulsar(tester, 'Siguiente');
        });
        _esperarSoloElAvisoDeListTile(errores);

        expect(find.text('PASO 2 DE 5'), findsOneWidget);
        final hueco = pintor(tester).hueco!;
        expect(hueco.width, closeTo(280, 1));
        // El panel es más alto que la pantalla: el hueco se recorta al área
        // visible, con la holgura con la que el pintor lo agranda.
        const visible = Rect.fromLTWH(0, 0, 1280, 900);
        expectHuecoEn(
          tester,
          tester
              .getRect(_marcas(MarcaRecorridoId.filtros))
              .intersect(visible.deflate(PintorFocoRecorrido.holgura)),
        );
        final tarjeta = tester.getRect(find.byType(TarjetaPasoRecorrido));
        expect(tarjeta.overlaps(hueco.inflate(8)), isFalse);
        expect(
          const Rect.fromLTWH(0, 0, 1280, 900).contains(tarjeta.center),
          isTrue,
        );
        final filtros = ConfiguracionRecorridoCliente.pasos.firstWhere(
          (p) => p.id == 'filtros',
        );
        expect(find.text(filtros.descripcion), findsOneWidget);
      },
    );
  });

  group('el buscador con el controlador inyectado', () {
    testWidgets(
      'usa el servicio falso y libera su controlador al desmontarse',
      (tester) async {
        final servicio = servicioCon(dosVerificados);
        await montar(tester, servicio);
        expect(servicio.busquedas, 1);

        await tester.pumpWidget(const SizedBox());

        expect(tester.takeException(), isNull);
        expect(registro.estaDisponible(MarcaRecorridoId.buscador), isFalse);
      },
    );

    testWidgets('buscar de nuevo mantiene una sola tarjeta marcada', (
      tester,
    ) async {
      final servicio = servicioCon(dosVerificados);
      await montar(tester, servicio);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Buscar'));
      await tester.pump();
      await tester.pump();

      expect(servicio.busquedas, 2);
      expect(find.byType(TarjetaAbogado), findsNWidgets(2));
      expect(_marcas(MarcaRecorridoId.tarjeta), findsOneWidget);
      expect(registro.estaDisponible(MarcaRecorridoId.tarjeta), isTrue);
    });
  });
}
