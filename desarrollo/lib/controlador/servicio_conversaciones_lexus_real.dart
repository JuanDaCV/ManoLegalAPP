import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../configuracion/configuracion_lexus.dart';
import '../modelo/error_lexus.dart';
import '../modelo/especialidad_abogado.dart';
import '../modelo/modelo_conversacion_lexus.dart';
import '../modelo/modelo_mensaje_lexus.dart';
import 'servicio_conversaciones_lexus.dart';

/// Implementación de [ServicioConversacionesLexus] sobre Cloud Firestore, en
/// `clientes/{uid}/conversacionesLexus/{conversacionId}/mensajes/{mensajeId}`.
///
/// El uid sale de la sesión actual. Las reglas de Firestore solo dejan leer y
/// escribir esa ruta a su dueño; los mapas que se escriben aquí tienen
/// exactamente los campos que esas reglas validan (ver `firestore.rules`).
/// La conversión entre mapas y modelos vive en este archivo: el modelo de
/// mensaje no sabe nada de Firestore.
class ServicioConversacionesLexusReal implements ServicioConversacionesLexus {
  static const String _coleccionClientes = 'clientes';
  static const String _coleccionConversaciones = 'conversacionesLexus';
  static const String _coleccionMensajes = 'mensajes';

  /// Una escritura propia aún sin confirmar trae la marca del servidor vacía;
  /// con `estimate` se lee como la hora local aproximada.
  static const GetOptions _lectura = GetOptions(
    serverTimestampBehavior: ServerTimestampBehavior.estimate,
  );

