import 'package:cloud_firestore/cloud_firestore.dart';

import 'modelo_evidencia_pqrs.dart';

/// Tipos de PQRS. [valor] es lo que se guarda en Firestore (y lo único que
/// aceptan las reglas); [etiqueta] es lo que se muestra al usuario.
enum TipoPqrs {
  peticion('peticion', 'Petición'),
  queja('queja', 'Queja'),
  reclamo('reclamo', 'Reclamo'),
  solicitud('solicitud', 'Solicitud');

  final String valor;
  final String etiqueta;

  const TipoPqrs(this.valor, this.etiqueta);

  static TipoPqrs? desdeValor(String? valor) {
    for (final tipo in values) {
      if (tipo.valor == valor) return tipo;
    }
    return null;
  }
}

/// Máximo de caracteres de la descripción. Coincide con las reglas.
const int longitudMaximaDescripcionPqrs = 2000;

/// Máximo de evidencias por PQRS. Coincide con las reglas de Firestore y de
/// Storage, que solo admiten los nombres `evidencia_1` a `evidencia_3`.
const int maximoEvidenciasPqrs = 3;

/// Una PQRS (petición, queja, reclamo o solicitud) de un usuario.
class ModeloPqrs {
  final String id;
  final String uid;
  final TipoPqrs tipo;
  final String descripcion;
  final List<ModeloEvidenciaPqrs> evidencias;

  /// Los asigna la Cloud Function después de la creación: son `null`
  /// mientras no ha corrido. El usuario nunca los escribe.
  final String? radicado;
  final String? estado;

  /// `null` solo en el instante en que el documento todavía no tiene la
  /// fecha del servidor.
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const ModeloPqrs({
    required this.id,
    required this.uid,
    required this.tipo,
    required this.descripcion,
    this.evidencias = const [],
    this.radicado,
    this.estado,
    this.creadoEn,
    this.actualizadoEn,
  });

  /// Crea la PQRS a partir de un mapa de Firestore. Es tolerante: un campo
  /// ausente o un tipo desconocido no rompen la interfaz.
  factory ModeloPqrs.fromMap(String id, Map<String, dynamic> mapa) {
    final evidencias = (mapa['evidencias'] as List<dynamic>?) ?? const [];
    return ModeloPqrs(
      id: id,
      uid: (mapa['uid'] as String?) ?? '',
      tipo: TipoPqrs.desdeValor(mapa['tipo'] as String?) ?? TipoPqrs.peticion,
      descripcion: (mapa['descripcion'] as String?) ?? '',
      evidencias: evidencias
          .whereType<Map>()
          .map((mapaEvidencia) => ModeloEvidenciaPqrs.fromMap(Map<String, dynamic>.from(mapaEvidencia)))
          .toList(),
      radicado: mapa['radicado'] as String?,
      estado: mapa['estado'] as String?,
      creadoEn: (mapa['creadoEn'] as Timestamp?)?.toDate(),
      actualizadoEn: (mapa['actualizadoEn'] as Timestamp?)?.toDate(),
    );
  }

  /// Mapa para crear la PQRS: solo los campos que el usuario puede escribir.
  ///
  /// No incluye `radicado` ni `estado`: los escribe la Cloud Function, y las
  /// reglas rechazan la creación si vienen. Las fechas las pone el servidor.
  Map<String, dynamic> toMapCreacion() {
    return {
      'uid': uid,
      'tipo': tipo.valor,
      'descripcion': descripcion,
      'evidencias': evidencias.map((evidencia) => evidencia.toMap()).toList(),
      'creadoEn': FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
  }
}

/// Valida el tipo elegido en el formulario. Devuelve `null` si es válido.
String? validarTipoPqrs(TipoPqrs? tipo) {
  return tipo == null ? 'Selecciona el tipo de PQRS.' : null;
}

/// Valida la descripción del formulario. Devuelve `null` si es válida.
String? validarDescripcionPqrs(String? descripcion) {
  final limpia = descripcion?.trim() ?? '';
  if (limpia.isEmpty) return 'Describe tu solicitud.';
  if (limpia.length > longitudMaximaDescripcionPqrs) {
    return 'La descripción no puede superar los $longitudMaximaDescripcionPqrs caracteres.';
  }
  return null;
}
