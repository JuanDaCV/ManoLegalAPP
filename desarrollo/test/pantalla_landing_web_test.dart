import 'package:desarrollo/configuracion/configuracion_landing.dart';
import 'package:desarrollo/modelo/especialidad_abogado.dart';
import 'package:desarrollo/modelo/ubicacion_cali.dart';
import 'package:desarrollo/vista/autenticacion/pantalla_landing_web.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/banda_hechos_landing.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/barra_landing.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/estilos_landing.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/navegacion_landing.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/pie_landing.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/verificacion_landing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  late List<String> destinos;

  setUp(() {
    // Sin red en las pruebas: el texto usa la tipografía del tema.
    EstilosLanding.usarTipografiaDeMarca = false;
    destinos = [];
    NavegacionLanding.interceptor = destinos.add;
  });

  tearDown(() => NavegacionLanding.interceptor = null);

  Future<void> montar(
    WidgetTester tester, {
    double ancho = 1440,
    double alto = 900,
    double escalaTexto = 1,
  }) async {
    tester.view.physicalSize = Size(ancho, alto);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, hijo) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(escalaTexto),
          ),
          child: hijo!,
        ),
        home: const PantallaLandingWeb(),
      ),
    );
    await tester.pump();
  }

  ScrollPosition posicion(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  /// Recorre toda la página para que cada sección se construya y se mida.
  Future<void> recorrer(WidgetTester tester) async {
    final p = posicion(tester);
    var destino = 0.0;
    while (destino < p.maxScrollExtent) {
      destino += 700;
      p.jumpTo(destino.clamp(0, p.maxScrollExtent));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'offset $destino');
    }
    p.jumpTo(0);
    await tester.pump();
  }

  /// Deja el widget a mitad de la ventana, lejos de la barra fija.
  Future<void> centrar(WidgetTester tester, Finder buscar) async {
    await Scrollable.ensureVisible(
      tester.element(buscar.first),
      alignment: 0.5,
    );
    await tester.pump();
  }

  Future<void> tocar(WidgetTester tester, Finder buscar) async {
    await centrar(tester, buscar);
    await tester.tap(buscar.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('diseño adaptable', () {
    for (final ancho in const [
      280.0,
      320.0,
      375.0,
      390.0,
      430.0,
      600.0,
      768.0,
      1024.0,
      1280.0,
      1440.0,
      1920.0,
      2560.0,
    ]) {
      testWidgets('no desborda a ${ancho.toInt()} px', (tester) async {
        await montar(tester, ancho: ancho);
        expect(tester.takeException(), isNull);
        await recorrer(tester);
      });
    }

    for (final ancho in const [390.0, 1440.0]) {
      testWidgets('no desborda con texto al 150 % a ${ancho.toInt()} px', (
        tester,
      ) async {
        await montar(tester, ancho: ancho, escalaTexto: 1.5);
        expect(tester.takeException(), isNull);
        await recorrer(tester);
      });
    }

    testWidgets('no desborda al redimensionar la ventana', (tester) async {
      await montar(tester, ancho: 1440);
      for (final tamano in const [
        Size(1000, 800),
        Size(390, 844),
        Size(700, 900),
        Size(1440, 900),
      ]) {
        tester.view.physicalSize = tamano;
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$tamano');
      }
    });
  });

  group('navegación', () {
    testWidgets('"Encontrar abogado" del hero lleva a explorar sin cuenta', (
      tester,
    ) async {
      await montar(tester);
      await tocar(tester, find.text('Encontrar abogado'));
      expect(destinos, ['explorar']);
    });

    for (final ancho in const [1440.0, 390.0]) {
      testWidgets(
        '"Ingresar" de la barra abre el panel visitante a ${ancho.toInt()} px',
        (tester) async {
          await montar(tester, ancho: ancho);
          final barra = find.byType(BarraLanding);
          await tester.tap(
            find.descendant(
              of: barra,
              matching: find.widgetWithText(OutlinedButton, 'Ingresar'),
            ),
          );
          await tester.pump();
          expect(destinos, ['explorar']);
        },
      );
    }

    testWidgets('"Ingresar" del pie sigue llevando al inicio de sesión', (
      tester,
    ) async {
      await montar(tester);
      posicion(tester).jumpTo(posicion(tester).maxScrollExtent);
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(PieLanding),
          matching: find.text('Ingresar'),
        ),
      );
      await tester.pump();
      expect(destinos, ['login']);
    });

    testWidgets('"Crea tu cuenta" lleva al registro', (tester) async {
      await montar(tester);
      await tocar(tester, find.text('Crea tu cuenta'));
      expect(destinos, ['registro']);
    });

    testWidgets('el menú móvil ofrece "Crear cuenta"', (tester) async {
      await montar(tester, ancho: 390);
      await tester.tap(find.byTooltip('Abrir menú'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Especialidades'), findsWidgets);
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Crear cuenta'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(destinos, ['registro']);
    });

    testWidgets('la barra lleva a la sección de verificación', (tester) async {
      await montar(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(BarraLanding),
          matching: find.text('Verificación'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find
            .text(
              'Un perfil verificado pasó por una revisión, no solo por un '
              'formulario',
            )
            .hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('"No sé qué área necesito" baja hasta Lexus', (tester) async {
      await montar(tester);
      await tocar(tester, find.text('No sé qué área necesito'));
      expect(
        find.text('¿No sabes qué tipo de abogado necesitas?').hitTestable(),
        findsOneWidget,
      );
    });
  });

  group('descarga de la app', () {
    testWidgets('en escritorio abre un diálogo con las tres descargas', (
      tester,
    ) async {
      await montar(tester);
      await tocar(tester, find.text('Descargar la app'));

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Descarga ManoLegal para Android'), findsOneWidget);
      expect(find.text('Google Drive'), findsOneWidget);
      expect(find.text('MediaFire'), findsOneWidget);
      expect(find.text('MEGA'), findsOneWidget);
      expect(find.text('Abrir en una pestaña nueva'), findsNWidgets(3));
      expect(find.text('Enlace pendiente'), findsNothing);

      await tester.tap(find.text('Google Drive'));
      await tester.pump();
      expect(destinos, ['externo:${ConfiguracionLanding.descargaGoogleDrive}']);

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('en móvil abre una hoja inferior', (tester) async {
      await montar(tester, ancho: 390);
      await tocar(tester, find.text('Descargar la app'));

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Google Drive'), findsOneWidget);
      expect(find.text('Abrir en una pestaña nueva'), findsNWidgets(3));
    });

    testWidgets('"Usar ManoLegal en la Web" cierra y va al inicio de sesión', (
      tester,
    ) async {
      await montar(tester);
      await tocar(tester, find.text('Descargar la app'));
      await tester.tap(find.text('Usar ManoLegal en la Web'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(destinos, ['login']);
    });
  });

  group('contenido', () {
    testWidgets('el pie enlaza las cuatro redes oficiales', (tester) async {
      await montar(tester);
      posicion(tester).jumpTo(posicion(tester).maxScrollExtent);
      await tester.pump();

      expect(find.text('Redes oficiales: próximamente'), findsNothing);
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is FaIcon &&
              w.icon?.codePoint == FontAwesomeIcons.instagram.codePoint,
        ),
      );
      await tester.pump();
      expect(destinos, ['externo:${ConfiguracionLanding.instagram}']);
    });

    testWidgets('muestra todas las especialidades', (tester) async {
      await montar(tester);
      for (final e in EspecialidadAbogado.values) {
        final etiqueta = e == EspecialidadAbogado.otra
            ? 'Otras áreas'
            : e.textoLegible;
        expect(find.text(etiqueta), findsOneWidget, reason: etiqueta);
      }
    });

    testWidgets('los datos de la banda salen de los enums y las listas', (
      tester,
    ) async {
      await montar(tester);
      final areas = EspecialidadAbogado.values
          .where((e) => e != EspecialidadAbogado.otra)
          .length;
      Finder enBanda(String texto) => find.descendant(
        of: find.byType(BandaHechosLanding),
        matching: find.text(texto),
      );
      expect(enBanda('$areas'), findsOneWidget);
      expect(enBanda('${UbicacionCali.values.length}'), findsOneWidget);
      expect(enBanda('${documentosObligatorios.length}'), findsOneWidget);
      expect(enBanda('Web · Android'), findsOneWidget);
    });

    testWidgets('el perfil es una ilustración rotulada con la insignia', (
      tester,
    ) async {
      await montar(tester);
      expect(find.text('Ilustración'), findsOneWidget);
      expect(find.text('Verificado'), findsWidgets);
      expect(find.text('Reseñas de clientes'), findsWidgets);
    });

    testWidgets('no promete Google Play ni inventa contacto', (tester) async {
      await montar(tester);
      expect(find.textContaining('Próximamente en Google Play'), findsNothing);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('el acordeón abre una pregunta a la vez', (tester) async {
      await montar(tester);
      const p1 = '¿Cuesta algo usar ManoLegal?';
      const p2 = '¿Cómo contacto a un abogado?';
      await tocar(tester, find.text(p1));
      expect(find.textContaining('no tiene pagos'), findsOneWidget);

      await tocar(tester, find.text(p2));
      expect(find.textContaining('no tiene pagos'), findsNothing);
      expect(find.textContaining('no intermedia'), findsOneWidget);
    });
  });

  testWidgets('no deja temporizadores pendientes al salir', (tester) async {
    await montar(tester);
    await recorrer(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
