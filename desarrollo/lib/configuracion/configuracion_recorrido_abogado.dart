import '../modelo/modelo_paso_recorrido.dart';
import '../modelo/modelo_recorrido.dart';
import 'configuracion_recorrido_cliente.dart';

/// Recorridos guiados del abogado: Inicio, Mi perfil y Panel. PQRS es
/// compartido con el cliente y vive en `ConfiguracionRecorridoPqrs`.
///
/// Los textos describen solo funciones que existen hoy y hablan al abogado
/// como colega: en Inicio consulta a otros profesionales, no busca a quién
/// contratar.
abstract final class ConfiguracionRecorridoAbogado {
  /// Mi perfil y Panel dependen de la carga del perfil desde Firestore: se
  /// espera más que en las secciones que se dibujan de inmediato.
  static const Duration esperaPerfil = Duration(seconds: 15);

  /// Inicio usa el mismo buscador que el cliente, con sus mismas marcas y
  /// esperas.
  static const ModeloRecorrido inicio = ModeloRecorrido(
    id: 'abogado.inicio',
    prefijoClave: 'manolegal.recorrido.abogado.inicio.v1.',
    pasos: pasosInicio,
    marcaInicial: MarcaRecorridoId.buscador,
    marcaCargando: MarcaRecorridoId.cargandoResultados,
    esperaInicial: ConfiguracionRecorridoCliente.esperaBuscador,
    esperaCarga: ConfiguracionRecorridoCliente.esperaResultados,
  );

  static const ModeloRecorrido miPerfil = ModeloRecorrido(
    id: 'abogado.mi_perfil',
    prefijoClave: 'manolegal.recorrido.abogado.mi_perfil.v1.',
    pasos: pasosMiPerfil,
    marcaInicial: MarcaRecorridoId.perfilLeyenda,
    esperaInicial: esperaPerfil,
    esperaCarga: esperaPerfil,
  );

  static const ModeloRecorrido panel = ModeloRecorrido(
    id: 'abogado.panel',
    prefijoClave: 'manolegal.recorrido.abogado.panel.v1.',
    pasos: pasosPanel,
    marcaInicial: MarcaRecorridoId.panelEstado,
    esperaInicial: esperaPerfil,
    esperaCarga: esperaPerfil,
  );

  /// Como el de Inicio del cliente, con palabras de colega. Sin resultados,
  /// la tarjeta y «Ver perfil» se omiten y la verificación va centrada.
  static const List<ModeloPasoRecorrido> pasosInicio = [
    ModeloPasoRecorrido(
      id: 'bienvenida',
      tipo: TipoPasoRecorrido.bienvenida,
      titulo: 'Bienvenido a ManoLegal',
      descripcion: 'Te mostramos cómo consultar los perfiles de otros profesionales registrados en la plataforma.',
    ),
    ModeloPasoRecorrido(
      id: 'buscador',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.buscador,
      titulo: 'Busca colegas',
      descripcion: 'Aquí puedes buscar abogados por nombre, especialidad o ubicación, incluidos colegas de otras especialidades.',
    ),
    ModeloPasoRecorrido(
      id: 'filtros',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.filtros,
      titulo: 'Filtra los resultados',
      descripcion: 'Acota la búsqueda por especialidad, ubicación y calificación mínima. «Solo abogados verificados» viene activado; desactívalo para ver a todos.',
      descripcionMovil: 'Toca «Filtros» para elegir especialidad, ubicación y calificación mínima. «Solo abogados verificados» viene activado.',
    ),
    ModeloPasoRecorrido(
      id: 'tarjeta',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.tarjeta,
      titulo: 'Perfiles de colegas',
      descripcion: 'Cada tarjeta resume la información principal del abogado: especialidad, calificación, ubicación y tarifa, si la publica.',
    ),
    ModeloPasoRecorrido(
      id: 'verPerfil',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.verPerfil,
      requiereMarca: MarcaRecorridoId.tarjeta,
      titulo: 'Ver perfil',
      descripcion: 'Abre el perfil completo, tal como lo ven los clientes. Como abogado, allí no puedes dejar reseñas.',
    ),
    ModeloPasoRecorrido(
      id: 'verificacion',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.insignia,
      siFaltaMarca: SiFaltaMarca.centrar,
      titulo: 'Abogados verificados',
      descripcion: 'La insignia «Verificado» indica que ManoLegal revisó los documentos del abogado. Es una revisión documental, no una recomendación.',
      descripcionSinMarca: 'Los abogados verificados llevan la insignia «Verificado» junto a su nombre. Indica que ManoLegal revisó sus documentos; no es una recomendación.',
    ),
    ModeloPasoRecorrido(
      id: 'cierre',
      tipo: TipoPasoRecorrido.cierre,
      titulo: 'Listo',
      descripcion: 'Ya sabes cómo consultar los perfiles de tus colegas en ManoLegal.',
    ),
  ];

