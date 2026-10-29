import 'dart:async';

import 'package:flutter/foundation.dart';

import '../configuracion/configuracion_lexus.dart';
import '../modelo/error_lexus.dart';
import 'servicio_grabacion_audio.dart';
import 'servicio_grabacion_audio_real.dart';
import 'servicio_transcripcion.dart';
import 'servicio_transcripcion_real.dart';

enum EstadoDictadoLexus { inactivo, pidiendoPermiso, grabando, transcribiendo }

enum TipoErrorDictadoLexus {
  permisoDenegado,
  noDisponible,
  demasiadoCorto,
  sinTexto,
  transcripcionFallida,
}

/// Último fallo del dictado. Cada fallo es un objeto nuevo: la vista distingue
/// uno de otro por identidad y así avisa de cada uno aunque se repita el tipo.
class ErrorDictadoLexus {
  const ErrorDictadoLexus(this.tipo, {this.causa});

  final TipoErrorDictadoLexus tipo;

  /// Tipo del fallo de la transcripción, si ese fue el motivo.
  final TipoErrorLexus? causa;
}

/// Coordina el dictado por voz: graba, transcribe y entrega el texto.
///
/// Solo entrega texto por [alTranscribir]. No conoce el chat ni lo que hace
/// con él: quien lo use decide dónde poner el texto. Nunca envía nada.
///
/// Ningún fallo sale de aquí como excepción: el estado vuelve a
/// [EstadoDictadoLexus.inactivo] y el motivo queda en [ultimoError].
class ControladorDictadoLexus extends ChangeNotifier {
  ControladorDictadoLexus({
    required this.alTranscribir,
    ServicioGrabacionAudio? grabadora,
    ServicioTranscripcion? transcriptor,
    DateTime Function()? ahora,
    Timer Function(Duration periodo, void Function(Timer) alTic)?
    crearTemporizador,
  }) : _grabadoraInyectada = grabadora,
       _transcriptorInyectado = transcriptor,
       _ahora = ahora ?? DateTime.now,
       _crearTemporizador = crearTemporizador ?? Timer.periodic;

  /// Recibe el texto transcrito.
  final void Function(String texto) alTranscribir;

  final ServicioGrabacionAudio? _grabadoraInyectada;
  final ServicioTranscripcion? _transcriptorInyectado;
  final DateTime Function() _ahora;
  final Timer Function(Duration periodo, void Function(Timer) alTic)
  _crearTemporizador;

  /// Se crean al primer uso: ninguno toca un plugin ni Firebase hasta que la
  /// persona pulsa el micrófono.
  late final ServicioGrabacionAudio _grabadora =
      _grabadoraInyectada ?? ServicioGrabacionAudioReal();
  late final ServicioTranscripcion _transcriptor =
      _transcriptorInyectado ?? ServicioTranscripcionReal();

  EstadoDictadoLexus _estado = EstadoDictadoLexus.inactivo;
  Duration _restante = ConfiguracionLexus.duracionMaximaAudio;
  ErrorDictadoLexus? _ultimoError;
  Timer? _temporizador;
  DateTime? _inicio;
  bool _grabadoraUsada = false;
  bool _desechado = false;

  /// Cada cancelación sube el contador: una transcripción que llega después
  /// de cancelar se descarta.
  int _generacion = 0;

  EstadoDictadoLexus get estado => _estado;

  /// Tiempo que queda de grabación; es el máximo mientras no se graba.
  Duration get restante => _restante;
  ErrorDictadoLexus? get ultimoError => _ultimoError;

  /// Verdadero mientras se pide el permiso, se graba o se transcribe.
  bool get ocupado => _estado != EstadoDictadoLexus.inactivo;
  bool get grabando => _estado == EstadoDictadoLexus.grabando;

  /// Empieza a grabar o, si ya se graba, detiene y transcribe. Ignora el toque
  /// mientras se pide el permiso o se transcribe.
  Future<void> alternar() async {
    switch (_estado) {
      case EstadoDictadoLexus.inactivo:
        await _iniciar();
      case EstadoDictadoLexus.grabando:
        await _detenerYTranscribir();
      case EstadoDictadoLexus.pidiendoPermiso ||
          EstadoDictadoLexus.transcribiendo:
        break;
    }
  }

  /// Descarta la grabación en curso sin transcribirla. Si ya se transcribe,
  /// descarta el resultado cuando llegue.
  Future<void> cancelar() async {
    if (_estado == EstadoDictadoLexus.inactivo) return;
    _generacion++;
    _temporizador?.cancel();
    _temporizador = null;
    final grababa = _estado == EstadoDictadoLexus.grabando;
    _estado = EstadoDictadoLexus.inactivo;
    _restante = ConfiguracionLexus.duracionMaximaAudio;
    _notificar();
    if (grababa) await _cancelarGrabacion();
  }

