import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

import '../modelo/modelo_capitulo_como_funciona.dart';
import 'servicio_pantalla.dart';

/// Estado del reproductor de un capítulo, tal como lo ve la interfaz.
enum EstadoReproduccion {
  /// El capítulo no se reproduce: se ve su portada.
  inactivo,

  /// El usuario pidió reproducirlo y el video se está cargando.
  cargando,

  /// El video está cargado, reproduciéndose o en pausa.
  listo,

  /// No se pudo cargar ni reproducir el video.
  error,
}

/// Coordina la reproducción de los seis videos de "Cómo funciona".
///
/// Los videos pesan decenas de megabytes y cada reproductor activo ocupa un
/// decodificador de hardware, que en los teléfonos es un recurso escaso. Por
/// eso este controlador sostiene estas reglas:
///
/// - I1: como máximo hay UN reproductor vivo como activo. Pasar a otro
///   capítulo suelta el anterior.
/// - I2: un reproductor solo se crea en [reproducir] o [reintentar], que
///   responden a un toque del usuario. Nunca al montar la sección ni al
///   desplazarse: no hay reproducción automática ni descargas por adelantado.
/// - I3: el reproductor anterior se descarta ANTES de crear el siguiente: se
///   quita el listener, se pausa, se apaga la bandera de pantalla encendida y
///   se libera después del siguiente fotograma. Nunca se espera a que
///   `dispose()` termine, porque puede tardar mientras la plataforma crea el
///   reproductor.
/// - I4: un contador de generación vuelve inofensiva cualquier continuación
///   asíncrona de un reproductor ya descartado: si su `initialize()` termina
///   tarde, el resultado se ignora.
/// - I5: [pausar] (pestaña oculta, navegación por índice) no libera nada y
///   nunca reanuda por su cuenta. La única reanudación automática es la de
///   [reanudarTrasReubicar], y una pausa posterior la cancela.
/// - I6: [dispose] descarta todo y apaga la pantalla encendida.
class ControladorComoFunciona extends ChangeNotifier {
  ControladorComoFunciona({
    VideoPlayerController Function(ModeloCapituloComoFunciona capitulo)? crearVideo,
    ServicioPantalla? pantalla,
    bool? controlesDelNavegador,
  }) : _crearVideo = crearVideo ?? crearVideoPorDefecto,
       _pantalla = pantalla ?? const ServicioPantalla(),
       controlesDelNavegador = controlesDelNavegador ?? kIsWeb;

  /// Tiempo máximo de espera de `initialize()`. Sin tope, un video que nunca
  /// carga dejaría la portada con el indicador de progreso para siempre.
  static const Duration _tiempoMaximoDeCarga = Duration(seconds: 25);

  final VideoPlayerController Function(ModeloCapituloComoFunciona capitulo) _crearVideo;
  final ServicioPantalla _pantalla;

  /// En Web el video usa los controles nativos del navegador y Flutter no
  /// dibuja nada encima. En Android e iOS usa los controles propios.
  final bool controlesDelNavegador;

  VideoPlayerController? _video;
  ModeloCapituloComoFunciona? _capitulo;
  EstadoReproduccion _estado = EstadoReproduccion.inactivo;

  /// Cambia con cada reproductor nuevo y con cada descarte (I4).
  int _generacion = 0;
  bool _inicializado = false;

  /// El usuario pausó (o cambió de pestaña) antes de que el video terminara de
  /// cargar: al quedar listo no debe arrancar solo.
  bool _inicioCancelado = false;

  /// Identifica la última petición de [reanudarTrasReubicar]. Cualquier
  /// [pausar] posterior la deja obsoleta.
  int _ordenReanudar = 0;
  bool _pantallaEncendida = false;
  bool _desechado = false;

  // Últimos valores vistos, para avisar a la interfaz solo cuando cambian.
  bool _reproduciendo = false;
  bool _completado = false;
  bool _silencio = false;

  /// Capítulo que tiene reproductor (cargando, listo o con error).
  ModeloCapituloComoFunciona? get capituloActivo => _capitulo;

  /// Reproductor del capítulo activo, o `null` si ninguno está activo.
  VideoPlayerController? get video => _video;

  EstadoReproduccion estadoDe(ModeloCapituloComoFunciona capitulo) {
    return _capitulo?.numero == capitulo.numero ? _estado : EstadoReproduccion.inactivo;
  }

  bool get silenciado => (_video?.value.volume ?? 1) == 0;

