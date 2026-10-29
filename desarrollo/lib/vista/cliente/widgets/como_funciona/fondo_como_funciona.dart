import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';

/// Fondo de la página: el gris claro de la app con dos resplandores muy
/// suaves, uno azul turquí arriba a la izquierda y otro dorado a la derecha.
///
/// Es estático a propósito (sin animación ni desenfoque): se pinta una vez en
/// su propia capa y el desplazamiento no lo vuelve a dibujar. Es decorativo,
/// así que ni recibe toques ni aparece para los lectores de pantalla.
class FondoComoFunciona extends StatelessWidget {
  const FondoComoFunciona({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: ColoresApp.grisClaro),
              _Resplandor(
                color: ColoresApp.azulTurqui,
                opacidad: 0.06,
                centro: const Alignment(-0.9, -0.95),
                radio: 0.9,
              ),
              _Resplandor(color: ColoresApp.dorado, opacidad: 0.07, centro: const Alignment(1.0, -0.2), radio: 0.7),
            ],
          ),
        ),
      ),
    );
  }
}

class _Resplandor extends StatelessWidget {
  final Color color;
  final double opacidad;
  final Alignment centro;
  final double radio;

  const _Resplandor({required this.color, required this.opacidad, required this.centro, required this.radio});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: centro,
          radius: radio,
          // El final usa el mismo color con opacidad cero: con `transparent`
          // (negro sin opacidad) el degradado pasaría por un gris sucio.
          colors: [
            color.withValues(alpha: opacidad),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
