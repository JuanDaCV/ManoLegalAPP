import 'package:flutter/material.dart';

import '../../../../controlador/controlador_como_funciona.dart';
import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import '../../../tema/tema_app.dart';
import 'estilos_como_funciona.dart';
import 'reproductor_capitulo.dart';

/// Escenario del video en pantalla ancha: el video dentro de un marco azul
/// turquí y, detrás, un contorno dorado desplazado que le da relieve.
///
/// El contorno se refleja de un capítulo al siguiente ([contornoALaDerecha]),
/// de modo que la lista alterna en vez de repetir el mismo gesto seis veces.
/// Mientras se ve la portada, el marco "se levanta" al pasar el cursor; con un
/// video en reproducción se queda quieto para no distraer.
///
/// La caja del video lleva la clave `marco_video_N`: es el recuadro con la
/// proporción exacta del video, y las pruebas lo miden.
class EscenarioVideo extends StatefulWidget {
  final ModeloCapituloComoFunciona capitulo;
  final ControladorComoFunciona controlador;
  final FocusNode focoReproducir;

  /// Ancho del video, sin contar el marco azul.
  final double anchoVideo;
  final bool contornoALaDerecha;

  const EscenarioVideo({
    super.key,
    required this.capitulo,
    required this.controlador,
    required this.focoReproducir,
    required this.anchoVideo,
    required this.contornoALaDerecha,
  });

  @override
  State<EscenarioVideo> createState() => _EscenarioVideoState();
}

class _EscenarioVideoState extends State<EscenarioVideo> {
  bool _cursorEncima = false;

  @override
  Widget build(BuildContext context) {
    final desplazamiento = widget.contornoALaDerecha ? const Offset(16, 16) : const Offset(-16, 16);
    return MouseRegion(
      onEnter: (_) => setState(() => _cursorEncima = true),
      onExit: (_) => setState(() => _cursorEncima = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: desplazamiento.dx,
            top: desplazamiento.dy,
            right: -desplazamiento.dx,
            bottom: -desplazamiento.dy,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: ColoresApp.dorado.withValues(alpha: 0.55), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: widget.controlador,
            builder: (context, _) {
              final conPortada = widget.controlador.estadoDe(widget.capitulo) == EstadoReproduccion.inactivo;
              return AnimatedContainer(
                duration: EstilosComoFunciona.duracion(context, const Duration(milliseconds: 200)),
                padding: const EdgeInsets.all(12),
                decoration: EstilosComoFunciona.marcoAzul(elevado: _cursorEncima && conPortada),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: widget.anchoVideo,
                    child: AspectRatio(
                      key: ValueKey('marco_video_${widget.capitulo.numero}'),
                      aspectRatio: widget.capitulo.proporcion,
                      child: ReproductorCapitulo(
                        capitulo: widget.capitulo,
                        controlador: widget.controlador,
                        focoReproducir: widget.focoReproducir,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
