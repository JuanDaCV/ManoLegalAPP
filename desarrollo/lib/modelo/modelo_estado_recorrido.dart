/// Estado del recorrido guiado de un cliente en este dispositivo.
///
/// Solo [completado] y [omitido] se guardan: [noVisto] es la ausencia de dato.
/// Así, un valor desconocido (por ejemplo, escrito por otra versión de la
/// app) se lee como [noVisto] y el recorrido se vuelve a mostrar en lugar de
/// quedar bloqueado para siempre.
enum EstadoRecorrido {
  noVisto,
  completado,
  omitido;

  /// Interpreta el texto guardado. `null` o un valor no reconocido es
  /// [noVisto].
  static EstadoRecorrido desdeTexto(String? valor) {
    return switch (valor) {
      'completado' => EstadoRecorrido.completado,
      'omitido' => EstadoRecorrido.omitido,
      _ => EstadoRecorrido.noVisto,
    };
  }

  /// Texto que se guarda, o `null` si no hay nada que guardar ([noVisto]).
  String? get comoTexto {
    return switch (this) {
      EstadoRecorrido.noVisto => null,
      EstadoRecorrido.completado => 'completado',
      EstadoRecorrido.omitido => 'omitido',
    };
  }
}
