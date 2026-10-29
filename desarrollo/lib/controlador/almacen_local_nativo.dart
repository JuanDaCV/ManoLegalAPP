import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'almacen_local_base.dart';

/// Almacén local de móvil y escritorio: un archivo JSON.
///
/// Devuelve siempre la misma instancia del proceso. Cada instancia ordena
/// solo sus propias operaciones; dos instancias sobre el mismo archivo
/// podrían leer y reescribir el mapa a la vez y perder una escritura (dos
/// recorridos que terminan casi juntos, o el arranque que guarda su indicio).
AlmacenLocal crearAlmacenLocal() => _almacenCompartido;

/// Se crea al pedirlo por primera vez; crearlo no toca el disco.
final AlmacenLocalArchivo _almacenCompartido = AlmacenLocalArchivo();

/// Almacén que guarda todos los pares en un único archivo JSON, dentro del
/// directorio de soporte de la app (persistente, a diferencia del temporal).
///
/// Un archivo ausente o corrupto cuenta como vacío. Las operaciones se
/// ejecutan de una en una: cada escritura lee, modifica y guarda el mapa
/// completo, y dos a la vez se pisarían entre sí.
class AlmacenLocalArchivo implements AlmacenLocal {
  /// [directorio] permite a las pruebas usar una carpeta temporal en lugar del
  /// directorio de soporte, que necesita el plugin de la plataforma.
  AlmacenLocalArchivo({Future<Directory> Function()? directorio})
    : _directorio = directorio ?? getApplicationSupportDirectory;

  static const String nombreArchivo = 'recorridos.json';

  final Future<Directory> Function() _directorio;

  /// Fin de la última operación encolada. Nunca termina en error: el error le
  /// llega a quien pidió esa operación, no a la siguiente.
  Future<void> _cola = Future<void>.value();

  @override
  Future<String?> leer(String clave) {
    return _enCola(() async => (await _cargar())[clave]);
  }

  @override
  Future<void> escribir(String clave, String valor) {
    return _enCola(() async {
      try {
        final datos = await _cargar();
        datos[clave] = valor;
        await _guardar(datos);
      } on Exception {
        // Mejor esfuerzo: sin poder escribir, el recorrido se volverá a
        // mostrar la próxima vez.
      }
    });
  }

  @override
  Future<void> borrar(String clave) {
    return _enCola(() async {
      try {
        final datos = await _cargar();
        if (datos.remove(clave) != null) await _guardar(datos);
      } on Exception {
        // Mejor esfuerzo, igual que al escribir.
      }
    });
  }

  Future<T> _enCola<T>(Future<T> Function() operacion) {
    final resultado = _cola.then((_) => operacion());
    _cola = resultado.then<void>((_) {}, onError: (Object _) {});
    return resultado;
  }

  Future<File> _archivo() async {
    final directorio = await _directorio();
    return File('${directorio.path}${Platform.pathSeparator}$nombreArchivo');
  }

  Future<Map<String, String>> _cargar() async {
    final archivo = await _archivo();
    if (!await archivo.exists()) return {};
    try {
      final json = jsonDecode(await archivo.readAsString());
      if (json is Map<String, dynamic>) {
        return {
          for (final entrada in json.entries)
            if (entrada.value case final String valor) entrada.key: valor,
        };
      }
    } on FormatException {
      // Archivo corrupto: se trata como vacío. Lo peor que pasa es que el
      // recorrido se vuelva a mostrar una vez.
    }
    return {};
  }

  /// Escribe en un archivo temporal y lo renombra: si la app se cierra a
  /// mitad de la escritura, el archivo anterior sigue intacto.
  Future<void> _guardar(Map<String, String> datos) async {
    final archivo = await _archivo();
    await archivo.parent.create(recursive: true);
    final temporal = File('${archivo.path}.tmp');
    await temporal.writeAsString(jsonEncode(datos), flush: true);
    await temporal.rename(archivo.path);
  }
}
