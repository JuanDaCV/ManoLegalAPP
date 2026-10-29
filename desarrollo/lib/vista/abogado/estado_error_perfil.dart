import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../controlador/controlador_perfil_abogado.dart';
import '../tema/tema_app.dart';

/// Estado de error compartido por "Mi perfil" y "Panel" cuando la carga del
/// perfil del abogado falla.
///
/// Muestra la causa real y ofrece reintentar, en lugar de dejar una pantalla
/// vacía o un indicador de carga infinito.
class EstadoErrorPerfil extends StatelessWidget {
  final ControladorPerfilAbogado controlador;

  const EstadoErrorPerfil({super.key, required this.controlador});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: ColoresApp.rojoNoVerificado),
            const SizedBox(height: 12),
            const Text(
              'No se pudo cargar tu perfil',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: ColoresApp.azulTurquiOscuro),
            ),
            const SizedBox(height: 6),
            Text(
              controlador.mensajeError ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                final usuario = FirebaseAuth.instance.currentUser;
                if (usuario != null) controlador.cargar(usuario.uid);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
