import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';

enum EstadoMascotaLexus { reposo, pensando, atento }

/// Rostro de Lexus: un círculo azul turquí con aro dorado, cejas, ojos y
/// sonrisa serenos, bandas de toga y un pequeño mazo dorado. Está dibujado con código, sin imágenes,
/// y se mantiene legible entre 24 y 160 px de lado.
class MascotaLexus extends StatelessWidget {
  const MascotaLexus({
    super.key,
    this.tamanio = 48,
    this.estado = EstadoMascotaLexus.reposo,
    this.etiquetaSemantica,
  });

  final double tamanio;
  final EstadoMascotaLexus estado;

  /// Si se indica, la mascota se anuncia con esta etiqueta; si no, es
  /// puramente decorativa y los lectores de pantalla la ignoran.
  final String? etiquetaSemantica;

  @override
  Widget build(BuildContext context) {
    final dibujo = SizedBox(
      width: tamanio,
      height: tamanio,
      child: CustomPaint(painter: _PintorMascota(estado)),
    );
    final etiqueta = etiquetaSemantica;
    if (etiqueta == null) return ExcludeSemantics(child: dibujo);
    return Semantics(
      label: etiqueta,
      image: true,
      child: ExcludeSemantics(child: dibujo),
    );
  }
}

class _PintorMascota extends CustomPainter {
  const _PintorMascota(this.estado);

  final EstadoMascotaLexus estado;

