import 'package:desarrollo/vista/autenticacion/pantalla_landing_web.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/especialidades_landing.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/estilos_landing.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/hero_landing.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/navegacion_landing.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/pasos_landing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los botones de la landing que buscan abogados abren el modo visitante
/// («explorar»); los de cuenta siguen yendo al inicio de sesión y al registro.
void main() {
  late List<String> destinos;

  setUp(() {
    // Sin red en las pruebas: el texto usa la tipografía del tema.
    EstilosLanding.usarTipografiaDeMarca = false;
    destinos = [];
    NavegacionLanding.interceptor = destinos.add;
  });

  tearDown(() => NavegacionLanding.interceptor = null);

  Future<void> montar(WidgetTester tester, double ancho) async {
    tester.view.physicalSize = Size(ancho, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, hijo) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: hijo!,
        ),
        home: const PantallaLandingWeb(),
      ),
    );
    await tester.pump();
  }

  /// Lleva el botón a mitad de la ventana, lejos de la barra fija, y lo toca.
  Future<void> tocar(WidgetTester tester, Finder boton) async {
    await Scrollable.ensureVisible(tester.element(boton), alignment: 0.5);
    await tester.pump();
    await tester.tap(boton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder textoEn(Type seccion, String texto) =>
      find.descendant(of: find.byType(seccion), matching: find.text(texto));

  for (final ancho in const [390.0, 1440.0]) {
    group('a ${ancho.toInt()} px', () {
      testWidgets('«Encontrar abogado» del hero abre el modo visitante', (tester) async {
        await montar(tester, ancho);
        await tocar(tester, textoEn(HeroLanding, 'Encontrar abogado'));
        expect(destinos, ['explorar']);
      });

      testWidgets('«Encontrar abogado» de los pasos abre el modo visitante', (tester) async {
        await montar(tester, ancho);
        await tocar(tester, textoEn(PasosLanding, 'Encontrar abogado'));
        expect(destinos, ['explorar']);
      });

      testWidgets('«Buscar por especialidad» abre el modo visitante', (tester) async {
        await montar(tester, ancho);
        await tocar(tester, textoEn(EspecialidadesLanding, 'Buscar por especialidad'));
        expect(destinos, ['explorar']);
      });
    });
  }

  testWidgets('«Crea tu cuenta» del hero sigue llevando al registro', (tester) async {
    await montar(tester, 1440);
    await tocar(tester, find.text('Crea tu cuenta'));
    expect(destinos, ['registro']);
  });
}
