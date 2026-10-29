import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';

/// Réplica de la insignia "Verificado" de la tarjeta real de abogado
/// (ícono + texto: nunca depende solo del color).
class InsigniaVerificadoLanding extends StatelessWidget {
  const InsigniaVerificadoLanding({super.key, this.escala = 1});

  final double escala;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresApp.verdeVerificado.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * escala,
          vertical: 3 * escala,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              size: 13 * escala,
              color: ColoresApp.verdeVerificado,
            ),
            SizedBox(width: 4 * escala),
            Text(
              'Verificado',
              style: TextStyle(
                fontSize: 11 * escala,
                fontWeight: FontWeight.w700,
                color: ColoresApp.verdeVerificado,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
