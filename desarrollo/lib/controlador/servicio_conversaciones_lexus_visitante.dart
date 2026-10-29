import '../modelo/error_lexus.dart';
import '../modelo/modelo_conversacion_lexus.dart';
import '../modelo/modelo_mensaje_lexus.dart';
import 'servicio_conversaciones_lexus.dart';

/// Historial de Lexus para el visitante web, que no tiene sesión ni cuenta.
///
/// No hay a quién guardarle nada: la carga devuelve `null` (sin conversación
/// que retomar), así el chat arranca vacío y nunca muestra el aviso de
/// historial no disponible, que sería falso para alguien que aún no tiene
/// cuenta. Nunca toca Firebase.
///
/// Las escrituras no se alcanzan: en el modo visitante el envío se intercepta
/// antes de llegar al controlador y pide crear una cuenta. Si algún cambio
/// futuro las alcanzara, lanzan en lugar de fingir que guardaron; el
/// historial lo trata como cualquier fallo y la conversación sigue solo en
/// memoria.
class ServicioConversacionesLexusVisitante
    implements ServicioConversacionesLexus {
  static const String _sinSesion =
      'Sin sesión: los visitantes no guardan conversaciones.';

  /// Los identificadores no escriben nada (ver la interfaz), así que se dan
  /// locales en vez de fallar: un fallo aquí marcaría el historial como no
  /// disponible y mostraría el aviso.
  int _contador = 0;

  @override
  Future<ConversacionLexusGuardada?> cargarMasReciente() async => null;

  @override
  String nuevoIdConversacion() => 'visitante-conversacion-${++_contador}';

  @override
  String nuevoIdMensaje() => 'visitante-mensaje-${++_contador}';

  @override
  Future<void> guardarEnvio({
    required String conversacionId,
    required bool conversacionNueva,
    String? titulo,
    required String mensajeId,
    required String texto,
    required int orden,
  }) => throw StateError(_sinSesion);

  @override
  Future<void> guardarRespuesta({
    required String conversacionId,
    required String mensajeUsuarioId,
    required bool usuarioEnHistorialModelo,
    required ModeloMensajeLexus respuesta,
    required int orden,
  }) => throw StateError(_sinSesion);

  @override
  Future<void> guardarFallo({
    required String conversacionId,
    required String mensajeId,
    required TipoErrorLexus tipo,
  }) => throw StateError(_sinSesion);

  @override
  Future<void> guardarReintento({
    required String conversacionId,
    required String mensajeId,
    required int orden,
  }) => throw StateError(_sinSesion);

  @override
  Future<void> cerrar(String conversacionId) => throw StateError(_sinSesion);

  @override
  Future<void> expirar(String conversacionId) => throw StateError(_sinSesion);
}
