/// Zonas generales de ubicación de un abogado dentro de Cali y su área
/// metropolitana.
enum UbicacionCali { norteCali, surCali, centroCali, oesteCali, jamundi }

/// Traducción legible en español de una [UbicacionCali] y su clave de
/// almacenamiento en Firestore.
extension UbicacionCaliTexto on UbicacionCali {
  String get textoLegible {
    switch (this) {
      case UbicacionCali.norteCali:
        return 'Norte de Cali';
      case UbicacionCali.surCali:
        return 'Sur de Cali';
      case UbicacionCali.centroCali:
        return 'Centro de Cali';
      case UbicacionCali.oesteCali:
        return 'Oeste de Cali';
      case UbicacionCali.jamundi:
        return 'Jamundí';
    }
  }

  /// Clave estable con la que esta ubicación se guarda en Firestore.
  String get clave => name;
}

/// Convierte la clave almacenada en Firestore a un valor del enum. Devuelve
/// `null` si la clave es nula o desconocida: a diferencia de la
/// especialidad, aquí no existe una categoría "otra" de respaldo.
UbicacionCali? ubicacionDesdeClave(Object? clave) {
  for (final valor in UbicacionCali.values) {
    if (valor.name == clave) return valor;
  }
  return null;
}
