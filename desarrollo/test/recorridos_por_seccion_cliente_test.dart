import 'package:desarrollo/configuracion/configuracion_recorrido_abogado.dart';
import 'package:desarrollo/configuracion/configuracion_recorrido_cliente.dart';
import 'package:desarrollo/configuracion/configuracion_recorrido_pqrs.dart';
import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:desarrollo/modelo/modelo_recorrido.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/indice_capitulos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_como_funciona.dart';
import 'dobles_lexus.dart';
import 'dobles_onboarding_secciones.dart';

/// Títulos de bienvenida de todos los recorridos: en pantalla solo debe
/// estar el de la sección actual.
final List<ModeloRecorrido> _todos = [
  ...BancoPanelCliente.recorridos,
  ConfiguracionRecorridoAbogado.inicio,
  ConfiguracionRecorridoAbogado.miPerfil,
  ConfiguracionRecorridoAbogado.panel,
];

void _soloLaGuiaDe(ModeloRecorrido recorrido) {
  for (final otro in _todos) {
    final bienvenida = otro.pasos.first;
    if (otro.id == recorrido.id ||
        bienvenida.titulo == recorrido.pasos.first.titulo) {
      continue;
    }
    expect(enLaGuia(bienvenida.titulo), findsNothing, reason: otro.id);
  }
  expect(enLaGuia(recorrido.pasos.first.titulo), findsOneWidget);
  expect(enLaGuia(recorrido.pasos.first.descripcion), findsOneWidget);
}

