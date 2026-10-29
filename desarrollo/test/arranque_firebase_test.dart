import 'dart:async';

import 'package:desarrollo/configuracion/arranque_firebase.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/navegacion_landing.dart';
import 'package:desarrollo/vista/utilidades/enrutador_inicial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ObservadorDeRutas extends NavigatorObserver {
  int empujes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    empujes++;
  }
}

void main() {
  tearDown(ArranqueFirebase.reiniciarEnPruebas);

  group('enrutador inicial mientras Firebase arranca', () {
    testWidgets('con indicio de sesión muestra la espera, no la bienvenida', (
      tester,
    ) async {
      ArranqueFirebase.usarEnPruebas(
        listo: Completer<void>().future,
        hayIndicioDeSesion: true,
      );

      await tester.pumpWidget(const MaterialApp(home: EnrutadorInicial()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('navegación de la landing', () {
    Future<(BuildContext, _ObservadorDeRutas)> montar(
      WidgetTester tester,
    ) async {
      final observador = _ObservadorDeRutas();
      late BuildContext contexto;
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observador],
          home: Builder(
            builder: (context) {
              contexto = context;
              return const SizedBox();
            },
          ),
        ),
      );
      observador.empujes = 0;
      return (contexto, observador);
    }

    testWidgets('"Ingresar" no abre el inicio de sesión antes de que '
        'Firebase esté listo', (tester) async {
      ArranqueFirebase.usarEnPruebas(listo: Completer<void>().future);
      final (contexto, observador) = await montar(tester);

      unawaited(NavegacionLanding.irAInicioSesion(contexto));
      unawaited(NavegacionLanding.irARegistro(contexto));
      await tester.pump(const Duration(seconds: 5));

      expect(observador.empujes, 0);
    });

    testWidgets('si la landing ya no está cuando Firebase termina, no navega '
        'ni falla', (tester) async {
      final arranque = Completer<void>();
      ArranqueFirebase.usarEnPruebas(listo: arranque.future);
      final (contexto, observador) = await montar(tester);

      final navegacion = NavegacionLanding.irAInicioSesion(contexto);
      await tester.pumpWidget(const SizedBox());
      arranque.complete();
      await navegacion;
      await tester.pump();

      expect(observador.empujes, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
