import 'package:desarrollo/vista/autenticacion/widgets/landing/fila_altura_igual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(Widget hijo) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 320, child: hijo),
  ),
);

Widget _celda(Key clave, double alto) => Align(
  key: clave,
  alignment: Alignment.topCenter,
  child: SizedBox(height: alto),
);

void main() {
  testWidgets('reparte el ancho y estira cada celda al alto de la mayor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        FilaAlturaIgual(
          espacio: 20,
          children: [
            _celda(const Key('a'), 40),
            _celda(const Key('b'), 90),
            _celda(const Key('c'), 10),
          ],
        ),
      ),
    );

    for (final clave in ['a', 'b', 'c']) {
      expect(tester.getSize(find.byKey(Key(clave))), const Size(280 / 3, 90));
    }
    expect(tester.getTopLeft(find.byKey(const Key('b'))).dx, 280 / 3 + 20);
    expect(tester.getSize(find.byType(FilaAlturaIgual)), const Size(320, 90));
  });

  testWidgets('vuelve a medirse si una celda crece sin reconstruir la fila', (
    tester,
  ) async {
    // Reproduce el caso de la fuente web que termina de cargar: cambia el
    // contenido de una celda sin que la fila se reconstruya.
    final alto = ValueNotifier<double>(30);
    addTearDown(alto.dispose);
    await tester.pumpWidget(
      _envolver(
        FilaAlturaIgual(
          children: [
            ValueListenableBuilder<double>(
              valueListenable: alto,
              builder: (_, valor, _) => _celda(const Key('a'), valor),
            ),
            _celda(const Key('b'), 50),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('a'))).height, 50);

    alto.value = 120;
    await tester.pump();

    expect(tester.getSize(find.byKey(const Key('b'))).height, 120);
    expect(tester.getSize(find.byType(FilaAlturaIgual)).height, 120);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin celdas ocupa alto cero', (tester) async {
    await tester.pumpWidget(_envolver(const FilaAlturaIgual(children: [])));

    expect(tester.getSize(find.byType(FilaAlturaIgual)), const Size(320, 0));
  });

  testWidgets('informa como alto intrínseco el de la celda mayor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        FilaAlturaIgual(
          espacio: 20,
          children: [_celda(const Key('a'), 40), _celda(const Key('b'), 75)],
        ),
      ),
    );
    final caja = tester.renderObject<RenderBox>(find.byType(FilaAlturaIgual));

    expect(caja.getMaxIntrinsicHeight(320), 75);
    expect(caja.getDryLayout(const BoxConstraints(maxWidth: 320)).height, 75);
  });
}
