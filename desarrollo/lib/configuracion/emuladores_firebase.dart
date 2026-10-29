import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Se define al ejecutar con `--dart-define=USAR_EMULADORES=true`.
const bool _usarEmuladores = bool.fromEnvironment('USAR_EMULADORES');

/// Puertos de `firebase.json`.
const int _puertoAuth = 9099;
const int _puertoFirestore = 8080;
const int _puertoStorage = 9199;

/// Conecta Authentication, Firestore y Storage a los emuladores locales, para
/// probar sin tocar el proyecto real.
///
/// Solo actúa en modo debug y con `USAR_EMULADORES`; en cualquier otro caso no
/// hace nada, así que un build de release nunca apunta a un emulador. Debe
/// llamarse antes de que la app use Auth, Firestore o Storage.
///
/// Uso: `firebase emulators:start --only auth,firestore,storage --project
/// claude-manolegal` y, en otra terminal, `flutter run -d chrome --web-port 5050
/// --dart-define=USAR_EMULADORES=true`. El puerto 8080 es del emulador de
/// Firestore, por eso la web corre en otro.
///
/// El emulador separa los datos por id de proyecto y la app siempre usa el
/// suyo (`claude-manolegal`): con otro id, la interfaz del emulador no
/// mostraría lo que escribe la app. Usar ese id no toca producción, porque
/// Auth, Firestore y Storage quedan emulados. Functions, App Check y Firebase
/// AI Logic (Lexus) NO se emulan: siguen yendo al proyecto real.
///
/// En Android, el build de debug permite HTTP sin cifrar solo hacia estos
/// hosts (`android/app/src/debug/res/xml/network_security_config.xml`).
Future<void> conectarEmuladoresFirebase() async {
  if (!kDebugMode || !_usarEmuladores) return;

  // El emulador de Android ve el computador anfitrión como 10.0.2.2.
  final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, _puertoAuth);
  FirebaseFirestore.instance.useFirestoreEmulator(host, _puertoFirestore);
  await FirebaseStorage.instance.useStorageEmulator(host, _puertoStorage);
  debugPrint(
    'Firebase: Auth, Firestore y Storage conectados a los emuladores locales.',
  );
}
