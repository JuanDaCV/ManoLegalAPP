import 'package:desarrollo/controlador/controlador_autenticacion.dart';
import 'package:desarrollo/controlador/servicio_google.dart';
import 'package:desarrollo/vista/autenticacion/pantalla_inicio_sesion.dart';
import 'package:desarrollo/vista/widgets_comunes/panel_marca_acceso_web.dart';
import 'package:desarrollo/vista/widgets_comunes/plantilla_autenticacion.dart';
import 'package:desarrollo/vista/widgets_comunes/tarjeta_cristal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'dobles_pqrs.dart';
import 'dobles_visitante.dart';

const Size _escritorio = Size(1440, 900);
const Size _telefono = Size(390, 844);
const String _fraseInicioSesion = 'Justicia accesible, verificada';

void main() {
  void fijarVentana(WidgetTester tester, Size tamano) {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget aplicacion(Widget inicio, {bool reducirAnimaciones = false}) {
    return MaterialApp(
      builder: (context, hijo) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducirAnimaciones),
        child: hijo!,
      ),
      home: inicio,
    );
  }

  PlantillaAutenticacion plantilla({
    required bool? disenoWeb,
    MotivoAutenticacion motivo = MotivoAutenticacion.iniciarSesion,
  }) {
    return PlantillaAutenticacion(
      titulo: 'Bienvenido de nuevo',
      subtitulo: 'Ingresa tus datos.',
      motivo: motivo,
      disenoWeb: disenoWeb,
      formulario: const Text('Formulario de prueba'),
    );
  }

  /// No usa pumpAndSettle: el ícono del panel de marca anima sin fin.
  Future<void> montar(WidgetTester tester, Widget inicio, {Size tamano = _escritorio, bool reducirAnimaciones = false}) async {
    fijarVentana(tester, tamano);
    await tester.pumpWidget(aplicacion(inicio, reducirAnimaciones: reducirAnimaciones));
    await tester.pump();
  }

  group('plantilla de autenticación', () {
    testWidgets('en la web de escritorio, la marca va a la izquierda del formulario', (tester) async {
      await montar(tester, plantilla(disenoWeb: true));

      final panel = find.byType(PanelMarcaAccesoWeb);
      expect(panel, findsOneWidget);
      final formulario = find.text('Formulario de prueba');
      expect(tester.getTopLeft(panel).dx, lessThan(tester.getTopLeft(formulario).dx));
      expect(tester.getTopRight(panel).dx, lessThanOrEqualTo(tester.getTopLeft(formulario).dx));
      // El panel ocupa toda la altura de la ventana.
      expect(tester.getSize(panel).height, _escritorio.height);
      expect(find.descendant(of: panel, matching: find.text(_fraseInicioSesion)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin el diseño web conserva el diseño de escritorio de siempre', (tester) async {
      await montar(tester, plantilla(disenoWeb: false));

      expect(find.byType(PanelMarcaAccesoWeb), findsNothing);
      expect(find.text(_fraseInicioSesion), findsOneWidget);
      expect(find.text('Formulario de prueba'), findsOneWidget);
    });

    testWidgets('en un teléfono conserva el diseño móvil aunque sea web', (tester) async {
      await montar(tester, plantilla(disenoWeb: true), tamano: _telefono);

      expect(find.byType(PanelMarcaAccesoWeb), findsNothing);
      // El héroe móvil muestra el ícono, no la frase.
      expect(find.text(_fraseInicioSesion), findsNothing);
      expect(find.byIcon(Icons.balance), findsOneWidget);
      expect(find.text('Formulario de prueba'), findsOneWidget);
    });

    testWidgets('los demás motivos conservan su diseño aunque sea web', (tester) async {
      await montar(tester, plantilla(disenoWeb: true, motivo: MotivoAutenticacion.registroCliente));

      expect(find.byType(PanelMarcaAccesoWeb), findsNothing);
      expect(find.text('Encuentra al abogado indicado'), findsOneWidget);
    });

    testWidgets('fuera de la web (por defecto en las pruebas) no usa el diseño web', (tester) async {
      await montar(tester, plantilla(disenoWeb: null));

      expect(find.byType(PanelMarcaAccesoWeb), findsNothing);
    });

    testWidgets('no desborda en una ventana de escritorio baja', (tester) async {
      await montar(tester, plantilla(disenoWeb: true), tamano: const Size(1000, 560));

      expect(find.byType(PanelMarcaAccesoWeb), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Volver» aparece si hay adónde volver, y vuelve', (tester) async {
      fijarVentana(tester, _escritorio);
      await tester.pumpWidget(
        aplicacion(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => plantilla(disenoWeb: true)),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Volver'), findsNothing);

      await tester.tap(find.text('Abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Volver'), findsOneWidget);

      await tester.tap(find.text('Volver'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PanelMarcaAccesoWeb), findsNothing);
      expect(find.text('Abrir'), findsOneWidget);
    });
  });

  group('ícono animado del panel de marca', () {
    Finder enLaTarjeta(IconData icono) => find.descendant(
      of: find.descendant(of: find.byType(PanelMarcaAccesoWeb), matching: find.byType(TarjetaCristal)),
      matching: find.byIcon(icono),
    );

    testWidgets('alterna balanza, mazo y libro con un fundido', (tester) async {
      await montar(tester, plantilla(disenoWeb: true));
      expect(enLaTarjeta(Icons.balance), findsOneWidget);
      expect(enLaTarjeta(Icons.gavel), findsNothing);

      // Cerca del final del primer periodo (3,5 s) los dos se cruzan.
      await tester.pump(const Duration(milliseconds: 3300));
      expect(enLaTarjeta(Icons.balance), findsOneWidget);
      expect(enLaTarjeta(Icons.gavel), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1200));
      expect(enLaTarjeta(Icons.balance), findsNothing);
      expect(enLaTarjeta(Icons.gavel), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 3500));
      expect(enLaTarjeta(Icons.menu_book), findsOneWidget);
      expect(enLaTarjeta(Icons.gavel), findsNothing);

      // Y vuelve a empezar.
      await tester.pump(const Duration(milliseconds: 3500));
      expect(enLaTarjeta(Icons.balance), findsOneWidget);
      expect(enLaTarjeta(Icons.menu_book), findsNothing);
    });

    testWidgets('con la animación del sistema reducida queda fijo', (tester) async {
      await montar(tester, plantilla(disenoWeb: true), reducirAnimaciones: true);

      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 3300));
        expect(enLaTarjeta(Icons.balance), findsOneWidget);
        expect(enLaTarjeta(Icons.gavel), findsNothing);
        expect(enLaTarjeta(Icons.menu_book), findsNothing);
      }
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('va dentro de un RepaintBoundary y deja de animar al salir', (tester) async {
      await montar(tester, plantilla(disenoWeb: true));
      expect(
        find.ancestor(of: enLaTarjeta(Icons.balance), matching: find.byType(RepaintBoundary)),
        findsWidgets,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });
  });

  group('pantalla de inicio de sesión', () {
    Widget pantalla({required bool esWeb}) {
      return ChangeNotifierProvider<ControladorAutenticacion>(
        create: (_) => ControladorAutenticacion(
          servicioFirestore: FirestoreFalso(),
          servicioStorage: StorageFalso(),
          servicioGoogle: ServicioGoogle(),
        ),
        child: PantallaInicioSesion(esWeb: esWeb),
      );
    }

    Finder iconoFa(FaIconData icono) =>
        find.byWidgetPredicate((w) => w is FaIcon && w.icon?.codePoint == icono.codePoint);

    testWidgets('en la web solo ofrece Google, con el diseño de dos paneles', (tester) async {
      await montar(tester, pantalla(esWeb: true));

      expect(find.byType(PanelMarcaAccesoWeb), findsOneWidget);
      expect(find.text('o continúa con'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(iconoFa(FontAwesomeIcons.google), findsOneWidget);
      expect(iconoFa(FontAwesomeIcons.facebookF), findsNothing);
      expect(iconoFa(FontAwesomeIcons.github), findsNothing);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
      expect(find.text('¿No tienes cuenta? Regístrate'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fuera de la web conserva Google, Facebook y GitHub', (tester) async {
      for (final tamano in const [_telefono, _escritorio]) {
        await montar(tester, pantalla(esWeb: false), tamano: tamano);

        expect(find.byType(PanelMarcaAccesoWeb), findsNothing);
        expect(find.text('o continúa con'), findsOneWidget);
        expect(find.byTooltip('Continuar con Google'), findsOneWidget);
        expect(find.byTooltip('Continuar con Facebook'), findsOneWidget);
        expect(find.byTooltip('Continuar con GitHub'), findsOneWidget);
        expect(iconoFa(FontAwesomeIcons.facebookF), findsOneWidget);
        expect(iconoFa(FontAwesomeIcons.github), findsOneWidget);
      }
    });

    testWidgets('en la web en un teléfono usa el diseño móvil, también solo con Google', (tester) async {
      await montar(tester, pantalla(esWeb: true), tamano: _telefono);

      expect(find.byType(PanelMarcaAccesoWeb), findsNothing);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(iconoFa(FontAwesomeIcons.facebookF), findsNothing);
      expect(iconoFa(FontAwesomeIcons.github), findsNothing);
    });
  });
}
