import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../controlador/controlador_como_funciona.dart';
import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import 'escenario_web.dart';
import 'estados_reproductor.dart';
import 'estilos_como_funciona.dart';
import 'pantalla_completa_video.dart';
import 'video_movil.dart';

/// Recuadro de un capítulo: portada, carga, video en reproducción o error.
///
/// Llena la caja que recibe; quien lo usa le da la proporción del video. Mira
/// al [ControladorComoFunciona] para saber en qué estado está SU capítulo:
/// aunque haya seis recuadros, solo uno puede tener un reproductor a la vez.
class ReproductorCapitulo extends StatefulWidget {
  final ModeloCapituloComoFunciona capitulo;
  final ControladorComoFunciona controlador;

  /// Foco del botón de reproducir. Es de la sección, que lo usa para llevar
  /// el teclado a este capítulo cuando se elige en el índice.
  final FocusNode focoReproducir;

  const ReproductorCapitulo({
    super.key,
    required this.capitulo,
    required this.controlador,
    required this.focoReproducir,
  });

  @override
  State<ReproductorCapitulo> createState() => _ReproductorCapituloState();
}

class _ReproductorCapituloState extends State<ReproductorCapitulo> {
  /// Foco del video en Web, para los atajos de teclado.
  final FocusNode _focoEscenario = FocusNode(debugLabel: 'Video en reproducción');
  bool _escenarioConFoco = false;

  @override
  void initState() {
    super.initState();
    _focoEscenario.addListener(_alCambiarFocoDelEscenario);
  }

  @override
  void dispose() {
    _focoEscenario.removeListener(_alCambiarFocoDelEscenario);
    _focoEscenario.dispose();
    super.dispose();
  }

  void _alCambiarFocoDelEscenario() {
    if (mounted && _escenarioConFoco != _focoEscenario.hasFocus) {
      setState(() => _escenarioConFoco = _focoEscenario.hasFocus);
    }
  }

  Future<void> _activar() async {
    final controlador = widget.controlador;
    // Quien activó la portada con el teclado sigue con el teclado: al pasar a
    // video, el foco se lleva al escenario para que los atajos funcionen.
    final llevarFocoAlVideo =
        controlador.controlesDelNavegador &&
        widget.focoReproducir.hasFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    await controlador.reproducir(widget.capitulo);
    if (mounted && llevarFocoAlVideo && controlador.estadoDe(widget.capitulo) == EstadoReproduccion.listo) {
      _focoEscenario.requestFocus();
    }
  }

  Future<void> _abrirPantallaCompleta(VideoPlayerController video) async {
    await PantallaCompletaVideo.abrir(
      context,
      controlador: widget.controlador,
      video: video,
      capitulo: widget.capitulo,
    );
    if (!mounted) return;
    // Al volver, la pantalla pudo girar y el diseño cambiar de tamaño: se
    // vuelve a poner el video a la vista una vez dibujado el nuevo diseño.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: EstilosComoFunciona.duracion(context, const Duration(milliseconds: 250)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controlador,
      builder: (context, _) {
        final controlador = widget.controlador;
        final capitulo = widget.capitulo;
        final estado = controlador.estadoDe(capitulo);
        final video = controlador.video;

        if (estado == EstadoReproduccion.listo && video != null) {
          if (controlador.controlesDelNavegador) {
            return EscenarioWeb(
              controlador: controlador,
              video: video,
              capitulo: capitulo,
              foco: _focoEscenario,
              enfocado: _escenarioConFoco,
            );
          }
          return VideoMovil(
            // Un reproductor nuevo (reintento, o vuelta a este capítulo)
            // reinicia el estado de la portada que cubre el primer fotograma.
            key: ValueKey(video),
            controlador: controlador,
            video: video,
            capitulo: capitulo,
            alAbrirPantallaCompleta: () => _abrirPantallaCompleta(video),
          );
        }
        if (estado == EstadoReproduccion.error) {
          return EstadoErrorVideo(capitulo: capitulo, alReintentar: () => controlador.reintentar(capitulo));
        }
        return PortadaInteractiva(
          capitulo: capitulo,
          cargando: estado == EstadoReproduccion.cargando,
          foco: widget.focoReproducir,
          alActivar: _activar,
        );
      },
    );
  }
}
