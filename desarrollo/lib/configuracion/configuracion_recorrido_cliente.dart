import '../modelo/modelo_paso_recorrido.dart';
import '../modelo/modelo_recorrido.dart';

/// Pasos, textos y tiempos de los recorridos guiados del cliente: Inicio,
/// Cómo funciona y Lexus. PQRS es compartido con el abogado y vive en
/// `ConfiguracionRecorridoPqrs`.
///
/// Los textos describen solo funciones que existen hoy en cada sección. El
/// «Paso X de N» cuenta únicamente los pasos que señalan algo en pantalla; la
/// bienvenida y el cierre no cuentan.
abstract final class ConfiguracionRecorridoCliente {
  /// Recorrido de Inicio: el primero que existió. Conserva su clave, sus
  /// pasos y sus esperas.
  static const ModeloRecorrido inicio = ModeloRecorrido(
    id: 'cliente.inicio',
    prefijoClave: prefijoClave,
    pasos: pasos,
    marcaInicial: MarcaRecorridoId.buscador,
    marcaCargando: MarcaRecorridoId.cargandoResultados,
    esperaInicial: esperaBuscador,
    esperaCarga: esperaResultados,
  );

  /// Recorrido de Cómo funciona. La sección no dibuja nada hasta que se ve
  /// por primera vez; la espera inicial cubre ese primer cuadro.
  static const ModeloRecorrido comoFunciona = ModeloRecorrido(
    id: 'cliente.como_funciona',
    prefijoClave: 'manolegal.recorrido.cliente.como_funciona.v1.',
    pasos: pasosComoFunciona,
    marcaInicial: MarcaRecorridoId.comoFuncionaEncabezado,
    esperaInicial: esperaBuscador,
    esperaCarga: esperaResultados,
  );

  /// Recorrido de Lexus. Espera a que termine de cargarse la conversación
  /// guardada: de eso depende que haya introducción con sugerencias.
  static const ModeloRecorrido lexus = ModeloRecorrido(
    id: 'cliente.lexus',
    prefijoClave: 'manolegal.recorrido.cliente.lexus.v1.',
    pasos: pasosLexus,
    marcaInicial: MarcaRecorridoId.lexusAviso,
    marcaCargando: MarcaRecorridoId.lexusCargando,
    esperaInicial: Duration(seconds: 15),
    esperaCarga: Duration(seconds: 15),
  );

  /// Prefijo de la clave con la que se recuerda, por usuario y por
  /// dispositivo, que el recorrido ya se vio. La `v1` permite volver a
  /// mostrarlo a todos si algún día cambia de forma sustancial.
  static const String prefijoClave = 'manolegal.recorrido.cliente.v1.';

  /// Cuánto se espera a que Inicio esté activo y dibujado antes de renunciar a
  /// mostrar el recorrido. Si el cliente se fue a otra pestaña, no aparece.
  static const Duration esperaBuscador = Duration(seconds: 8);

  /// Cuánto se espera a que terminen de cargarse los resultados para saber si
  /// hay tarjetas que señalar.
  static const Duration esperaResultados = Duration(seconds: 5);

  /// Cada cuánto se consulta si la vista ya está lista.
  static const Duration intervaloSondeo = Duration(milliseconds: 150);

  static const List<ModeloPasoRecorrido> pasos = [
    ModeloPasoRecorrido(
      id: 'bienvenida',
      tipo: TipoPasoRecorrido.bienvenida,
      titulo: 'Bienvenido a ManoLegal',
      descripcion: 'Te mostraremos rápidamente cómo encontrar y conocer abogados dentro de la plataforma.',
    ),
    ModeloPasoRecorrido(
      id: 'buscador',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.buscador,
      titulo: 'Busca abogados',
      descripcion: 'Aquí puedes buscar abogados por nombre, especialidad o ubicación, según la necesidad legal que tengas.',
    ),
    ModeloPasoRecorrido(
      id: 'filtros',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.filtros,
      titulo: 'Filtra los resultados',
      descripcion: 'Utiliza los filtros para encontrar opciones que se ajusten mejor a tu búsqueda: especialidad, ubicación, calificación mínima y solo abogados verificados.',
      descripcionMovil: 'Toca «Filtros» para elegir especialidad, ubicación, calificación mínima y si ver solo abogados verificados.',
    ),
    ModeloPasoRecorrido(
      id: 'tarjeta',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.tarjeta,
      titulo: 'Conoce a cada abogado',
      descripcion: 'Aquí puedes consultar rápidamente la información principal de cada abogado: especialidad, calificación, ubicación y tarifa, si la publica.',
    ),
    ModeloPasoRecorrido(
      id: 'verPerfil',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.verPerfil,
      requiereMarca: MarcaRecorridoId.tarjeta,
      titulo: 'Ver perfil',
      descripcion:
          'Desde aquí puedes consultar el perfil completo del abogado.',
    ),
    ModeloPasoRecorrido(
      id: 'verificacion',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.insignia,
      siFaltaMarca: SiFaltaMarca.centrar,
      titulo: 'Abogados verificados',
      descripcion: 'Los abogados que aparecen como verificados han pasado por el proceso de verificación administrado por ManoLegal. Es una revisión de sus documentos, no una recomendación.',
      descripcionSinMarca: 'Los abogados que aparecen como verificados han pasado por el proceso de verificación administrado por ManoLegal. Los reconocerás por la insignia «Verificado» junto a su nombre en los resultados.',
    ),
    ModeloPasoRecorrido(
      id: 'cierre',
      tipo: TipoPasoRecorrido.cierre,
      titulo: 'Listo',
      descripcion: 'Ya conoces las funciones principales para comenzar a utilizar ManoLegal.',
    ),
  ];

