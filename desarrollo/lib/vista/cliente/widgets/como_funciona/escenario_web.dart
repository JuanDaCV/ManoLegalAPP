import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../../controlador/controlador_como_funciona.dart';
import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import '../../../tema/tema_app.dart';

/// Video en reproducción en Web: lo único que Flutter dibuja es el propio
/// video. Los controles son los del navegador (`<video controls>`).
///
/// NINGÚN widget de Flutter va encima del video. En Web el video es un
/// elemento HTML que recibe los clics directamente; un widget que lo tape
/// duplicaría el manejo (por ejemplo, un clic pausaría dos veces) y dejaría
/// los controles nativos fuera de alcance. La única excepción es el aro de
/// foco del teclado, que solo existe mientras el escenario tiene el foco y es
/// intocable (`IgnorePointer`).
///
/// Los atajos de teclado solo actúan con el escenario enfocado: Espacio o K
/// pausan y reanudan, las flechas saltan 5 segundos y M silencia. Mientras no
/// tiene el foco, Espacio desplaza la página como siempre.
class EscenarioWeb extends StatelessWidget {
  static const Duration _salto = Duration(seconds: 5);

  final ControladorComoFunciona controlador;
  final VideoPlayerController video;
  final ModeloCapituloComoFunciona capitulo;
  final FocusNode foco;

  /// El escenario tiene el foco, para dibujar el aro.
  final bool enfocado;

  const EscenarioWeb({
    super.key,
    required this.controlador,
    required this.video,
    required this.capitulo,
    required this.foco,
    required this.enfocado,
  });

  KeyEventResult _alTeclear(FocusNode nodo, KeyEvent evento) {
    if (evento is KeyUpEvent) return KeyEventResult.ignored;
    // Con Ctrl, Alt o Cmd las teclas son atajos del navegador (Alt+Izquierda
    // es "atrás"): no se tocan.
    final teclado = HardwareKeyboard.instance;
    if (teclado.isControlPressed || teclado.isAltPressed || teclado.isMetaPressed) return KeyEventResult.ignored;

    final tecla = evento.logicalKey;
    final esPulsacionNueva = evento is KeyDownEvent;
    if (esPulsacionNueva && (tecla == LogicalKeyboardKey.space || tecla == LogicalKeyboardKey.keyK)) {
      controlador.alternarReproduccion();
      return KeyEventResult.handled;
    }
    // Las flechas también se repiten al mantenerlas apretadas.
    if (tecla == LogicalKeyboardKey.arrowLeft) {
      controlador.saltar(-_salto);
      return KeyEventResult.handled;
    }
    if (tecla == LogicalKeyboardKey.arrowRight) {
      controlador.saltar(_salto);
      return KeyEventResult.handled;
    }
    if (esPulsacionNueva && tecla == LogicalKeyboardKey.keyM) {
      controlador.alternarSonido();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final valor = video.value;
    final proporcion = valor.isInitialized ? valor.aspectRatio : capitulo.proporcion;
    final conAro = enfocado && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

    return TapRegion(
      // Un clic fuera suelta el foco: así Espacio vuelve a desplazar la página.
      onTapOutside: (_) => foco.unfocus(),
      child: Semantics(
        container: true,
        label:
            'Video: ${capitulo.titulo}. Usa la barra de reproducción del video o el teclado: '
            'Espacio para pausar o reproducir, flechas para avanzar o retroceder, M para silenciar.',
        child: Focus(
          focusNode: foco,
          onKeyEvent: _alTeclear,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(aspectRatio: proporcion, child: VideoPlayer(video)),
                ),
              ),
              if (conAro)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.all(color: ColoresApp.blanco, width: 2)),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: DecoratedBox(
                        decoration: BoxDecoration(border: Border.all(color: ColoresApp.azulTurqui, width: 2)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
