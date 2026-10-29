import 'modelo_paso_recorrido.dart';

/// Un recorrido guiado completo: sus pasos y lo que el controlador necesita
/// para decidir cuándo mostrarlo. Hay uno por sección y por rol (Inicio del
/// cliente, Mi perfil del abogado, PQRS…), y todos usan el mismo motor.
class ModeloRecorrido {
  const ModeloRecorrido({
    required this.id,
    required this.prefijoClave,
    required this.pasos,
    required this.marcaInicial,
    this.marcaCargando,
    required this.esperaInicial,
    required this.esperaCarga,
  });

  /// Identificador estable, por ejemplo `abogado.mi_perfil`. Sirve para
  /// recordar, durante la sesión, qué recorridos ya terminaron.
  final String id;

  /// Prefijo de la clave con la que se recuerda en el dispositivo que el
  /// recorrido ya se vio; se completa con el uid. Es explícito y no se deriva
  /// de [id] para conservar la clave que ya usaba el recorrido del cliente.
  final String prefijoClave;

  final List<ModeloPasoRecorrido> pasos;

  /// Elemento que indica que la sección está a la vista y lista. Debe existir
  /// siempre que la sección se muestra, y su desplazamiento es el que se
  /// recuerda y se devuelve al terminar.
  final MarcaRecorridoId marcaInicial;

  /// Indicador de carga que hay que dejar desaparecer antes de decidir qué
  /// pasos mostrar. `null` si la sección no carga nada después de verse.
  final MarcaRecorridoId? marcaCargando;

  /// Cuánto se espera a [marcaInicial] antes de renunciar. Las secciones que
  /// dependen de una carga de red (el perfil del abogado) esperan más.
  final Duration esperaInicial;

  /// Cuánto se espera a que desaparezca [marcaCargando].
  final Duration esperaCarga;
}
