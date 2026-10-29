import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../controlador/controlador_como_funciona.dart';
import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import 'controles_video_movil.dart';
import 'estilos_como_funciona.dart';
import 'portada_capitulo.dart';

/// Video en reproducción en Android e iOS: el video, la portada que lo cubre
/// un instante y los controles propios.
///
/// Al arrancar, el reproductor nativo muestra uno o dos fotogramas en negro
/// antes de dibujar la imagen. Para que no se vea ese parpadeo, la portada
/// (que es justo el primer fotograma del video) se queda encima hasta que la
/// posición avanza por primera vez, y entonces se desvanece.
class VideoMovil extends StatefulWidget {
  final ControladorComoFunciona controlador;
  final VideoPlayerController video;
  final ModeloCapituloComoFunciona capitulo;
  final VoidCallback alAbrirPantallaCompleta;

  const VideoMovil({
    super.key,
    required this.controlador,
    required this.video,
    required this.capitulo,
    required this.alAbrirPantallaCompleta,
  });

  @override
  State<VideoMovil> createState() => _VideoMovilState();
}

class _VideoMovilState extends State<VideoMovil> {
  late bool _cubierto = widget.video.value.position == Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.video.addListener(_vigilarPosicion);
  }

  @override
  void didUpdateWidget(VideoMovil anterior) {
    super.didUpdateWidget(anterior);
    if (!identical(anterior.video, widget.video)) {
      anterior.video.removeListener(_vigilarPosicion);
      widget.video.addListener(_vigilarPosicion);
      _cubierto = widget.video.value.position == Duration.zero;
    }
  }

  @override
  void dispose() {
    widget.video.removeListener(_vigilarPosicion);
    super.dispose();
  }

  /// Una vez descubierto, el video no vuelve a cubrirse: si el usuario
  /// regresa al segundo cero, el fotograma que se ve ya es el del video.
  void _vigilarPosicion() {
    if (_cubierto && widget.video.value.position > Duration.zero) setState(() => _cubierto = false);
  }

  @override
  Widget build(BuildContext context) {
    final valor = widget.video.value;
    final proporcion = valor.isInitialized ? valor.aspectRatio : widget.capitulo.proporcion;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        Center(
          child: AspectRatio(
            aspectRatio: proporcion,
            child: Semantics(label: 'Video: ${widget.capitulo.titulo}', child: VideoPlayer(widget.video)),
          ),
        ),
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _cubierto ? 1 : 0,
            duration: EstilosComoFunciona.duracion(context, const Duration(milliseconds: 200)),
            child: PortadaCapitulo(capitulo: widget.capitulo),
          ),
        ),
        ControlesVideoMovil(
          controlador: widget.controlador,
          video: widget.video,
          capitulo: widget.capitulo,
          alAlternarPantallaCompleta: widget.alAbrirPantallaCompleta,
        ),
      ],
    );
  }
}
