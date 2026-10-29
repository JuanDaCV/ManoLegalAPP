import 'dart:async';
import 'dart:convert';

import 'package:desarrollo/controlador/servicio_conversaciones_lexus.dart';
import 'package:desarrollo/controlador/servicio_lexus.dart';
import 'package:desarrollo/modelo/error_lexus.dart';
import 'package:desarrollo/modelo/especialidad_abogado.dart';
import 'package:desarrollo/modelo/modelo_conversacion_lexus.dart';
import 'package:desarrollo/modelo/modelo_mensaje_lexus.dart';
import 'package:desarrollo/modelo/modelo_resultado_abogado.dart';

/// Servicio de Lexus con resultados programados: cada llamada consume el
/// siguiente. Nunca toca la red ni Firebase.
class ServicioLexusDoble implements ServicioLexus {
  final List<Object> _cola = [];

  /// Cada llamada recibida, con el historial y el mensaje que llegaron.
  final List<({List<TurnoLexus> historial, String mensaje})> llamadas = [];

  void responder(String json) => _cola.add(json);

  void fallar(ErrorLexus error) => _cola.add(error);

  /// La próxima llamada queda en espera hasta que se complete el resultado.
  Completer<String> retener() {
    final completer = Completer<String>();
    _cola.add(completer);
    return completer;
  }

  @override
  Future<String> enviar({
    required List<TurnoLexus> historial,
    required String mensaje,
  }) async {
    llamadas.add((historial: List.of(historial), mensaje: mensaje));
    if (_cola.isEmpty) {
      throw StateError('No hay un resultado programado para esta llamada.');
    }
    final siguiente = _cola.removeAt(0);
    if (siguiente is ErrorLexus) throw siguiente;
    if (siguiente is Completer<String>) return siguiente.future;
    return siguiente as String;
  }
}

/// Mensaje tal como quedó en el historial.
class MensajeAlmacenadoDoble {
  MensajeAlmacenadoDoble({
    required this.id,
    required this.autor,
    required this.texto,
    required this.orden,
    required this.estado,
    this.error,
    this.origen = OrigenMensajeLexus.local,
    this.urgente = false,
    this.areaSugerida,
    this.enHistorialModelo = false,
    this.textoParaModelo,
  });

  final String id;
  final AutorMensajeLexus autor;
  final String texto;
  final OrigenMensajeLexus origen;
  final bool urgente;
  final EspecialidadAbogado? areaSugerida;
  final String? textoParaModelo;
  int orden;
  EstadoMensajeLexus estado;
  TipoErrorLexus? error;
  bool enHistorialModelo;
}

/// Conversación tal como quedó en el historial.
class ConversacionAlmacenadaDoble {
  ConversacionAlmacenadaDoble(this.id);

  final String id;
  String? titulo;
  int turnos = 0;
  EstadoConversacionLexus estado = EstadoConversacionLexus.activa;
  final Map<String, MensajeAlmacenadoDoble> mensajes = {};

  /// Mensajes por posición, como los cargaría el servicio real.
  List<MensajeAlmacenadoDoble> get enOrden =>
      mensajes.values.toList()..sort((a, b) => a.orden.compareTo(b.orden));
}

/// Historial de conversaciones en memoria. Registra cada llamada y lo que
/// habría quedado guardado, y nunca toca Firebase.
class ServicioConversacionesLexusDoble implements ServicioConversacionesLexus {
  ConversacionLexusGuardada? _guardada;

  /// Lo que devuelve la carga; nulo si la persona no tiene conversaciones.
  /// Al asignarla, también queda como lo ya guardado en [conversaciones], para
  /// que las escrituras posteriores encuentren sus mensajes.
  ConversacionLexusGuardada? get guardada => _guardada;
  set guardada(ConversacionLexusGuardada? valor) {
    _guardada = valor;
    if (valor == null) return;
    final conversacion = _conversacion(valor.id)
      ..turnos = valor.turnos
      ..estado = valor.estado;
    for (final guardado in valor.mensajes) {
      final m = guardado.mensaje;
      conversacion.mensajes[m.id] = MensajeAlmacenadoDoble(
        id: m.id,
        autor: m.autor,
        texto: m.texto,
        orden: guardado.orden,
        estado: m.estado,
        error: m.error,
        origen: m.origen,
        urgente: m.urgente,
        areaSugerida: m.areaSugerida,
        enHistorialModelo: m.enHistorialModelo,
        textoParaModelo: m.textoParaModelo,
      );
    }
  }

  /// Con verdadero, la carga y toda escritura fallan de forma asíncrona, como
  /// un permiso denegado o una red caída.
  bool fallar = false;

  /// Con verdadero, solo `expirar` falla.
  bool fallarExpiracion = false;

  /// Con verdadero, la carga y las escrituras lanzan al instante, como el
  /// servicio real cuando no hay sesión. Los identificadores se siguen dando.
  bool sinSesion = false;

  /// Con verdadero, además los identificadores lanzan, como el servicio real
  /// cuando Firebase no está inicializado.
  bool sinFirebase = false;

