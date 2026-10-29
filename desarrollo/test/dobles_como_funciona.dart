import 'dart:async';

import 'package:desarrollo/controlador/controlador_como_funciona.dart';
import 'package:desarrollo/controlador/servicio_pantalla.dart';
import 'package:desarrollo/modelo/modelo_capitulo_como_funciona.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

// =============================================================================
// El reproductor real necesita la plataforma de video, que no existe en
// `flutter test`. Estos dobles registran las llamadas para comprobar el
// comportamiento del controlador y de la interfaz. Se declaran con `implements`
// + `noSuchMethod`, como los demás dobles de prueba del proyecto.
// =============================================================================

/// Reproductor falso: imita lo esencial del real (valores, notificaciones,
/// que `dispose` es idempotente y que un `initialize` tardío de un reproductor
/// ya liberado no hace nada).
class VideoFalso extends ValueNotifier<VideoPlayerValue> implements VideoPlayerController {
  VideoFalso({
    this.tamano = const Size(1920, 1080),
    this.duracion = const Duration(seconds: 30),
    this.fallaAlIniciar = false,
    this.retenerInicio,
  }) : super(const VideoPlayerValue.uninitialized()) {
    creados.add(this);
  }

  /// Todos los reproductores creados desde el último [reiniciarRegistro].
  static final List<VideoFalso> creados = [];

  /// Los que no se han liberado.
  static List<VideoFalso> get vivos => creados.where((video) => !video.liberado).toList();

  static void reiniciarRegistro() => creados.clear();

  final Size tamano;
  final Duration duracion;
  final bool fallaAlIniciar;

  /// Si está puesto, `initialize` espera a que se complete (carga "en curso").
  final Completer<void>? retenerInicio;

  final llamadas = <String>[];
  bool liberado = false;

  int veces(String llamada) => llamadas.where((l) => l == llamada).length;

  // Sin id de reproductor, VideoPlayer dibuja un contenedor vacío en vez de
  // pedirle una vista a la plataforma.
  @override
  int get playerId => VideoPlayerController.kUninitializedPlayerId;

  @override
  Future<void> initialize() async {
    llamadas.add('initialize');
    await retenerInicio?.future;
    if (liberado) return;
    if (fallaAlIniciar) throw PlatformException(code: 'sin_video');
    value = VideoPlayerValue(duration: duracion, size: tamano, isInitialized: true);
  }

  @override
  Future<void> setVolume(double volume) async {
    llamadas.add('volumen $volume');
    value = value.copyWith(volume: volume);
  }

  @override
  Future<void> setLooping(bool looping) async {
    llamadas.add('loop $looping');
    value = value.copyWith(isLooping: looping);
  }

  @override
  Future<void> play() async {
    llamadas.add('play');
    value = value.copyWith(isPlaying: true, isCompleted: false);
  }

  @override
  Future<void> pause() async {
    llamadas.add('pause');
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    llamadas.add('seekTo ${position.inMilliseconds}');
    final limitada = position > value.duration ? value.duration : position;
    value = value.copyWith(position: limitada, isCompleted: limitada == value.duration);
  }

  @override
  Future<void> dispose() async {
    llamadas.add('dispose');
    if (liberado) return;
    liberado = true;
    super.dispose();
  }

  /// Simula que el video llegó al final.
  void completar() {
    value = value.copyWith(isPlaying: false, isCompleted: true, position: value.duration);
  }

  /// Simula un error de la plataforma, como hace el reproductor real.
  void fallar([String descripcion = 'error de reproducción']) {
    value = VideoPlayerValue.erroneous(descripcion);
  }

  /// Simula el avance del video mientras suena.
  void avanzarA(Duration posicion) {
    value = value.copyWith(position: posicion);
  }

  /// Simula que el navegador pausó el elemento por su cuenta (por ejemplo, al
  /// sacarlo del documento): el valor cambia sin que la app llame a `pause()`.
  void simularPausaDelNavegador() {
    value = value.copyWith(isPlaying: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Servicio de pantalla encendida falso: solo anota las llamadas.
class PantallaFalsa implements ServicioPantalla {
  final llamadas = <bool>[];

  @override
  Future<void> mantenerEncendida(bool encendida) async => llamadas.add(encendida);
}

/// Reproductor que carga bien, con el tamaño y la duración reales del capítulo.
VideoFalso _videoDelCapitulo(ModeloCapituloComoFunciona capitulo) =>
    VideoFalso(tamano: Size(capitulo.anchoPx.toDouble(), capitulo.altoPx.toDouble()), duracion: capitulo.duracion);

/// Controlador con reproductores falsos, listo para inyectar en la sección.
///
/// [crear] decide cómo se construye el reproductor de cada capítulo; por
/// defecto, uno que carga bien con el tamaño real del capítulo.
ControladorComoFunciona controladorDePrueba({
  VideoFalso Function(ModeloCapituloComoFunciona capitulo)? crear,
  PantallaFalsa? pantalla,
  bool navegador = false,
}) {
  return ControladorComoFunciona(
    crearVideo: crear ?? _videoDelCapitulo,
    pantalla: pantalla ?? PantallaFalsa(),
    controlesDelNavegador: navegador,
  );
}

/// Controlador que cuenta las veces que la sección le avisa de que el panel
/// cruzó el umbral escritorio/móvil (`reanudarTrasReubicar`).
class ControladorEspia extends ControladorComoFunciona {
  ControladorEspia({super.crearVideo, super.pantalla, super.controlesDelNavegador});

  int reubicaciones = 0;

  @override
  void reanudarTrasReubicar() {
    reubicaciones++;
    super.reanudarTrasReubicar();
  }
}

/// [ControladorEspia] con reproductores falsos que cargan bien.
ControladorEspia espiaDePrueba({bool navegador = false}) {
  return ControladorEspia(crearVideo: _videoDelCapitulo, pantalla: PantallaFalsa(), controlesDelNavegador: navegador);
}