  @override
  void paint(Canvas canvas, Size size) {
    final lado = size.shortestSide;
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = lado / 2;
    final circulo = Rect.fromCircle(center: centro, radius: radio);

    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: [ColoresApp.azulProfundo, ColoresApp.azulTurqui],
        ).createShader(circulo),
    );

    // Los detalles finos solo se dibujan cuando hay espacio para leerlos.
    final detallado = lado >= 32;
    if (detallado) {
      canvas.save();
      canvas.clipPath(Path()..addOval(circulo));
      _dibujarToga(canvas, centro, lado);
      canvas.restore();
    }

    final grosorAro = math.max(1.0, lado * 0.035);
    canvas.drawCircle(
      centro,
      radio - grosorAro / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosorAro
        ..color = ColoresApp.dorado,
    );

    // En tamaños chicos la cara baja al centro, porque no hay toga debajo.
    final cara = detallado ? centro.translate(0, -lado * 0.07) : centro;
    if (detallado) _dibujarCejas(canvas, cara, lado);
    _dibujarOjos(canvas, cara, lado);
    _dibujarSonrisa(canvas, cara, lado);
    if (detallado) _dibujarMazo(canvas, centro, lado);
  }

  /// Hombros con toga, cuello blanco y bandas: el rasgo que asocia a Lexus
  /// con el ámbito jurídico sin recurrir a la balanza de siempre.
  void _dibujarToga(Canvas canvas, Offset centro, double lado) {
    final cx = centro.dx;
    final cy = centro.dy;
    final hombros = cy + lado * 0.27;
    canvas.drawPath(
      Path()
        ..moveTo(cx - lado * 0.5, cy + lado * 0.44)
        ..quadraticBezierTo(cx - lado * 0.3, hombros, cx, hombros)
        ..quadraticBezierTo(
          cx + lado * 0.3,
          hombros,
          cx + lado * 0.5,
          cy + lado * 0.44,
        )
        ..lineTo(cx + lado * 0.5, cy + lado * 0.5)
        ..lineTo(cx - lado * 0.5, cy + lado * 0.5)
        ..close(),
      Paint()..color = ColoresApp.azulTurquiOscuro,
    );

    final blanco = Paint()..color = ColoresApp.blanco.withValues(alpha: 0.95);
    // Cuello en V.
    canvas.drawPath(
      Path()
        ..moveTo(cx - lado * 0.13, hombros + lado * 0.005)
        ..lineTo(cx, hombros + lado * 0.085)
        ..lineTo(cx + lado * 0.13, hombros + lado * 0.005)
        ..lineTo(cx + lado * 0.1, hombros - lado * 0.012)
        ..lineTo(cx, hombros + lado * 0.045)
        ..lineTo(cx - lado * 0.1, hombros - lado * 0.012)
        ..close(),
      blanco,
    );
    // Bandas.
    for (final signo in [-1.0, 1.0]) {
      final x = cx + signo * lado * 0.024;
      final arriba = hombros + lado * 0.07;
      canvas.drawPath(
        Path()
          ..moveTo(x - lado * 0.018, arriba)
          ..lineTo(x + lado * 0.018, arriba)
          ..lineTo(x + lado * 0.024, arriba + lado * 0.12)
          ..lineTo(x - lado * 0.024, arriba + lado * 0.12)
          ..close(),
        blanco,
      );
    }
  }

  void _dibujarCejas(Canvas canvas, Offset cara, double lado) {
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, lado * 0.026)
      ..color = ColoresApp.blanco.withValues(alpha: 0.85);
    for (final signo in [-1.0, 1.0]) {
      // Pensando: la ceja derecha se levanta un poco.
      final alza = estado == EstadoMascotaLexus.pensando && signo > 0
          ? lado * 0.035
          : 0.0;
      final x = cara.dx + signo * lado * 0.16;
      final y = cara.dy - lado * 0.17 - alza;
      canvas.drawPath(
        Path()
          ..moveTo(x - lado * 0.07, y + lado * 0.012)
          ..quadraticBezierTo(x, y - lado * 0.028, x + lado * 0.07, y),
        trazo,
      );
    }
  }

  void _dibujarOjos(Canvas canvas, Offset cara, double lado) {
    final factor = estado == EstadoMascotaLexus.atento ? 1.1 : 1.0;
    final ancho = lado * 0.115 * factor;
    final alto = lado * 0.13 * factor;
    final blanco = Paint()..color = ColoresApp.blanco;
    final pupila = Paint()..color = ColoresApp.azulTurquiOscuro;
    final desplazamiento = estado == EstadoMascotaLexus.pensando
        ? Offset(lado * 0.02, -lado * 0.025)
        : Offset(0, lado * 0.008);

    for (final signo in [-1.0, 1.0]) {
      final ojo = Offset(cara.dx + signo * lado * 0.16, cara.dy - lado * 0.06);
      canvas.drawOval(
        Rect.fromCenter(center: ojo, width: ancho, height: alto),
        blanco,
      );
      canvas.drawCircle(ojo + desplazamiento, lado * 0.034 * factor, pupila);
    }
  }

  void _dibujarSonrisa(Canvas canvas, Offset cara, double lado) {
    final trazo = Path()
      ..moveTo(cara.dx - lado * 0.085, cara.dy + lado * 0.09)
      ..quadraticBezierTo(
        cara.dx,
        cara.dy + lado * 0.145,
        cara.dx + lado * 0.085,
        cara.dy + lado * 0.09,
      );
    canvas.drawPath(
      trazo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.0, lado * 0.026)
        ..color = ColoresApp.blanco.withValues(alpha: 0.9),
    );
  }

  /// Mazo pequeño apoyado en el borde inferior derecho del círculo.
  void _dibujarMazo(Canvas canvas, Offset centro, double lado) {
    final base = Offset(centro.dx + lado * 0.36, centro.dy + lado * 0.33);
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(-0.7);

    final mango = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: lado * 0.045,
        height: lado * 0.26,
      ),
      Radius.circular(lado * 0.02),
    );
    final cabeza = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -lado * 0.11),
        width: lado * 0.2,
        height: lado * 0.1,
      ),
      Radius.circular(lado * 0.025),
    );
    final relleno = Paint()..color = ColoresApp.dorado;
    final contorno = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, lado * 0.015)
      ..color = ColoresApp.azulTurquiOscuro;

    canvas.drawRRect(mango, relleno);
    canvas.drawRRect(mango, contorno);
    canvas.drawRRect(cabeza, relleno);
    canvas.drawRRect(cabeza, contorno);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorMascota anterior) => anterior.estado != estado;
}