  /// Lo que se escribió, por identificador de conversación.
  final Map<String, ConversacionAlmacenadaDoble> conversaciones = {};

  /// Cada llamada, en orden.
  final List<({String nombre, String? conversacionId})> llamadas = [];

  Completer<ConversacionLexusGuardada?>? _cargaRetenida;
  int _contadorConversaciones = 0;
  int _contadorMensajes = 0;

  /// La próxima carga queda en espera hasta que se complete el resultado.
  Completer<ConversacionLexusGuardada?> retenerCarga() {
    return _cargaRetenida = Completer<ConversacionLexusGuardada?>();
  }

  /// Nombres de las llamadas, en orden.
  List<String> get nombres => [for (final l in llamadas) l.nombre];

  List<({String nombre, String? conversacionId})> llamadasDe(String nombre) =>
      [for (final l in llamadas) if (l.nombre == nombre) l];

  ConversacionAlmacenadaDoble _conversacion(String id) =>
      conversaciones.putIfAbsent(id, () => ConversacionAlmacenadaDoble(id));

  /// Registra la llamada. Con [sinFirebase] lanza al instante, como el servicio
  /// real cuando Firebase no está inicializado; con [fallar] devuelve un
  /// futuro fallido y la escritura no se aplica. Las llamadas constan en cuanto
  /// se hacen, antes de cualquier espera.
  Future<void>? _alLlamar(String nombre, [String? conversacionId]) {
    llamadas.add((nombre: nombre, conversacionId: conversacionId));
    if (sinFirebase || sinSesion) {
      throw StateError('Sin Firebase o sin sesión.');
    }
    if (fallar) {
      return Future.error(StateError('Fallo simulado del historial.'));
    }
    return null;
  }

  @override
  Future<ConversacionLexusGuardada?> cargarMasReciente() async {
    final fallo = _alLlamar('cargarMasReciente');
    if (fallo != null) await fallo;
    return _cargaRetenida != null ? _cargaRetenida!.future : _guardada;
  }

  @override
  String nuevoIdConversacion() {
    if (sinFirebase) throw StateError('Firebase no está inicializado.');
    return 'conv-${++_contadorConversaciones}';
  }

  @override
  String nuevoIdMensaje() {
    if (sinFirebase) throw StateError('Firebase no está inicializado.');
    return 'msg-${++_contadorMensajes}';
  }

  @override
  Future<void> guardarEnvio({
    required String conversacionId,
    required bool conversacionNueva,
    String? titulo,
    required String mensajeId,
    required String texto,
    required int orden,
  }) {
    final fallo = _alLlamar(
      conversacionNueva ? 'guardarEnvio:nueva' : 'guardarEnvio',
      conversacionId,
    );
    if (fallo != null) return fallo;
    final conversacion = _conversacion(conversacionId);
    if (conversacionNueva) conversacion.titulo = titulo;
    conversacion.mensajes[mensajeId] = MensajeAlmacenadoDoble(
      id: mensajeId,
      autor: AutorMensajeLexus.usuario,
      texto: texto,
      orden: orden,
      estado: EstadoMensajeLexus.enviando,
    );
    return Future.value();
  }

  @override
  Future<void> guardarRespuesta({
    required String conversacionId,
    required String mensajeUsuarioId,
    required bool usuarioEnHistorialModelo,
    required ModeloMensajeLexus respuesta,
    required int orden,
  }) {
    final fallo = _alLlamar('guardarRespuesta', conversacionId);
    if (fallo != null) return fallo;
    final conversacion = _conversacion(conversacionId);
    conversacion.mensajes[mensajeUsuarioId]!
      ..estado = EstadoMensajeLexus.enviado
      ..error = null
      ..enHistorialModelo = usuarioEnHistorialModelo;
    conversacion.mensajes[respuesta.id] = MensajeAlmacenadoDoble(
      id: respuesta.id,
      autor: AutorMensajeLexus.lexus,
      texto: respuesta.texto,
      orden: orden,
      estado: EstadoMensajeLexus.enviado,
      origen: respuesta.origen,
      urgente: respuesta.urgente,
      areaSugerida: respuesta.areaSugerida,
      enHistorialModelo: respuesta.enHistorialModelo,
      textoParaModelo: respuesta.textoParaModelo,
    );
    conversacion.turnos++;
    return Future.value();
  }

  @override
  Future<void> guardarFallo({
    required String conversacionId,
    required String mensajeId,
    required TipoErrorLexus tipo,
  }) {
    final fallo = _alLlamar('guardarFallo', conversacionId);
    if (fallo != null) return fallo;
    _conversacion(conversacionId).mensajes[mensajeId]!
      ..estado = EstadoMensajeLexus.fallido
      ..error = tipo;
    return Future.value();
  }

  @override
  Future<void> guardarReintento({
    required String conversacionId,
    required String mensajeId,
    required int orden,
  }) {
    final fallo = _alLlamar('guardarReintento', conversacionId);
    if (fallo != null) return fallo;
    _conversacion(conversacionId).mensajes[mensajeId]!
      ..estado = EstadoMensajeLexus.enviando
      ..error = null
      ..orden = orden;
    return Future.value();
  }

