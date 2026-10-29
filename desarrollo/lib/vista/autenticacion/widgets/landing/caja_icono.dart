import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';

/// Cuadrado azul con un ícono blanco y, opcionalmente, un punto dorado en la
/// esquina: el motivo de ícono de toda la landing.
class CajaIcono extends StatelessWidget {
  const CajaIcono({
    super.key,
    required this.icono,
    this.tamanio = 48,
    this.conPunto = false,
  });

  final IconData icono;
  final double tamanio;
  final bool conPunto;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: tamanio,
        height: tamanio,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ColoresApp.azulProfundo, ColoresApp.azulTurqui],
                  ),
                  borderRadius: BorderRadius.circular(tamanio * 0.28),
                ),
                child: Center(
                  child: Icon(
                    icono,
                    size: tamanio * 0.5,
                    color: ColoresApp.blanco,
                  ),
                ),
              ),
            ),
            if (conPunto)
              const Positioned(
                top: -3,
                right: -3,
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ColoresApp.dorado,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
