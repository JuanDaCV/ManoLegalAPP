import 'package:desarrollo/vista/autenticacion/widgets/landing/marco_telefono.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// El teléfono dentro de una página desplazable, [antes] px más abajo del
  /// borde superior. La ventana mide 800 × 600.
  Future<ScrollController> montar(
    WidgetTester tester, {
    required double antes,
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final desplazamiento = ScrollController();
    addTearDown(desplazamiento.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: desplazamiento,
            child: Column(
              children: [
                SizedBox(height: antes),
                const PantallasTelefono(capturas: capturasApp, ancho: 160),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return desplazamiento;
  }

  Finder captura(int indice) => find.byKey(ValueKey(capturasApp[indice].ruta));

  /// Deja pasar un turno del temporizador y la transición de 600 ms.
  Future<void> siguienteTurno(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 700));
  }

  /// Desmonta la página para que el temporizador se cancele.
  Future<void> desmontar(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('a la vista, rota a la siguiente captura cada 5 s', (
    tester,
  ) async {
    await montar(tester, antes: 0);
    expect(captura(0), findsOneWidget);

    await siguienteTurno(tester);

    expect(captura(0), findsNothing);
    expect(captura(1), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('fuera de la ventana no rota ni pide cuadros', (tester) async {
    await montar(tester, antes: 1500);

    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 10));

    expect(captura(0), findsOneWidget);
    expect(captura(1), findsNothing);
    await desmontar(tester);
  });

  testWidgets('al volver a la vista retoma la rotación', (tester) async {
    final desplazamiento = await montar(tester, antes: 1500);
    await siguienteTurno(tester);
    expect(captura(0), findsOneWidget);

    desplazamiento.jumpTo(1400);
    await tester.pump();
    await siguienteTurno(tester);

    expect(captura(1), findsOneWidget);
    await desmontar(tester);
  });
}