  /// Mi perfil: qué se edita y dónde. El recorrido no abre editores ni cambia
  /// la foto; solo señala.
  static const List<ModeloPasoRecorrido> pasosMiPerfil = [
    ModeloPasoRecorrido(
      id: 'bienvenida',
      tipo: TipoPasoRecorrido.bienvenida,
      titulo: 'Tu perfil profesional',
      descripcion: 'Esto es lo que verán los clientes de ti. Te mostramos qué puedes editar y dónde.',
    ),
    ModeloPasoRecorrido(
      id: 'leyenda',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.perfilLeyenda,
      titulo: 'Qué puedes editar',
      descripcion: 'El lápiz marca lo que editas tú. El candado, lo que gestiona ManoLegal y no se cambia desde aquí.',
    ),
    ModeloPasoRecorrido(
      id: 'cabecera',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.perfilCabecera,
      titulo: 'Tu foto y tus datos principales',
      descripcion: 'Así te presentas en ManoLegal. Toca el botón de la cámara sobre tu foto para cambiarla.',
    ),
    ModeloPasoRecorrido(
      id: 'sobreMi',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.perfilSobreMi,
      titulo: 'Edita un bloque',
      descripcion: 'Toca el lápiz de un bloque, como «Sobre mí», para escribir o actualizar su contenido.',
    ),
    ModeloPasoRecorrido(
      id: 'experiencia',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.perfilExperiencia,
      titulo: 'Tu experiencia',
      descripcion: 'Con «Agregar experiencia» sumas a tu perfil los cargos y la trayectoria que quieras mostrar.',
    ),
    ModeloPasoRecorrido(
      id: 'contacto',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.perfilContacto,
      titulo: 'Cómo te contactarán',
      descripcion: 'Esta vista previa muestra las opciones de contacto que verán los clientes en tu perfil.',
    ),
    ModeloPasoRecorrido(
      id: 'cierre',
      tipo: TipoPasoRecorrido.cierre,
      titulo: 'Listo',
      descripcion: 'Mantén tu perfil completo y al día para que los clientes te conozcan mejor.',
    ),
  ];

  /// Panel: las tres tarjetas con datos reales y, aparte, las de
  /// demostración, que se presentan como lo que son.
  static const List<ModeloPasoRecorrido> pasosPanel = [
    ModeloPasoRecorrido(
      id: 'bienvenida',
      tipo: TipoPasoRecorrido.bienvenida,
      titulo: 'Tu panel',
      descripcion: 'Aquí ves un resumen de tu perfil en ManoLegal. Te explicamos qué muestra cada tarjeta.',
    ),
    ModeloPasoRecorrido(
      id: 'estado',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.panelEstado,
      titulo: 'Estado del perfil',
      descripcion: 'Indica si ManoLegal ya verificó tus documentos («Verificado») o si la revisión sigue pendiente.',
    ),
    ModeloPasoRecorrido(
      id: 'reputacion',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.panelReputacion,
      titulo: 'Reputación',
      descripcion: 'Tu calificación promedio y cuántas reseñas te han dejado los clientes.',
    ),
    ModeloPasoRecorrido(
      id: 'completitud',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.panelCompletitud,
      titulo: 'Completitud del perfil',
      descripcion: 'Qué tan completo está tu perfil. Puedes completarlo desde «Mi perfil».',
    ),
    ModeloPasoRecorrido(
      id: 'demostracion',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.panelDemostracion,
      titulo: 'Datos de demostración',
      descripcion: 'Las tarjetas marcadas «Dato de demostración» (Visualizaciones del perfil, Solicitudes recibidas y Contactos) todavía no muestran cifras reales: son datos de ejemplo.',
    ),
    ModeloPasoRecorrido(
      id: 'cierre',
      tipo: TipoPasoRecorrido.cierre,
      titulo: 'Listo',
      descripcion: 'Vuelve a tu panel cuando quieras revisar el estado de tu perfil.',
    ),
  ];
}
