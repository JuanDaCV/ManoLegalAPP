import 'dart:async';
import 'dart:typed_data';

import 'package:desarrollo/controlador/servicio_grabacion_audio.dart';
import 'package:desarrollo/controlador/servicio_grabacion_audio_real.dart';
import 'package:desarrollo/controlador/servicio_transcripcion.dart';
import 'package:record/record.dart';

/// Grabadora nativa falsa: no usa canales de plataforma. El flujo de audio se
/// controla desde la prueba con [emitir].
class GrabadoraNativaFalsa implements GrabadoraNativa {
  bool permiso = true;
  Object? errorAlPedirPermiso;
  Object? errorAlIniciar;
  Object? errorAlDetener;

  /// Configuraciones con las que se pidió un flujo.
  final List<RecordConfig> configuraciones = [];
  int detenciones = 0;
  int cancelaciones = 0;
  int liberaciones = 0;

  StreamController<Uint8List>? _flujo;

  void emitir(List<int> bytes) => _flujo!.add(Uint8List.fromList(bytes));

  void emitirError(Object error) => _flujo!.addError(error);

  @override
  Future<bool> tienePermiso() async {
    final error = errorAlPedirPermiso;
    if (error != null) throw error;
    return permiso;
  }

  @override
  Future<Stream<Uint8List>> iniciarFlujo(RecordConfig configuracion) async {
    configuraciones.add(configuracion);
    final error = errorAlIniciar;
    if (error != null) throw error;
    _flujo = StreamController<Uint8List>();
    return _flujo!.stream;
  }

  @override
  Future<void> detener() async {
    detenciones++;
    final error = errorAlDetener;
    if (error != null) throw error;
    await _flujo?.close();
  }

  @override
  Future<void> cancelar() async {
    cancelaciones++;
    await _flujo?.close();
  }

  @override
  Future<void> liberar() async {
    liberaciones++;
  }
}

/// Servicio de grabación falso para el controlador del dictado.
class GrabacionAudioFalsa implements ServicioGrabacionAudio {
  PermisoMicrofono permiso = PermisoMicrofono.concedido;
  bool iniciarCorrecto = true;
  Object? errorAlPedirPermiso;

  /// Audio que devuelve [detener]; nulo simula una grabación sin audio.
  Uint8List? wav = Uint8List.fromList(List<int>.generate(64, (i) => i));

  final List<String> llamadas = [];

  int cuenta(String nombre) => llamadas.where((l) => l == nombre).length;

  @override
  Future<PermisoMicrofono> pedirPermiso() async {
    llamadas.add('pedirPermiso');
    final error = errorAlPedirPermiso;
    if (error != null) throw error;
    return permiso;
  }

  @override
  Future<bool> iniciar() async {
    llamadas.add('iniciar');
    return iniciarCorrecto;
  }

  @override
  Future<Uint8List?> detener() async {
    llamadas.add('detener');
    return wav;
  }

  @override
  Future<void> cancelar() async {
    llamadas.add('cancelar');
  }

  @override
  Future<void> liberar() async {
    llamadas.add('liberar');
  }
}

/// Transcriptor falso: devuelve [texto], lanza [error] o queda en espera.
class TranscriptorFalso implements ServicioTranscripcion {
  String texto = 'Me despidieron sin justa causa';
  Object? error;

  /// Cada audio recibido. Es el único lugar al que llega el audio.
  final List<Uint8List> recibidos = [];

  Completer<String>? _retenido;

  /// La próxima transcripción queda en espera hasta completar el resultado.
  Completer<String> retener() => _retenido = Completer<String>();

  @override
  Future<String> transcribir(Uint8List wav) async {
    recibidos.add(wav);
    final fallo = error;
    if (fallo != null) throw fallo;
    final retenido = _retenido;
    if (retenido != null) {
      _retenido = null;
      return retenido.future;
    }
    return texto;
  }
}

/// Reloj y temporizador controlados por la prueba: el tiempo solo avanza con
/// [tic].
class RelojDictadoFalso {
  DateTime ahora = DateTime(2026, 1, 1);
  _TemporizadorFalso? _temporizador;

  DateTime call() => ahora;

  bool get hayTemporizadorActivo => _temporizador?.isActive ?? false;

  Timer crearTemporizador(Duration periodo, void Function(Timer) alTic) {
    return _temporizador = _TemporizadorFalso(alTic);
  }

  /// Avanza el reloj y dispara un tic, si el temporizador sigue activo.
  void tic([Duration avance = const Duration(seconds: 1)]) {
    ahora = ahora.add(avance);
    final temporizador = _temporizador;
    if (temporizador != null && temporizador.isActive) temporizador.disparar();
  }

  /// Avanza el reloj sin disparar ningún tic.
  void avanzar(Duration avance) => ahora = ahora.add(avance);
}

class _TemporizadorFalso implements Timer {
  _TemporizadorFalso(this._alTic);

  final void Function(Timer) _alTic;
  bool _activo = true;
  int _tics = 0;

  void disparar() {
    _tics++;
    _alTic(this);
  }

  @override
  void cancel() => _activo = false;

  @override
  bool get isActive => _activo;

  @override
  int get tick => _tics;
}
