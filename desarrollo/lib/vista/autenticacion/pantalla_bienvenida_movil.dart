import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/tema_app.dart';
import '../widgets_comunes/fondo_juridico.dart';
import 'pantalla_inicio_sesion.dart';
import 'pantalla_seleccion_rol.dart';

/// Pantalla de bienvenida mostrada en móvil cuando no hay sesión activa.
class PantallaBienvenidaMovil extends StatelessWidget {
  const PantallaBienvenidaMovil({super.key});

  void _irAInicioSesion(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaInicioSesion()));
  }

  void _irARegistro(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaSeleccionRol()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FondoJuridico(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Text(
                  'ManoLegal',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 34,
                    color: ColoresApp.blanco,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Justicia accesible, verificada',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: ColoresApp.blanco,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Encuentra abogados verificados en Cali y resuelve tu caso con confianza.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: ColoresApp.blanco.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(flex: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresApp.blanco,
                      foregroundColor: ColoresApp.azulTurqui,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: () => _irAInicioSesion(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _irARegistro(context),
                  child: const Text('Regístrate', style: TextStyle(color: ColoresApp.blanco)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Al continuar, aceptas los Términos y condiciones y la Política de privacidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: ColoresApp.blanco.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