  @override
  Future<void> cerrar(String conversacionId) {
    final fallo = _alLlamar('cerrar', conversacionId);
    if (fallo != null) return fallo;
    _conversacion(conversacionId).estado = EstadoConversacionLexus.cerrada;
    return Future.value();
  }

  @override
  Future<void> expirar(String conversacionId) {
    final fallo = _alLlamar('expirar', conversacionId);
    if (fallo != null) return fallo;
    if (fallarExpiracion) {
      return Future.error(StateError('Fallo simulado al expirar.'));
    }
    _conversacion(conversacionId).estado = EstadoConversacionLexus.expirada;
    return Future.value();
  }
}

/// Mensaje guardado de prueba. Como el servicio real, el texto de la persona
/// solo vuelve como `textoParaModelo` si estaba en el historial del modelo.
MensajeGuardadoLexus mensajeGuardadoDePrueba({
  required String id,
  required AutorMensajeLexus autor,
  required String texto,
  required int orden,
  EstadoMensajeLexus estado = EstadoMensajeLexus.enviado,
  OrigenMensajeLexus origen = OrigenMensajeLexus.local,
  TipoErrorLexus? error,
  bool enHistorialModelo = false,
  String? textoParaModelo,
}) {
  return MensajeGuardadoLexus(
    orden: orden,
    mensaje: ModeloMensajeLexus(
      id: id,
      autor: autor,
      texto: texto,
      momento: DateTime(2026, 1, 1),
      estado: estado,
      origen: origen,
      error: error,
      enHistorialModelo: enHistorialModelo,
      textoParaModelo: autor == AutorMensajeLexus.usuario
          ? (enHistorialModelo ? texto : null)
          : textoParaModelo,
    ),
  );
}

/// Un intercambio completo respondido por el modelo: la pregunta de la
/// persona y la respuesta de Lexus, como quedan en el historial.
List<MensajeGuardadoLexus> intercambioGuardado(
  int numero, {
  required String pregunta,
  required String respuesta,
}) {
  return [
    mensajeGuardadoDePrueba(
      id: 'u$numero',
      autor: AutorMensajeLexus.usuario,
      texto: pregunta,
      orden: numero * 2,
      enHistorialModelo: true,
    ),
    mensajeGuardadoDePrueba(
      id: 'l$numero',
      autor: AutorMensajeLexus.lexus,
      texto: respuesta,
      orden: numero * 2 + 1,
      origen: OrigenMensajeLexus.modelo,
      enHistorialModelo: true,
      textoParaModelo: jsonLexus(respuesta: respuesta),
    ),
  ];
}

ConversacionLexusGuardada conversacionGuardadaDePrueba({
  String id = 'guardada-1',
  EstadoConversacionLexus estado = EstadoConversacionLexus.activa,
  int turnos = 0,
  DateTime? actualizadoEn,
  List<MensajeGuardadoLexus> mensajes = const [],
}) {
  return ConversacionLexusGuardada(
    id: id,
    estado: estado,
    turnos: turnos,
    actualizadoEn: actualizadoEn,
    mensajes: mensajes,
  );
}

/// JSON como lo devolvería el modelo.
String jsonLexus({
  String? respuesta = 'Respuesta de prueba.',
  String ambito = 'juridico',
  String? area,
  bool urgente = false,
  bool sugerir = false,
  List<String> preguntas = const [],
}) {
  return jsonEncode({
    'respuesta': ?respuesta,
    'ambito': ambito,
    'area_probable': area,
    'urgente': urgente,
    'sugerir_abogados': sugerir,
    'preguntas_pendientes': preguntas,
  });
}

/// Búsqueda de abogados falsa: devuelve [resultado] o lanza [error].
class BuscadorAbogadosFalso {
  List<ModeloResultadoAbogado> resultado = const [];
  Object? error;
  final List<EspecialidadAbogado> llamadas = [];

  Future<List<ModeloResultadoAbogado>> buscar(EspecialidadAbogado area) async {
    llamadas.add(area);
    final fallo = error;
    if (fallo != null) throw fallo;
    return resultado;
  }
}

/// Datos obviamente inventados, solo para pruebas.
ModeloResultadoAbogado abogadoDePrueba({String uid = 'uid-prueba-1'}) {
  return ModeloResultadoAbogado(
    uid: uid,
    nombreCompleto: 'Abogada de Prueba',
    especialidad: 'Derecho de familia',
    ubicacion: 'Cali',
    verificado: true,
    calificacion: 4.5,
    cantidadResenas: 3,
  );
}

/// Reloj controlable para las pruebas del intervalo mínimo entre envíos.
class RelojFalso {
  DateTime ahora = DateTime(2026, 1, 1);

  void avanzar([Duration duracion = const Duration(seconds: 2)]) =>
      ahora = ahora.add(duracion);

  DateTime call() => ahora;
}
