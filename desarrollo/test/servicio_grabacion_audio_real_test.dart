import 'dart:typed_data';

import 'package:desarrollo/controlador/audio_wav.dart';
import 'package:desarrollo/controlador/servicio_grabacion_audio.dart';
import 'package:desarrollo/controlador/servicio_grabacion_audio_real.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'dobles_dictado_lexus.dart';

void main() {
  late GrabadoraNativaFalsa grabadora;
  late int creaciones;
  late ServicioGrabacionAudioReal servicio;

  setUp(() {
    grabadora = GrabadoraNativaFalsa();
    creaciones = 0;
    servicio = ServicioGrabacionAudioReal(
      crearGrabadora: () {
        creaciones++;
        return grabadora;
      },
    );
  });

  Uint8List audioDe(Uint8List wav) => wav.sublist(tamanioCabeceraWav);

  group('formato de la grabación', () {
    test('pide un flujo PCM de 16 bits, 16 kHz y un canal', () async {
      expect(await servicio.iniciar(), isTrue);

      final configuracion = grabadora.configuraciones.single;
      expect(configuracion.encoder, AudioEncoder.pcm16bits);
      expect(configuracion.sampleRate, 16000);
      expect(configuracion.numChannels, 1);
    });

    test('une los fragmentos y devuelve un WAV válido', () async {
      await servicio.iniciar();
      grabadora
        ..emitir([1, 2, 3, 4])
        ..emitir([5, 6])
        ..emitir([7, 8, 9, 10]);

      final wav = await servicio.detener();

      expect(wav, isNotNull);
      expect(String.fromCharCodes(wav!.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(audioDe(wav), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      final datos = ByteData.view(wav.buffer);
      expect(datos.getUint32(24, Endian.little), 16000);
      expect(datos.getUint16(22, Endian.little), 1);
      expect(datos.getUint32(40, Endian.little), 10);
      expect(grabadora.detenciones, 1);
    });

    test('descarta un byte suelto: una muestra de 16 bits ocupa 2', () async {
      await servicio.iniciar();
      grabadora.emitir([1, 2, 3]);

      final wav = await servicio.detener();

      expect(audioDe(wav!), [1, 2]);
    });

    test('sin fragmentos no hay audio utilizable', () async {
      await servicio.iniciar();

      expect(await servicio.detener(), isNull);
    });

    test('un error en el flujo invalida la grabación', () async {
      await servicio.iniciar();
      grabadora
        ..emitir([1, 2])
        ..emitirError(StateError('fallo'));

      expect(await servicio.detener(), isNull);
    });

    test('sin grabación en curso, detener devuelve nulo', () async {
      expect(await servicio.detener(), isNull);
    });
  });

  group('cancelar', () {
    test('descarta el audio y una grabación nueva empieza de cero', () async {
      await servicio.iniciar();
      grabadora.emitir([1, 2, 3, 4]);

      await servicio.cancelar();

      expect(grabadora.cancelaciones, 1);
      expect(await servicio.detener(), isNull);

      await servicio.iniciar();
      grabadora.emitir([9, 9]);
      final wav = await servicio.detener();
      expect(audioDe(wav!), [9, 9]);
    });
  });

  group('permiso y errores del plugin', () {
    test('permiso concedido', () async {
      expect(await servicio.pedirPermiso(), PermisoMicrofono.concedido);
    });

    test('permiso denegado no lanza', () async {
      grabadora.permiso = false;

      expect(await servicio.pedirPermiso(), PermisoMicrofono.denegado);
    });

    test('una excepción al pedir el permiso da "no disponible"', () async {
      grabadora.errorAlPedirPermiso = StateError('sin micrófono');

      expect(await servicio.pedirPermiso(), PermisoMicrofono.noDisponible);
    });

    test('una excepción al iniciar devuelve falso y no lanza', () async {
      grabadora.errorAlIniciar = StateError('ocupado');

      expect(await servicio.iniciar(), isFalse);
      expect(await servicio.detener(), isNull);
    });

    test('una excepción al detener devuelve nulo y no lanza', () async {
      await servicio.iniciar();
      grabadora.emitir([1, 2]);
      grabadora.errorAlDetener = StateError('fallo');

      expect(await servicio.detener(), isNull);
    });
  });

  group('creación diferida', () {
    test('no toca la grabadora hasta el primer uso', () async {
      expect(creaciones, 0);

      await servicio.cancelar();
      await servicio.liberar();
      expect(creaciones, 0, reason: 'cancelar y liberar no la crean');

      await servicio.pedirPermiso();
      expect(creaciones, 1);
    });

    test('liberar cancela y libera la grabadora', () async {
      await servicio.iniciar();

      await servicio.liberar();

      expect(grabadora.cancelaciones, 1);
      expect(grabadora.liberaciones, 1);
    });
  });
}
