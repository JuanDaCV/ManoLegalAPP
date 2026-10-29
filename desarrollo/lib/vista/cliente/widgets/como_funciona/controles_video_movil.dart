import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../controlador/controlador_como_funciona.dart';
import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import '../../../tema/tema_app.dart';
import 'barra_progreso_video.dart';
import 'estilos_como_funciona.dart';

/// Controles propios del video en Android e iOS (en Web se usan los del
/// navegador). Se dibujan encima del video: un toque en el video los muestra
/// u oculta, y se esconden solos a los 3 segundos mientras suena.
///
/// Con un lector de pantalla activo ([MediaQuery.accessibleNavigationOf]) NO se
/// esconden nunca: quien navega con TalkBack o VoiceOver no ve el video y no
/// puede "tocar para volver a mostrarlos". Tampoco se esconden en pausa ni al
/// terminar el video.
class ControlesVideoMovil extends StatefulWidget {
  final ControladorComoFunciona controlador;
  final VideoPlayerController video;
  final ModeloCapituloComoFunciona capitulo;
  final bool enPantallaCompleta;

  /// Qué hacer al tocar el botón de pantalla completa. Sin esto, el botón no
  /// se muestra.
  final VoidCallback? alAlternarPantallaCompleta;

  const ControlesVideoMovil({
    super.key,
    required this.controlador,
    required this.video,
    required this.capitulo,
    this.enPantallaCompleta = false,
    this.alAlternarPantallaCompleta,
  });

  @override
  State<ControlesVideoMovil> createState() => _ControlesVideoMovilState();
}

class _ControlesVideoMovilState extends State<ControlesVideoMovil> {
  static const Duration _tiempoParaOcultar = Duration(seconds: 3);

