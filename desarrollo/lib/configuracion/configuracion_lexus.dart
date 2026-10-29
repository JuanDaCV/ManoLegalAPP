/// Parámetros de Lexus, el asistente jurídico de ManoLegal.
abstract final class ConfiguracionLexus {
  /// Identificador del modelo, centralizado aquí para poder cambiarlo sin
  /// tocar código de lógica ni de vista. Se eligió un modelo "flash-lite" por
  /// costo y porque admite respuesta estructurada con esquema, que Lexus
  /// necesita.
  static const String modelo = 'gemini-3.5-flash-lite';

  static const int largoMaximoMensaje = 2000;

  /// Turnos a partir de los cuales se sugiere iniciar una conversación nueva.
  static const int turnosAvisoConversacionLarga = 24;

  /// Turnos máximos por conversación. Acota el costo y el tamaño del
  /// historial que se reenvía al modelo en cada consulta.
  static const int turnosMaximos = 30;

  static const Duration intervaloMinimoEntreEnvios = Duration(
    milliseconds: 1500,
  );

  /// La librería no trae tiempo límite propio.
  static const Duration tiempoLimiteRespuesta = Duration(seconds: 45);

  static const int maxTokensSalida = 2048;

  static const int abogadosSugeridos = 3;

  // Dictado por voz. El audio se graba en memoria, se transcribe con el mismo
  // modelo y nunca se guarda: ni en disco, ni en Firestore, ni en Storage.

  /// Duración máxima de un dictado. Al cumplirse, la grabación se detiene sola
  /// y se transcribe; nunca se envía.
  static const Duration duracionMaximaAudio = Duration(minutes: 2);

  /// Una grabación más corta se descarta sin consultar al modelo: casi siempre
  /// es un toque accidental.
  static const Duration duracionMinimaAudio = Duration(seconds: 1);

  /// 16 kHz mono basta para voz y mantiene el audio pequeño (unos 3,8 MB en
  /// los 2 minutos de [duracionMaximaAudio]).
  static const int frecuenciaMuestreoAudio = 16000;

  /// Como el chat, la librería no trae tiempo límite propio.
  static const Duration tiempoLimiteTranscripcion = Duration(seconds: 45);

  /// Margen amplio para unos 2 minutos de habla (el texto resultante ocupa
  /// bastante menos).
  static const int maxTokensTranscripcion = 1024;

  /// Las respuestas del modelo más largas se recortan en una palabra y se
  /// cierran con «…».
  static const int largoMaximoRespuesta = 4000;

  /// Tiempo sin actividad a partir del cual una conversación guardada ya no se
  /// retoma. 24 h se queda corto (alguien consulta de noche y vuelve la tarde
  /// siguiente) y con 7 días se arrastrarían relatos viejos, que además se
  /// reenvían al modelo en cada turno y encarecen cada consulta.
  static const Duration vigenciaConversacion = Duration(hours: 48);

  /// Caracteres que se toman del primer mensaje como título de la conversación
  /// guardada; si se recorta, se añade «…».
  static const int largoMaximoTitulo = 60;

  // Decisiones de alcance de la versión 1 (no son parámetros):
  //
  // - Sin búsqueda de Google (grounding): no garantiza que la ley citada sea
  //   la correcta, añade obligaciones de uso y costo, y los resultados web no
  //   son una base jurídica oficial.
  // - Audio: el dictado por voz ya está implementado. El audio se transcribe
  //   y nunca se guarda; el texto resultante se añade al campo de escritura y
  //   la persona lo revisa y lo envía a mano.
  // - Documentos: pendiente (Fase 2). Se dejan para cuando el chat de texto,
  //   App Check y la respuesta estructurada estén estables.
  // - El historial se guarda por cliente en `clientes/{uid}/conversacionesLexus`
  //   y solo su dueño puede leerlo: las reglas excluyen al administrador de la
  //   app. Se retoma la conversación activa con actividad en las últimas 48 h
  //   ([vigenciaConversacion]). En esta versión no se puede borrar ni hay una
  //   lista de conversaciones anteriores.
}
