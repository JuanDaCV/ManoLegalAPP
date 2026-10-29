import 'dart:ui';

import 'package:flutter/material.dart';

/// Panel de cristal esmerilado. SOLO sobre fondos azul marino: sobre blanco
/// el relleno translúcido blanco no se distingue.
///
/// [oscuro] lo vuelve casi opaco: es para piezas que flotan encima de una
/// superficie clara (por ejemplo, la pantalla del teléfono en el hero), donde
/// el texto blanco sobre cristal claro sería ilegible.
class CristalLanding extends StatelessWidget {
  const CristalLanding({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radio = 16,
    this.oscuro = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radio;
  final bool oscuro;

  /// Desenfoque del cristal claro. Era 14: con 8 se ve igual de esmerilado y
  /// el navegador lo recalcula con bastante menos trabajo en equipos lentos.
  static const double _desenfoque = 8;

  @override
  Widget build(BuildContext context) {
    final borde = BorderRadius.circular(radio);
    final relleno = DecoratedBox(
      decoration: BoxDecoration(
        color: oscuro ? const Color(0xE60A1930) : const Color(0x1AFFFFFF),
        borderRadius: borde,
        border: Border.all(
          color: oscuro ? const Color(0x24FFFFFF) : const Color(0x2EFFFFFF),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    // El cristal oscuro es 90 % opaco: el desenfoque de lo que hay detrás no
    // se percibe, así que no se paga.
    final panel = oscuro
        ? relleno
        : ClipRRect(
            borderRadius: borde,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: _desenfoque, sigmaY: _desenfoque),
              child: relleno,
            ),
          );
    if (!oscuro) return panel;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borde,
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: panel,
    );
  }
}
