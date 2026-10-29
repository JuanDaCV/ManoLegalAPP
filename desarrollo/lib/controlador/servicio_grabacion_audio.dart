import 'dart:typed_data';

/// Resultado de pedir acceso al micrófono.
enum PermisoMicrofono { concedido, denegado, noDisponible }

/// Grabación de voz en memoria para el dictado de Lexus.
///
/// Ninguna implementación escribe el audio en disco ni lo envía a un servicio
/// de almacenamiento: solo entrega los bytes a quien llama.
///
/// Ningún método lanza: un fallo del plugin se traduce en
/// [PermisoMicrofono.noDisponible], `false` o `null`.
abstract class ServicioGrabacionAudio {
  /// Comprueba el permiso y, si hace falta, lo solicita a la persona.
  Future<PermisoMicrofono> pedirPermiso();

  /// Empieza a grabar. Devuelve falso si no se pudo.
  Future<bool> iniciar();

  /// Termina la grabación y devuelve el audio como WAV, o nulo si no hay
  /// audio utilizable.
  Future<Uint8List?> detener();

  /// Termina la grabación y descarta el audio.
  Future<void> cancelar();

  /// Libera el micrófono y los recursos del plugin. Se puede llamar varias
  /// veces y aunque nunca se haya grabado.
  Future<void> liberar();
}
