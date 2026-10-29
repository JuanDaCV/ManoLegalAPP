import 'package:desarrollo/controlador/servicio_conversaciones_lexus_visitante.dart';
import 'package:desarrollo/modelo/error_lexus.dart';
import 'package:desarrollo/vista/visitante/aviso_requiere_cuenta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('aviso de cuenta requerida', () {
    late BuildContext contextoPanel;
    late List<String> llamadas;

    setUp(() => llamadas = []);

    Future<void> abrir(WidgetTester tester, MotivoCuentaRequerida motivo, {Size tamano = const Size(390, 844)}) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              contextoPanel = context;
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => mostrarAvisoRequiereCuenta(
                      context,
                      motivo: motivo,
                      // Cuando llega la devolución, el aviso ya no debe estar
                      // encima: quien navega lo hace desde el panel.
                      alIniciarSesion: () =>
                          llamadas.add('login, aviso abierto: ${Navigator.of(contextoPanel).canPop()}'),
                      alCrearCuenta: () =>
                          llamadas.add('registro, aviso abierto: ${Navigator.of(contextoPanel).canPop()}'),
                    ),
                    child: const Text('Abrir'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> tocar(WidgetTester tester, String texto) async {
      await tester.tap(find.text(texto));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    const textos = {
      MotivoCuentaRequerida.verPerfil: (
        'Conoce el perfil completo',
        'Crea tu cuenta en ManoLegal o inicia sesión para consultar la información completa de este abogado.',
      ),
      MotivoCuentaRequerida.lexus: (
        'Conversa con Lexus',
        'Crea tu cuenta o inicia sesión para enviar tu consulta a Lexus.',
      ),
      MotivoCuentaRequerida.pqrs: (
        'Radica tu PQRS',
        'Crea tu cuenta o inicia sesión para radicar una PQRS y recibir tu número de radicado.',
      ),
    };

    for (final MapEntry(key: motivo, value: (titulo, mensaje)) in textos.entries) {
      testWidgets('${motivo.name}: título, mensaje y las tres acciones a 390 px', (tester) async {
        await abrir(tester, motivo);

        expect(find.text(titulo), findsOneWidget);
        expect(find.text(mensaje), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Iniciar sesión'), findsOneWidget);
        expect(find.widgetWithText(OutlinedButton, 'Crear cuenta'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Continuar explorando'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('en escritorio no pasa de 420 px de ancho', (tester) async {
      await abrir(tester, MotivoCuentaRequerida.verPerfil, tamano: const Size(1440, 900));

      final superficie = find.descendant(of: find.byType(Dialog), matching: find.byType(SingleChildScrollView));
      expect(tester.getSize(superficie).width, lessThanOrEqualTo(420));
    });

    testWidgets('«Iniciar sesión» cierra el aviso antes de navegar', (tester) async {
      await abrir(tester, MotivoCuentaRequerida.lexus);

      await tocar(tester, 'Iniciar sesión');

      expect(llamadas, ['login, aviso abierto: false']);
      expect(find.byType(AvisoRequiereCuenta), findsNothing);
    });

    testWidgets('«Crear cuenta» cierra el aviso antes de navegar', (tester) async {
      await abrir(tester, MotivoCuentaRequerida.pqrs);

      await tocar(tester, 'Crear cuenta');

      expect(llamadas, ['registro, aviso abierto: false']);
      expect(find.byType(AvisoRequiereCuenta), findsNothing);
    });

    testWidgets('«Continuar explorando» solo cierra el aviso', (tester) async {
      await abrir(tester, MotivoCuentaRequerida.verPerfil);

      await tocar(tester, 'Continuar explorando');

      expect(llamadas, isEmpty);
      expect(find.byType(AvisoRequiereCuenta), findsNothing);
    });
  });

  group('historial de Lexus del visitante', () {
    test('no tiene conversación que retomar', () async {
      expect(await ServicioConversacionesLexusVisitante().cargarMasReciente(), isNull);
    });

    test('da identificadores locales distintos sin escribir nada', () {
      final servicio = ServicioConversacionesLexusVisitante();
      final ids = {
        servicio.nuevoIdConversacion(),
        servicio.nuevoIdMensaje(),
        servicio.nuevoIdMensaje(),
      };
      expect(ids, hasLength(3));
    });

    test('no finge guardar: toda escritura lanza', () {
      final servicio = ServicioConversacionesLexusVisitante();
      final sinSesion = throwsA(isA<StateError>());

      expect(
        () => servicio.guardarEnvio(
          conversacionId: 'c',
          conversacionNueva: true,
          titulo: 't',
          mensajeId: 'm',
          texto: 'Hola',
          orden: 0,
        ),
        sinSesion,
      );
      expect(
        () => servicio.guardarFallo(conversacionId: 'c', mensajeId: 'm', tipo: TipoErrorLexus.interno),
        sinSesion,
      );
      expect(() => servicio.guardarReintento(conversacionId: 'c', mensajeId: 'm', orden: 1), sinSesion);
      expect(() => servicio.cerrar('c'), sinSesion);
      expect(() => servicio.expirar('c'), sinSesion);
    });
  });
}
