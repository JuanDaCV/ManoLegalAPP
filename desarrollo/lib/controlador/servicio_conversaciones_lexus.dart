import '../modelo/error_lexus.dart';
import '../modelo/modelo_conversacion_lexus.dart';
import '../modelo/modelo_mensaje_lexus.dart';

/// Historial de las conversaciones con Lexus de la persona con sesión.
///
/// Es una interfaz para que las pruebas usen un doble y para que ningún
/// controlador ni widget vea objetos de Firestore: la única implementación
/// real está en `servicio_conversaciones_lexus_real.dart`.
///
/// Cada escritura es independiente y el controlador no las espera antes de
/// llamar al modelo. Todo fallo se lanza tal cual; el controlador decide qué
/// hacer con él.
abstract interface class ServicioConversacionesLexus {
  /// La conversación con la actividad más reciente, con sus mensajes en
  /// orden, o `null` si la persona aún no tiene ninguna.
  Future<ConversacionLexusGuardada?> cargarMasReciente();

  /// Identificadores nuevos. No escriben nada ni dependen de la sesión.
  String nuevoIdConversacion();
  String nuevoIdMensaje();

  /// Guarda el mensaje de la persona al enviarlo, con estado `enviando`.
  /// Si la [conversacionNueva] aún no existe, la crea en el mismo lote (con
  /// [titulo]); si no, solo actualiza su última actividad.
  Future<void> guardarEnvio({
    required String conversacionId,
    required bool conversacionNueva,
    String? titulo,
    required String mensajeId,
    required String texto,
    required int orden,
  });

  /// Cierra el turno en un solo lote: el mensaje de la persona pasa a
  /// `enviado`, se guarda [respuesta] (de Lexus) y suben los turnos en uno.
  Future<void> guardarRespuesta({
    required String conversacionId,
    required String mensajeUsuarioId,
    required bool usuarioEnHistorialModelo,
    required ModeloMensajeLexus respuesta,
    required int orden,
  });

  /// Marca el mensaje de la persona como `fallido`.
  Future<void> guardarFallo({
    required String conversacionId,
    required String mensajeId,
    required TipoErrorLexus tipo,
  });

  /// Reenvía un mensaje ya guardado: el mismo documento, de nuevo en
  /// `enviando` y con un [orden] nuevo, que lo lleva al final.
  Future<void> guardarReintento({
    required String conversacionId,
    required String mensajeId,
    required int orden,
  });

  /// La persona dejó la conversación con «Nueva conversación».
  Future<void> cerrar(String conversacionId);

  /// La conversación venció por falta de actividad.
  Future<void> expirar(String conversacionId);
}
