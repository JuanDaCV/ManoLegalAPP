import '../modelo/modelo_paso_recorrido.dart';
import '../modelo/modelo_recorrido.dart';
import 'configuracion_recorrido_cliente.dart';

/// Recorridos guiados del modo visitante (web, sin cuenta): Inicio, Cómo
/// funciona, Lexus y PQRS.
///
/// Usan las mismas marcas que los del cliente, porque las secciones son las
/// mismas, pero sus textos describen solo lo que un visitante puede hacer:
/// explorar libremente y crear una cuenta para ver perfiles completos, enviar
/// consultas a Lexus o radicar una PQRS. Sus claves son propias
/// (`manolegal.recorrido.visitante.…`): no leen ni escriben el estado de los
/// recorridos de clientes o abogados.
abstract final class ConfiguracionRecorridoVisitante {
  /// Sufijo fijo de la clave en el almacén local del dispositivo. No es un
  /// usuario ni una sesión: el visitante no tiene cuenta, y el estado de sus
  /// recorridos se recuerda por navegador.
  static const String claveDispositivo = 'visitante';

  static const ModeloRecorrido inicio = ModeloRecorrido(
    id: 'visitante.inicio',
    prefijoClave: 'manolegal.recorrido.visitante.v1.',
    pasos: pasosInicio,
    marcaInicial: MarcaRecorridoId.buscador,
    marcaCargando: MarcaRecorridoId.cargandoResultados,
    esperaInicial: ConfiguracionRecorridoCliente.esperaBuscador,
    esperaCarga: ConfiguracionRecorridoCliente.esperaResultados,
  );

  static const ModeloRecorrido comoFunciona = ModeloRecorrido(
    id: 'visitante.como_funciona',
    prefijoClave: 'manolegal.recorrido.visitante.como_funciona.v1.',
    pasos: pasosComoFunciona,
    marcaInicial: MarcaRecorridoId.comoFuncionaEncabezado,
    esperaInicial: ConfiguracionRecorridoCliente.esperaBuscador,
    esperaCarga: ConfiguracionRecorridoCliente.esperaResultados,
  );

  static const ModeloRecorrido lexus = ModeloRecorrido(
    id: 'visitante.lexus',
    prefijoClave: 'manolegal.recorrido.visitante.lexus.v1.',
    pasos: pasosLexus,
    marcaInicial: MarcaRecorridoId.lexusAviso,
    marcaCargando: MarcaRecorridoId.lexusCargando,
    esperaInicial: ConfiguracionRecorridoCliente.esperaBuscador,
    esperaCarga: ConfiguracionRecorridoCliente.esperaResultados,
  );

  static const ModeloRecorrido pqrs = ModeloRecorrido(
    id: 'visitante.pqrs',
    prefijoClave: 'manolegal.recorrido.visitante.pqrs.v1.',
    pasos: pasosPqrs,
    marcaInicial: MarcaRecorridoId.pqrsCategorias,
    esperaInicial: ConfiguracionRecorridoCliente.esperaBuscador,
    esperaCarga: ConfiguracionRecorridoCliente.esperaResultados,
  );

  static const List<ModeloRecorrido> todos = [inicio, comoFunciona, lexus, pqrs];

  /// Inicio: el directorio se explora sin cuenta; el perfil completo la pide.
  static const List<ModeloPasoRecorrido> pasosInicio = [
    ModeloPasoRecorrido(
      id: 'bienvenida',
      tipo: TipoPasoRecorrido.bienvenida,
      titulo: 'Bienvenido a ManoLegal',
      descripcion: 'Puedes explorar ManoLegal sin crear una cuenta. Te mostramos rápidamente cómo encontrar abogados.',
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
      descripcion: 'Utiliza los filtros para elegir especialidad, ubicación, calificación mínima y si ver solo abogados verificados.',
      descripcionMovil: 'Toca «Filtros» para elegir especialidad, ubicación, calificación mínima y si ver solo abogados verificados.',
    ),
    ModeloPasoRecorrido(
      id: 'tarjeta',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.tarjeta,
      titulo: 'Conoce a cada abogado',
      descripcion: 'Cada tarjeta muestra la información principal del abogado: especialidad, calificación, ubicación y tarifa, si la publica.',
    ),
    ModeloPasoRecorrido(
      id: 'verPerfil',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.verPerfil,
      requiereMarca: MarcaRecorridoId.tarjeta,
      titulo: 'Ver perfil',
      descripcion: 'Para ver el perfil completo y los datos de contacto del abogado, inicia sesión o crea una cuenta.',
    ),
    ModeloPasoRecorrido(
      id: 'verificacion',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.insignia,
      siFaltaMarca: SiFaltaMarca.centrar,
      titulo: 'Abogados verificados',
      descripcion: 'Los abogados que aparecen como verificados han pasado por el proceso de verificación administrado por ManoLegal. Es una revisión de sus documentos, no una recomendación.',
      descripcionSinMarca: 'Los abogados que aparecen como verificados han pasado por el proceso de verificación administrado por ManoLegal. Los reconocerás por la insignia «Verificado» junto a su nombre.',
    ),
    ModeloPasoRecorrido(
      id: 'cierre',
      tipo: TipoPasoRecorrido.cierre,
      titulo: 'Listo',
      descripcion: 'Ya puedes explorar el directorio. Revisa también «Cómo funciona», Lexus y PQRS en la barra de navegación.',
    ),
  ];

