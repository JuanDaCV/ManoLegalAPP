import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import '../../../tema/tema_app.dart';

/// Portada de un capítulo: el primer fotograma del video, en una imagen.
///
/// Mientras el usuario no pide reproducir, el capítulo es solo esta imagen: no
/// hay reproductor, decodificador ni descarga del video. Por eso la portada se
/// decodifica a un tamaño acorde con el recuadro (no a 1920 px completos) y
/// sin deformarse: el recuadro ya tiene la proporción del video.
class PortadaCapitulo extends StatelessWidget {
  final ModeloCapituloComoFunciona capitulo;

  /// Oscurece la portada, para ponerle un mensaje encima (error de carga).
  final bool oscurecida;

  const PortadaCapitulo({super.key, required this.capitulo, this.oscurecida = false});

  static const List<int> _anchosDeDecodificacion = [360, 540, 720, 960, 1280, 1920];

  /// Ancho, en píxeles, al que se decodifica la portada: el escalón más
  /// pequeño que cubre el recuadro en píxeles físicos, sin pasar del ancho
  /// original. Escalonar evita decodificar de nuevo la imagen por cada pixel
  /// que cambia el tamaño de la ventana.
  @visibleForTesting
  static int anchoDeDecodificacion({
    required double anchoLogico,
    required double pixelRatio,
    required int anchoOriginal,
  }) {
    final necesario = anchoLogico * pixelRatio;
    final escalon = _anchosDeDecodificacion.firstWhere(
      (ancho) => ancho >= necesario,
      orElse: () => _anchosDeDecodificacion.last,
    );
    return math.min(escalon, anchoOriginal);
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        // El azul oscuro se ve mientras la imagen se decodifica y si no se
        // pudiera cargar, en vez de un hueco blanco.
        const ColoredBox(color: ColoresApp.azulTurquiOscuro),
        LayoutBuilder(
          builder: (context, restricciones) => Image.asset(
            capitulo.rutaPortada,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            cacheWidth: anchoDeDecodificacion(
              anchoLogico: restricciones.maxWidth,
              pixelRatio: pixelRatio,
              anchoOriginal: capitulo.anchoPx,
            ),
            errorBuilder: (context, error, pila) => const ColoredBox(color: ColoresApp.azulTurquiOscuro),
          ),
        ),
        // Degradado solo en el 35% inferior: da contraste a la etiqueta de
        // duración sin tapar la imagen.
        IgnorePointer(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.35,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColoresApp.azulTurquiOscuro.withValues(alpha: 0),
                      ColoresApp.azulTurquiOscuro.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (oscurecida) ColoredBox(color: ColoresApp.azulTurquiOscuro.withValues(alpha: 0.6)),
      ],
    );
  }
}
