import 'package:desarrollo/controlador/controlador_busqueda_abogados.dart';
import 'package:desarrollo/modelo/modelo_resultado_abogado.dart';
import 'package:desarrollo/vista/compartido/barra_superior_post_login.dart';
import 'package:desarrollo/vista/compartido/pantalla_perfil_abogado.dart';
import 'package:desarrollo/vista/compartido/plantilla_post_login.dart';
import 'package:desarrollo/vista/compartido/widgets/bienvenida_post_login.dart';
import 'package:desarrollo/vista/compartido/widgets/buscador_abogados.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_visitante.dart';

// =============================================================================
// Los parámetros nuevos del modo visitante son opcionales: sin ellos, cada
// widget compartido se comporta como antes para el cliente y el abogado.
// =============================================================================

const List<DestinoNavegacion> _destinos = [
  (Icons.home_outlined, 'Uno'),
  (Icons.help_outline, 'Dos'),
];

class _ObservadorDeRutas extends NavigatorObserver {
  final List<Route<dynamic>> empujadas = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => empujadas.add(route);
}

void main() {
  void fijarVentana(WidgetTester tester, Size tamano) {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget plantilla({VoidCallback? alIngresar, VoidCallback? alCrearCuenta, VoidCallback? alVolver}) {
    return MaterialApp(
      home: PlantillaPostLogin(
        destinos: _destinos,
        nombre: 'Ana',
        alIngresar: alIngresar,
        alCrearCuenta: alCrearCuenta,
        alVolver: alVolver,
        construirSecciones: (esEscritorio) => [
          for (final destino in _destinos) Center(child: Text('Sección ${destino.$2}')),
        ],
      ),
    );
  }

  group('plantilla post-login sin modo visitante', () {
    testWidgets('en móvil muestra cerrar sesión y no «Ingresar»', (tester) async {
      fijarVentana(tester, const Size(390, 844));
      await tester.pumpWidget(plantilla());

      expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text('Ingresar'), findsNothing);
    });

    testWidgets('en escritorio muestra el menú del usuario y no los botones de cuenta', (tester) async {
      fijarVentana(tester, const Size(1440, 900));
      await tester.pumpWidget(plantilla());

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Ingresar'), findsNothing);
      expect(find.text('Crear cuenta'), findsNothing);
      expect(find.byTooltip('Volver'), findsNothing);
    });
  });

  group('plantilla post-login en modo visitante', () {
    testWidgets('en escritorio cambia el menú por «Crear cuenta» e «Ingresar», y ofrece volver', (tester) async {
      final llamadas = <String>[];
      fijarVentana(tester, const Size(1440, 900));
      await tester.pumpWidget(
        plantilla(
          alIngresar: () => llamadas.add('ingresar'),
          alCrearCuenta: () => llamadas.add('crear'),
          alVolver: () => llamadas.add('volver'),
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsNothing);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Crear cuenta'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ingresar'));
      await tester.tap(find.byTooltip('Volver'));
      expect(llamadas, ['crear', 'ingresar', 'volver']);
    });

    testWidgets('en móvil cambia cerrar sesión por «Ingresar»', (tester) async {
      var ingresos = 0;
      fijarVentana(tester, const Size(390, 844));
      await tester.pumpWidget(plantilla(alIngresar: () => ingresos++));

      expect(find.byTooltip('Cerrar sesión'), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Ingresar'));
      expect(ingresos, 1);
    });

    for (final ancho in const [900.0, 1000.0, 1100.0]) {
      testWidgets('la barra no desborda a ${ancho.toInt()} px', (tester) async {
        fijarVentana(tester, Size(ancho, 700));
        await tester.pumpWidget(
          MaterialApp(
            home: PlantillaPostLogin(
              destinos: const [
                (Icons.home_outlined, 'Inicio'),
                (Icons.help_outline, 'Cómo funciona'),
                (Icons.gavel_outlined, 'Lexus'),
                (Icons.support_agent, 'PQRS'),
              ],
              nombre: null,
              alIngresar: () {},
              alCrearCuenta: () {},
              alVolver: () {},
              construirSecciones: (esEscritorio) => const [SizedBox(), SizedBox(), SizedBox(), SizedBox()],
            ),
          ),
        );

        expect(find.byType(BarraSuperiorPostLogin), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('bienvenida', () {
    testWidgets('sin título saluda por el nombre, como siempre', (tester) async {
      fijarVentana(tester, const Size(1440, 900));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BienvenidaPostLogin(nombre: 'Ana', esEscritorio: true))),
      );

      expect(find.text('Bienvenido a ManoLegal, Ana'), findsOneWidget);
    });

    testWidgets('con título lo usa en lugar del saludo personal', (tester) async {
      fijarVentana(tester, const Size(1440, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BienvenidaPostLogin(nombre: '', esEscritorio: true, titulo: 'Bienvenido a ManoLegal'),
          ),
        ),
      );

      expect(find.text('Bienvenido a ManoLegal'), findsOneWidget);
      expect(find.textContaining('ManoLegal,'), findsNothing);
    });
  });

  group('«Ver perfil» del buscador', () {
    setUp(() => BuscadorAbogados.usarTipografiaDeMarca = false);
    tearDown(() => BuscadorAbogados.usarTipografiaDeMarca = true);

    Future<_ObservadorDeRutas> montar(
      WidgetTester tester, {
      void Function(ModeloResultadoAbogado abogado)? alVerPerfil,
    }) async {
      final observador = _ObservadorDeRutas();
      fijarVentana(tester, const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observador],
          home: Scaffold(
            body: SingleChildScrollView(
              child: BuscadorAbogados(
                esEscritorio: false,
                alVerPerfil: alVerPerfil,
                crearControlador: () =>
                    ControladorBusquedaAbogados(servicioPerfilPublico: TarjetasFalsas(abogadosVisitante())),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      observador.empujadas.clear();
      return observador;
    }

    testWidgets('sin devolución propia abre el perfil completo del abogado', (tester) async {
      final observador = await montar(tester);

      await tester.tap(find.text('Ver perfil').first);
      await tester.pump();
      // La pantalla real necesita Firebase, que no existe en las pruebas: al
      // construirse falla, pero lo que importa aquí es que se abrió.
      expect(tester.takeException(), isA<FirebaseException>());

      final ruta = observador.empujadas.single as MaterialPageRoute<dynamic>;
      final destino = ruta.builder(tester.element(find.byType(BuscadorAbogados)));
      expect(destino, isA<PantallaPerfilAbogado>().having((p) => p.uid, 'uid', 'a1'));
    });

    testWidgets('con devolución propia la llama con el abogado y no navega', (tester) async {
      final elegidos = <ModeloResultadoAbogado>[];
      final observador = await montar(tester, alVerPerfil: elegidos.add);

      await tester.tap(find.text('Ver perfil').first);
      await tester.pump();

      expect(elegidos.single.uid, 'a1');
      expect(elegidos.single.nombreCompleto, 'Ana Prueba');
      expect(observador.empujadas, isEmpty);
    });
  });
}
