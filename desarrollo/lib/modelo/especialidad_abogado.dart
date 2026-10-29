/// Áreas de especialidad disponibles para un abogado.
enum EspecialidadAbogado {
  laboral,
  penal,
  comercial,
  civil,
  familia,
  administrativo,
  inmobiliario,
  otra,
}

/// Traducción legible en español de una [EspecialidadAbogado] y su clave de
/// almacenamiento en Firestore.
extension EspecialidadAbogadoTexto on EspecialidadAbogado {
  String get textoLegible {
    switch (this) {
      case EspecialidadAbogado.laboral:
        return 'Derecho laboral';
      case EspecialidadAbogado.penal:
        return 'Derecho penal';
      case EspecialidadAbogado.comercial:
        return 'Derecho comercial';
      case EspecialidadAbogado.civil:
        return 'Derecho civil';
      case EspecialidadAbogado.familia:
        return 'Derecho de familia';
      case EspecialidadAbogado.administrativo:
        return 'Derecho administrativo';
      case EspecialidadAbogado.inmobiliario:
        return 'Derecho inmobiliario';
      case EspecialidadAbogado.otra:
        return 'Otra especialidad';
    }
  }

  /// Clave estable con la que esta especialidad se guarda en Firestore.
  String get clave => name;
}

/// Convierte la clave almacenada en Firestore a un valor del enum.
/// Devuelve [EspecialidadAbogado.otra] si la clave es nula o desconocida,
/// para tolerar documentos antiguos o valores futuros.
EspecialidadAbogado especialidadDesdeClave(Object? clave) {
  return EspecialidadAbogado.values.firstWhere(
    (valor) => valor.name == clave,
    orElse: () => EspecialidadAbogado.otra,
  );
}
