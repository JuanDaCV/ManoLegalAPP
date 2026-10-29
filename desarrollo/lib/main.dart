import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'configuracion/arranque_firebase.dart';
import 'controlador/controlador_administrador.dart';
import 'controlador/controlador_autenticacion.dart';
import 'vista/tema/tema_app.dart';
import 'vista/utilidades/enrutador_inicial.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) await ArranqueFirebase.leerIndicioDeSesion();
  if (kIsWeb && !ArranqueFirebase.hayIndicioDeSesion) {
    // Visitante sin sesión: la landing se dibuja sin esperar a Firebase. Lo
    // que lo usa espera a `ArranqueFirebase.listo` (ver arranque_firebase.dart).
    unawaited(ArranqueFirebase.listo);
  } else {
    // Android, y quien ya tenía sesión en la web: como siempre.
    await ArranqueFirebase.listo;
  }
  runApp(const AplicacionManoLegal());
}

/// Widget raíz de la aplicación ManoLegal.
class AplicacionManoLegal extends StatelessWidget {
  const AplicacionManoLegal({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ControladorAutenticacion()),
        ChangeNotifierProvider(create: (_) => ControladorAdministrador()),
      ],
      child: MaterialApp(
        theme: TemaApp.temaClaro,
        home: const EnrutadorInicial(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
