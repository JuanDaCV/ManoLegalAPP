import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../controlador/filtros_administrador.dart';
import '../../tema/tema_app.dart';

/// Gráfico de dona con la proporción de abogados verificados y pendientes.
///
/// Se dibuja con un [CustomPainter] en lugar de una librería de gráficos:
/// dos segmentos no justifican una dependencia nueva, y así los colores son
/// exactamente los de ManoLegal. La dona se anima al aparecer y cada vez que
/// los datos cambian en Firestore.
class GraficoDonaVerificacion extends StatelessWidget {
  final ResumenVerificacion resumen;
  final double diametro;

  /// Coloca la leyenda debajo en lugar de al lado. Lo decide quien contiene
  /// el gráfico según su ancho disponible.
  final bool leyendaAbajo;

  const GraficoDonaVerificacion({
    super.key,
    required this.resumen,
    this.diametro = 188,
    this.leyendaAbajo = false,
  });

  @override
  Widget build(BuildContext context) {
    final (porcentajeVerificados, porcentajePendientes) = resumen.porcentajes;
    final vacio = resumen.total == 0;

    final dona = Semantics(
      label: vacio
          ? 'Sin abogados registrados'
          : '${resumen.verificados} verificados y ${resumen.pendientes} no verificados, '
              'de ${resumen.total} abogados',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: diametro,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: resumen.proporcionVerificados),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, proporcion, centro) => CustomPaint(
            painter: _PintorDona(proporcionVerificados: proporcion, vacio: vacio),
            child: centro,
          ),
          child: Center(
            child: vacio
                ? const Text(
                    'Sin abogados\nregistrados',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColoresApp.grisTexto, fontSize: 12.5, fontWeight: FontWeight.w600),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$porcentajeVerificados%',
                        style: const TextStyle(
                          color: ColoresApp.azulTurquiOscuro,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const Text('verificados', style: TextStyle(color: ColoresApp.grisTexto, fontSize: 12)),
                    ],
                  ),
          ),
        ),
      ),
    );

    final leyenda = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilaLeyenda(
          color: ColoresApp.verdeVerificado,
          etiqueta: 'Verificados',
          cantidad: resumen.verificados,
          porcentaje: porcentajeVerificados,
        ),
        const SizedBox(height: 12),
        _FilaLeyenda(
          color: ColoresApp.dorado,
          etiqueta: 'No verificados',
          cantidad: resumen.pendientes,
          porcentaje: porcentajePendientes,
        ),
        const Divider(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Total de abogados',
                style: TextStyle(color: ColoresApp.grisTexto, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${resumen.total}',
              style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );

    if (leyendaAbajo) {
      return Column(mainAxisSize: MainAxisSize.min, children: [dona, const SizedBox(height: 22), leyenda]);
    }
    return Row(children: [dona, const SizedBox(width: 28), Expanded(child: leyenda)]);
  }
}

class _FilaLeyenda extends StatelessWidget {
  final Color color;
  final String etiqueta;
  final int cantidad;
  final int porcentaje;

  const _FilaLeyenda({required this.color, required this.etiqueta, required this.cantidad, required this.porcentaje});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            etiqueta,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '$cantidad',
          style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 15, fontWeight: FontWeight.w800),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$porcentaje%',
            textAlign: TextAlign.right,
            style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class _PintorDona extends CustomPainter {
  final double proporcionVerificados;
  final bool vacio;

  _PintorDona({required this.proporcionVerificados, required this.vacio});

  /// Separación entre segmentos, en radianes.
  static const double _hueco = 0.045;

  @override
  void paint(Canvas canvas, Size size) {
    final grosor = size.width * 0.13;
    final area = Rect.fromLTWH(grosor / 2, grosor / 2, size.width - grosor, size.height - grosor);
    const inicio = -math.pi / 2;
    const vuelta = math.pi * 2;

    Paint pincel(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.butt
      ..color = color;

    canvas.drawArc(area, 0, vuelta, false, pincel(const Color(0x146B7280)));
    if (vacio) return;

    final proporcion = proporcionVerificados.clamp(0.0, 1.0);
    final verificados = pincel(ColoresApp.verdeVerificado);
    final pendientes = pincel(ColoresApp.dorado);

    // Una sola categoría ocupa el anillo completo, sin hueco.
    if (proporcion >= 1) {
      canvas.drawArc(area, inicio, vuelta, false, verificados);
      return;
    }
    if (proporcion <= 0) {
      canvas.drawArc(area, inicio, vuelta, false, pendientes);
      return;
    }

    final barridoVerificados = vuelta * proporcion;
    final barridoPendientes = vuelta - barridoVerificados;
    canvas.drawArc(area, inicio + _hueco / 2, math.max(barridoVerificados - _hueco, 0.001), false, verificados);
    canvas.drawArc(
      area,
      inicio + barridoVerificados + _hueco / 2,
      math.max(barridoPendientes - _hueco, 0.001),
      false,
      pendientes,
    );
  }

  @override
  bool shouldRepaint(_PintorDona anterior) =>
      anterior.proporcionVerificados != proporcionVerificados || anterior.vacio != vacio;
}
