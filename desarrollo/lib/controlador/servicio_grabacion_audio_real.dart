import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../configuracion/configuracion_lexus.dart';
import 'audio_wav.dart';
import 'servicio_grabacion_audio.dart';

/// Lo mínimo que se necesita del plugin `record`. Existe para poder probar la
/// lógica de [ServicioGrabacionAudioReal] sin canales de plataforma.
abstract class GrabadoraNativa {
  Future<bool> tienePermiso();

  /// Empieza a grabar y devuelve los fragmentos de audio a medida que llegan.
  /// El flujo se cierra cuando se detiene o se cancela la grabación.
  Future<Stream<Uint8List>> iniciarFlujo(RecordConfig configuracion);

  Future<void> detener();
  Future<void> cancelar();
  Future<void> liberar();
}

/// Adaptador sobre `AudioRecorder`. Solo usa el modo de flujo (`startStream`):
/// el plugin nunca recibe una ruta, así que no puede escribir el audio en
/// disco.
///
/// El `AudioRecorder` se crea en el primer uso: construirlo toca un canal de
/// plataforma, y no debe ocurrir en pantallas ni pruebas que nunca graban.
class GrabadoraRecord implements GrabadoraNativa {
  AudioRecorder? _grabadora;

  AudioRecorder get _activa => _grabadora ??= AudioRecorder();

  @override
  Future<bool> tienePermiso() => _activa.hasPermission();

  @override
  Future<Stream<Uint8List>> iniciarFlujo(RecordConfig configuracion) =>
      _activa.startStream(configuracion);

  @override
  Future<void> detener() async {
    await _grabadora?.stop();
  }

  @override
  Future<void> cancelar() async {
    await _grabadora?.cancel();
  }

  @override
  Future<void> liberar() async {
    final grabadora = _grabadora;
    _grabadora = null;
    await grabadora?.dispose();
  }
}

/// Implementación de [ServicioGrabacionAudio]: reúne en memoria los
/// fragmentos PCM de 16 bits y 16 kHz mono que entrega la grabadora y, al
/// terminar, los devuelve envueltos en un WAV.
///
/// No usa archivos: el audio solo existe como bytes en memoria hasta que quien
/// llama lo transcribe.
class ServicioGrabacionAudioReal implements ServicioGrabacionAudio {
  ServicioGrabacionAudioReal({GrabadoraNativa Function()? crearGrabadora})
    : _crearGrabadora = crearGrabadora ?? GrabadoraRecord.new;

  /// Formato pedido al plugin: PCM de 16 bits, 16 kHz, un canal.
  static const RecordConfig configuracion = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: ConfiguracionLexus.frecuenciaMuestreoAudio,
    numChannels: 1,
  );

  /// Tras detener, el plugin cierra el flujo y con ello entrega el último
  /// fragmento. Si el cierre no llega, se sigue con lo recibido.
  static const Duration _esperaCierreDelFlujo = Duration(seconds: 2);

  final GrabadoraNativa Function() _crearGrabadora;
  GrabadoraNativa? _grabadora;

  BytesBuilder? _pcm;
  StreamSubscription<Uint8List>? _suscripcion;
  Completer<void>? _cierre;
  bool _falloElFlujo = false;

  /// Se crea al primer uso (ver [GrabadoraRecord]).
  GrabadoraNativa get _activa => _grabadora ??= _crearGrabadora();

  @override
  Future<PermisoMicrofono> pedirPermiso() async {
    try {
      return await _activa.tienePermiso()
          ? PermisoMicrofono.concedido
          : PermisoMicrofono.denegado;
    } catch (e) {
      _registrar(e);
      return PermisoMicrofono.noDisponible;
    }
  }

  @override
  Future<bool> iniciar() async {
    try {
      await _soltarFlujo();
      final flujo = await _activa.iniciarFlujo(configuracion);
      // Copia cada fragmento: no se puede garantizar que el plugin no reutilice
      // sus búferes, y como mucho son unos pocos MB.
      final pcm = BytesBuilder();
      final cierre = Completer<void>();
      _pcm = pcm;
      _cierre = cierre;
      _falloElFlujo = false;
      _suscripcion = flujo.listen(
        pcm.add,
        onError: (Object error) {
          _falloElFlujo = true;
          _registrar(error);
        },
        onDone: () {
          if (!cierre.isCompleted) cierre.complete();
        },
      );
      return true;
    } catch (e) {
      _registrar(e);
      await _soltarFlujo();
      return false;
    }
  }

  @override
  Future<Uint8List?> detener() async {
    final pcm = _pcm;
    final cierre = _cierre;
    final grabadora = _grabadora;
    if (pcm == null || cierre == null || grabadora == null) return null;
    try {
      await grabadora.detener();
    } catch (e) {
      _registrar(e);
      await _soltarFlujo();
      return null;
    }
    try {
      await cierre.future.timeout(_esperaCierreDelFlujo);
    } on TimeoutException {
      // Se sigue con los fragmentos que llegaron.
    }
    final fallo = _falloElFlujo;
    final bytes = pcm.takeBytes();
    await _soltarFlujo();
    // Una muestra de 16 bits ocupa 2 bytes: se descarta un byte suelto.
    final utiles = bytes.length - (bytes.length % 2);
    if (fallo || utiles == 0) return null;
    return envolverPcmEnWav(
      Uint8List.sublistView(bytes, 0, utiles),
      frecuenciaMuestreo: configuracion.sampleRate,
      canales: configuracion.numChannels,
    );
  }

  @override
  Future<void> cancelar() async {
    try {
      await _grabadora?.cancelar();
    } catch (e) {
      _registrar(e);
    }
    await _soltarFlujo();
  }

  @override
  Future<void> liberar() async {
    await cancelar();
    final grabadora = _grabadora;
    _grabadora = null;
    try {
      await grabadora?.liberar();
    } catch (e) {
      _registrar(e);
    }
  }

  /// Deja de escuchar el flujo y suelta el audio acumulado.
  Future<void> _soltarFlujo() async {
    final suscripcion = _suscripcion;
    _suscripcion = null;
    _pcm = null;
    _cierre = null;
    try {
      await suscripcion?.cancel();
    } catch (e) {
      _registrar(e);
    }
  }

  /// Solo el tipo del error: nunca su mensaje ni contenido de audio.
  void _registrar(Object error) =>
      debugPrint('Lexus: dictado, fallo del plugin (${error.runtimeType})');
}
