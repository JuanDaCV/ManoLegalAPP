import 'error_lexus.dart';
import 'especialidad_abogado.dart';

enum AutorMensajeLexus { usuario, lexus }

enum EstadoMensajeLexus { enviando, enviado, fallido }

/// De dónde viene el texto de un mensaje de Lexus: del modelo o de un texto
/// fijo de la aplicación.
enum OrigenMensajeLexus { modelo, local }

/// Mensaje de la conversación tal como lo ve la persona.
class ModeloMensajeLexus {
  const ModeloMensajeLexus({
    required this.id,
    required this.autor,
    required this.texto,
    required this.momento,
    this.estado = EstadoMensajeLexus.enviado,
    this.origen = OrigenMensajeLexus.local,
    this.areaSugerida,
    this.urgente = false,
    this.error,
    this.enHistorialModelo = false,
    this.textoParaModelo,
  });

  final String id;
  final AutorMensajeLexus autor;

  /// Lo que se muestra en pantalla.
  final String texto;
  final EstadoMensajeLexus estado;
  final OrigenMensajeLexus origen;
  final DateTime momento;

  /// Solo no es nulo cuando la aplicación decidió mostrar el botón de
  /// abogados de esa especialidad.
  final EspecialidadAbogado? areaSugerida;
  final bool urgente;

  /// Tipo de fallo, para un mensaje del usuario que no se pudo enviar.
  final TipoErrorLexus? error;

  /// Si el mensaje se reenvía al modelo como contexto en los turnos
  /// siguientes.
  final bool enHistorialModelo;

  /// Lo que se reenvía al modelo: el JSON crudo que devolvió (Lexus) o el
  /// texto escrito (usuario).
  final String? textoParaModelo;

  ModeloMensajeLexus copyWith({
    EstadoMensajeLexus? estado,
    TipoErrorLexus? error,
    bool quitarError = false,
    bool? enHistorialModelo,
  }) {
    return ModeloMensajeLexus(
      id: id,
      autor: autor,
      texto: texto,
      momento: momento,
      estado: estado ?? this.estado,
      origen: origen,
      areaSugerida: areaSugerida,
      urgente: urgente,
      error: quitarError ? null : (error ?? this.error),
      enHistorialModelo: enHistorialModelo ?? this.enHistorialModelo,
      textoParaModelo: textoParaModelo,
    );
  }
}

/// Turno del historial que se entrega al servicio, sin detalles de vista.
class TurnoLexus {
  const TurnoLexus({required this.esUsuario, required this.texto});

  final bool esUsuario;
  final String texto;
}
