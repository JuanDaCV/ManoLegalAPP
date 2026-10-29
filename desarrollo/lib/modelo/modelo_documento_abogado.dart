/// Rutas de los documentos de verificación de un abogado. Cada ruta apunta a
/// un documento de Firestore (subcolección `documentos`) donde viven los
/// bytes reales, ej. `abogados/{uid}/documentos/cedula`.
class ModeloDocumentoAbogado {
  final String cedulaRuta;
  final String tarjetaProfesionalRuta;
  final String certificadoRnaRuta;
  final String? diplomaRuta;
  final String antecedentesRuta;

  const ModeloDocumentoAbogado({
    required this.cedulaRuta,
    required this.tarjetaProfesionalRuta,
    required this.certificadoRnaRuta,
    this.diplomaRuta,
    required this.antecedentesRuta,
  });

  factory ModeloDocumentoAbogado.fromMap(Map<String, dynamic> mapa) {
    return ModeloDocumentoAbogado(
      cedulaRuta: mapa['cedulaRuta'] as String,
      tarjetaProfesionalRuta: mapa['tarjetaProfesionalRuta'] as String,
      certificadoRnaRuta: mapa['certificadoRnaRuta'] as String,
      diplomaRuta: mapa['diplomaRuta'] as String?,
      antecedentesRuta: mapa['antecedentesRuta'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cedulaRuta': cedulaRuta,
      'tarjetaProfesionalRuta': tarjetaProfesionalRuta,
      'certificadoRnaRuta': certificadoRnaRuta,
      'diplomaRuta': diplomaRuta,
      'antecedentesRuta': antecedentesRuta,
    };
  }
}
