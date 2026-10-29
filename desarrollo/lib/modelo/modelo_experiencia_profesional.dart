/// Un ítem de experiencia profesional dentro del perfil de un abogado (por
/// ejemplo: un título académico, una especialización o un logro concreto),
/// mostrado en la línea de tiempo de la sección "Experiencia".
class ModeloExperienciaProfesional {
  final String id;
  final String titulo;
  final String? detalle;
  final String? anio;

  const ModeloExperienciaProfesional({
    required this.id,
    required this.titulo,
    this.detalle,
    this.anio,
  });

  /// Crea la experiencia a partir de un mapa de Firestore. Es tolerante:
  /// nunca lanza una excepción por un campo ausente.
  factory ModeloExperienciaProfesional.fromMap(Map<String, dynamic> mapa) {
    return ModeloExperienciaProfesional(
      id: (mapa['id'] as String?) ?? '',
      titulo: (mapa['titulo'] as String?) ?? '',
      detalle: mapa['detalle'] as String?,
      anio: mapa['anio'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'detalle': detalle,
      'anio': anio,
    };
  }
}
