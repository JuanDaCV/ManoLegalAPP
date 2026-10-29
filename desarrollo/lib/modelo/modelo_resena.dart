import 'package:cloud_firestore/cloud_firestore.dart';

/// Una reseña dejada por un cliente en el perfil de un abogado.
class ModeloResena {
  final String abogadoUid;
  final String clienteUid;
  final String autor;

  /// Calificación entera de 1 a 5 estrellas. Se guarda como entero (no
  /// [double]) porque las reglas de Firestore solo permiten valores enteros
  /// en este rango; usar un decimal invitaría a calificaciones falseadas
  /// que no corresponden a ninguna selección real de estrellas.
  final int calificacion;
  final String comentario;
  final DateTime fecha;

  const ModeloResena({
    required this.abogadoUid,
    required this.clienteUid,
    required this.autor,
    required this.calificacion,
    required this.comentario,
    required this.fecha,
  });

  /// Crea la reseña a partir de un mapa de Firestore. Es tolerante: nunca
  /// lanza una excepción por un campo ausente. La calificación se ajusta al
  /// rango 1..5 solo para efectos de visualización; esto no "corrige" datos
  /// inválidos, simplemente evita que un valor corrupto rompa la interfaz.
  factory ModeloResena.fromMap(String clienteUid, Map<String, dynamic> mapa) {
    final calificacionCruda = (mapa['calificacion'] as num?)?.toInt() ?? 0;
    return ModeloResena(
      abogadoUid: (mapa['abogadoUid'] as String?) ?? '',
      clienteUid: clienteUid,
      autor: (mapa['autor'] as String?) ?? '',
      calificacion: calificacionCruda.clamp(1, 5).toInt(),
      comentario: (mapa['comentario'] as String?) ?? '',
      fecha: (mapa['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'abogadoUid': abogadoUid,
      'clienteUid': clienteUid,
      'autor': autor,
      'calificacion': calificacion,
      'comentario': comentario,
      'fecha': FieldValue.serverTimestamp(),
    };
  }
}

/// Valida una reseña antes de enviarla. Devuelve `null` si es válida, o el
/// mensaje de error en español para mostrar al usuario.
String? validarResena({
  required int calificacion,
  required String comentario,
  required String abogadoUid,
  required String clienteUid,
}) {
  if (calificacion < 1 || calificacion > 5) {
    return 'Selecciona una calificación de 1 a 5 estrellas.';
  }
  final comentarioLimpio = comentario.trim();
  if (comentarioLimpio.isEmpty) {
    return 'Escribe un comentario para publicar tu reseña.';
  }
  if (comentarioLimpio.length > 500) {
    return 'El comentario no puede superar los 500 caracteres.';
  }
  if (abogadoUid == clienteUid) {
    return 'No puedes dejar una reseña en tu propio perfil.';
  }
  return null;
}