void main() {
  late BancoPanelCliente banco;

  setUp(() {
    usarTipografiaDePrueba();
    VideoFalso.reiniciarRegistro();
    banco = BancoPanelCliente();
  });

  tearDown(() {
    restaurarTipografia();
    banco.cerrar();
  });

  Future<void> montar(WidgetTester tester, Size tamano) async {
    fijarVentana(tester, tamano);
    await tester.pumpWidget(banco.construir());
    await avanzar(tester);
  }

  for (final tamano in const [tamanoTelefono, tamanoEscritorio]) {
    final medida = '${tamano.width.toInt()}×${tamano.height.toInt()}';

    group('a $medida', () {
      testWidgets(
        'Inicio muestra la guía de siempre al abrir el panel y la guarda con su clave',
        (tester) async {
          await aceptandoSoloAvisoDeListTile(() async {
            await montar(tester, tamano);

            _soloLaGuiaDe(ConfiguracionRecorridoCliente.inicio);
            await recorrerGuia(tester, ConfiguracionRecorridoCliente.inicio);
          });

          expect(banco.almacen.datos, {
            'manolegal.recorrido.cliente.v1.${BancoPanelCliente.uid}':
                'completado',
          });
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'cada sección muestra solo su guía al entrar, señalando sus elementos reales',
        (tester) async {
          banco.yaVisto(ConfiguracionRecorridoCliente.inicio);
          await aceptandoSoloAvisoDeListTile(() async {
            await montar(tester, tamano);
            expect(hayGuia(), isFalse);

            for (final (etiqueta, recorrido) in [
              ('Cómo funciona', ConfiguracionRecorridoCliente.comoFunciona),
              ('Lexus', ConfiguracionRecorridoCliente.lexus),
              ('PQRS', ConfiguracionRecorridoPqrs.pqrs),
            ]) {
              await irASeccion(tester, etiqueta);
              _soloLaGuiaDe(recorrido);
              await recorrerGuia(tester, recorrido);
              expect(banco.estadoGuardado(recorrido), 'completado');
            }

            // Ya vistas: al volver a cada sección no reaparecen.
            for (final etiqueta in ['Inicio', 'Cómo funciona', 'Lexus', 'PQRS']) {
              await irASeccion(tester, etiqueta);
              await avanzar(tester, cuadros: 20);
              expect(hayGuia(), isFalse, reason: etiqueta);
            }
          });
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'el índice de capítulos que se señala es el del diseño en pantalla',
        (tester) async {
          banco.yaVisto(ConfiguracionRecorridoCliente.inicio);
          await aceptandoSoloAvisoDeListTile(() async {
            await montar(tester, tamano);
            await irASeccion(tester, 'Cómo funciona');
            await pulsarEnLaGuia(tester, 'Comenzar');
            await pulsarEnLaGuia(tester, 'Siguiente');

            final paso = ConfiguracionRecorridoCliente.pasosComoFunciona[2];
            expect(enLaGuia(paso.titulo), findsOneWidget);
            final indice = tamano == tamanoTelefono
                ? find.byType(ChipsCapitulos)
                : find.byType(RielCapitulos);
            expect(
              tester.getRect(indice).contains(huecoActual(tester)!.center),
              isTrue,
            );
          });
        },
      );
    });
  }

  group('cerrar la guía', () {
    testWidgets(
      'con Esc, con el botón atrás o con «Saltar tutorial»: se cierra, se recuerda como omitida y la navegación sigue',
      (tester) async {
        banco.yaVisto(ConfiguracionRecorridoCliente.inicio);
        await montar(tester, tamanoTelefono);

        await irASeccion(tester, 'Lexus');
        expect(enLaGuia('Conoce a Lexus'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await avanzar(tester);
        expect(hayGuia(), isFalse);

        await irASeccion(tester, 'Cómo funciona');
        expect(enLaGuia('Aprende a usar ManoLegal'), findsOneWidget);
        await pulsarEnLaGuia(tester, 'Comenzar');
        await tester.binding.handlePopRoute();
        await avanzar(tester);
        expect(hayGuia(), isFalse);

        await irASeccion(tester, 'PQRS');
        expect(enLaGuia('PQRS'), findsOneWidget);
        await pulsarEnLaGuia(tester, 'Saltar tutorial');
        expect(hayGuia(), isFalse);

        expect(
          banco.estadoGuardado(ConfiguracionRecorridoCliente.lexus),
          'omitido',
        );
        expect(
          banco.estadoGuardado(ConfiguracionRecorridoCliente.comoFunciona),
          'omitido',
        );
        expect(banco.estadoGuardado(ConfiguracionRecorridoPqrs.pqrs), 'omitido');

        // La navegación sigue funcionando y ninguna guía vuelve.
        for (final (etiqueta, contenido) in [
          ('Lexus', 'Escribe tu consulta…'),
          ('Cómo funciona', 'Cómo funciona ManoLegal'),
          ('PQRS', 'Radicar una PQRS'),
          ('Inicio', 'Buscar abogados'),
        ]) {
          await irASeccion(tester, etiqueta);
          await avanzar(tester, cuadros: 20);
          expect(hayGuia(), isFalse, reason: etiqueta);
          expect(find.text(contenido), findsWidgets, reason: etiqueta);
        }
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Lexus', () {
    testWidgets(
      'espera a que cargue la conversación antes de decidir los pasos',
      (tester) async {
        banco.yaVisto(ConfiguracionRecorridoCliente.inicio);
        final carga = banco.historial.retenerCarga();
        await montar(tester, tamanoTelefono);

        await irASeccion(tester, 'Lexus');
        expect(marcasDe(MarcaRecorridoId.lexusCargando), findsOneWidget);
        await tester.tap(enLaGuia('Comenzar'));
        await avanzar(tester);
        // Sigue en la bienvenida, esperando.
        expect(enLaGuia('Conoce a Lexus'), findsOneWidget);

        carga.complete(null);
        await avanzar(tester);

        expect(marcasDe(MarcaRecorridoId.lexusCargando), findsNothing);
        expect(enLaGuia('Orientación, no asesoría'), findsOneWidget);
        expect(enLaGuia('PASO 1 DE 5'), findsOneWidget);
        await pulsarEnLaGuia(tester, 'Siguiente');
        expect(enLaGuia('Empieza con una sugerencia'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('con una conversación guardada omite las sugerencias', (
      tester,
    ) async {
      banco.yaVisto(ConfiguracionRecorridoCliente.inicio);
      banco.historial.guardada = conversacionGuardadaDePrueba(
        turnos: 1,
        actualizadoEn: banco.reloj.ahora,
        mensajes: intercambioGuardado(
          0,
          pregunta: 'Consulta de prueba',
          respuesta: 'Respuesta de prueba.',
        ),
      );
      await montar(tester, tamanoTelefono);

      await irASeccion(tester, 'Lexus');
      await recorrerGuia(
        tester,
        ConfiguracionRecorridoCliente.lexus,
        resaltados: const ['aviso', 'entrada', 'dictado', 'nuevaConversacion'],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('la guía no envía ni dicta nada', (tester) async {
      banco.yaVisto(ConfiguracionRecorridoCliente.inicio);
      await montar(tester, tamanoTelefono);

      await irASeccion(tester, 'Lexus');
      await recorrerGuia(tester, ConfiguracionRecorridoCliente.lexus);

      expect(banco.lexus.llamadas, isEmpty);
      expect(banco.grabadora.cuenta('pedirPermiso'), 0);
      expect(banco.grabadora.cuenta('iniciar'), 0);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });
  });
}