  bool _visibles = true;
  bool _accesible = false;
  bool _arrastrando = false;
  double _previsualizacionMs = 0;
  bool _reproduciendoAntes = false;
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _reproduciendoAntes = widget.video.value.isPlaying;
    widget.video.addListener(_alCambiarValor);
    if (_reproduciendoAntes) _programarOcultar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _accesible = MediaQuery.accessibleNavigationOf(context);
    if (_accesible) {
      _temporizador?.cancel();
      _visibles = true;
    }
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    widget.video.removeListener(_alCambiarValor);
    super.dispose();
  }

  void _alCambiarValor() {
    final reproduciendo = widget.video.value.isPlaying;
    if (reproduciendo == _reproduciendoAntes) return;
    _reproduciendoAntes = reproduciendo;
    if (reproduciendo) {
      _programarOcultar();
    } else {
      _temporizador?.cancel();
      if (!_visibles && mounted) setState(() => _visibles = true);
    }
  }

  void _programarOcultar() {
    _temporizador?.cancel();
    if (_accesible) return;
    _temporizador = Timer(_tiempoParaOcultar, () {
      if (mounted && !_arrastrando && widget.video.value.isPlaying) setState(() => _visibles = false);
    });
  }

  /// Cada interacción reinicia la cuenta: los controles no se esconden en
  /// medio de un gesto.
  void _alInteractuar() {
    if (widget.video.value.isPlaying) _programarOcultar();
  }

  void _alTocarVideo(VideoPlayerValue valor) {
    if (_accesible || !valor.isPlaying || valor.isCompleted) return;
    setState(() => _visibles = !_visibles);
    if (_visibles) _programarOcultar();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.video,
      builder: (context, valor, _) {
        final mostrar = _visibles || _accesible || !valor.isPlaying || valor.isCompleted;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Mostrar u ocultar los controles es un atajo táctil: con un lector
          // de pantalla los controles ya están siempre a la vista.
          excludeFromSemantics: true,
          onTap: () => _alTocarVideo(valor),
          child: IgnorePointer(
            ignoring: !mostrar,
            child: AnimatedOpacity(
              opacity: mostrar ? 1 : 0,
              duration: EstilosComoFunciona.duracion(context, const Duration(milliseconds: 180)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: ColoresApp.azulTurquiOscuro.withValues(alpha: 0.28)),
                  Center(child: _construirBotonCentral(valor)),
                  Align(alignment: Alignment.bottomCenter, child: _construirBarraInferior(valor)),
                  if (widget.enPantallaCompleta) Positioned(top: 8, left: 8, child: _construirBotonSalir()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _construirBotonCentral(VideoPlayerValue valor) {
    final terminado = valor.isCompleted;
    return IconButton(
      key: const ValueKey('boton_central'),
      tooltip: terminado ? 'Ver de nuevo' : (valor.isPlaying ? 'Pausar' : 'Reproducir'),
      iconSize: 36,
      onPressed: () {
        widget.controlador.alternarReproduccion();
        _alInteractuar();
      },
      style: IconButton.styleFrom(
        fixedSize: const Size(64, 64),
        padding: EdgeInsets.zero,
        backgroundColor: ColoresApp.azulTurqui.withValues(alpha: 0.88),
        foregroundColor: ColoresApp.blanco,
        shape: const CircleBorder(),
        side: const BorderSide(color: ColoresApp.dorado, width: 2),
      ),
      icon: Icon(terminado ? Icons.replay_rounded : (valor.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)),
    );
  }

  Widget _construirBotonSalir() {
    return IconButton(
      key: const ValueKey('boton_salir'),
      tooltip: 'Salir de pantalla completa',
      onPressed: widget.alAlternarPantallaCompleta,
      style: IconButton.styleFrom(
        backgroundColor: ColoresApp.azulTurquiOscuro.withValues(alpha: 0.6),
        foregroundColor: ColoresApp.blanco,
      ),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }

  Widget _construirBarraInferior(VideoPlayerValue valor) {
    final total = valor.duration;
    final totalMs = math.max(1, total.inMilliseconds).toDouble();
    final posicionMs = math.min(
      math.max(_arrastrando ? _previsualizacionMs : valor.position.inMilliseconds.toDouble(), 0.0),
      totalMs,
    );
    final transcurrido = Duration(milliseconds: posicionMs.round());
    final silenciado = valor.volume == 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColoresApp.azulTurquiOscuro.withValues(alpha: 0),
            ColoresApp.azulTurquiOscuro.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final ancho = restricciones.maxWidth;
            // El tiempo es información de apoyo: en recuadros angostos cede su
            // lugar a la barra, que es lo que se usa para avanzar.
            final textoTiempo = ancho >= 420
                ? '${formatearTiempoVideo(transcurrido)} / ${formatearTiempoVideo(total)}'
                : formatearTiempoVideo(transcurrido);
            return Row(
              children: [
                IconButton(
                  key: const ValueKey('boton_play_pausa'),
                  tooltip: valor.isCompleted ? 'Ver de nuevo' : (valor.isPlaying ? 'Pausar' : 'Reproducir'),
                  color: ColoresApp.blanco,
                  onPressed: () {
                    widget.controlador.alternarReproduccion();
                    _alInteractuar();
                  },
                  icon: Icon(
                    valor.isCompleted
                        ? Icons.replay_rounded
                        : (valor.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                ),
                if (ancho >= 260)
                  ExcludeSemantics(
                    child: Text(
                      textoTiempo,
                      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
                      style: const TextStyle(
                        color: ColoresApp.blanco,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        fontFeatures: EstilosComoFunciona.cifrasTabulares,
                      ),
                    ),
                  ),
                Expanded(child: _construirBarraProgreso(posicionMs, totalMs)),
                IconButton(
                  key: const ValueKey('boton_sonido'),
                  tooltip: silenciado ? 'Activar sonido' : 'Silenciar',
                  color: ColoresApp.blanco,
                  onPressed: () {
                    widget.controlador.alternarSonido();
                    _alInteractuar();
                  },
                  icon: Icon(silenciado ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                ),
                if (widget.alAlternarPantallaCompleta != null)
                  IconButton(
                    key: const ValueKey('boton_pantalla_completa'),
                    tooltip: widget.enPantallaCompleta ? 'Salir de pantalla completa' : 'Pantalla completa',
                    color: ColoresApp.blanco,
                    onPressed: widget.alAlternarPantallaCompleta,
                    icon: Icon(widget.enPantallaCompleta ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Mientras se arrastra solo cambia la vista previa: buscar en cada
  /// movimiento haría saltar el video a cada fotograma intermedio. La
  /// búsqueda real ocurre una vez, al soltar.
  Widget _construirBarraProgreso(double posicionMs, double totalMs) {
    return BarraProgresoVideo(
      posicionMs: posicionMs,
      totalMs: totalMs,
      alEmpezar: (valor) {
        _temporizador?.cancel();
        setState(() {
          _arrastrando = true;
          _previsualizacionMs = valor;
        });
      },
      alCambiar: (valor) => setState(() => _previsualizacionMs = valor),
      alSoltar: (valor) {
        setState(() => _arrastrando = false);
        widget.controlador.buscar(Duration(milliseconds: valor.round()));
        _alInteractuar();
      },
    );
  }
}
