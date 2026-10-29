import 'dart:typed_data';

/// Convierte el audio de un dictado en texto.
///
/// Devuelve el texto literal de lo dicho, o una cadena vacía si no hay habla
/// inteligible. Si falla, lanza un `ErrorLexus`. Nunca conserva el audio.
abstract class ServicioTranscripcion {
  /// [wav] es un audio WAV (PCM de 16 bits) completo.
  Future<String> transcribir(Uint8List wav);
}
