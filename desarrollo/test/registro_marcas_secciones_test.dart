import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/ambito_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/registro_marcas_recorrido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tarjeta = MarcaRecorridoId.tarjeta;

void main() {
  late RegistroMarcasRecorrido registro;

  setUp(() {
    registro = RegistroMarcasRecorrido();
  });

  /// Dos pestañas de un `IndexedStack`, cada una con su propio contenido
  /// desplazable y una marca con el mismo id: como una tarjeta de abogado que
  /// apareciera en Inicio y en otra sección.
  Future<ValueNotifier<int>> montarDosPestanas(
    WidgetTester tester, {
    MarcaRecorridoId idPrimera = _tarjeta,
    MarcaRecorridoId idSegunda = _tarjeta,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final indice = ValueNotifier(0);
    addTearDown(indice.dispose);

    Widget pestana(MarcaRecorridoId id, Key clave) {
      return SingleChildScrollView(
        primary: false,
        child: Column(
          children: [
            const SizedBox(height: 1200),
            MarcaRecorrido(
              id: id,
              child: SizedBox(key: clave, height: 80, width: 200),
            ),
            const SizedBox(height: 1200),
          ],
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: AmbitoRecorrido(
          registro: registro,
          child: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: indice,
              builder: (context, valor, _) => IndexedStack(
                index: valor,
                children: [
                  pestana(idPrimera, const Key('primera')),
                  // Se registra después: es la más reciente.
                  pestana(idSegunda, const Key('segunda')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return indice;
  }

  group('varias marcas con el mismo id', () {
    testWidgets('una copia en una pestaña oculta no tapa a la visible', (
      tester,
    ) async {
      final indice = await montarDosPestanas(tester);
      final versionInicial = registro.version(_tarjeta);

      final contexto = registro.contextoDisponible(_tarjeta);
      expect(contexto, isNotNull);
      expect(
        contexto!.findRenderObject(),
        tester.renderObject(find.byKey(const Key('primera'))),
      );
      // La copia oculta llegó después, pero no manda: la versión no cambió
      // por ella y el hueco sigue sobre la visible.
      expect(registro.version(_tarjeta), versionInicial);

      indice.value = 1;
      await tester.pump();

      expect(
        registro.contextoDisponible(_tarjeta)!.findRenderObject(),
        tester.renderObject(find.byKey(const Key('segunda'))),
      );
      // Ahora manda otra entrada: quien la señalaba debe volver a medir.
      expect(registro.version(_tarjeta), versionInicial + 1);
    });

    testWidgets('al liberar la visible, la otra sigue registrada', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox(key: Key('x'))),
      );
      final contexto = tester.element(find.byKey(const Key('x')));
      final a = Object();
      final b = Object();

      registro.registrar(_tarjeta, contexto, propietario: a, visible: true);
      registro.registrar(_tarjeta, contexto, propietario: b, visible: false);
      expect(registro.version(_tarjeta), 1);
      expect(registro.estaDisponible(_tarjeta), isTrue);

      registro.liberar(_tarjeta, a);
      // Queda solo la oculta: existe, pero no está disponible.
      expect(registro.estaDisponible(_tarjeta), isFalse);
      expect(registro.version(_tarjeta), 2);

      registro.registrar(_tarjeta, contexto, propietario: b, visible: true);
      expect(registro.estaDisponible(_tarjeta), isTrue);
      expect(registro.version(_tarjeta), 2);
    });
  });

  group('restaurar el desplazamiento', () {
    testWidgets('usa la marca capturada, no el buscador', (tester) async {
      // Sin buscador en pantalla: es otra sección.
      await montarDosPestanas(
        tester,
        idPrimera: MarcaRecorridoId.pqrsCategorias,
        idSegunda: MarcaRecorridoId.buscador,
      );
      final posicion = Scrollable.of(
        tester.element(find.byKey(const Key('primera'))),
      ).position;
      posicion.jumpTo(300);
      await tester.pump();

      registro.capturarDesplazamiento(MarcaRecorridoId.pqrsCategorias);
      posicion.jumpTo(900);
      await tester.pump();
      registro.restaurarDesplazamiento();
      await tester.pumpAndSettle();

      expect(posicion.pixels, 300);
    });

    testWidgets('si la captura falla, no restaura nada', (tester) async {
      await montarDosPestanas(
        tester,
        idPrimera: MarcaRecorridoId.pqrsCategorias,
        idSegunda: MarcaRecorridoId.buscador,
      );
      final posicion = Scrollable.of(
        tester.element(find.byKey(const Key('primera'))),
      ).position;
      posicion.jumpTo(300);
      await tester.pump();
      registro.capturarDesplazamiento(MarcaRecorridoId.pqrsCategorias);

      // El buscador está en la pestaña oculta: capturarlo falla y olvida la
      // captura anterior.
      registro.capturarDesplazamiento(MarcaRecorridoId.buscador);
      posicion.jumpTo(900);
      await tester.pump();
      registro.restaurarDesplazamiento();
      await tester.pumpAndSettle();

      expect(posicion.pixels, 900);
    });
  });
}