  Future<void> _iniciar() async {
    final generacion = _generacion;
    _ultimoError = null;
    _estado = EstadoDictadoLexus.pidiendoPermiso;
    _notificar();

    _grabadoraUsada = true;
    PermisoMicrofono permiso;
    try {
      permiso = await _grabadora.pedirPermiso();
    } catch (_) {
      permiso = PermisoMicrofono.noDisponible;
    }
    if (_desechado || generacion != _generacion) return;
    if (permiso != PermisoMicrofono.concedido) {
      _fallar(
        permiso == PermisoMicrofono.denegado
            ? TipoErrorDictadoLexus.permisoDenegado
            : TipoErrorDictadoLexus.noDisponible,
      );
      return;
    }

    bool inicio;
    try {
      inicio = await _grabadora.iniciar();
    } catch (_) {
      inicio = false;
    }
    if (_desechado || generacion != _generacion) {
      // Se canceló mientras arrancaba: se apaga lo que haya arrancado.
      if (inicio) await _cancelarGrabacion();
      return;
    }
    if (!inicio) {
      _fallar(TipoErrorDictadoLexus.noDisponible);
      return;
    }

    _inicio = _ahora();
    _restante = ConfiguracionLexus.duracionMaximaAudio;
    _estado = EstadoDictadoLexus.grabando;
    _temporizador = _crearTemporizador(
      const Duration(seconds: 1),
      (_) => _alTic(),
    );
    _notificar();
  }

  void _alTic() {
    final inicio = _inicio;
    if (_estado != EstadoDictadoLexus.grabando || inicio == null) return;
    // Se mide con el reloj y no contando tics: si el sistema retrasa el
    // temporizador (pestaña en segundo plano), el límite sigue siendo real.
    final transcurrido = _ahora().difference(inicio);
    final restante = ConfiguracionLexus.duracionMaximaAudio - transcurrido;
    _restante = restante.isNegative ? Duration.zero : restante;
    _notificar();
    if (transcurrido >= ConfiguracionLexus.duracionMaximaAudio) {
      unawaited(_detenerYTranscribir());
    }
  }

  Future<void> _detenerYTranscribir() async {
    final inicio = _inicio;
    if (_estado != EstadoDictadoLexus.grabando || inicio == null) return;
    final generacion = _generacion;
    final transcurrido = _ahora().difference(inicio);
    _temporizador?.cancel();
    _temporizador = null;
    _estado = EstadoDictadoLexus.transcribiendo;
    _notificar();

    if (transcurrido < ConfiguracionLexus.duracionMinimaAudio) {
      await _cancelarGrabacion();
      if (_desechado || generacion != _generacion) return;
      _fallar(TipoErrorDictadoLexus.demasiadoCorto);
      return;
    }

    Uint8List? wav;
    try {
      wav = await _grabadora.detener();
    } catch (_) {
      wav = null;
    }
    if (_desechado || generacion != _generacion) return;
    if (wav == null || wav.isEmpty) {
      _fallar(TipoErrorDictadoLexus.noDisponible);
      return;
    }

    final String texto;
    try {
      texto = (await _transcriptor.transcribir(wav)).trim();
    } catch (e) {
      if (_desechado || generacion != _generacion) return;
      _fallar(
        TipoErrorDictadoLexus.transcripcionFallida,
        causa: e is ErrorLexus ? e.tipo : TipoErrorLexus.interno,
      );
      return;
    }
    if (_desechado || generacion != _generacion) return;
    if (texto.isEmpty) {
      _fallar(TipoErrorDictadoLexus.sinTexto);
      return;
    }

    _estado = EstadoDictadoLexus.inactivo;
    _restante = ConfiguracionLexus.duracionMaximaAudio;
    _notificar();
    try {
      alTranscribir(texto);
    } catch (_) {
      debugPrint('Lexus: dictado, error tipo=entrega');
    }
  }

  /// Deja el dictado en reposo y registra el motivo. El campo de texto no se
  /// toca: aquí no hay nada que lo modifique.
  void _fallar(TipoErrorDictadoLexus tipo, {TipoErrorLexus? causa}) {
    _temporizador?.cancel();
    _temporizador = null;
    _estado = EstadoDictadoLexus.inactivo;
    _restante = ConfiguracionLexus.duracionMaximaAudio;
    _ultimoError = ErrorDictadoLexus(tipo, causa: causa);
    debugPrint('Lexus: dictado, error tipo=${tipo.name}');
    _notificar();
  }

  Future<void> _cancelarGrabacion() async {
    try {
      await _grabadora.cancelar();
    } catch (_) {
      // Sin acción: ya no hay nada que recuperar de esa grabación.
    }
  }

  void _notificar() {
    if (!_desechado) notifyListeners();
  }

  @override
  void dispose() {
    if (_desechado) return;
    _desechado = true;
    _generacion++;
    _temporizador?.cancel();
    _temporizador = null;
    if (_grabadoraUsada) unawaited(_liberarGrabadora());
    super.dispose();
  }

  Future<void> _liberarGrabadora() async {
    try {
      await _grabadora.cancelar();
      await _grabadora.liberar();
    } catch (_) {
      // Sin acción: la pantalla ya se cerró.
    }
  }
}
