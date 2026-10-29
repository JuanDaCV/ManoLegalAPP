import 'package:flutter/material.dart';

import '../tema/tema_app.dart';

/// Fondo reutilizable con gradiente + orbes decorativos + ícono jurídico de
/// marca de agua. Sirve tanto a pantalla completa (onboarding móvil, hero web)
/// como en miniatura (mockup de teléfono dentro de la landing web).
///
/// No usa imágenes ni assets externos: todo el "ambiente jurídico" se logra
/// con gradientes, círculos degradados y [Icons.gavel] a gran tamaño.
class FondoJuridico extends StatelessWidget {
  /// Opacidad del ícono grande de fondo.
  final double intensidadIcono;

  /// Si se muestran los círculos decorativos desenfocados.
  final bool mostrarOrbes;

  /// Contenido a superponer, sin restricciones de tamaño adicionales.
  final Widget? child;

  const FondoJuridico({
    super.key,
    this.intensidadIcono = 0.10,
    this.mostrarOrbes = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder envuelve todo el Stack (no solo el ícono) para poder
    // usar sus constraints al calcular el tamaño del ícono sin romper la
    // regla de que un Positioned debe ser hijo directo del Stack.
    return LayoutBuilder(
      builder: (context, constraints) {
        final tamanioIcono = constraints.maxWidth * 0.9;
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColoresApp.azulTurquiOscuro,
                    ColoresApp.azulTurqui,
                    ColoresApp.azulProfundo,
                  ],
                ),
              ),
            ),
            if (mostrarOrbes) ...[
              const Positioned(top: -80, right: -60, child: _Orbe(diametro: 220)),
              const Positioned(bottom: -100, left: -80, child: _Orbe(diametro: 260)),
              const Positioned(top: 140, left: -60, child: _Orbe(diametro: 140)),
            ],
            Positioned(
              bottom: -40,
              right: -40,
              child: Transform.rotate(
                angle: -0.35,
                child: Icon(
                  Icons.gavel,
                  size: tamanioIcono,
                  color: Colors.white.withValues(alpha: intensidadIcono),
                ),
              ),
            ),
            if (child != null) Positioned.fill(child: child!),
          ],
        );
      },
    );
  }
}

/// Círculo grande desenfocado usado como orbe decorativo de profundidad.
class _Orbe extends StatelessWidget {
  final double diametro;

  const _Orbe({required this.diametro});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            ColoresApp.azulBrillante.withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
