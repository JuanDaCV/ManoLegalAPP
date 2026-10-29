import 'package:flutter/material.dart';

import '../../tema/tema_app.dart';
import '../estilos_administrador.dart';

/// Etiqueta del estado de verificación de un abogado.
///
/// Verificado usa el verde semántico que ya usa ManoLegal para esa insignia.
/// Pendiente usa el dorado de marca como acento, con texto oscuro: el dorado
/// no tiene contraste suficiente como color de texto sobre blanco.
class ChipEstadoVerificacion extends StatelessWidget {
  final bool verificado;

  /// Variante para fondos oscuros, como la cabecera del detalle.
  final bool sobreFondoOscuro;

  const ChipEstadoVerificacion({super.key, required this.verificado, this.sobreFondoOscuro = false});

  @override
  Widget build(BuildContext context) {
    final etiqueta = verificado ? 'Verificado' : 'Pendiente';

    final Color fondo;
    final Color borde;
    final Color texto;
    if (verificado) {
      fondo = sobreFondoOscuro ? ColoresApp.verdeVerificado.withValues(alpha: 0.35) : EstilosAdmin.tinteVerificado;
      borde = sobreFondoOscuro ? ColoresApp.verdeVerificado.withValues(alpha: 0.7) : EstilosAdmin.bordeVerificado;
      texto = sobreFondoOscuro ? ColoresApp.blanco : ColoresApp.verdeVerificado;
    } else {
      fondo = sobreFondoOscuro ? ColoresApp.dorado.withValues(alpha: 0.26) : EstilosAdmin.tintePendiente;
      borde = sobreFondoOscuro ? ColoresApp.dorado.withValues(alpha: 0.75) : EstilosAdmin.bordePendiente;
      texto = sobreFondoOscuro ? ColoresApp.blanco : ColoresApp.azulTurquiOscuro;
    }

    return Semantics(
      label: 'Estado: $etiqueta',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borde),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (verificado)
              Icon(Icons.verified, size: 14, color: texto)
            else
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: ColoresApp.dorado, shape: BoxShape.circle),
              ),
            const SizedBox(width: 6),
            // Flexible: con texto agrandado por accesibilidad, o en una
            // columna angosta de la tabla, la etiqueta se recorta en lugar de
            // desbordar.
            Flexible(
              child: Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: texto),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
