import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Autenticación con Google. Clase plana, sin estado propio más allá de la
/// inicialización perezosa de `google_sign_in` (ver [_inicializacion]).
class ServicioGoogle {
  /// `google_sign_in` exige llamar `initialize()` exactamente una vez y
  /// esperar a que termine antes de usar cualquier otro método del paquete.
  /// Se guarda el Future para que llamadas repetidas reutilicen la misma
  /// inicialización en vez de dispararla de nuevo.
  Future<void>? _inicializacion;

  Future<void> _asegurarInicializado() {
    return _inicializacion ??= GoogleSignIn.instance.initialize();
  }

  /// Autentica con Google y devuelve la credencial de Firebase resultante.
  ///
  /// En web, `google_sign_in` v7 no soporta `authenticate()`: su propio
  /// README indica que lanza `UnsupportedError` en esa plataforma y exige
  /// usar su widget `renderButton`, lo que cambiaría el diseño de los
  /// botones ya existentes. Por eso en web se usa directamente la vía
  /// oficial de Firebase (`signInWithPopup`), que no depende del paquete.
  /// En Android/iOS sí se usa `google_sign_in`.
  Future<UserCredential> autenticar() async {
    if (kIsWeb) {
      return FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    }

    await _asegurarInicializado();
    final cuenta = await GoogleSignIn.instance.authenticate();
    final idToken = cuenta.authentication.idToken;
    if (idToken == null) {
      throw ArgumentError(
        'Google no entregó un idToken. Revisa que el serverClientId '
        '(Android) o el cliente OAuth de iOS/SHA-1 estén bien configurados '
        'en Firebase.',
      );
    }

    final credencial = GoogleAuthProvider.credential(idToken: idToken);
    return FirebaseAuth.instance.signInWithCredential(credencial);
  }

  /// Cierra también la sesión del SDK nativo de Google para que la próxima
  /// vez vuelva a mostrar el selector de cuenta en vez de reautenticar en
  /// silencio con la última cuenta usada.
  ///
  /// No hace nada en web (ahí no se usa este paquete) ni si nunca se llegó a
  /// inicializar (el usuario nunca presionó el botón de Google en esta
  /// sesión de la app), para no arriesgar tocar el plugin sin inicializar.
  Future<void> cerrarSesion() async {
    if (kIsWeb || _inicializacion == null) return;
    await _asegurarInicializado();
    await GoogleSignIn.instance.signOut();
  }
}
