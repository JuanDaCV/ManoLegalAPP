import '../modelo/modelo_mensaje_lexus.dart';

/// Acceso al modelo de lenguaje de Lexus.
///
/// Es una interfaz para que las pruebas usen un doble y para que ningún
/// widget ni controlador vea objetos del SDK: la única implementación real
/// está en `servicio_lexus_real.dart`.
abstract interface class ServicioLexus {
  /// Envía [mensaje] con el [historial] previo y devuelve el JSON crudo de la
  /// respuesta. Todo fallo se lanza como `ErrorLexus`.
  Future<String> enviar({
    required List<TurnoLexus> historial,
    required String mensaje,
  });
}
