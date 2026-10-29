import 'dart:async';

import 'package:desarrollo/configuracion/configuracion_recorrido_abogado.dart';
import 'package:desarrollo/configuracion/configuracion_recorrido_cliente.dart';
import 'package:desarrollo/configuracion/configuracion_recorrido_pqrs.dart';
import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_onboarding_secciones.dart';

void main() {
  late BancoPanelAbogado banco;

  setUp(() {
    usarTipografiaDePrueba();
    banco = BancoPanelAbogado();
  });

  tearDown(() {
    restaurarTipografia();
    banco.cerrar();
  });

  /// Monta el panel y empieza a cargar el perfil, como `PanelAbogado`.
  Future<void> montar(WidgetTester tester, Size tamano) async {
    fijarVentana(tester, tamano);
    unawaited(banco.perfil.cargar(BancoPanelAbogado.uid));
    await tester.pumpWidget(banco.construir());
    await avanzar(tester);
  }

  for (final tamano in const [tamanoTelefono, tamanoEscritorio]) {
    final medida = '${tamano.width.toInt()}×${tamano.height.toInt()}';

    group('a $medida', () {
      testWidgets(
        'Inicio del abogado usa sus propios textos y su propia clave',
        (tester) async {
          await aceptandoSoloAvisoDeListTile(() async {
            await montar(tester, tamano);

            // Textos de colega, no los del cliente.
            expect(
              enLaGuia(
                ConfiguracionRecorridoAbogado.pasosInicio.first.descripcion,
              ),
              findsOneWidget,
            );
            expect(
              enLaGuia(ConfiguracionRecorridoCliente.pasos.first.descripcion),
              findsNothing,
            );
            await recorrerGuia(tester, ConfiguracionRecorridoAbogado.inicio);
          });

          expect(banco.almacen.datos, {
            'manolegal.recorrido.abogado.inicio.v1.${BancoPanelAbogado.uid}':
                'completado',
          });
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Mi perfil y Panel esperan a que cargue el perfil y luego señalan sus elementos reales',
        (tester) async {
          banco.yaVisto(ConfiguracionRecorridoAbogado.inicio);
          final carga = banco.firestore.retener = Completer<void>();
          await aceptandoSoloAvisoDeListTile(() async {
            await montar(tester, tamano);

            await irASeccion(tester, 'Mi perfil');
            await avanzar(tester, cuadros: 30);
            // Con el perfil cargando no hay a qué señalar: no hay guía.
            expect(hayGuia(), isFalse);
            expect(find.byType(CircularProgressIndicator), findsWidgets);

            carga.complete();
            await avanzar(tester);
            await recorrerGuia(tester, ConfiguracionRecorridoAbogado.miPerfil);

            await irASeccion(tester, 'Panel');
            var vioLaDemostracion = false;
            await recorrerGuia(
              tester,
              ConfiguracionRecorridoAbogado.panel,
              alMostrar: (paso) {
                if (paso.id != 'demostracion') return;
                vioLaDemostracion = true;
                final tarjeta = marcasDe(MarcaRecorridoId.panelDemostracion);
                expect(
                  find.descendant(
                    of: tarjeta,
                    matching: find.text('Dato de demostración'),
                  ),
                  findsOneWidget,
                );
                expect(
                  find.descendant(
                    of: tarjeta,
                    matching: find.text('Visualizaciones del perfil'),
                  ),
                  findsOneWidget,
                );
              },
            );
            expect(vioLaDemostracion, isTrue);

            await irASeccion(tester, 'PQRS');
            await recorrerGuia(tester, ConfiguracionRecorridoPqrs.pqrs);
          });

          for (final recorrido in BancoPanelAbogado.recorridos) {
            expect(banco.estadoGuardado(recorrido), 'completado');
          }
          expect(tester.takeException(), isNull);
        },
      );
    });
  }

  testWidgets(
    'salir de Mi perfil mientras carga cancela su guía: no aparece en otra sección',
    (tester) async {
      banco.yaVisto(ConfiguracionRecorridoAbogado.inicio);
      final carga = banco.firestore.retener = Completer<void>();
      await montar(tester, tamanoTelefono);

      await irASeccion(tester, 'Mi perfil');
      await irASeccion(tester, 'PQRS');
      expect(enLaGuia('PQRS'), findsOneWidget);
      await pulsarEnLaGuia(tester, 'Saltar tutorial');

      // El perfil termina de cargar mientras el abogado está en PQRS.
      carga.complete();
      await avanzar(tester, cuadros: 30);
      expect(hayGuia(), isFalse);

      // Al volver a Mi perfil sí aparece su guía.
      await irASeccion(tester, 'Mi perfil');
      expect(
        enLaGuia(ConfiguracionRecorridoAbogado.pasosMiPerfil.first.titulo),
        findsOneWidget,
      );
      expect(banco.estadoGuardado(ConfiguracionRecorridoPqrs.pqrs), 'omitido');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Inicio del abogado sin resultados: omite tarjeta y «Ver perfil» y centra la verificación',
    (tester) async {
      banco.abogados.perfiles = const [];
      await montar(tester, tamanoTelefono);

      await pulsarEnLaGuia(tester, 'Comenzar');
      expect(enLaGuia('Busca colegas'), findsOneWidget);
      expect(enLaGuia('PASO 1 DE 3'), findsOneWidget);
      await pulsarEnLaGuia(tester, 'Siguiente');
      expect(enLaGuia('PASO 2 DE 3'), findsOneWidget);
      await pulsarEnLaGuia(tester, 'Siguiente');

      final verificacion = ConfiguracionRecorridoAbogado.pasosInicio
          .firstWhere((p) => p.id == 'verificacion');
      expect(enLaGuia('PASO 3 DE 3'), findsOneWidget);
      expect(enLaGuia(verificacion.descripcionSinMarca!), findsOneWidget);
      expect(huecoActual(tester), isNull);
      expect(enLaGuia('Perfiles de colegas'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('PQRS comparte la guía con el cliente, pero cada uno guarda la suya', (
    tester,
  ) async {
    banco.yaVisto(ConfiguracionRecorridoAbogado.inicio);
    // Lo que haya visto un cliente en el mismo equipo no cuenta para el
    // abogado: la clave lleva el uid.
    banco.almacen.datos['${ConfiguracionRecorridoPqrs.pqrs.prefijoClave}uid-cliente'] =
        'completado';
    await montar(tester, tamanoTelefono);

    await irASeccion(tester, 'PQRS');
    await recorrerGuia(tester, ConfiguracionRecorridoPqrs.pqrs);

    expect(banco.pqrs.creadas, isEmpty);
    expect(find.text('Radicar una PQRS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
