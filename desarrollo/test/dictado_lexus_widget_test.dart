import 'package:desarrollo/configuracion/respuestas_locales_lexus.dart';
import 'package:desarrollo/controlador/controlador_dictado_lexus.dart';
import 'package:desarrollo/controlador/controlador_lexus.dart';
import 'package:desarrollo/controlador/servicio_grabacion_audio.dart';
import 'package:desarrollo/modelo/error_lexus.dart';
import 'package:desarrollo/vista/cliente/seccion_lexus.dart';
import 'package:desarrollo/vista/cliente/widgets/lexus/boton_dictado_lexus.dart';
import 'package:desarrollo/vista/cliente/widgets/lexus/boton_enviar_lexus.dart';
import 'package:desarrollo/vista/cliente/widgets/lexus/estilos_lexus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_dictado_lexus.dart';
import 'dobles_lexus.dart';

void main() {
  late ServicioLexusDoble servicio;
  late ServicioConversacionesLexusDoble historial;
  late BuscadorAbogadosFalso buscador;
  late RelojFalso relojChat;
  late GrabacionAudioFalsa grabadora;
  late TranscriptorFalso transcriptor;
  late RelojDictadoFalso relojDictado;

  const textoDictado = 'Me despidieron sin justa causa';

  setUp(() {
    EstilosLexus.usarTipografiaDeMarca = false;
    servicio = ServicioLexusDoble();
    historial = ServicioConversacionesLexusDoble();
    buscador = BuscadorAbogadosFalso();
    relojChat = RelojFalso();
    grabadora = GrabacionAudioFalsa();
    transcriptor = TranscriptorFalso();
    relojDictado = RelojDictadoFalso();
  });

  ControladorLexus crearControlador() => ControladorLexus(
    servicio: servicio,
    conversaciones: historial,
    buscarAbogados: buscador.buscar,
    haySesion: () => true,
    ahora: () {
      relojChat.avanzar();
      return relojChat.ahora;
    },
  );

  Future<void> montar(
    WidgetTester tester, {
    bool reducirAnimaciones = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, hijo) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducirAnimaciones),
          child: hijo!,
        ),
        home: Scaffold(
          body: SeccionLexus(
            crearControlador: crearControlador,
            crearDictado: (alTranscribir) => ControladorDictadoLexus(
              alTranscribir: alTranscribir,
              grabadora: grabadora,
              transcriptor: transcriptor,
              ahora: relojDictado.call,
              crearTemporizador: relojDictado.crearTemporizador,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  /// No usa pumpAndSettle: el punto de grabación late sin fin.
  Future<void> avanzar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder botonMicrofono() => find.byTooltip('Dictar consulta');
  Finder botonDetener() => find.byTooltip('Detener y transcribir');

  Future<void> empezarADictar(WidgetTester tester) async {
    await tester.tap(botonMicrofono());
    await avanzar(tester);
  }

  Future<void> detenerDictado(
    WidgetTester tester, {
    Duration duracion = const Duration(seconds: 5),
  }) async {
    relojDictado.tic(duracion);
    await tester.pump();
    await tester.tap(botonDetener());
    await avanzar(tester);
  }

  String textoDelCampo(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  Future<void> escribir(WidgetTester tester, String texto) async {
    await tester.enterText(find.byType(TextField), texto);
    await tester.pump();
  }

  bool envioHabilitado(WidgetTester tester) =>
      tester.widget<BotonEnviarLexus>(find.byType(BotonEnviarLexus)).habilitado;

  group('barra de entrada', () {
    testWidgets('muestra el botón del micrófono junto al de enviar', (
      tester,
    ) async {
      await montar(tester);

      expect(find.byType(BotonDictadoLexus), findsOneWidget);
      expect(botonMicrofono(), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
      expect(find.byType(BotonEnviarLexus), findsOneWidget);
      expect(find.byType(IndicadorDictadoLexus), findsOneWidget);
      expect(find.text('Grabando'), findsNothing);
      expect(
        grabadora.llamadas,
        isEmpty,
        reason: 'montar no toca el micrófono',
      );
    });

    testWidgets('el micrófono tiene semántica de botón "Dictar consulta"', (
      tester,
    ) async {
      final manejador = tester.ensureSemantics();
      await montar(tester);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Dictar consulta')),
        matchesSemantics(
          label: 'Dictar consulta',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      manejador.dispose();
    });

    testWidgets('mientras el historial carga, el micrófono está desactivado', (
      tester,
    ) async {
      final carga = historial.retenerCarga();
      await montar(tester);

      expect(
        tester
            .widget<BotonDictadoLexus>(find.byType(BotonDictadoLexus))
            .habilitado,
        isFalse,
      );
      await tester.tap(botonMicrofono());
      await avanzar(tester);
      expect(grabadora.llamadas, isEmpty);

      carga.complete(null);
      await avanzar(tester);
      expect(
        tester
            .widget<BotonDictadoLexus>(find.byType(BotonDictadoLexus))
            .habilitado,
        isTrue,
      );
    });
  });

  group('grabando', () {
    testWidgets('muestra el indicador de grabación y la cuenta atrás', (
      tester,
    ) async {
      await montar(tester);

      await empezarADictar(tester);

      expect(find.text('Grabando'), findsOneWidget);
      expect(find.byKey(const ValueKey('punto-grabacion')), findsOneWidget);
      expect(find.text('2:00'), findsOneWidget);
      expect(botonDetener(), findsOneWidget);
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

      relojDictado.tic(const Duration(seconds: 15));
      await tester.pump();
      expect(find.text('1:45'), findsOneWidget);
      expect(find.text('2:00'), findsNothing);
    });

    testWidgets('el punto de grabación late, salvo con animaciones reducidas', (
      tester,
    ) async {
      await montar(tester);
      await empezarADictar(tester);
      // Pasa la onda de pulsación del toque: solo queda el latido.
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const ValueKey('punto-grabacion')), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(const SizedBox());
      grabadora.llamadas.clear();
      await montar(tester, reducirAnimaciones: true);
      await empezarADictar(tester);
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const ValueKey('punto-grabacion')), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('el botón de enviar se desactiva y el campo sigue editable', (
      tester,
    ) async {
      await montar(tester);
      await escribir(tester, 'Hola Lexus');
      expect(envioHabilitado(tester), isTrue);

      await empezarADictar(tester);

      expect(envioHabilitado(tester), isFalse);
      expect(
        tester.widget<TextField>(find.byType(TextField)).enabled,
        isNot(false),
      );
      await escribir(tester, 'Hola Lexus, otra cosa');
      expect(textoDelCampo(tester), 'Hola Lexus, otra cosa');
      expect(envioHabilitado(tester), isFalse);
    });

    testWidgets('cancelar descarta la grabación y no cambia el campo', (
      tester,
    ) async {
      await montar(tester);
      await escribir(tester, 'Texto previo');
      await empezarADictar(tester);

      await tester.tap(find.text('Cancelar'));
      await avanzar(tester);

      expect(find.text('Grabando'), findsNothing);
      expect(textoDelCampo(tester), 'Texto previo');
      expect(transcriptor.recibidos, isEmpty);
      expect(envioHabilitado(tester), isTrue);
    });
  });

  group('transcribiendo', () {
    testWidgets('muestra "Transcribiendo…" y mantiene el envío desactivado', (
      tester,
    ) async {
      final espera = transcriptor.retener();
      await montar(tester);
      await escribir(tester, 'Hola');
      await empezarADictar(tester);

      await detenerDictado(tester);

      expect(find.text('Transcribiendo…'), findsOneWidget);
      expect(find.text('Grabando'), findsNothing);
      expect(envioHabilitado(tester), isFalse);
      expect(textoDelCampo(tester), 'Hola');

      espera.complete(textoDictado);
      await avanzar(tester);
      expect(find.text('Transcribiendo…'), findsNothing);
      expect(envioHabilitado(tester), isTrue);
    });
  });

  group('resultado', () {
    testWidgets('añade la transcripción al texto existente y no la envía', (
      tester,
    ) async {
      await montar(tester);
      await escribir(tester, 'Hola Lexus,');
      await empezarADictar(tester);

      await detenerDictado(tester);

      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.controller!.text, 'Hola Lexus, $textoDictado');
      expect(
        campo.controller!.selection,
        TextSelection.collapsed(offset: campo.controller!.text.length),
      );
      expect(campo.focusNode!.hasFocus, isTrue);
      // Quedó en el campo para revisarlo: nada se envió.
      expect(servicio.llamadas, isEmpty);
      expect(historial.llamadasDe('guardarEnvio:nueva'), isEmpty);
      expect(historial.llamadasDe('guardarEnvio'), isEmpty);
      expect(envioHabilitado(tester), isTrue);
    });

    testWidgets('con el campo vacío no añade espacio inicial', (tester) async {
      await montar(tester);
      await empezarADictar(tester);

      await detenerDictado(tester);

      expect(textoDelCampo(tester), textoDictado);
      expect(servicio.llamadas, isEmpty);
    });

    testWidgets('dos dictados seguidos se añaden uno tras otro', (
      tester,
    ) async {
      await montar(tester);
      await empezarADictar(tester);
      transcriptor.texto = 'primero';
      await detenerDictado(tester);
      await empezarADictar(tester);
      transcriptor.texto = 'segundo';
      await detenerDictado(tester);

      expect(textoDelCampo(tester), 'primero segundo');
      expect(servicio.llamadas, isEmpty);
    });
  });

  group('errores', () {
    testWidgets('permiso denegado: diálogo con los pasos para activarlo', (
      tester,
    ) async {
      grabadora.permiso = PermisoMicrofono.denegado;
      await montar(tester);
      await escribir(tester, 'Mi consulta');

      await tester.tap(botonMicrofono());
      await avanzar(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Activa el micrófono'), findsOneWidget);
      // En las pruebas la plataforma por defecto es Android.
      expect(
        find.textContaining('Ajustes > Aplicaciones > ManoLegal > Permisos'),
        findsOneWidget,
      );
      expect(find.textContaining('seguir escribiendo'), findsOneWidget);
      expect(textoDelCampo(tester), 'Mi consulta');
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(find.text('Entendido'));
      await avanzar(tester);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('permiso denegado dos veces avisa dos veces', (tester) async {
      grabadora.permiso = PermisoMicrofono.denegado;
      await montar(tester);

      for (var i = 0; i < 2; i++) {
        await tester.tap(botonMicrofono());
        await avanzar(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('Entendido'));
        await avanzar(tester);
        expect(find.byType(AlertDialog), findsNothing);
      }
    });

    testWidgets('fallo de la transcripción: mensaje y el campo intacto', (
      tester,
    ) async {
      transcriptor.error = StateError('fallo');
      await montar(tester);
      await escribir(tester, 'Texto que no debe perderse');
      await empezarADictar(tester);

      await detenerDictado(tester);

      expect(
        find.text(
          'No se pudo transcribir el audio. Inténtalo de nuevo o escribe tu consulta.',
        ),
        findsOneWidget,
      );
      expect(textoDelCampo(tester), 'Texto que no debe perderse');
      expect(servicio.llamadas, isEmpty);
      expect(find.text('Transcribiendo…'), findsNothing);
      expect(envioHabilitado(tester), isTrue);
    });

    testWidgets('sin conexión reutiliza el texto de Lexus para ese error', (
      tester,
    ) async {
      transcriptor.error = const ErrorLexus(TipoErrorLexus.sinConexion);
      await montar(tester);
      await empezarADictar(tester);

      await detenerDictado(tester);

      expect(
        find.text(RespuestasLocalesLexus.respuestaSinConexion),
        findsOneWidget,
      );
    });

    testWidgets('grabación muy corta: aviso breve y no se llama al modelo', (
      tester,
    ) async {
      await montar(tester);
      await empezarADictar(tester);

      await detenerDictado(tester, duracion: const Duration(milliseconds: 400));

      expect(find.textContaining('muy corta'), findsOneWidget);
      expect(transcriptor.recibidos, isEmpty);
      expect(textoDelCampo(tester), isEmpty);
    });

    testWidgets('transcripción vacía: aviso y el campo intacto', (
      tester,
    ) async {
      transcriptor.texto = '';
      await montar(tester);
      await escribir(tester, 'Algo ya escrito');
      await empezarADictar(tester);

      await detenerDictado(tester);

      expect(
        find.textContaining('No se entendió ninguna palabra'),
        findsOneWidget,
      );
      expect(textoDelCampo(tester), 'Algo ya escrito');
    });

    testWidgets('micrófono no disponible: aviso breve', (tester) async {
      grabadora.permiso = PermisoMicrofono.noDisponible;
      await montar(tester);

      await tester.tap(botonMicrofono());
      await avanzar(tester);

      expect(
        find.textContaining('No se pudo usar el micrófono'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('ciclo de vida', () {
    testWidgets('cerrar la sección durante la grabación la cancela', (
      tester,
    ) async {
      await montar(tester);
      await empezarADictar(tester);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(grabadora.cuenta('cancelar'), greaterThanOrEqualTo(1));
      expect(grabadora.cuenta('liberar'), 1);
      expect(relojDictado.hayTemporizadorActivo, isFalse);
      expect(transcriptor.recibidos, isEmpty);
    });
  });
}
