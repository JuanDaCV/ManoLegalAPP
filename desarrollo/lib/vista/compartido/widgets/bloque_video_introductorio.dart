import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../tema/tema_app.dart';

/// Ruta estable del video introductorio. Para cambiar el video basta con
/// reemplazar el archivo conservando esta ruta y este nombre: nada en este
/// widget depende de su duración ni de su contenido.
const String rutaVideoIntroductorio = 'video/videoPromoV1.mp4';

enum _EstadoVideo { cargando, listo, error }

/// Video introductorio del Inicio post-login (cliente y abogado).
///
/// Se reproduce solo, sin sonido y en loop infinito mientras está en
/// pantalla. Arrancar en silencio es lo que permite el autoplay en Web: los
/// navegadores bloquean la reproducción automática con sonido. Un toque
/// alterna el sonido; nunca pausa. No muestra controles de reproductor.
///
/// Se pausa cuando no está a la vista: si la sección queda oculta en el
/// [IndexedStack] del panel ([Visibility.of]) o si otra ruta la tapa
/// ([TickerMode]). Sin esto seguiría sonando detrás de otra pestaña.
class BloqueVideoIntroductorio extends StatefulWidget {
  const BloqueVideoIntroductorio({super.key, this.crearControlador});

  /// Permite a las pruebas inyectar un controlador falso: el real necesita
  /// la plataforma de video, que no existe en `flutter test`.
  @visibleForTesting
  final VideoPlayerController Function()? crearControlador;

  @override
  State<BloqueVideoIntroductorio> createState() => _BloqueVideoIntroductorioState();
}

class _BloqueVideoIntroductorioState extends State<BloqueVideoIntroductorio> {
  late VideoPlayerController _controlador;
  _EstadoVideo _estado = _EstadoVideo.cargando;
  bool _silenciado = true;
  bool _enPantalla = false;

  @override
  void initState() {
    super.initState();
    _prepararVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enPantalla = Visibility.of(context) && TickerMode.valuesOf(context).enabled;
    _sincronizarReproduccion();
  }

  @override
  void dispose() {
    _controlador.removeListener(_vigilarErrores);
    _controlador.dispose();
    super.dispose();
  }

  VideoPlayerController _crearControladorPorDefecto() {
    return VideoPlayerController.asset(
      rutaVideoIntroductorio,
      videoPlayerOptions: VideoPlayerOptions(
        // Con sonido apagado no tiene sentido cortar la música de otra app
        // (Android e iOS). En Web se ignora.
        mixWithOthers: true,
        // En loop infinito, `true` impediría que la pantalla se apague
        // mientras el usuario esté en Inicio (iOS).
        preventsDisplaySleepDuringVideoPlayback: false,
        // Quita del clic derecho "Guardar video como", "Mostrar controles"
        // y transmitir. Los controles ya vienen desactivados.
        webOptions: const VideoPlayerWebOptions(allowContextMenu: false, allowRemotePlayback: false),
      ),
    );
  }

  Future<void> _prepararVideo() async {
    final controlador = (widget.crearControlador ?? _crearControladorPorDefecto)();
    _controlador = controlador;
    controlador.addListener(_vigilarErrores);
    try {
      await controlador.initialize();
      // El silencio va antes de cualquier play(): es lo que habilita el
      // autoplay en Web.
      await controlador.setVolume(0);
      await controlador.setLooping(true);
    } catch (_) {
      if (mounted && identical(controlador, _controlador)) setState(() => _estado = _EstadoVideo.error);
      return;
    }
    if (!mounted || !identical(controlador, _controlador)) return;
    setState(() {
      _estado = _EstadoVideo.listo;
      _silenciado = true;
    });
    _sincronizarReproduccion();
  }

  /// Un error de la plataforma (por ejemplo, el navegador rechaza el
  /// autoplay) deja al controlador inutilizable: sus play() posteriores no
  /// hacen nada. Por eso se pasa al estado de error, que ofrece reintentar.
  void _vigilarErrores() {
    if (_controlador.value.hasError && _estado != _EstadoVideo.error && mounted) {
      setState(() => _estado = _EstadoVideo.error);
    }
  }

  void _sincronizarReproduccion() {
    if (_estado != _EstadoVideo.listo) return;
    final reproduciendo = _controlador.value.isPlaying;
    if (_enPantalla && !reproduciendo) {
      _controlador.play();
    } else if (!_enPantalla && reproduciendo) {
      _controlador.pause();
    }
  }

  /// El toque controla solo el sonido: nunca pausa.
  void _alternarSonido() {
    final silenciar = !_silenciado;
    setState(() => _silenciado = silenciar);
    _controlador.setVolume(silenciar ? 0 : 1);
    if (_enPantalla && !_controlador.value.isPlaying) _controlador.play();
  }

  /// Crea un controlador nuevo dentro del gesto del usuario, que es lo que
  /// el navegador exige para reproducir si antes bloqueó el autoplay.
  void _reintentar() {
    final anterior = _controlador;
    anterior.removeListener(_vigilarErrores);
    setState(() => _estado = _EstadoVideo.cargando);
    _prepararVideo();
    anterior.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El marco conserva el lugar del antiguo placeholder: el layout no se
    // mueve al cargar el video ni si se reemplaza por uno de otra proporción.
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: switch (_estado) {
        _EstadoVideo.cargando => const _RecuadroVideo(),
        _EstadoVideo.error => _RecuadroVideo(alTocar: _reintentar),
        _EstadoVideo.listo => Center(
          // Proporción real del archivo: nunca se deforma ni se recorta.
          child: AspectRatio(
            aspectRatio: _controlador.value.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(child: VideoPlayer(_controlador)),
                  Positioned(right: 12, bottom: 12, child: _IndicadorSonido(silenciado: _silenciado)),
                  // La capa táctil va ENCIMA del video, no envolviéndolo: en
                  // Web el video es un elemento HTML (vista de plataforma) que
                  // se queda con los clics que lo alcanzan primero. Solo
                  // llegan a Flutter si un widget de Flutter lo tapa.
                  Positioned.fill(
                    child: Semantics(
                      button: true,
                      label: _silenciado
                          ? 'Video introductorio. Toca para activar el sonido.'
                          : 'Video introductorio. Toca para silenciarlo.',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _alternarSonido),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      },
    );
  }
}

/// Estado del sonido. No es un botón: todo el video responde al toque.
class _IndicadorSonido extends StatelessWidget {
  final bool silenciado;

  const _IndicadorSonido({required this.silenciado});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ColoresApp.azulTurquiOscuro.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          silenciado ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: ColoresApp.blanco,
          size: 20,
        ),
      ),
    );
  }
}

/// Recuadro con el estilo del antiguo placeholder: vacío mientras el video
/// carga y, si falla, con el aviso para reintentar.
class _RecuadroVideo extends StatelessWidget {
  final VoidCallback? alTocar;

  const _RecuadroVideo({this.alTocar});

  @override
  Widget build(BuildContext context) {
    final recuadro = DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresApp.grisClaro,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresApp.grisTexto.withValues(alpha: 0.25)),
      ),
      child: alTocar == null
          ? const SizedBox.expand()
          : const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off_rounded, color: ColoresApp.grisTexto, size: 36),
                    SizedBox(height: 12),
                    Text(
                      'No se pudo reproducir el video. Toca para reintentar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ColoresApp.grisTexto, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
    );
    if (alTocar == null) return recuadro;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: alTocar, child: recuadro),
    );
  }
}
