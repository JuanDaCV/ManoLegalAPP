import 'dart:ui';

import 'package:flutter/material.dart';

import '../tema/tema_app.dart';

/// Tarjeta con efecto de vidrio esmerilado (glassmorfismo), reutilizable en
/// tarjetas puntuales (cómo funciona, testimonios, carrusel, FAQ).
///
/// Se ve bien tanto sobre fondo oscuro (azulTurqui/azulTurquiOscuro) como
/// sobre fondo claro (grisClaro/blanco) — sobre claro el contraste es más
/// sutil a propósito, pero mantiene el mismo lenguaje visual.
///
/// Este widget solo provee el contenedor de vidrio: el color del texto/ícono
/// interno lo decide quien lo usa, según el fondo sobre el que se apoye
/// (blanco sobre fondo oscuro, [ColoresApp.azulTurquiOscuro] sobre fondo claro).
class TarjetaCristal extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// Color de la superficie de vidrio. Por defecto [ColoresApp.superficieCristal]
  /// (~12% blanco), pensado para apoyarse sobre fondos oscuros.
  final Color? color;

  /// Color del borde de vidrio. Por defecto [ColoresApp.bordeCristal].
  final Color? colorBorde;

  const TarjetaCristal({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.color,
    this.colorBorde,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? ColoresApp.superficieCristal,
            border: Border.all(color: colorBorde ?? ColoresApp.bordeCristal),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}
