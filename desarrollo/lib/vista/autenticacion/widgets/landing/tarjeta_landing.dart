import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';
import 'elevable_al_pasar.dart';
import 'estilos_landing.dart';

/// Superficie blanca con borde fino y sombra suave, para fondos claros.
class TarjetaLanding extends StatelessWidget {
  const TarjetaLanding({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radio = 20,
    this.elevable = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radio;
  final bool elevable;

  @override
  Widget build(BuildContext context) {
    final tarjeta = DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(color: EstilosLanding.borde),
        boxShadow: EstilosLanding.sombraTarjeta,
      ),
      child: Padding(padding: padding, child: child),
    );
    return elevable ? ElevableAlPasar(radio: radio, child: tarjeta) : tarjeta;
  }
}
