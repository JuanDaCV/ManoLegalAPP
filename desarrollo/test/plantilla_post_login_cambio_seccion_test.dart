import 'package:desarrollo/vista/compartido/barra_superior_post_login.dart';
import 'package:desarrollo/vista/compartido/plantilla_post_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<DestinoNavegacion> _destinos = [
  (Icons.home_outlined, 'Uno'),
  (Icons.help_outline, 'Dos'),
  (Icons.support_agent, 'Tres'),
];

void main() {
  late List<int> cambios;
  late ValueNotifier<String> nombre;

  setUp(() {
    cambios = [];
    nombre = ValueNotifier('Ana');
  });

  tearDown(() => nombre.dispose());

  Future<void> montar(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<String>(
          valueListenable: nombre,
          builder: (context, valor, _) => PlantillaPostLogin(
            destinos: _destinos,
            nombre: valor,
            alCambiarSeccion: cambios.add,
            construirSecciones: (esEscritorio) => [
              for (final destino in _destinos)
                Center(child: Text('Sección ${destino.$2}')),
            ],
          ),
        ),
      ),
    );
  }

  /// El destino [etiqueta] de la navegación que se esté mostrando.
  Finder destino(String etiqueta) {
    final movil = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(etiqueta),
    );
    final escritorio = find.descendant(
      of: find.byType(BarraSuperiorPostLogin),
      matching: find.text(etiqueta),
    );
    return movil.evaluate().isNotEmpty ? movil : escritorio;
  }

  for (final (nombreLayout, tamano) in const [
    ('móvil', Size(390, 844)),
    ('escritorio', Size(1440, 900)),
  ]) {
    group('en $nombreLayout', () {
      testWidgets('avisa una vez por cada cambio real de sección', (
        tester,
      ) async {
        await montar(tester, tamano);

        await tester.tap(destino('Dos'));
        await tester.pump();
        await tester.tap(destino('Tres'));
        await tester.pump();
        await tester.tap(destino('Uno'));
        await tester.pump();

        expect(cambios, [1, 2, 0]);
        expect(find.text('Sección Uno'), findsOneWidget);
      });

      testWidgets('no avisa al volver a elegir la misma sección', (
        tester,
      ) async {
        await montar(tester, tamano);

        await tester.tap(destino('Uno'));
        await tester.pump();
        await tester.tap(destino('Dos'));
        await tester.pump();
        await tester.tap(destino('Dos'));
        await tester.pump();

        expect(cambios, [1]);
      });

      testWidgets('no avisa cuando el padre se reconstruye', (tester) async {
        await montar(tester, tamano);
        await tester.tap(destino('Tres'));
        await tester.pump();

        nombre.value = 'Beatriz';
        await tester.pump();

        expect(cambios, [2]);
      });
    });
  }

  testWidgets('no avisa al cruzar el ancho de escritorio', (tester) async {
    await montar(tester, const Size(390, 844));
    await tester.tap(destino('Dos'));
    await tester.pump();

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pump();
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();

    expect(cambios, [1]);
    // La sección elegida se conserva en los dos layouts.
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });
}