  /// Cómo funciona: la guía en video está abierta para todos.
  static const List<ModeloPasoRecorrido> pasosComoFunciona = [
    ModeloPasoRecorrido(
      id: 'bienvenida',
      tipo: TipoPasoRecorrido.bienvenida,
      titulo: 'Aprende a usar ManoLegal',
      descripcion: 'Esta guía en video está disponible sin cuenta. Te mostramos cómo está organizada.',
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

  /// Lexus: se conoce sin cuenta; enviar o dictar una consulta la pide.
  static const List<ModeloPasoRecorrido> pasosLexus = [
    ModeloPasoRecorrido(
      id: 'bienvenida',
      tipo: TipoPasoRecorrido.bienvenida,
      titulo: 'Conoce a Lexus',
      descripcion: 'Lexus te ayuda a entender mejor una situación jurídica y te orienta dentro de ManoLegal. Te mostramos cómo funciona.',
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
      descripcion: 'Si no sabes cómo empezar, toca una de estas frases: se copia en el campo de consulta y puedes editarla.',
    ),
    ModeloPasoRecorrido(
      id: 'entrada',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.lexusEntrada,
      titulo: 'Escribe tu consulta',
      descripcion: 'Cuéntale a Lexus qué sucede con tus palabras. Para enviar la consulta, inicia sesión o crea una cuenta.',
    ),
    ModeloPasoRecorrido(
      id: 'dictado',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.lexusDictado,
      titulo: 'Dicta en lugar de escribir',
      descripcion: 'Con una cuenta también puedes dictar tu consulta con el micrófono y revisarla antes de enviarla.',
    ),
    ModeloPasoRecorrido(
      id: 'cierre',
      tipo: TipoPasoRecorrido.cierre,
      titulo: 'Listo',
      descripcion: 'Cuando crees tu cuenta podrás consultarle a Lexus lo que necesites.',
    ),
  ];

  /// PQRS: se conoce el proceso; radicar pide cuenta.
  static const List<ModeloPasoRecorrido> pasosPqrs = [
    ModeloPasoRecorrido(
      id: 'bienvenida',
      tipo: TipoPasoRecorrido.bienvenida,
      titulo: 'PQRS',
      descripcion: 'Aquí se envían a ManoLegal peticiones, quejas, reclamos y solicitudes. Te mostramos cómo funciona.',
    ),
    ModeloPasoRecorrido(
      id: 'categorias',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.pqrsCategorias,
      titulo: 'Elige una categoría',
      descripcion: 'Cada categoría corresponde a un tipo de solicitud: Peticiones, Quejas, Reclamos o Solicitudes.',
    ),
    ModeloPasoRecorrido(
      id: 'radicar',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.pqrsRadicar,
      titulo: 'Radica una PQRS',
      descripcion: 'Para radicar una PQRS necesitas una cuenta: inicia sesión o crea una gratis.',
    ),
    ModeloPasoRecorrido(
      id: 'radicado',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.pqrsNotaRadicado,
      titulo: 'Número de radicado',
      descripcion: 'Cada PQRS recibe un número de radicado para hacerle seguimiento.',
    ),
    ModeloPasoRecorrido(
      id: 'cierre',
      tipo: TipoPasoRecorrido.cierre,
      titulo: 'Listo',
      descripcion: 'Ya sabes cómo funcionan las PQRS en ManoLegal.',
    ),
  ];
}
