import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/tema_app.dart';
import '../widgets_comunes/boton_personalizado.dart';

/// Acción del visitante que necesita una cuenta. Define el título y el
/// mensaje de [AvisoRequiereCuenta].
enum MotivoCuentaRequerida { verPerfil, lexus, pqrs }

/// Título y mensaje del aviso para cada [MotivoCuentaRequerida].
(String, String) _textosMotivo(MotivoCuentaRequerida motivo) {
  return switch (motivo) {
    MotivoCuentaRequerida.verPerfil => (
      'Conoce el perfil completo',
      'Crea tu cuenta en ManoLegal o inicia sesión para consultar la información completa de este abogado.',
    ),
    MotivoCuentaRequerida.lexus => (
      'Conversa con Lexus',
      'Crea tu cuenta o inicia sesión para enviar tu consulta a Lexus.',
    ),
    MotivoCuentaRequerida.pqrs => (
      'Radica tu PQRS',
      'Crea tu cuenta o inicia sesión para radicar una PQRS y recibir tu número de radicado.',
    ),
  };
}

/// Muestra el aviso de que [motivo] necesita una cuenta.
///
/// El diálogo se cierra a sí mismo antes de llamar a [alIniciarSesion] o a
/// [alCrearCuenta]. Esas devoluciones deben navegar con el contexto de quien
/// abrió el aviso (el panel del visitante), no con el del diálogo, que ya no
/// existe. «Continuar explorando» solo lo cierra: la búsqueda, los filtros y
/// lo escrito siguen como estaban.
Future<void> mostrarAvisoRequiereCuenta(
  BuildContext context, {
  required MotivoCuentaRequerida motivo,
  required VoidCallback alIniciarSesion,
  required VoidCallback alCrearCuenta,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogo) => AvisoRequiereCuenta(
      motivo: motivo,
      alIniciarSesion: () {
        Navigator.of(dialogo).pop();
        alIniciarSesion();
      },
      alCrearCuenta: () {
        Navigator.of(dialogo).pop();
        alCrearCuenta();
      },
      alContinuar: () => Navigator.of(dialogo).pop(),
    ),
  );
}

/// Diálogo que invita al visitante a iniciar sesión o crear una cuenta, con
/// la identidad de ManoLegal: fondo blanco, azul turquí y un acento dorado.
/// Cabe en un teléfono de 390 px y no pasa de 420 px de ancho.
class AvisoRequiereCuenta extends StatelessWidget {
  final MotivoCuentaRequerida motivo;
  final VoidCallback alIniciarSesion;
  final VoidCallback alCrearCuenta;
  final VoidCallback alContinuar;

  const AvisoRequiereCuenta({
    super.key,
    required this.motivo,
    required this.alIniciarSesion,
    required this.alCrearCuenta,
    required this.alContinuar,
  });

  @override
  Widget build(BuildContext context) {
    final (titulo, mensaje) = _textosMotivo(motivo);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: ColoresApp.blanco,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: ColoresApp.azulTurqui.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_person_outlined, color: ColoresApp.azulTurqui, size: 28),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: ColoresApp.dorado, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: ColoresApp.azulTurquiOscuro,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 14.5, height: 1.45),
              ),
              const SizedBox(height: 24),
              BotonPersonalizado(texto: 'Iniciar sesión', onPressed: alIniciarSesion),
              const SizedBox(height: 12),
              BotonPersonalizado(texto: 'Crear cuenta', esPrimario: false, onPressed: alCrearCuenta),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ColoresApp.azulTurqui,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: alContinuar,
                child: const Text('Continuar explorando'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
