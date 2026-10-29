import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mantiene la pantalla encendida mientras se reproduce un video de "Cómo
/// funciona".
///
/// Solo hace algo en Android, y por razones distintas en cada plataforma:
/// - Android: `video_player` no impide que la pantalla se apague, así que un
///   video de más de un minuto se cortaría a mitad de explicación. La
///   actividad nativa (`MainActivity`) activa y quita la bandera
///   `FLAG_KEEP_SCREEN_ON` a través de este canal.
/// - iOS: `video_player` ya lo resuelve con `preventsDisplaySleepDuringVideoPlayback`,
///   que por defecto es verdadero.
/// - Web: el navegador se encarga de no apagar la pantalla durante un video.
///
/// Es un detalle de comodidad, no una función crítica: si el canal no
/// responde (por ejemplo, una versión de la app sin la parte nativa), se
/// ignora el fallo y el video se reproduce igual.
class ServicioPantalla {
  const ServicioPantalla();

  /// Nombre del canal; debe coincidir con el de `MainActivity.kt`.
  static const String canal = 'manolegal/pantalla';

  static const MethodChannel _canal = MethodChannel(canal);

  Future<void> mantenerEncendida(bool encendida) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _canal.invokeMethod<void>('mantenerEncendida', encendida);
    } on MissingPluginException catch (e) {
      debugPrint('Pantalla encendida no disponible: $e');
    } on PlatformException catch (e) {
      debugPrint('No se pudo cambiar la pantalla encendida: ${e.message}');
    }
  }
}