  /// Se resuelve al primer uso: tocar Firebase al construir la clase la haría
  /// fallar en cualquier prueba o pantalla que no lo haya inicializado.
  late final FirebaseFirestore _bd = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _conversaciones() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No hay una sesión iniciada.');
    return _bd
        .collection(_coleccionClientes)
        .doc(uid)
        .collection(_coleccionConversaciones);
  }

  DocumentReference<Map<String, dynamic>> _conversacion(String id) =>
      _conversaciones().doc(id);

  DocumentReference<Map<String, dynamic>> _mensaje(
    String conversacionId,
    String mensajeId,
  ) => _conversacion(
    conversacionId,
  ).collection(_coleccionMensajes).doc(mensajeId);

  @override
  Future<ConversacionLexusGuardada?> cargarMasReciente() async {
    final reciente = await _conversaciones()
        .orderBy('actualizadoEn', descending: true)
        .limit(1)
        .get(_lectura);
    if (reciente.docs.isEmpty) return null;

    final documento = reciente.docs.first;
    final mensajes = await documento.reference
        .collection(_coleccionMensajes)
        .orderBy('orden')
        .get(_lectura);
    return conversacionDesdeDatos(
      id: documento.id,
      datos: documento.data(),
      mensajes: [for (final m in mensajes.docs) (id: m.id, datos: m.data())],
    );
  }

  // Los identificadores automáticos se generan en el cliente, sin red ni
  // sesión; la ruta que se use para pedirlos es indiferente.
  @override
  String nuevoIdConversacion() =>
      _bd.collection(_coleccionConversaciones).doc().id;

  @override
  String nuevoIdMensaje() => _bd.collection(_coleccionMensajes).doc().id;

  @override
  Future<void> guardarEnvio({
    required String conversacionId,
    required bool conversacionNueva,
    String? titulo,
    required String mensajeId,
    required String texto,
    required int orden,
  }) {
    final conversacion = _conversacion(conversacionId);
    final lote = _bd.batch();
    if (conversacionNueva) {
      if (titulo == null) throw ArgumentError.notNull('titulo');
      lote.set(conversacion, mapaCabeceraNueva(titulo));
    } else {
      lote.update(conversacion, {'actualizadoEn': FieldValue.serverTimestamp()});
    }
    lote.set(
      _mensaje(conversacionId, mensajeId),
      mapaMensajeUsuario(texto: texto, orden: orden),
    );
    return lote.commit();
  }

  @override
  Future<void> guardarRespuesta({
    required String conversacionId,
    required String mensajeUsuarioId,
    required bool usuarioEnHistorialModelo,
    required ModeloMensajeLexus respuesta,
    required int orden,
  }) {
    final lote = _bd.batch();
    lote.update(_mensaje(conversacionId, mensajeUsuarioId), {
      'estado': EstadoMensajeLexus.enviado.name,
      'error': null,
      'enHistorialModelo': usuarioEnHistorialModelo,
    });
    lote.set(
      _mensaje(conversacionId, respuesta.id),
      mapaMensajeLexus(respuesta, orden: orden),
    );
    lote.update(_conversacion(conversacionId), {
      'turnos': FieldValue.increment(1),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
    return lote.commit();
  }

  @override
  Future<void> guardarFallo({
    required String conversacionId,
    required String mensajeId,
    required TipoErrorLexus tipo,
  }) {
    return _mensaje(conversacionId, mensajeId).update({
      'estado': EstadoMensajeLexus.fallido.name,
      'error': tipo.name,
    });
  }

  @override
  Future<void> guardarReintento({
    required String conversacionId,
    required String mensajeId,
    required int orden,
  }) {
    final lote = _bd.batch();
    lote.update(_mensaje(conversacionId, mensajeId), {
      'estado': EstadoMensajeLexus.enviando.name,
      'error': null,
      'orden': orden,
      'momento': FieldValue.serverTimestamp(),
    });
    lote.update(_conversacion(conversacionId), {
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
    return lote.commit();
  }

  // Cerrar y expirar no tocan `actualizadoEn`: así la conversación nueva queda
  // siempre como la más reciente, sin empates al ordenar por actividad.
  @override
  Future<void> cerrar(String conversacionId) => _conversacion(
    conversacionId,
  ).update({'estado': EstadoConversacionLexus.cerrada.name});

  @override
  Future<void> expirar(String conversacionId) => _conversacion(
    conversacionId,
  ).update({'estado': EstadoConversacionLexus.expirada.name});
}

// -----------------------------------------------------------------------------
// Conversión entre mapas de Firestore y modelos. Son funciones puras (salvo por
// las marcas de tiempo del servidor) para poder probarlas sin Firebase.
// -----------------------------------------------------------------------------

/// Cabecera de una conversación nueva: activa, sin turnos y con las fechas
/// del servidor.
@visibleForTesting
Map<String, Object?> mapaCabeceraNueva(String titulo) => {
  'titulo': titulo,
  'creadoEn': FieldValue.serverTimestamp(),
  'actualizadoEn': FieldValue.serverTimestamp(),
  'turnos': 0,
  'estado': EstadoConversacionLexus.activa.name,
};

/// Mensaje de la persona recién enviado. No guarda `textoParaModelo`: es
/// idéntico a `texto` y se reconstruye al cargar.
@visibleForTesting
Map<String, Object?> mapaMensajeUsuario({
  required String texto,
  required int orden,
}) => {
  'autor': AutorMensajeLexus.usuario.name,
  'texto': texto,
  'momento': FieldValue.serverTimestamp(),
  'orden': orden,
  'estado': EstadoMensajeLexus.enviando.name,
  'error': null,
  'origen': OrigenMensajeLexus.local.name,
  'urgente': false,
  'areaSugerida': null,
  'enHistorialModelo': false,
  'textoParaModelo': null,
};

/// Mensaje de Lexus. Solo el del modelo guarda `textoParaModelo` (el JSON
/// crudo, para reenviar exactamente el mismo contexto tras recargar).
@visibleForTesting
Map<String, Object?> mapaMensajeLexus(
  ModeloMensajeLexus mensaje, {
  required int orden,
}) => {
  'autor': AutorMensajeLexus.lexus.name,
  'texto': mensaje.texto,
  'momento': FieldValue.serverTimestamp(),
  'orden': orden,
  'estado': EstadoMensajeLexus.enviado.name,
  'error': null,
  'origen': mensaje.origen.name,
  'urgente': mensaje.urgente,
  'areaSugerida': mensaje.areaSugerida?.clave,
  'enHistorialModelo': mensaje.enHistorialModelo,
  'textoParaModelo': mensaje.origen == OrigenMensajeLexus.modelo
      ? mensaje.textoParaModelo
      : null,
};

/// Arma la conversación a partir de los datos guardados. Tolera valores
/// desconocidos o ausentes (documentos de otra versión): un mensaje ilegible se
/// omite y una conversación de estado desconocido no se puede retomar.
@visibleForTesting
ConversacionLexusGuardada conversacionDesdeDatos({
  required String id,
  required Map<String, dynamic> datos,
  required Iterable<({String id, Map<String, dynamic> datos})> mensajes,
}) {
  final turnos = datos['turnos'];
  final guardados = <MensajeGuardadoLexus>[
    for (final mensaje in mensajes)
      ?_mensajeDesdeDatos(mensaje.id, mensaje.datos),
  ]..sort((a, b) => a.orden.compareTo(b.orden));

  return ConversacionLexusGuardada(
    id: id,
    estado:
        _porNombre(EstadoConversacionLexus.values, datos['estado']) ??
        EstadoConversacionLexus.cerrada,
    turnos: turnos is num
        ? turnos.toInt().clamp(0, ConfiguracionLexus.turnosMaximos)
        : 0,
    actualizadoEn: _fecha(datos['actualizadoEn']),
    mensajes: guardados,
  );
}

MensajeGuardadoLexus? _mensajeDesdeDatos(
  String id,
  Map<String, dynamic> datos,
) {
  final autor = _porNombre(AutorMensajeLexus.values, datos['autor']);
  final texto = datos['texto'];
  final orden = datos['orden'];
  if (autor == null || texto is! String || orden is! num) return null;

  final esUsuario = autor == AutorMensajeLexus.usuario;
  final enHistorialModelo = datos['enHistorialModelo'] == true;
  final textoGuardado = datos['textoParaModelo'];
  return MensajeGuardadoLexus(
    orden: orden.toInt(),
    mensaje: ModeloMensajeLexus(
      id: id,
      autor: autor,
      texto: texto,
      momento: _fecha(datos['momento']) ?? DateTime.now(),
      estado:
          _porNombre(EstadoMensajeLexus.values, datos['estado']) ??
          EstadoMensajeLexus.enviado,
      origen:
          _porNombre(OrigenMensajeLexus.values, datos['origen']) ??
          OrigenMensajeLexus.local,
      areaSugerida: _porNombre(EspecialidadAbogado.values, datos['areaSugerida']),
      urgente: datos['urgente'] == true,
      error: _porNombre(TipoErrorLexus.values, datos['error']),
      enHistorialModelo: enHistorialModelo,
      // El texto de la persona es idéntico a lo que se reenvía al modelo.
      textoParaModelo: esUsuario
          ? (enHistorialModelo ? texto : null)
          : (textoGuardado is String ? textoGuardado : null),
    ),
  );
}

T? _porNombre<T extends Enum>(List<T> valores, Object? nombre) {
  for (final valor in valores) {
    if (valor.name == nombre) return valor;
  }
  return null;
}

DateTime? _fecha(Object? valor) => valor is Timestamp ? valor.toDate() : null;
