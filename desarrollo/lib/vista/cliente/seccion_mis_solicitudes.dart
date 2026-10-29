import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/tema_app.dart';

/// Sección "Mis solicitudes" del panel del cliente.
///
/// Por ahora solo muestra el estado vacío: el sistema de solicitudes todavía
/// no existe (queda para una iteración futura, junto con la contratación y
/// la mensajería con el abogado).
class SeccionMisSolicitudes extends StatelessWidget {
  const SeccionMisSolicitudes({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis solicitudes',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 24, color: ColoresApp.azulTurquiOscuro),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aquí verás el estado de tus consultas con abogados.',
                style: TextStyle(color: ColoresApp.grisTexto, fontSize: 14),
              ),
              const SizedBox(height: 56),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: ColoresApp.grisClaro, shape: BoxShape.circle),
                      child: const Icon(Icons.inbox_outlined, size: 44, color: ColoresApp.grisTexto),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Todavía no tienes solicitudes',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: ColoresApp.azulTurquiOscuro),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: const Text(
                        'Aquí verás tus consultas y procesos en curso cuando contactes a un abogado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ColoresApp.grisTexto, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
