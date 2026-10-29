/// Evidencia adjunta a una PQRS, tal como queda registrada en Firestore.
///
/// Guarda la RUTA del archivo en Storage, nunca una URL de descarga: las
/// evidencias son privadas y solo se leen pasando por las reglas de Storage,
/// igual que los documentos de verificación de los abogados.
class ModeloEvidenciaPqrs {
  final String nombreArchivo;
  final String ruta;
  final String tipoContenido;
  final int tamanio;

  const ModeloEvidenciaPqrs({
    required this.nombreArchivo,
    required this.ruta,
    required this.tipoContenido,
    required this.tamanio,
  });

  factory ModeloEvidenciaPqrs.fromMap(Map<String, dynamic> mapa) {
    return ModeloEvidenciaPqrs(
      nombreArchivo: (mapa['nombreArchivo'] as String?) ?? '',
      ruta: (mapa['ruta'] as String?) ?? '',
      tipoContenido: (mapa['tipoContenido'] as String?) ?? '',
      tamanio: (mapa['tamanio'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombreArchivo': nombreArchivo,
      'ruta': ruta,
      'tipoContenido': tipoContenido,
      'tamanio': tamanio,
    };
  }
}
