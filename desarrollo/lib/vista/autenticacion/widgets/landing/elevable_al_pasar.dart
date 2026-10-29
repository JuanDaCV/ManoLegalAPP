import 'package:flutter/material.dart';

import 'estilos_landing.dart';

/// Eleva su hijo 4 px al pasar el puntero. Con "reducir movimiento" no se
/// aplica ninguna transformación.
class ElevableAlPasar extends StatefulWidget {
  const ElevableAlPasar({super.key, required this.child, this.radio = 20});

  final Widget child;
  final double radio;

  @override
  State<ElevableAlPasar> createState() => _ElevableAlPasarState();
}

class _ElevableAlPasarState extends State<ElevableAlPasar> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    final elevado = _encima && !sinMovimiento;
    return MouseRegion(
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: AnimatedContainer(
        duration: EstilosLanding.duracion(context, 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, elevado ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radio),
          boxShadow: elevado ? EstilosLanding.sombraElevada : const [],
        ),
        child: widget.child,
      ),
    );
  }
}
