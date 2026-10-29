import 'dart:async';

import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/ambito_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/pintor_foco_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/registro_marcas_recorrido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _buscador = MarcaRecorridoId.buscador;
const _filtros = MarcaRecorridoId.filtros;

/// El registrador privado que `MarcaRecorrido` agrega cuando hay un ámbito.
Finder _registradores() {
  return find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_RegistradorMarca',
  );
}

/// Aplicación de prueba. Con [reducirMovimiento] simula el ajuste del sistema.
Widget _aplicacion({required Widget hijo, bool reducirMovimiento = false}) {
  return MaterialApp(
    builder: (context, hijoDeLaApp) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: reducirMovimiento),
      child: hijoDeLaApp!,
    ),
    home: hijo,
  );
}

void main() {
  late RegistroMarcasRecorrido registro;

  setUp(() {
    registro = RegistroMarcasRecorrido();
  });

  group('registro y liberación', () {
    testWidgets('se registra al montarse y se libera al desmontarse', (
      tester,
    ) async {
      expect(registro.estaDisponible(_buscador), isFalse);
      expect(registro.version(_buscador), 0);

      await tester.pumpWidget(
        _aplicacion(
          hijo: AmbitoRecorrido(
            registro: registro,
            child: const Center(
              child: MarcaRecorrido(
                id: _buscador,
                child: SizedBox(width: 100, height: 50),
              ),
            ),
          ),
        ),
      );

      expect(registro.estaDisponible(_buscador), isTrue);
      expect(registro.version(_buscador), 1);

      await tester.pumpWidget(const SizedBox());

      expect(registro.estaDisponible(_buscador), isFalse);
    });

    testWidgets(
      'si se recrea en el mismo cuadro, la marca vieja no borra a la nueva',
      (tester) async {
        // Column y Row son tipos distintos: el árbol se monta de nuevo. La
        // marca nueva se registra al construir y la vieja se libera al final
        // del cuadro, que es el orden que sufre el panel al cruzar los 900 px.
        final usarFila = ValueNotifier(false);
        addTearDown(usarFila.dispose);
        await tester.pumpWidget(
          _aplicacion(
            hijo: AmbitoRecorrido(
              registro: registro,
              child: ValueListenableBuilder<bool>(
                valueListenable: usarFila,
                builder: (context, fila, _) {
                  const marca = MarcaRecorrido(
                    id: _buscador,
                    child: SizedBox(width: 100, height: 50),
                  );
                  return fila
                      ? const Row(children: [marca])
                      : const Column(children: [marca]);
                },
              ),
            ),
          ),
        );
        final versionAntes = registro.version(_buscador);

        usarFila.value = true;
        await tester.pump();

        expect(registro.estaDisponible(_buscador), isTrue);
        expect(registro.version(_buscador), versionAntes + 1);
      },
    );

    testWidgets('cambiar el id de una marca libera el anterior', (
      tester,
    ) async {
      final id = ValueNotifier(_buscador);
      addTearDown(id.dispose);
      await tester.pumpWidget(
        _aplicacion(
          hijo: AmbitoRecorrido(
            registro: registro,
            child: Center(
              child: ValueListenableBuilder<MarcaRecorridoId>(
                valueListenable: id,
                builder: (context, valor, _) => MarcaRecorrido(
                  id: valor,
                  child: const SizedBox(width: 100, height: 50),
                ),
              ),
            ),
          ),
        ),
      );
      expect(registro.estaDisponible(_buscador), isTrue);

      id.value = _filtros;
      await tester.pump();

      expect(registro.estaDisponible(_buscador), isFalse);
      expect(registro.estaDisponible(_filtros), isTrue);
    });

    testWidgets('cambiar el registro del ámbito mueve la marca al nuevo', (
      tester,
    ) async {
      final otro = RegistroMarcasRecorrido();
      final actual = ValueNotifier(registro);
      addTearDown(actual.dispose);
      await tester.pumpWidget(
        _aplicacion(
          hijo: ValueListenableBuilder<RegistroMarcasRecorrido>(
            valueListenable: actual,
            builder: (context, valor, _) => AmbitoRecorrido(
              registro: valor,
              child: const Center(
                child: MarcaRecorrido(
                  id: _buscador,
                  child: SizedBox(width: 100, height: 50),
                ),
              ),
            ),
          ),
        ),
      );
      expect(registro.estaDisponible(_buscador), isTrue);

      actual.value = otro;
      await tester.pump();

      expect(registro.estaDisponible(_buscador), isFalse);
      expect(otro.estaDisponible(_buscador), isTrue);
    });

    testWidgets(
      'el mismo dueño solo actualiza; otro dueño reemplaza y sube la versión',
      (tester) async {
        await tester.pumpWidget(
          _aplicacion(hijo: const SizedBox(key: Key('x'))),
        );
        final contexto = tester.element(find.byKey(const Key('x')));
        final a = Object();
        final b = Object();

        registro.registrar(_buscador, contexto, propietario: a, visible: true);
        expect(registro.version(_buscador), 1);
        registro.registrar(_buscador, contexto, propietario: a, visible: true);
        expect(registro.version(_buscador), 1);
        registro.registrar(_buscador, contexto, propietario: b, visible: true);
        expect(registro.version(_buscador), 2);

        // `a` ya no es el dueño: liberar no quita a `b`.
        registro.liberar(_buscador, a);
        expect(registro.estaDisponible(_buscador), isTrue);
        registro.liberar(_buscador, b);
        expect(registro.estaDisponible(_buscador), isFalse);
      },
    );

    testWidgets('una marca marcada como no visible no está disponible', (
      tester,
    ) async {
      await tester.pumpWidget(_aplicacion(hijo: const SizedBox(key: Key('x'))));
      final contexto = tester.element(find.byKey(const Key('x')));

      registro.registrar(
        _buscador,
        contexto,
        propietario: Object(),
        visible: false,
      );

      expect(registro.estaDisponible(_buscador), isFalse);
      expect(registro.rectoGlobal(_buscador), isNull);
    });

    testWidgets(
      'una marca cuyo contexto se desmontó deja de estar disponible',
      (tester) async {
        await tester.pumpWidget(
          _aplicacion(hijo: const SizedBox(key: Key('x'))),
        );
        final contexto = tester.element(find.byKey(const Key('x')));
        registro.registrar(
          _buscador,
          contexto,
          propietario: Object(),
          visible: true,
        );
        expect(registro.estaDisponible(_buscador), isTrue);

        await tester.pumpWidget(const SizedBox());

        expect(registro.estaDisponible(_buscador), isFalse);
      },
    );
  });

  group('visibilidad', () {
    testWidgets(
      'una pestaña oculta de un IndexedStack no está disponible, aunque tenga tamaño',
      (tester) async {
        final indice = ValueNotifier(0);
        addTearDown(indice.dispose);
        const ocultaInicialmente = Key('filtros');
        await tester.pumpWidget(
          _aplicacion(
            hijo: AmbitoRecorrido(
              registro: registro,
              child: Scaffold(
                body: ValueListenableBuilder<int>(
                  valueListenable: indice,
                  builder: (context, valor, _) => IndexedStack(
                    index: valor,
                    children: const [
                      MarcaRecorrido(
                        id: _buscador,
                        child: SizedBox(width: 100, height: 50),
                      ),
                      MarcaRecorrido(
                        id: _filtros,
                        child: SizedBox(
                          key: ocultaInicialmente,
                          width: 100,
                          height: 50,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(
          tester.getSize(find.byKey(ocultaInicialmente, skipOffstage: false)),
          const Size(100, 50),
        );
        expect(registro.estaDisponible(_buscador), isTrue);
        expect(registro.estaDisponible(_filtros), isFalse);

        indice.value = 1;
        await tester.pump();

        expect(registro.estaDisponible(_buscador), isFalse);
        expect(registro.estaDisponible(_filtros), isTrue);
      },
    );

    testWidgets(
      'una marca en un Visibility oculto no está disponible hasta que se muestra',
      (tester) async {
        final visible = ValueNotifier(false);
        addTearDown(visible.dispose);
        await tester.pumpWidget(
          _aplicacion(
            hijo: AmbitoRecorrido(
              registro: registro,
              child: Scaffold(
                body: ValueListenableBuilder<bool>(
                  valueListenable: visible,
                  builder: (context, valor, _) => Visibility(
                    visible: valor,
                    maintainState: true,
                    child: const MarcaRecorrido(
                      id: _buscador,
                      child: SizedBox(width: 100, height: 50),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(registro.estaDisponible(_buscador), isFalse);
        final version = registro.version(_buscador);

        visible.value = true;
        await tester.pump();

        expect(registro.estaDisponible(_buscador), isTrue);
        // Es el mismo elemento que vuelve a verse: no cuenta como recreado.
        expect(registro.version(_buscador), version);
      },
    );
  });

  group('sin y con ámbito', () {
    testWidgets('sin AmbitoRecorrido la marca devuelve su hijo tal cual', (
      tester,
    ) async {
      await tester.pumpWidget(
        _aplicacion(
          hijo: const Center(
            child: MarcaRecorrido(
              id: _buscador,
              child: SizedBox(key: Key('hijo'), width: 100, height: 50),
            ),
          ),
        ),
      );

      expect(_registradores(), findsNothing);
      Element? primerHijo;
      tester
          .element(find.byType(MarcaRecorrido))
          .visitChildren((e) => primerHijo ??= e);
      expect(primerHijo!.widget.key, const Key('hijo'));
      expect(registro.estaDisponible(_buscador), isFalse);
    });

    testWidgets('con ámbito agrega un solo registrador y no cambia el layout', (
      tester,
    ) async {
      const hijo = SizedBox(key: Key('hijo'), width: 100, height: 50);
      await tester.pumpWidget(
        _aplicacion(
          hijo: const Center(
            child: MarcaRecorrido(id: _buscador, child: hijo),
          ),
        ),
      );
      final sinAmbito = tester.getRect(find.byKey(const Key('hijo')));

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _aplicacion(
          hijo: AmbitoRecorrido(
            registro: registro,
            child: const Center(
              child: MarcaRecorrido(id: _buscador, child: hijo),
            ),
          ),
        ),
      );

      expect(_registradores(), findsOneWidget);
      expect(tester.getRect(find.byKey(const Key('hijo'))), sinAmbito);
    });
  });

  group('rectángulo global', () {
    const objetivo = Key('objetivo');

    /// Un objetivo de [alto] por [ancho] a 700 px del inicio de un contenido que
    /// se desplaza, bajo una barra de 56 px. El área visible mide 800×544 y va
    /// de y = 56 a y = 600. El objetivo va centrado: pegado al borde izquierdo,
    /// el recorte con holgura lo achicaría y la comparación con `getRect` no
    /// valdría.
    Widget anfitrion(
      ScrollController scroll, {
      double ancho = 120,
      double alto = 100,
      bool reducirMovimiento = false,
    }) {
      return _aplicacion(
        reducirMovimiento: reducirMovimiento,
        hijo: AmbitoRecorrido(
          registro: registro,
          child: Scaffold(
            appBar: AppBar(title: const Text('Barra')),
            body: SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: [
                  const SizedBox(height: 700),
                  Center(
                    child: MarcaRecorrido(
                      id: _buscador,
                      child: SizedBox(
                        key: objetivo,
                        width: ancho,
                        height: alto,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      );
    }

    late ScrollController scroll;

    setUp(() {
      scroll = ScrollController();
      addTearDown(scroll.dispose);
    });

    testWidgets('coincide con el rectángulo del elemento cuando se ve entero', (
      tester,
    ) async {
      await tester.pumpWidget(anfitrion(scroll));
      scroll.jumpTo(400);
      await tester.pump();

      expect(
        registro.rectoGlobal(_buscador),
        tester.getRect(find.byKey(objetivo)),
      );
    });

    testWidgets(
      'es nulo si el elemento está montado pero fuera del área visible',
      (tester) async {
        await tester.pumpWidget(anfitrion(scroll));

        expect(registro.estaDisponible(_buscador), isTrue);
        expect(registro.rectoGlobal(_buscador), isNull);
      },
    );

    testWidgets(
      'se recorta al área visible: nunca deja ver la barra de la app',
      (tester) async {
        await tester.pumpWidget(anfitrion(scroll));
        scroll.jumpTo(730);
        await tester.pump();

        final completo = tester.getRect(find.byKey(objetivo));
        expect(completo.top, lessThan(56));

        // El área visible se encoge la holgura con la que el pintor agranda el
        // hueco: ya agrandado, el borde superior queda justo en el límite de la
        // barra y no la deja ver.
        final recortado = registro.rectoGlobal(_buscador)!;
        expect(recortado.top, 56 + PintorFocoRecorrido.holgura);
        expect(recortado.bottom, completo.bottom);
        expect(recortado.left, completo.left);
        expect(recortado.right, completo.right);
        expect(
          recortado.top - PintorFocoRecorrido.holgura,
          greaterThanOrEqualTo(56),
        );
      },
    );

    testWidgets(
      'un elemento más grande que el área visible queda dentro de ella, con la holgura',
      (tester) async {
        await tester.pumpWidget(anfitrion(scroll, ancho: 2000, alto: 2000));
        scroll.jumpTo(900);
        await tester.pump();

        final recortado = registro.rectoGlobal(_buscador)!;

        expect(
          recortado,
          const Rect.fromLTRB(
            PintorFocoRecorrido.holgura,
            56 + PintorFocoRecorrido.holgura,
            800 - PintorFocoRecorrido.holgura,
            600 - PintorFocoRecorrido.holgura,
          ),
        );
        // Agrandado por el pintor, el hueco cabe exactamente en el área visible.
        expect(
          recortado.inflate(PintorFocoRecorrido.holgura),
          const Rect.fromLTRB(0, 56, 800, 600),
        );
      },
    );

    testWidgets(
      'un elemento a menos de la holgura del borde también se recorta',
      (tester) async {
        await tester.pumpWidget(anfitrion(scroll));
        // El elemento queda a 4 px del borde superior del área visible (y = 56).
        scroll.jumpTo(700 - 4);
        await tester.pump();

        final completo = tester.getRect(find.byKey(objetivo));
        expect(completo.top, 56 + 4);

        expect(
          registro.rectoGlobal(_buscador)!.top,
          56 + PintorFocoRecorrido.holgura,
        );
      },
    );

    testWidgets('es nulo si la marca no está disponible', (tester) async {
      await tester.pumpWidget(anfitrion(scroll));

      expect(registro.rectoGlobal(_filtros), isNull);
    });
  });

  group('preparar el paso', () {
    const objetivo = Key('objetivo');

    Widget anfitrion(
      ScrollController scroll, {
      double alto = 100,
      bool reducirMovimiento = false,
    }) {
      return _aplicacion(
        reducirMovimiento: reducirMovimiento,
        hijo: AmbitoRecorrido(
          registro: registro,
          child: Scaffold(
            appBar: AppBar(title: const Text('Barra')),
            body: SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: [
                  const SizedBox(height: 700),
                  MarcaRecorrido(
                    id: _buscador,
                    child: SizedBox(key: objetivo, width: 120, height: alto),
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      );
    }

    late ScrollController scroll;

    setUp(() {
      scroll = ScrollController();
      addTearDown(scroll.dispose);
    });

    testWidgets(
      'deja unos 300 px libres debajo del elemento, para la tarjeta',
      (tester) async {
        await tester.pumpWidget(anfitrion(scroll));

        unawaited(registro.prepararPaso(_buscador));
        await tester.pumpAndSettle();

        // El área visible va de y = 56 a y = 600 y el elemento mide 100: sobran
        // 444, de los que 300 quedan debajo. Es una alineación de 0,32, bajo el
        // tope de 0,35.
        final recto = tester.getRect(find.byKey(objetivo));
        expect(600 - recto.bottom, closeTo(300, 1));
        expect(recto.top, closeTo(56 + (544 - 100) - 300, 1));
      },
    );

    testWidgets('en una pantalla alta no lo baja de la alineación 0,35', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(anfitrion(scroll));

      unawaited(registro.prepararPaso(_buscador));
      await tester.pumpAndSettle();

      // Área visible de 1344 px: sobran 1244 y el tope es el 35 % de eso.
      expect(
        tester.getRect(find.byKey(objetivo)).top,
        closeTo(56 + 0.35 * (1344 - 100), 1),
      );
    });

    testWidgets('en una pantalla baja sube el elemento hasta arriba', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(anfitrion(scroll));

      unawaited(registro.prepararPaso(_buscador));
      await tester.pumpAndSettle();

      // Con 344 px visibles y 100 de elemento no hay 300 libres debajo: queda
      // lo más arriba posible.
      expect(tester.getRect(find.byKey(objetivo)).top, closeTo(56, 1));
    });

    testWidgets('un elemento muy alto se alinea con el borde superior', (
      tester,
    ) async {
      await tester.pumpWidget(anfitrion(scroll, alto: 500));

      unawaited(registro.prepararPaso(_buscador));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byKey(objetivo)).top, closeTo(56, 1));
    });

    testWidgets('el desplazamiento es animado y dura unos 300 ms', (
      tester,
    ) async {
      await tester.pumpWidget(anfitrion(scroll));

      var terminado = false;
      unawaited(registro.prepararPaso(_buscador).then((_) => terminado = true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(scroll.offset, greaterThan(0));
      expect(terminado, isFalse);

      await tester.pump(const Duration(milliseconds: 250));
      expect(terminado, isTrue);
    });

    testWidgets('con «reducir movimiento» salta de inmediato', (tester) async {
      await tester.pumpWidget(anfitrion(scroll, reducirMovimiento: true));

      await registro.prepararPaso(_buscador);
      await tester.pump();

      expect(
        tester.getRect(find.byKey(objetivo)).top,
        closeTo(56 + (544 - 100) - 300, 1),
      );
    });

    testWidgets('si la marca no está disponible no hace nada', (tester) async {
      await tester.pumpWidget(anfitrion(scroll));

      await registro.prepararPaso(_filtros);

      expect(scroll.offset, 0);
    });
  });

  group('desplazamiento capturado', () {
    late ScrollController scroll;
    late ValueNotifier<int> generacion;

    Widget anfitrion({bool reducirMovimiento = false}) {
      return _aplicacion(
        reducirMovimiento: reducirMovimiento,
        hijo: AmbitoRecorrido(
          registro: registro,
          child: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: generacion,
              // Otra clave: el desplazamiento se vuelve a montar y se crea una
              // posición de scroll nueva, como al cruzar los 900 px.
              builder: (context, valor, _) => SingleChildScrollView(
                key: ValueKey(valor),
                controller: scroll,
                child: const Column(
                  children: [
                    SizedBox(height: 700),
                    MarcaRecorrido(
                      id: _buscador,
                      child: SizedBox(width: 120, height: 100),
                    ),
                    SizedBox(height: 2000),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    setUp(() {
      scroll = ScrollController();
      generacion = ValueNotifier(0);
      addTearDown(scroll.dispose);
      addTearDown(generacion.dispose);
    });

    testWidgets('lo restaura con una animación', (tester) async {
      await tester.pumpWidget(anfitrion());
      scroll.jumpTo(100);
      await tester.pump();
      registro.capturarDesplazamiento(_buscador);
      scroll.jumpTo(600);
      await tester.pump();

      registro.restaurarDesplazamiento();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(scroll.offset, inExclusiveRange(100, 600));
      await tester.pumpAndSettle();

      expect(scroll.offset, 100);
    });

    testWidgets('con «reducir movimiento» lo restaura de inmediato', (
      tester,
    ) async {
      await tester.pumpWidget(anfitrion(reducirMovimiento: true));
      scroll.jumpTo(100);
      await tester.pump();
      registro.capturarDesplazamiento(_buscador);
      scroll.jumpTo(600);
      await tester.pump();

      registro.restaurarDesplazamiento();

      expect(scroll.offset, 100);
    });

    testWidgets('solo lo restaura una vez', (tester) async {
      await tester.pumpWidget(anfitrion(reducirMovimiento: true));
      scroll.jumpTo(100);
      await tester.pump();
      registro.capturarDesplazamiento(_buscador);
      scroll.jumpTo(600);
      await tester.pump();
      registro.restaurarDesplazamiento();
      scroll.jumpTo(500);
      await tester.pump();

      registro.restaurarDesplazamiento();

      expect(scroll.offset, 500);
    });

    testWidgets('sin captura previa no mueve nada', (tester) async {
      await tester.pumpWidget(anfitrion(reducirMovimiento: true));
      scroll.jumpTo(300);
      await tester.pump();

      registro.restaurarDesplazamiento();

      expect(scroll.offset, 300);
    });

    testWidgets('si el desplazamiento se volvió a montar, no mueve el nuevo', (
      tester,
    ) async {
      await tester.pumpWidget(anfitrion(reducirMovimiento: true));
      scroll.jumpTo(100);
      await tester.pump();
      registro.capturarDesplazamiento(_buscador);

      generacion.value++;
      await tester.pump();
      expect(scroll.offset, 0);

      registro.restaurarDesplazamiento();

      expect(scroll.offset, 0);
    });

    testWidgets(
      'capturar una marca que no está disponible olvida lo anterior',
      (tester) async {
        await tester.pumpWidget(anfitrion(reducirMovimiento: true));
        scroll.jumpTo(100);
        await tester.pump();
        registro.capturarDesplazamiento(_buscador);
        registro.capturarDesplazamiento(_filtros);
        scroll.jumpTo(600);
        await tester.pump();

        registro.restaurarDesplazamiento();

        expect(scroll.offset, 600);
      },
    );

    testWidgets('no pasa del máximo si el contenido ahora es más corto', (
      tester,
    ) async {
      await tester.pumpWidget(anfitrion(reducirMovimiento: true));
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      registro.capturarDesplazamiento(_buscador);
      scroll.jumpTo(0);
      await tester.pump();

      registro.restaurarDesplazamiento();

      expect(scroll.offset, scroll.position.maxScrollExtent);
    });
  });
}
