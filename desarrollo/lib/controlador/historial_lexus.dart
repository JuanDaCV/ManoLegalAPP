import 'dart:async';

import 'package:flutter/foundation.dart';

import '../configuracion/configuracion_lexus.dart';
import '../modelo/error_lexus.dart';
import '../modelo/modelo_conversacion_lexus.dart';
import '../modelo/modelo_mensaje_lexus.dart';
import 'servicio_conversaciones_lexus.dart';
import 'servicio_conversaciones_lexus_real.dart';

/// Guarda y retoma la conversación de Lexus en el historial de la persona.
///
/// Guardar nunca bloquea el chat: las escrituras no se esperan, y con el
/// primer fallo de carga o de escritura el historial pasa a [noDisponible],
/// avisa una sola vez y no vuelve a intentar nada. La conversación en pantalla
/// sigue en memoria; de ella se ocupa [ControladorLexus].
class HistorialLexus {
  HistorialLexus({
    ServicioConversacionesLexus? servicio,
    required this._alQuedarNoDisponible,
  }) : _servicioInyectado = servicio;

  final ServicioConversacionesLexus? _servicioInyectado;
  final VoidCallback _alQuedarNoDisponible;

  /// Se crea al primer uso: el servicio real depende de Firebase.
  late final ServicioConversacionesLexus _conversaciones =
      _servicioInyectado ?? ServicioConversacionesLexusReal();

  /// Pasa a falso con el primer fallo de carga o de escritura y ya no vuelve.
  bool _persistir = true;

  /// Conversación guardada a la que pertenecen los mensajes en pantalla; nulo
  /// mientras aún no se ha guardado ninguna.
  String? _conversacionId;

  /// Posición del próximo mensaje que se guarde en la conversación.
  int _siguienteOrden = 0;

  /// Mensajes de la persona cuyo documento ya existe en el historial.
  final Set<String> _idsGuardados = {};

  /// Conversación anterior que seguía activa pero ya venció: se marca
  /// expirada al enviar el primer mensaje de la nueva.
  String? _conversacionPorExpirar;

  /// Verdadero si el historial no se pudo cargar o guardar.
  bool get noDisponible => !_persistir;

  /// Identificador de un mensaje nuevo: el del historial, para que el mensaje
  /// en pantalla y su documento sean el mismo. Nulo si no hay historial o no
  /// se pudo generar; quien lo llama usa entonces uno local.
  String? nuevoIdMensaje() {
    return _persistir
        ? _intentar(() => _conversaciones.nuevoIdMensaje())
        : null;
  }

  /// Busca la conversación más reciente. Nunca lanza: si falla, el historial
  /// queda no disponible y devuelve nulo.
  Future<ConversacionLexusGuardada?> cargar() async {
    try {
      return await _conversaciones.cargarMasReciente();
    } catch (_) {
      _historialFallo();
      return null;
    }
  }

  /// Retoma [guardada] si está activa y tuvo actividad dentro de la vigencia, y
  /// devuelve sus mensajes y turnos. Si está activa pero venció, queda
  /// pendiente de marcarse expirada y devuelve nulo.
  ({List<ModeloMensajeLexus> mensajes, int turnos})? retomar(
    ConversacionLexusGuardada guardada,
    DateTime ahora,
  ) {
    if (guardada.estado != EstadoConversacionLexus.activa) return null;
    final ultimaActividad = guardada.actualizadoEn ?? ahora;
    if (ahora.difference(ultimaActividad) >=
        ConfiguracionLexus.vigenciaConversacion) {
      _conversacionPorExpirar = guardada.id;
      return null;
    }

    _conversacionId = guardada.id;
    final mensajes = <ModeloMensajeLexus>[];
    var ultimoOrden = -1;
    for (final guardado in guardada.mensajes) {
      mensajes.add(_restaurado(guardado.mensaje));
      _idsGuardados.add(guardado.mensaje.id);
      if (guardado.orden > ultimoOrden) ultimoOrden = guardado.orden;
    }
    _siguienteOrden = ultimoOrden + 1;
    return (mensajes: mensajes, turnos: guardada.turnos);
  }

  /// La persona empezó otra conversación mientras se cargaba: la guardada se
  /// cierra si seguía activa, porque si no volvería a aparecer la próxima vez.
  void descartarCargada(ConversacionLexusGuardada? guardada) {
    if (guardada != null && guardada.estado == EstadoConversacionLexus.activa) {
      final id = guardada.id;
      _guardar(() => _conversaciones.cerrar(id));
    }
  }

