/// Elementos reales de la interfaz que un paso del recorrido puede señalar.
/// Cada uno se registra en la vista con un `MarcaRecorrido`.
enum MarcaRecorridoId {
  buscador,
  filtros,
  tarjeta,
  verPerfil,
  insignia,

  /// Indicador de carga de los resultados. No lo señala ningún paso: el
  /// recorrido lo consulta para esperar a que terminen de cargarse los
  /// abogados antes de decidir qué pasos mostrar.
  cargandoResultados,

  // Cómo funciona (cliente).

  /// Encabezado «Cómo funciona ManoLegal». Es la marca de arranque: existe
  /// siempre que la sección está a la vista.
  comoFuncionaEncabezado,

  /// Índice de capítulos: los números de «Ir a un capítulo» en teléfonos y el
  /// riel «CAPÍTULOS» en pantalla ancha. Nunca están los dos a la vez.
  comoFuncionaIndice,

  /// Tarjeta del capítulo 1, con su portada y su resumen.
  comoFuncionaCapitulo,

  // Lexus (cliente).

  /// Nota permanente de que Lexus es una IA. Es la marca de arranque: a
  /// diferencia de la introducción, sigue ahí cuando ya hay conversación.
  lexusAviso,

  /// Frases sugeridas de la introducción. Solo existen sin conversación.
  lexusSugerencias,

  /// Campo de consulta. Desaparece cuando el chat llega a su límite.
  lexusEntrada,

  /// Botón del micrófono para dictar la consulta.
  lexusDictado,

  /// Acción «Nueva conversación» de la cabecera.
  lexusNuevaConversacion,

  /// Indicador de carga de la conversación guardada. Como
  /// [cargandoResultados], no lo señala ningún paso: el recorrido espera a
  /// que desaparezca para saber si hay introducción.
  lexusCargando,

  // PQRS (cliente y abogado).

  /// Tarjetas de las cuatro categorías. Es la marca de arranque.
  pqrsCategorias,

  /// Botón «Radicar una PQRS».
  pqrsRadicar,

  /// Nota «Recibirás tu número de radicado…».
  pqrsNotaRadicado,

  // Mi perfil (abogado).

  /// Leyenda «Lo editas tú» / «Lo gestiona ManoLegal». Es la marca de
  /// arranque: solo existe con el perfil ya cargado.
  perfilLeyenda,

  /// Cabecera con la foto y los datos principales.
  perfilCabecera,

  /// Bloque «Sobre mí», con su lápiz para editar.
  perfilSobreMi,

  /// Bloque de experiencia, con «Agregar experiencia».
  perfilExperiencia,

  /// Vista previa de las opciones de contacto que verán los clientes.
  perfilContacto,

  // Panel (abogado).

  /// Tarjeta «Estado del perfil». Es la marca de arranque: solo existe con el
  /// perfil ya cargado.
  panelEstado,

  /// Tarjeta «Reputación».
  panelReputacion,

  /// Tarjeta «Completitud del perfil».
  panelCompletitud,

  /// Primera tarjeta marcada «Dato de demostración».
  panelDemostracion,
}

/// Cómo se presenta un paso: una tarjeta centrada de bienvenida, una tarjeta
/// que señala un elemento de la pantalla, o la tarjeta centrada del cierre.
enum TipoPasoRecorrido { bienvenida, resaltado, cierre }

/// Qué hace el recorrido con un paso cuando su marca no está en pantalla.
enum SiFaltaMarca {
  /// El paso no se muestra, y tampoco cuenta en el «Paso X de N».
  omitir,

  /// El paso se muestra igual, centrado y sin resaltar nada.
  centrar,
}

/// Un paso del recorrido guiado: solo texto y la marca que señala. No sabe
/// nada de widgets, para que el controlador se pueda probar sin interfaz.
class ModeloPasoRecorrido {
  const ModeloPasoRecorrido({
    required this.id,
    required this.tipo,
    this.marca,
    required this.titulo,
    required this.descripcion,
    this.descripcionMovil,
    this.descripcionSinMarca,
    this.siFaltaMarca = SiFaltaMarca.omitir,
    this.requiereMarca,
  });

  final String id;
  final TipoPasoRecorrido tipo;

  /// Elemento que el paso resalta. `null` en la bienvenida y el cierre.
  final MarcaRecorridoId? marca;

  final String titulo;
  final String descripcion;

  /// Texto alternativo cuando el layout es el de móvil. Existe porque el mismo
  /// elemento cambia de forma: los filtros son un botón en móvil y un panel
  /// lateral en escritorio.
  final String? descripcionMovil;

  /// Texto alternativo cuando la marca no está en pantalla y el paso se
  /// muestra centrado: no puede decir «aquí» sobre algo que no se ve.
  final String? descripcionSinMarca;

  final SiFaltaMarca siFaltaMarca;

  /// Otra marca que debe estar en pantalla para que el paso tenga sentido.
  /// Sin ella el paso no se muestra, ni siquiera centrado: «Ver perfil» es un
  /// botón dentro de la tarjeta, y sin tarjeta no hay a qué señalar.
  final MarcaRecorridoId? requiereMarca;

  /// Texto a mostrar según el layout y si la marca está en pantalla. Sin
  /// marca manda [descripcionSinMarca]; luego, en móvil, [descripcionMovil].
  String descripcionPara({required bool esMovil, required bool conMarca}) {
    final sinMarca = descripcionSinMarca;
    if (!conMarca && sinMarca != null) return sinMarca;
    final movil = descripcionMovil;
    if (esMovil && movil != null) return movil;
    return descripcion;
  }
}
