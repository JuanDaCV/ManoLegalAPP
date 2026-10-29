import 'modelo_mensaje_lexus.dart';

/// Estado de una conversación guardada. Solo una [activa] se puede retomar:
/// [cerrada] es la que la persona dejó con «Nueva conversación» y [expirada]
/// la que venció por falta de actividad.
enum EstadoConversacionLexus { activa, cerrada, expirada }

/// Mensaje tal como se guardó: el mensaje y su posición en la conversación.
///
/// La posición (`orden`) es la que fija el orden al cargar; la hora no sirve,
/// porque dos mensajes de un mismo lote comparten marca de tiempo.
class MensajeGuardadoLexus {
  const MensajeGuardadoLexus({required this.mensaje, required this.orden});

  final ModeloMensajeLexus mensaje;
  final int orden;
}

/// Conversación leída de Firestore, lista para que el controlador la retome.
class ConversacionLexusGuardada {
  const ConversacionLexusGuardada({
    required this.id,
    required this.estado,
    required this.turnos,
    required this.actualizadoEn,
    required this.mensajes,
  });

  final String id;
  final EstadoConversacionLexus estado;

  /// Turnos ya respondidos: de aquí salen el aviso y el límite al retomar.
  final int turnos;

  /// Última actividad según el servidor. Es nula mientras el servidor aún no
  /// confirma una escritura reciente de este mismo dispositivo.
  final DateTime? actualizadoEn;

  /// Ordenados por [MensajeGuardadoLexus.orden].
  final List<MensajeGuardadoLexus> mensajes;
}