  /// Guarda el mensaje de la persona al enviarlo. Si todavía no hay
  /// conversación guardada, la crea en el mismo lote; si el mensaje ya estaba
  /// guardado (un reintento), solo lo lleva al final.
  void guardarEnvio(ModeloMensajeLexus usuario) {
    if (!_persistir) return;
    final orden = _siguienteOrden++;
    final existente = _conversacionId;
    if (existente != null && _idsGuardados.contains(usuario.id)) {
      _guardar(
        () => _conversaciones.guardarReintento(
          conversacionId: existente,
          mensajeId: usuario.id,
          orden: orden,
        ),
      );
      return;
    }

    final nueva = existente == null;
    final conversacionId =
        existente ?? _intentar(() => _conversaciones.nuevoIdConversacion());
    if (conversacionId == null) return;
    _conversacionId = conversacionId;
    _idsGuardados.add(usuario.id);
    _guardar(
      () => _conversaciones.guardarEnvio(
        conversacionId: conversacionId,
        conversacionNueva: nueva,
        titulo: nueva ? _titulo(usuario.texto) : null,
        mensajeId: usuario.id,
        texto: usuario.texto,
        orden: orden,
      ),
    );

    final anterior = _conversacionPorExpirar;
    if (anterior != null) {
      _conversacionPorExpirar = null;
      _expirarAnterior(anterior);
    }
  }

  /// Guarda el turno completo: el mensaje de la persona pasa a enviado, se
  /// guarda la respuesta y sube el contador de turnos.
  void guardarRespuesta(
    String idUsuario,
    ModeloMensajeLexus respuesta, {
    required bool usuarioEnHistorialModelo,
  }) {
    final conversacionId = _conversacionId;
    if (!_persistir || conversacionId == null) return;
    final orden = _siguienteOrden++;
    _guardar(
      () => _conversaciones.guardarRespuesta(
        conversacionId: conversacionId,
        mensajeUsuarioId: idUsuario,
        usuarioEnHistorialModelo: usuarioEnHistorialModelo,
        respuesta: respuesta,
        orden: orden,
      ),
    );
  }

  /// Guarda que el mensaje de la persona falló. Sin conversación guardada no
  /// hay nada que actualizar.
  void guardarFallo(String idUsuario, TipoErrorLexus tipo) {
    final conversacionId = _conversacionId;
    if (conversacionId == null) return;
    _guardar(
      () => _conversaciones.guardarFallo(
        conversacionId: conversacionId,
        mensajeId: idUsuario,
        tipo: tipo,
      ),
    );
  }

  /// Deja la conversación guardada como cerrada (no se borra) y limpia el
  /// estado para que la siguiente empiece de cero.
  void reiniciar() {
    final guardada = _conversacionId;
    if (guardada != null) _guardar(() => _conversaciones.cerrar(guardada));
    _conversacionId = null;
    _conversacionPorExpirar = null;
    _siguienteOrden = 0;
    _idsGuardados.clear();
  }

  /// Un mensaje de la persona que no llegó a confirmarse (quedó enviando o
  /// fallido) vuelve como fallido, con su botón de reintentar.
  static ModeloMensajeLexus _restaurado(ModeloMensajeLexus mensaje) {
    if (mensaje.autor != AutorMensajeLexus.usuario ||
        mensaje.estado == EstadoMensajeLexus.enviado) {
      return mensaje;
    }
    return mensaje.copyWith(
      estado: EstadoMensajeLexus.fallido,
      error: mensaje.error ?? TipoErrorLexus.interno,
    );
  }

  /// Marca como expirada la conversación anterior que ya había vencido. Va
  /// aparte del lote del mensaje nuevo a propósito: que no se pueda expirar
  /// nunca debe impedir guardar la conversación nueva, así que un fallo aquí
  /// solo se registra.
  void _expirarAnterior(String conversacionId) {
    unawaited(() async {
      try {
        await _conversaciones.expirar(conversacionId);
      } catch (_) {
        debugPrint('Lexus: error tipo=historial_expiracion');
      }
    }());
  }

  /// Lanza una escritura sin esperarla: Firestore conserva el orden de las
  /// escrituras de un mismo cliente, así que no hace falta. El cuerpo va dentro
  /// de la función asíncrona porque sin Firebase inicializado el servicio
  /// lanza de inmediato, no al esperar el resultado.
  void _guardar(Future<void> Function() escritura) {
    if (!_persistir) return;
    unawaited(() async {
      try {
        await escritura();
      } catch (_) {
        _historialFallo();
      }
    }());
  }

  /// Ejecuta una operación síncrona del historial; si falla, deja el historial
  /// como no disponible y devuelve nulo.
  T? _intentar<T>(T Function() operacion) {
    try {
      return operacion();
    } catch (_) {
      _historialFallo();
      return null;
    }
  }

  /// Primer fallo del historial: se avisa una sola vez, se registra sin
  /// contenido y se deja de guardar. La conversación sigue en memoria.
  void _historialFallo() {
    if (!_persistir) return;
    _persistir = false;
    debugPrint('Lexus: error tipo=historial');
    _alQuedarNoDisponible();
  }

  /// Comienzo del primer mensaje, en una sola línea y de largo acotado.
  static String _titulo(String texto) {
    final linea = texto.trim().replaceAll(RegExp(r'\s+'), ' ');
    final caracteres = linea.runes.toList();
    if (caracteres.length <= ConfiguracionLexus.largoMaximoTitulo) return linea;
    final recorte = String.fromCharCodes(
      caracteres.take(ConfiguracionLexus.largoMaximoTitulo),
    );
    return '${recorte.trimRight()}…';
  }
}
