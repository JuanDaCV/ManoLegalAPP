import 'dart:convert';
import 'dart:typed_data';

/// Tamaño fijo de la cabecera WAV (RIFF) de un PCM sin comprimir.
const int tamanioCabeceraWav = 44;

/// Envuelve audio PCM de 16 bits little-endian en un contenedor WAV.
///
/// Es una función pura: no toca disco ni plugins. La cabecera sigue el formato
/// canónico de 44 bytes (RIFF, `fmt ` de 16 bytes y `data`).
Uint8List envolverPcmEnWav(
  Uint8List pcm, {
  required int frecuenciaMuestreo,
  required int canales,
}) {
  const bitsPorMuestra = 16;
  final bytesPorMuestra = bitsPorMuestra ~/ 8;
  final bytesPorSegundo = frecuenciaMuestreo * canales * bytesPorMuestra;
  final alineacionBloque = canales * bytesPorMuestra;

  final resultado = Uint8List(tamanioCabeceraWav + pcm.length);
  final datos = ByteData.view(resultado.buffer);

  void texto(int posicion, String valor) =>
      resultado.setRange(posicion, posicion + 4, ascii.encode(valor));

  texto(0, 'RIFF');
  datos.setUint32(4, 36 + pcm.length, Endian.little);
  texto(8, 'WAVE');
  texto(12, 'fmt ');
  datos.setUint32(16, 16, Endian.little); // Tamaño del bloque fmt.
  datos.setUint16(20, 1, Endian.little); // 1 = PCM sin comprimir.
  datos.setUint16(22, canales, Endian.little);
  datos.setUint32(24, frecuenciaMuestreo, Endian.little);
  datos.setUint32(28, bytesPorSegundo, Endian.little);
  datos.setUint16(32, alineacionBloque, Endian.little);
  datos.setUint16(34, bitsPorMuestra, Endian.little);
  texto(36, 'data');
  datos.setUint32(40, pcm.length, Endian.little);
  resultado.setRange(tamanioCabeceraWav, resultado.length, pcm);
  return resultado;
}
