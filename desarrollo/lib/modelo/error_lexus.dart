enum TipoErrorLexus {
  sinConexion,
  tiempoAgotado,
  cuotaExcedida,
  appCheckRechazado,
  modeloNoDisponible,
  respuestaInvalida,
  bloqueoSeguridad,
  sesionExpirada,
  interno,
}

/// Fallo al consultar a Lexus. Solo lleva el tipo: no guarda texto del error
/// para que ningún mensaje del servicio ni de la conversación llegue a un
/// registro.
class ErrorLexus implements Exception {
  const ErrorLexus(this.tipo);

  final TipoErrorLexus tipo;

  @override
  String toString() => 'ErrorLexus(${tipo.name})';
}
