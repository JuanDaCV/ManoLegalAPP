import 'package:flutter/widgets.dart';

import '../../../tema/tema_app.dart';

/// Pinta el velo oscuro del recorrido con un hueco que deja ver, nítido, el
/// elemento que se está explicando.
///
/// Si [hueco] es `null` (bienvenida, cierre, o un elemento que no se ve) el
/// velo cubre toda la pantalla.
class PintorFocoRecorrido extends CustomPainter {
  const PintorFocoRecorrido({
    required this.hueco,
    this.apertura = 1,
    this.colorVelo,
    this.colorBorde,
  });

  /// Elemento resaltado, en las coordenadas de la capa. Se pinta [holgura]
  /// más grande para que el borde del elemento no quede pegado al recorte.
  final Rect? hueco;

  /// Cuánto se ve el hueco: de 0 (cubierto por el velo) a 1 (abierto). Permite
  /// abrirlo con un fundido en lugar de que aparezca de golpe.
  final double apertura;

  /// Por defecto, `azulTurquiOscuro` al 78 %: oscurece sin volverse negro.
  final Color? colorVelo;

  /// Por defecto, el dorado de la marca: solo como filete decorativo.
  final Color? colorBorde;

  /// Cuánto crece el hueco respecto al elemento, en píxeles.
  static const double holgura = 8;

  static const double _radio = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    final colorDelVelo =
        colorVelo ?? ColoresApp.azulTurquiOscuro.withValues(alpha: 0.78);
    final velo = Paint()..color = colorDelVelo;

    final hueco = this.hueco;
    if (hueco == null) {
      canvas.drawRect(area, velo);
      return;
    }

    final recorte = RRect.fromRectAndRadius(
      hueco.inflate(holgura),
      const Radius.circular(_radio),
    );
    // `evenOdd` deja sin pintar la parte del rectángulo que cubre el recorte.
    final camino = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(area)
      ..addRRect(recorte);
    canvas.drawPath(camino, velo);

    // Mientras se abre, el hueco conserva parte del velo.
    final abierto = apertura.clamp(0.0, 1.0);
    if (abierto < 1) {
      canvas.drawRRect(
        recorte,
        Paint()
          ..color = colorDelVelo.withValues(
            alpha: colorDelVelo.a * (1 - abierto),
          ),
      );
    }

    // Halo suave por fuera del recorte, para separarlo del velo.
    canvas.drawRRect(
      recorte.inflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = ColoresApp.blanco.withValues(alpha: 0.10 * abierto),
    );
    final borde = colorBorde ?? ColoresApp.dorado.withValues(alpha: 0.95);
    canvas.drawRRect(
      recorte,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = borde.withValues(alpha: borde.a * abierto),
    );
  }

  @override
  bool shouldRepaint(PintorFocoRecorrido oldDelegate) {
    return oldDelegate.hueco != hueco ||
        oldDelegate.apertura != apertura ||
        oldDelegate.colorVelo != colorVelo ||
        oldDelegate.colorBorde != colorBorde;
  }
}
