import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';
import 'estilos_landing.dart';

/// Fondo azul marino de la landing: degradado diagonal, trama de rayas finas,
/// halo azul y dos aros dorados tipo sello. Se coloca con `Positioned.fill`.
class FondoLanding extends StatelessWidget {
  const FondoLanding({
    super.key,
    this.centroHalo = const Alignment(0.55, -0.1),
    this.curvaInferior = 0,
  });

  /// Posición del halo y de los aros dentro del fondo.
  final Alignment centroHalo;

  /// Profundidad en px de la curva del borde inferior (0 = recto).
  final double curvaInferior;

  @override
  Widget build(BuildContext context) {
    Widget fondo = RepaintBoundary(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _PintorFondo(centroHalo),
          size: Size.infinite,
        ),
      ),
    );
    if (curvaInferior > 0) {
      fondo = ClipPath(clipper: _CurvaInferior(curvaInferior), child: fondo);
    }
    return fondo;
  }
}

class _CurvaInferior extends CustomClipper<Path> {
  const _CurvaInferior(this.curva);

  final double curva;

  @override
  Path getClip(Size size) {
    final c = math.min(curva, size.height / 2);
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - c)
      ..quadraticBezierTo(size.width / 2, size.height + c, 0, size.height - c)
      ..close();
  }

  @override
  bool shouldReclip(_CurvaInferior anterior) => anterior.curva != curva;
}

class _PintorFondo extends CustomPainter {
  const _PintorFondo(this.centroHalo);

  final Alignment centroHalo;

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.drawRect(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EstilosLanding.noche,
            ColoresApp.azulTurqui,
            ColoresApp.azulProfundo,
          ],
          stops: [0, 0.55, 1],
        ).createShader(area),
    );

    final lineas = Paint()
      ..color = const Color(0x06FFFFFF)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 14) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        lineas,
      );
    }

    final centro = centroHalo.alongSize(size);
    final lado = math.max(size.width, size.height);
    final radioHalo = lado * 0.5;
    canvas.drawCircle(
      centro,
      radioHalo,
      Paint()
        ..shader = RadialGradient(
          colors: [
            ColoresApp.azulBrillante.withValues(alpha: 0.28),
            ColoresApp.azulBrillante.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: radioHalo)),
    );

    final base = math.min(size.width, size.height);
    final aro = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(
      centro,
      base * 0.42,
      aro..color = ColoresApp.dorado.withValues(alpha: 0.20),
    );
    canvas.drawCircle(
      centro,
      base * 0.58,
      aro..color = ColoresApp.dorado.withValues(alpha: 0.09),
    );
  }

  @override
  bool shouldRepaint(_PintorFondo anterior) =>
      anterior.centroHalo != centroHalo;
}
