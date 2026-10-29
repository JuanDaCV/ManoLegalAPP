import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';

/// Tiempo del video como "m:ss": 0:12, 1:03.
String formatearTiempoVideo(Duration duracion) {
  return '${duracion.inMinutes}:${(duracion.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// Barra de progreso del video, para los controles propios de Android e iOS.
///
/// Es un `Slider` y no un `VideoProgressIndicator`: este último mide pocos
/// píxeles de alto (difícil de tocar) y no tiene semántica, así que un lector
/// de pantalla no podría usarlo. Aquí tiene etiqueta ("Progreso del video"),
/// valor leído en voz alta ("0:12 de 0:48") y acciones de subir y bajar.
///
/// Es solo presentación: quien la usa decide qué hacer al arrastrar (los
/// controles muestran una vista previa y buscan solo al soltar).
class BarraProgresoVideo extends StatelessWidget {
  /// Posición y duración, en milisegundos. La posición ya viene acotada.
  final double posicionMs;
  final double totalMs;
  final ValueChanged<double> alEmpezar;
  final ValueChanged<double> alCambiar;
  final ValueChanged<double> alSoltar;

  const BarraProgresoVideo({
    super.key,
    required this.posicionMs,
    required this.totalMs,
    required this.alEmpezar,
    required this.alCambiar,
    required this.alSoltar,
  });

  @override
  Widget build(BuildContext context) {
    final total = Duration(milliseconds: totalMs.round());
    // Alto fijo de 48: sin él, el `Slider` ocupa todo el alto que le ofrece la
    // fila (que es el del video) y su zona táctil taparía el botón central y
    // el resto del video.
    return SizedBox(
      height: 48,
      child: MergeSemantics(
        child: Semantics(
          label: 'Progreso del video',
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: ColoresApp.blanco,
              inactiveTrackColor: ColoresApp.blanco.withValues(alpha: 0.3),
              thumbColor: ColoresApp.dorado,
              overlayColor: ColoresApp.blanco.withValues(alpha: 0.16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: posicionMs,
              max: totalMs,
              onChangeStart: alEmpezar,
              onChanged: alCambiar,
              onChangeEnd: alSoltar,
              semanticFormatterCallback: (valor) =>
                  '${formatearTiempoVideo(Duration(milliseconds: valor.round()))} de ${formatearTiempoVideo(total)}',
            ),
          ),
        ),
      ),
    );
  }
}
