import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../controlador/almacen_local.dart';
import 'configuracion_app_check.dart';
import 'emuladores_firebase.dart';
import 'firebase_options.dart';

/// Arranque de Firebase separado del primer cuadro.
///
/// En la web la landing pública no usa Firebase, así que a un visitante sin
/// sesión se le dibuja mientras Firebase y App Check terminan de iniciarse.
/// Todo lo que sí usa Firebase espera a [listo] antes de tocarlo: el
/// enrutador inicial y la navegación de la landing hacia el inicio de sesión
/// y el registro. En Android, y en la web cuando ya había una sesión, `main()`
/// espera a [listo] antes de `runApp`, como siempre.
///
/// El orden no cambia: primero `Firebase.initializeApp` y después App Check,
/// antes de cualquier uso de Auth, Firestore, Storage o Lexus. Justo después,
/// y solo en debug con `USAR_EMULADORES`, Auth y Firestore se conectan a los
/// emuladores locales (ver [conectarEmuladoresFirebase]).
abstract final class ArranqueFirebase {
  /// Indicio guardado en el navegador de que la última vez había una sesión
  /// iniciada. Con él, el enrutador espera a Firebase en lugar de mostrar la
  /// landing un instante a quien en realidad va a entrar a su panel.
  static const String claveIndicioSesion = 'manolegal.sesion.v1';

  static Future<void>? _listo;
  static bool _hayIndicioDeSesion = false;

  /// Termina cuando Firebase y App Check están listos. La primera llamada
  /// inicia el arranque; las siguientes devuelven el mismo `Future`.
  static Future<void> get listo => _listo ??= _iniciar();

  /// Si al abrir la app había un indicio de sesión iniciada (solo web).
  static bool get hayIndicioDeSesion => _hayIndicioDeSesion;

  /// Lee el indicio de sesión. Si el navegador no deja leer su
  /// almacenamiento, se toma como «sin sesión»: lo peor que pasa es ver la
  /// landing un instante antes del panel, como antes de este cambio.
  static Future<void> leerIndicioDeSesion() async {
    try {
      _hayIndicioDeSesion =
          await crearAlmacenLocal().leer(claveIndicioSesion) == '1';
    } catch (_) {
      _hayIndicioDeSesion = false;
    }
  }

  static Future<void> _iniciar() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await activarAppCheck();
    await conectarEmuladoresFirebase();
    if (kIsWeb) _recordarSesion();
  }

  /// Mantiene el indicio al día con cada inicio y cierre de sesión.
  static void _recordarSesion() {
    final almacen = crearAlmacenLocal();
    FirebaseAuth.instance.authStateChanges().listen((usuario) {
      if (usuario == null) {
        unawaited(almacen.borrar(claveIndicioSesion));
      } else {
        unawaited(almacen.escribir(claveIndicioSesion, '1'));
      }
    });
  }

  /// Reemplaza el arranque en las pruebas, que no tienen Firebase.
  @visibleForTesting
  static void usarEnPruebas({
    required Future<void> listo,
    bool hayIndicioDeSesion = false,
  }) {
    _listo = listo;
    _hayIndicioDeSesion = hayIndicioDeSesion;
  }

  /// Vuelve al estado inicial después de una prueba.
  @visibleForTesting
  static void reiniciarEnPruebas() {
    _listo = null;
    _hayIndicioDeSesion = false;
  }
}