  /// Cómo funciona: el encabezado, el índice de capítulos y un capítulo. El
  /// recorrido nunca reproduce un video; solo explica dónde tocar.
  static const List<ModeloPasoRecorrido> pasosComoFunciona = [
    ModeloPasoRecorrido(
      id: 'bienvenida',
      tipo: TipoPasoRecorrido.bienvenida,
      titulo: 'Aprende a usar ManoLegal',
      descripcion: 'Te mostramos cómo está organizada esta guía en video para que encuentres rápido lo que necesitas.',
    ),
    ModeloPasoRecorrido(
      id: 'encabezado',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.comoFuncionaEncabezado,
      titulo: 'Una guía en seis videos',
      descripcion: 'Son seis videos breves: qué es ManoLegal, cómo encontrar y elegir un abogado, qué significa la verificación y cómo contactarlo.',
    ),
    ModeloPasoRecorrido(
      id: 'indice',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.comoFuncionaIndice,
      titulo: 'Ve directo a un capítulo',
      descripcion: 'Usa el índice de capítulos para saltar al video que te interesa. Puedes verlos en el orden que quieras.',
    ),
    ModeloPasoRecorrido(
      id: 'capitulo',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.comoFuncionaCapitulo,
      titulo: 'Mira cada capítulo',
      descripcion: 'Cada capítulo tiene su video y un resumen. Toca la portada cuando quieras reproducirlo.',
    ),
    ModeloPasoRecorrido(
      id: 'cierre',
      tipo: TipoPasoRecorrido.cierre,
      titulo: 'Listo',
      descripcion: 'Ya sabes cómo usar la guía. Vuelve cuando quieras repasar un tema.',
    ),
  ];

  /// Lexus: qué es, cómo empezar y cómo escribir o dictar. Ningún paso envía,
  /// graba ni borra nada; solo señala.
  static const List<ModeloPasoRecorrido> pasosLexus = [
    ModeloPasoRecorrido(
      id: 'bienvenida',
      tipo: TipoPasoRecorrido.bienvenida,
      titulo: 'Conoce a Lexus',
      descripcion: 'Lexus te ayuda a entender mejor una situación jurídica y te orienta dentro de ManoLegal. Te mostramos cómo usarlo.',
    ),
    ModeloPasoRecorrido(
      id: 'aviso',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.lexusAviso,
      titulo: 'Orientación, no asesoría',
      descripcion: 'Lexus es una inteligencia artificial de orientación inicial. No es un abogado, puede equivocarse y no reemplaza la asesoría de un profesional.',
    ),
    ModeloPasoRecorrido(
      id: 'sugerencias',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.lexusSugerencias,
      titulo: 'Empieza con una sugerencia',
      descripcion: 'Si no sabes cómo empezar, toca una de estas frases: se copia en el campo de consulta y puedes editarla antes de enviarla.',
    ),
    ModeloPasoRecorrido(
      id: 'entrada',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.lexusEntrada,
      titulo: 'Escribe tu consulta',
      descripcion: 'Cuéntale a Lexus qué sucede con tus palabras. No compartas contraseñas, números de tarjetas ni datos que no sean necesarios.',
    ),
    ModeloPasoRecorrido(
      id: 'dictado',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.lexusDictado,
      titulo: 'Dicta en lugar de escribir',
      descripcion: 'Con el micrófono puedes dictar tu consulta. El texto queda en el campo para que lo revises; nada se envía hasta que tú lo decidas.',
    ),
    ModeloPasoRecorrido(
      id: 'nuevaConversacion',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.lexusNuevaConversacion,
      titulo: 'Empieza de nuevo',
      descripcion: 'Cuando ya tengas una conversación, «Nueva conversación» te permite empezar de cero. La anterior queda archivada en tu cuenta.',
    ),
    ModeloPasoRecorrido(
      id: 'cierre',
      tipo: TipoPasoRecorrido.cierre,
      titulo: 'Listo',
      descripcion: 'Ya puedes consultarle a Lexus lo que necesites.',
    ),
  ];
}
