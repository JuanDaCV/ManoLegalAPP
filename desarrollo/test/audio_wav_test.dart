import 'dart:convert';
import 'dart:typed_data';

import 'package:desarrollo/controlador/audio_wav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('envolverPcmEnWav', () {
    final pcm = Uint8List.fromList(List<int>.generate(100, (i) => i));
    late Uint8List wav;
    late ByteData datos;

    setUp(() {
      wav = envolverPcmEnWav(pcm, frecuenciaMuestreo: 16000, canales: 1);
      datos = ByteData.view(wav.buffer);
    });

    String marca(int posicion) =>
        ascii.decode(wav.sublist(posicion, posicion + 4));

    test('la cabecera mide 44 bytes y el audio va después, sin cambios', () {
      expect(tamanioCabeceraWav, 44);
      expect(wav.length, 44 + pcm.length);
      expect(wav.sublist(44), pcm);
    });

    test('tiene las marcas RIFF, WAVE, fmt y data', () {
      expect(marca(0), 'RIFF');
      expect(marca(8), 'WAVE');
      expect(marca(12), 'fmt ');
      expect(marca(36), 'data');
    });

    test('los tamaños de RIFF y de data coinciden con el audio', () {
      expect(datos.getUint32(4, Endian.little), 36 + pcm.length);
      expect(datos.getUint32(40, Endian.little), pcm.length);
      expect(datos.getUint32(16, Endian.little), 16);
    });

    test('declara PCM de 16 bits, un canal y 16 kHz', () {
      expect(datos.getUint16(20, Endian.little), 1); // PCM sin comprimir.
      expect(datos.getUint16(22, Endian.little), 1);
      expect(datos.getUint32(24, Endian.little), 16000);
      expect(datos.getUint16(34, Endian.little), 16);
    });

    test('calcula la tasa de bytes y la alineación de bloque', () {
      expect(datos.getUint32(28, Endian.little), 32000);
      expect(datos.getUint16(32, Endian.little), 2);
    });

    test('con dos canales y 44,1 kHz ajusta tasa y alineación', () {
      final estereo = envolverPcmEnWav(
        pcm,
        frecuenciaMuestreo: 44100,
        canales: 2,
      );
      final d = ByteData.view(estereo.buffer);
      expect(d.getUint16(22, Endian.little), 2);
      expect(d.getUint32(24, Endian.little), 44100);
      expect(d.getUint32(28, Endian.little), 176400);
      expect(d.getUint16(32, Endian.little), 4);
    });

    test('un audio vacío da solo la cabecera', () {
      final vacio = envolverPcmEnWav(
        Uint8List(0),
        frecuenciaMuestreo: 16000,
        canales: 1,
      );

      expect(vacio.length, 44);
      expect(ByteData.view(vacio.buffer).getUint32(40, Endian.little), 0);
    });
  });
}
