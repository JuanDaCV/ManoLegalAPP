import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Token de depuración de App Check, inyectado al compilar con
/// `--dart-define-from-file=<archivo fuera del proyecto>`.
///
/// Nunca se escribe en el código: es una credencial (quien lo tenga obtiene
/// tokens válidos) y se puede revocar desde la consola de Firebase.
const String _tokenDepuracion = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

/// Clave de sitio de reCAPTCHA Enterprise para la web en producción.
const String _claveRecaptchaEnterprise = String.fromEnvironment(
  'RECAPTCHA_ENTERPRISE_SITE_KEY',
);

/// Clave de reCAPTCHA Enterprise de tipo Android, registrada para el paquete
/// `com.example.desarrollo` y habilitada para APK instalados fuera de Google
/// Play.
///
/// Va escrita aquí a propósito: una clave de sitio de reCAPTCHA es pública por
/// diseño (viaja dentro de la app y no da acceso por sí sola). Así
/// `flutter build apk --release` funciona sin `--dart-define`.
const String _claveRecaptchaAndroid =
    '6LfBhd8tAAAAAJNgN0QzLwdV1vZcGeUxU4Tm7JV8';

/// Activa Firebase App Check, que Firebase AI Logic (Lexus) exige para aceptar
/// solicitudes al modelo.
///
/// Proveedor elegido:
/// - Con `APP_CHECK_DEBUG_TOKEN` definido (cualquier modo de compilación) o en
///   modo debug: proveedor de depuración. Sin token fijo, el SDK genera uno y
///   lo muestra en la consola para registrarlo en Firebase.
/// - En release: reCAPTCHA Enterprise en Android (Play Integrity no sirve para
///   el APK, que se instala fuera de Google Play) y en la web (solo si se
///   definió su clave).
///
/// Un fallo aquí no debe impedir que la app arranque: App Check hoy solo se
/// exige para Lexus, no para Auth, Firestore ni Storage.
Future<void> activarAppCheck() async {
  final token = _tokenDepuracion.isEmpty ? null : _tokenDepuracion;
  final depuracion = token != null || kDebugMode;
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: depuracion
          ? AndroidDebugProvider(debugToken: token)
          : const AndroidReCaptchaProvider(_claveRecaptchaAndroid),
      providerWeb: depuracion
          ? WebDebugProvider(debugToken: token)
          : (_claveRecaptchaEnterprise.isEmpty
                ? null
                : ReCaptchaEnterpriseProvider(_claveRecaptchaEnterprise)),
    );
  } catch (_) {
    // Sin detalles: el error podría incluir datos de configuración.
    debugPrint('App Check no se pudo activar; Lexus no estará disponible.');
  }
}
