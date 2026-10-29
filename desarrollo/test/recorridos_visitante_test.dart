import 'package:desarrollo/configuracion/configuracion_recorrido_visitante.dart';
import 'package:desarrollo/modelo/modelo_recorrido.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/navegacion_landing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_onboarding_secciones.dart';
import 'dobles_visitante.dart';

/// Igual que en las pruebas del panel visitante: el texto al 80 % para que la
/// fuente de pruebas, más ancha que la real, quepa a 390 px.
Widget _aplicacion(Widget inicio) {
  return MaterialApp(
    builder: (context, hijo) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.8)),
      child: hijo!,
    ),
    home: inicio,
  );
}

String _clave(ModeloRecorrido recorrido) =>
    '${recorrido.prefijoClave}${ConfiguracionRecorridoVisitante.claveDispositivo}';

void main() {
  late BancoVisitante banco;

  setUp(() {
    usarTipografiaDePrueba();
    banco = BancoVisitante()..recorridosVistos = false;
    NavegacionLanding.interceptor = (_) {};
  });

  tearDown(() async {
    NavegacionLanding.interceptor = null;
    restaurarTipografia();
    await banco.cerrar();
  });

  Future<void> montar(WidgetTester tester, Size tamano) async {
    fijarVentana(tester, tamano);
    await tester.pumpWidget(_aplicacion(banco.panel()));
    await avanzar(tester);
  }

  test('las claves del visitante son propias y no repiten las de cuentas', () {
    final prefijos = ConfiguracionRecorridoVisitante.todos.map((r) => r.prefijoClave).toList();
    expect(prefijos.toSet(), hasLength(prefijos.length));
    for (final prefijo in prefijos) {
      expect(prefijo, startsWith('manolegal.recorrido.visitante.'));
    }
    final ids = ConfiguracionRecorridoVisitante.todos.map((r) => r.id);
    expect(ids, everyElement(startsWith('visitante.')));
  });

  for (final tamano in const [tamanoTelefono, tamanoEscritorio]) {
    final medida = '${tamano.width.toInt()}×${tamano.height.toInt()}';

    group('a $medida', () {
      testWidgets('Inicio: la guía aparece sin sesión, se recorre y se recuerda en el navegador', (tester) async {
        await aceptandoSoloAvisoDeListTile(() async {
          await montar(tester, tamano);
          await recorrerGuia(tester, ConfiguracionRecorridoVisitante.inicio);
        });
        expect(banco.recorridos.datos, {
          _clave(ConfiguracionRecorridoVisitante.inicio): 'completado',
        });
      });

      for (final (etiqueta, recorrido) in const [
        ('Cómo funciona', ConfiguracionRecorridoVisitante.comoFunciona),
        ('Lexus', ConfiguracionRecorridoVisitante.lexus),
        ('PQRS', ConfiguracionRecorridoVisitante.pqrs),
      ]) {
        testWidgets('$etiqueta: cada paso señala un elemento real del panel visitante', (tester) async {
          await aceptandoSoloAvisoDeListTile(() async {
            await montar(tester, tamano);
            await pulsarEnLaGuia(tester, 'Saltar tutorial');
            await irASeccion(tester, etiqueta);
            await recorrerGuia(tester, recorrido);
          });
          expect(banco.recorridos.datos[_clave(recorrido)], 'completado');
        });
      }

      testWidgets('cada sección muestra su guía de visitante la primera vez', (tester) async {
        await aceptandoSoloAvisoDeListTile(() async {
          await montar(tester, tamano);
          await pulsarEnLaGuia(tester, 'Saltar tutorial');
          for (final (etiqueta, recorrido) in const [
            ('Cómo funciona', ConfiguracionRecorridoVisitante.comoFunciona),
            ('Lexus', ConfiguracionRecorridoVisitante.lexus),
            ('PQRS', ConfiguracionRecorridoVisitante.pqrs),
          ]) {
            await irASeccion(tester, etiqueta);
            final bienvenida = recorrido.pasos.first;
            expect(enLaGuia(bienvenida.titulo), findsOneWidget, reason: recorrido.id);
            expect(enLaGuia(bienvenida.descripcion), findsOneWidget, reason: recorrido.id);
            await pulsarEnLaGuia(tester, 'Saltar tutorial');
            expect(hayGuia(), isFalse, reason: recorrido.id);
          }
        });
        expect(banco.recorridos.datos, {
          for (final recorrido in ConfiguracionRecorridoVisitante.todos) _clave(recorrido): 'omitido',
        });
      });
    });
  }

  testWidgets('al volver a entrar no reaparece una guía ya cerrada', (tester) async {
    await montar(tester, tamanoTelefono);
    await pulsarEnLaGuia(tester, 'Saltar tutorial');
    expect(hayGuia(), isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_aplicacion(banco.panel()));
    await avanzar(tester);
    expect(hayGuia(), isFalse);
  });

  testWidgets('la guía no impide usar la navegación', (tester) async {
    await montar(tester, tamanoTelefono);
    expect(hayGuia(), isTrue);
    await pulsarEnLaGuia(tester, 'Saltar tutorial');
    await irASeccion(tester, 'Cómo funciona');
    expect(enLaGuia(ConfiguracionRecorridoVisitante.comoFunciona.pasos.first.titulo), findsOneWidget);
  });
}
