// El audio del dictado nunca se escribe en disco ni se guarda en Firestore o
// Storage. Este archivo lo comprueba de dos formas:
//
//  - Un recorrido por el código fuente de `lib/`: los archivos del dictado no
//    pueden importar ni nombrar nada que escriba o suba datos, y el plugin
//    `record` solo se usa en modo de flujo en memoria.
//  - Una prueba de flujo completo: dictar, ver el texto en el campo y enviar.
//    El historial recibe únicamente texto; el audio solo llega al transcriptor.
//
// Además, `firestore.rules` usa `hasOnly` en los mensajes de Lexus, así que el
// servidor también rechazaría cualquier campo extra (por ejemplo, audio). Las
// reglas no cambian con esta función.
import 'dart:io';
import 'dart:typed_data';

import 'package:desarrollo/controlador/controlador_dictado_lexus.dart';
import 'package:desarrollo/controlador/controlador_lexus.dart';
import 'package:desarrollo/vista/cliente/seccion_lexus.dart';
import 'package:desarrollo/vista/cliente/widgets/lexus/boton_enviar_lexus.dart';
import 'package:desarrollo/vista/cliente/widgets/lexus/estilos_lexus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_dictado_lexus.dart';
import 'dobles_lexus.dart';

/// Cosas que ningún archivo del dictado debe importar ni usar.
const _prohibidos = <String>[
  'dart:io',
  'path_provider',
  'cloud_firestore',
  'firebase_storage',
  'File(',
  'getApplicationDocumentsDirectory',
  'getTemporaryDirectory',
];

/// Archivos de `lib/` que pertenecen al dictado o al audio, por su nombre.
List<File> _archivosDelDictado() {
  const marcas = ['dictado', 'audio', 'grabacion', 'transcripcion'];
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) {
        final nombre = f.uri.pathSegments.last;
        return marcas.any(nombre.contains);
      })
      .toList();
}

String _nombre(File f) => f.uri.pathSegments.last;

void main() {
  group('el código del dictado no guarda audio', () {
    test('se encuentran todos los archivos del dictado', () {
      final nombres = _archivosDelDictado().map(_nombre).toSet();

      expect(
        nombres,
        containsAll(<String>{
          'audio_wav.dart',
          'servicio_grabacion_audio.dart',
          'servicio_grabacion_audio_real.dart',
          'servicio_transcripcion.dart',
          'servicio_transcripcion_real.dart',
          'controlador_dictado_lexus.dart',
          'boton_dictado_lexus.dart',
          'textos_dictado_lexus.dart',
        }),
      );
    });

    test('ninguno importa ni usa disco, Firestore ni Storage', () {
      for (final archivo in _archivosDelDictado()) {
        final fuente = archivo.readAsStringSync();
        for (final prohibido in _prohibidos) {
          expect(
            fuente.contains(prohibido),
            isFalse,
            reason: '${_nombre(archivo)} no debe contener "$prohibido"',
          );
        }
      }
    });

    test('el plugin record se usa solo con startStream, nunca con ruta', () {
      final usuarios = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('package:record/'))
          .toList();

      // Solo el adaptador del plugin lo importa.
      expect(usuarios.map(_nombre), ['servicio_grabacion_audio_real.dart']);

      final fuente = usuarios.single.readAsStringSync();
      expect(fuente, contains('.startStream('));
      // El modo de archivo es `start(config, path: ...)`: no debe aparecer.
      expect(RegExp(r'\.start\s*\(').hasMatch(fuente), isFalse);
      expect(RegExp(r'\bpath\s*:').hasMatch(fuente), isFalse);
    });

    test('en todo lib/ no hay llamadas a start con path sobre el grabador', () {
      final patron = RegExp(r'\.start\s*\([^;]*path\s*:', dotAll: true);
      for (final archivo
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        expect(
          patron.hasMatch(archivo.readAsStringSync()),
          isFalse,
          reason: _nombre(archivo),
        );
      }
    });
  });

  group('el flujo completo solo guarda texto', () {
    testWidgets('dictar, revisar en el campo y enviar: el audio no sale del '
        'transcriptor', (tester) async {
      EstilosLexus.usarTipografiaDeMarca = false;
      final servicio = ServicioLexusDoble();
      final historial = ServicioConversacionesLexusDoble();
      final relojChat = RelojFalso();
      final grabadora = GrabacionAudioFalsa();
      final transcriptor = TranscriptorFalso();
      final relojDictado = RelojDictadoFalso();
      const dictado = 'Me despidieron sin justa causa';
      transcriptor.texto = dictado;

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeccionLexus(
              crearControlador: () => ControladorLexus(
                servicio: servicio,
                conversaciones: historial,
                haySesion: () => true,
                ahora: () {
                  relojChat.avanzar();
                  return relojChat.ahora;
                },
              ),
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

      // Dictar.
      await tester.tap(find.byTooltip('Dictar consulta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      relojDictado.tic(const Duration(seconds: 6));
      await tester.pump();
      await tester.tap(find.byTooltip('Detener y transcribir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // El texto quedó en el campo y todavía no se envió nada.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        dictado,
      );
      expect(servicio.llamadas, isEmpty);
      expect(historial.llamadasDe('guardarEnvio:nueva'), isEmpty);

      // Enviar a mano.
      servicio.responder(jsonLexus());
      await tester.tap(find.byType(BotonEnviarLexus));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // El modelo del chat recibió solo texto.
      expect(servicio.llamadas.single.mensaje, dictado);
      // El historial guardó el texto del envío y nada más.
      expect(historial.llamadasDe('guardarEnvio:nueva'), hasLength(1));
      final guardados = historial.conversaciones.values.single.mensajes.values;
      expect(guardados.map((m) => m.texto), contains(dictado));
      expect(
        guardados.map((m) => m.texto),
        everyElement(isNot(contains('RIFF'))),
      );
      // El audio solo llegó al transcriptor, y una sola vez.
      expect(transcriptor.recibidos.single, same(grabadora.wav));
      expect(grabadora.wav, isA<Uint8List>());
    });
  });
}
