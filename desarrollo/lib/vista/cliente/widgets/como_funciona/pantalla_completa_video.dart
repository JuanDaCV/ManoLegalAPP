import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../../controlador/controlador_como_funciona.dart';
import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import 'controles_video_movil.dart';

/// Video a pantalla completa en Android e iOS.
///
/// Reutiliza el MISMO reproductor que está en la sección: no crea otro, así
/// que el video sigue en el segundo en que iba y el límite de un solo
/// reproductor vivo se mantiene. Solo se dibuja otra vez sobre una ruta negra
/// que tapa todo, sin barras del sistema y girando la pantalla según el
/// formato del video.
class PantallaCompletaVideo extends StatelessWidget {
  final ControladorComoFunciona controlador;
  final VideoPlayerController video;
  final ModeloCapituloComoFunciona capitulo;

  const PantallaCompletaVideo({super.key, required this.controlador, required this.video, required this.capitulo});

  /// Abre la pantalla completa y espera a que el usuario salga.
  ///
  /// El `finally` restaura las barras y la orientación aunque la ruta se
  /// cierre de forma inesperada (por ejemplo, si la sección desaparece con el
  /// video abierto): dejar el teléfono sin barras y bloqueado en horizontal
  /// sería mucho peor que cualquier otro fallo de este módulo. No toca la
  /// bandera de pantalla encendida: es la misma ventana y ya está activa.
  static Future<void> abrir(
    BuildContext context, {
    required ControladorComoFunciona controlador,
    required VideoPlayerController video,
    required ModeloCapituloComoFunciona capitulo,
  }) async {
    // Se leen antes de cualquier espera: después, el contexto puede ya no
    // existir.
    final navegador = Navigator.of(context, rootNavigator: true);
    final duracion = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200);
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(
        capitulo.esVertical
            ? const [DeviceOrientation.portraitUp]
            : const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
      );
      await navegador.push(
        PageRouteBuilder<void>(
          opaque: true,
          transitionDuration: duracion,
          reverseTransitionDuration: duracion,
          pageBuilder: (context, animacion, animacionSecundaria) =>
              PantallaCompletaVideo(controlador: controlador, video: video, capitulo: capitulo),
          transitionsBuilder: (context, animacion, animacionSecundaria, hijo) =>
              FadeTransition(opacity: animacion, child: hijo),
        ),
      );
    } finally {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      await SystemChrome.setPreferredOrientations(const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: video.value.isInitialized ? video.value.aspectRatio : capitulo.proporcion,
                child: VideoPlayer(video),
              ),
            ),
            ControlesVideoMovil(
              controlador: controlador,
              video: video,
              capitulo: capitulo,
              enPantallaCompleta: true,
              alAlternarPantallaCompleta: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
