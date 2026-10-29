import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';

/// Botón de enviar: círculo azul turquí con flecha hacia arriba.
///
/// Es convencional a propósito: usar el rostro de la mascota como botón de
/// enviar comunicaría peor la acción que una flecha que ya todos reconocen.
class BotonEnviarLexus extends StatelessWidget {
  const BotonEnviarLexus({
    super.key,
    required this.habilitado,
    required this.enviando,
    required this.onPressed,
  });

  final bool habilitado;
  final bool enviando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const mensaje = 'Enviar mensaje';
    return Tooltip(
      message: mensaje,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        enabled: habilitado,
        label: mensaje,
        excludeSemantics: true,
        onTap: habilitado ? onPressed : null,
        child: Material(
          color: habilitado
              ? ColoresApp.azulTurqui
              : ColoresApp.grisTexto.withValues(alpha: 0.3),
          shape: CircleBorder(
            side: habilitado
                ? const BorderSide(color: ColoresApp.dorado, width: 1.5)
                : BorderSide.none,
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: habilitado ? onPressed : null,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColoresApp.blanco,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: ColoresApp.blanco,
                        size: 24,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
