import '../configuracion/configuracion_recorrido_cliente.dart';
import '../modelo/modelo_estado_recorrido.dart';
import 'almacen_local.dart';

/// Recuerda, por usuario, si el recorrido guiado ya se vio.
abstract interface class ServicioEstadoRecorrido {
  /// Estado del recorrido de [uid]. Lanza si no se puede leer: el controlador
  /// entonces no muestra el recorrido (falla cerrado) en vez de repetírselo a
  /// quien ya lo vio.
  Future<EstadoRecorrido> leer(String uid);

  Future<void> guardar(String uid, EstadoRecorrido estado);

  /// Olvida el estado de [uid], para volver a ver el recorrido. Todavía no
  /// tiene interfaz: queda listo para una futura sección de Ayuda.
  Future<void> reiniciar(String uid);
}

/// Estado guardado en el dispositivo, sin servidor ni dependencias nuevas. La
/// clave lleva el uid, así que dos cuentas en el mismo equipo no se pisan; en
/// otro navegador o tras reinstalar, el recorrido aparece una vez más.
///
/// Cada recorrido usa su propio [prefijoClave], así que varios servicios
/// pueden compartir el mismo almacén sin pisarse.
class ServicioEstadoRecorridoLocal implements ServicioEstadoRecorrido {
  ServicioEstadoRecorridoLocal({
    AlmacenLocal? almacen,
    this.prefijoClave = ConfiguracionRecorridoCliente.prefijoClave,
  }) : _almacenInyectado = almacen;

  final AlmacenLocal? _almacenInyectado;

  /// Prefijo de la clave, que se completa con el uid. Por defecto, el del
  /// recorrido de Inicio del cliente, que existía antes que los demás: así
  /// lo ya guardado sigue valiendo sin migrar nada.
  final String prefijoClave;

  /// Se crea al usarlo por primera vez: construir el servicio no toca ni el
  /// disco ni el navegador.
  late final AlmacenLocal _almacen = _almacenInyectado ?? crearAlmacenLocal();

  String _clave(String uid) => '$prefijoClave$uid';

  @override
  Future<EstadoRecorrido> leer(String uid) async {
    return EstadoRecorrido.desdeTexto(await _almacen.leer(_clave(uid)));
  }

  @override
  Future<void> guardar(String uid, EstadoRecorrido estado) {
    final texto = estado.comoTexto;
    if (texto == null) return reiniciar(uid);
    return _almacen.escribir(_clave(uid), texto);
  }

  @override
  Future<void> reiniciar(String uid) => _almacen.borrar(_clave(uid));
}