  /// Reproductor con opciones explícitas, que son necesarias por dos razones:
  /// - En Android `mixWithOthers` es una bandera COMPARTIDA por todo el
  ///   plugin y el video del Inicio la pone en verdadero. Sin opciones propias,
  ///   estos videos la heredarían y nunca pedirían el foco de audio: se
  ///   oirían encima de la música de otra app.
  /// - En Web se activan los controles nativos del navegador, sin descarga ni
  ///   imagen en imagen, y se quitan el menú contextual y la transmisión.
  static VideoPlayerController crearVideoPorDefecto(ModeloCapituloComoFunciona capitulo) {
    return VideoPlayerController.asset(
      capitulo.rutaVideo,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        webOptions: const VideoPlayerWebOptions(
          controls: VideoPlayerWebOptionsControls.enabled(
            allowDownload: false,
            allowFullscreen: true,
            allowPlaybackRate: true,
            allowPictureInPicture: false,
          ),
          allowContextMenu: false,
          allowRemotePlayback: false,
        ),
      ),
    );
  }

  /// Reproduce el capítulo. Si ya es el activo no crea nada: lo reanuda (o lo
  /// repite, si había terminado).
  Future<void> reproducir(ModeloCapituloComoFunciona capitulo) async {
    if (_desechado) return;
    if (_capitulo?.numero == capitulo.numero) {
      if (_estado == EstadoReproduccion.cargando) {
        // Un nuevo toque durante la carga confirma que sí quiere verlo.
        _inicioCancelado = false;
        return;
      }
      if (_estado == EstadoReproduccion.listo) {
        if (_video!.value.isCompleted) return reiniciar();
        return _video!.play();
      }
    }

    _descartarActual();
    final generacion = _generacion;
    _capitulo = capitulo;
    _estado = EstadoReproduccion.cargando;
    _notificar();

    try {
      final video = _crearVideo(capitulo);
      _video = video;
      _reproduciendo = _completado = _silencio = false;
      video.addListener(_alCambiarValor);
      await video.initialize().timeout(_tiempoMaximoDeCarga);
      if (generacion != _generacion) return;
      _inicializado = true;
      _estado = EstadoReproduccion.listo;
      _notificar();

      // El volumen y el loop van antes de `play()`: en Web el navegador solo
      // acepta la reproducción automática si el estado ya está definido.
      await video.setVolume(1);
      await video.setLooping(false);
      if (generacion != _generacion || _inicioCancelado) return;
      await video.play();
    } catch (e) {
      if (generacion != _generacion) return;
      debugPrint('No se pudo reproducir el capítulo ${capitulo.numero}: $e');
      // El reproductor fallido se conserva solo para liberarlo después.
      if (_estado != EstadoReproduccion.error) {
        _estado = EstadoReproduccion.error;
        _notificar();
      }
    }
  }

  /// Reemplaza el reproductor por uno nuevo. Debe llamarse desde el toque del
  /// usuario: en Web el navegador solo permite reproducir dentro de un gesto.
  Future<void> reintentar(ModeloCapituloComoFunciona capitulo) {
    _descartarActual();
    return reproducir(capitulo);
  }

  /// Pausa sin liberar el reproductor. Es lo que ocurre al ocultar la pestaña:
  /// al volver, el usuario decide si sigue (I5).
  Future<void> pausar() async {
    _ordenReanudar++;
    if (_estado == EstadoReproduccion.cargando) {
      // Todavía no hay nada que pausar, pero no debe empezar a sonar cuando
      // termine de cargar con la pestaña ya oculta.
      _inicioCancelado = true;
    } else if (_estado == EstadoReproduccion.listo) {
      await _video?.pause();
    }
  }

  /// Solo Web: reanuda el video que el navegador pausó al reubicar su elemento.
  ///
  /// Al cruzar los 900 px del panel, el motor de Flutter para Web saca del
  /// documento el DOM de las vistas de plataforma y lo vuelve a insertar. Según
  /// la especificación de HTML, un elemento multimedia que sale del documento
  /// se pausa: el `<video>` que sonaba (el mismo elemento, en la misma
  /// posición) queda detenido sin que el usuario haya hecho nada, por ejemplo
  /// al girar una tableta entre 768 y 1024 px.
  ///
  /// El evento de pausa llega en cola, así que se esperan 150 ms antes de mirar
  /// `isPlaying`. Solo se reanuda lo que sonaba al llamar, y un [pausar] en ese
  /// lapso (pestaña oculta) lo cancela: no debe sonar un video escondido.
  void reanudarTrasReubicar() {
    final video = _video;
    if (!controlesDelNavegador || _estado != EstadoReproduccion.listo || video == null) return;
    if (!video.value.isPlaying) return;
    final generacion = _generacion;
    final orden = ++_ordenReanudar;
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      final vigente = !_desechado && generacion == _generacion && orden == _ordenReanudar && identical(_video, video);
      if (vigente && _estado == EstadoReproduccion.listo && !video.value.isPlaying) {
        unawaited(video.play().catchError((Object e) => debugPrint('No se pudo reanudar el video: $e')));
      }
    });
  }

  Future<void> alternarReproduccion() => _conVideoListo((video) {
    if (video.value.isCompleted) return reiniciar();
    return video.value.isPlaying ? video.pause() : video.play();
  });

  Future<void> reiniciar() => _conVideoListo((video) async {
    await video.seekTo(Duration.zero);
    await video.play();
  });

  Future<void> alternarSonido() => _conVideoListo((video) => video.setVolume(video.value.volume == 0 ? 1 : 0));

  Future<void> buscar(Duration posicion) => _conVideoListo((video) => video.seekTo(posicion));

  /// Avanza o retrocede [desplazamiento] sin salirse del video.
  Future<void> saltar(Duration desplazamiento) => _conVideoListo((video) {
    final duracion = video.value.duration;
    final destino = video.value.position + desplazamiento;
    return video.seekTo(destino < Duration.zero ? Duration.zero : (destino > duracion ? duracion : destino));
  });

  /// Vuelve a la portada, soltando el reproductor.
  void detener() {
    if (_desechado) return;
    _descartarActual();
    _notificar();
  }

  /// Los controles solo actúan sobre un video ya cargado: en cualquier otro
  /// estado un toque tardío (por ejemplo, tras un error) no hace nada.
  Future<void> _conVideoListo(Future<void> Function(VideoPlayerController video) accion) async {
    final video = _estado == EstadoReproduccion.listo ? _video : null;
    if (video != null) await accion(video);
  }

  void _alCambiarValor() {
    final video = _video;
    if (video == null || _desechado) return;
    final valor = video.value;
    var cambio = false;

    // En Web, un error tras cargar suele ser el navegador rechazando la
    // reproducción automática: el video sigue siendo utilizable con sus
    // controles nativos, así que no se muestra el error.
    final erroresToleradosEnWeb = controlesDelNavegador && _inicializado;
    if (valor.hasError && !erroresToleradosEnWeb && _estado != EstadoReproduccion.error) {
      _estado = EstadoReproduccion.error;
      cambio = true;
    }
    _sincronizarPantalla(valor.isPlaying);

    // La posición cambia varias veces por segundo y no se avisa aquí: la
    // interfaz que la necesita escucha el valor del reproductor directamente.
    final silencio = valor.volume == 0;
    if (valor.isPlaying != _reproduciendo || valor.isCompleted != _completado || silencio != _silencio) {
      _reproduciendo = valor.isPlaying;
      _completado = valor.isCompleted;
      _silencio = silencio;
      cambio = true;
    }
    if (cambio) _notificar();
  }

  /// Enciende o apaga la pantalla encendida solo cuando cambia el estado.
  void _sincronizarPantalla(bool encendida) {
    if (_pantallaEncendida == encendida) return;
    _pantallaEncendida = encendida;
    unawaited(_pantalla.mantenerEncendida(encendida));
  }

  /// Suelta el reproductor activo (I3). No avisa a la interfaz: quien llama lo
  /// hace justo después, para que el cambio quede en un solo fotograma.
  void _descartarActual() {
    _generacion++;
    _inicioCancelado = false;
    _inicializado = false;
    _capitulo = null;
    _estado = EstadoReproduccion.inactivo;
    _sincronizarPantalla(false);

    final video = _video;
    if (video == null) return;
    _video = null;
    video.removeListener(_alCambiarValor);
    unawaited(video.pause().catchError((Object _) {}));
    // La interfaz todavía puede tener el video en pantalla durante este
    // fotograma. Liberarlo después de dibujar el siguiente evita que la
    // plataforma dibuje un reproductor ya destruido. Se pide un fotograma para
    // que ocurra aunque no haya otra animación en marcha.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(video.dispose().catchError((Object e) => debugPrint('No se pudo liberar el reproductor: $e')));
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void _notificar() {
    if (!_desechado) notifyListeners();
  }

  @override
  void dispose() {
    _descartarActual();
    _desechado = true;
    super.dispose();
  }
}
