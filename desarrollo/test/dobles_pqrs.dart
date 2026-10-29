import 'dart:async';
import 'dart:typed_data';

import 'package:desarrollo/controlador/servicio_pqrs.dart';
import 'package:desarrollo/controlador/servicio_storage.dart';
import 'package:desarrollo/modelo/modelo_archivo_adjunto.dart';
import 'package:desarrollo/modelo/modelo_pqrs.dart';
import 'package:firebase_core/firebase_core.dart';

// =============================================================================
// Servicios falsos declarados con `implements`: extenderlos ejecutaría
// `FirebaseFirestore.instance` / `FirebaseStorage.instance` al crearlos.
// =============================================================================

class PqrsFalso implements ServicioPqrs {
  final creadas = <ModeloPqrs>[];
  final flujo = StreamController<ModeloPqrs?>.broadcast();
  bool fallarAlCrear = false;

  /// Si está puesto, la creación espera a que se complete (envío "en curso").
  Completer<void>? retenerCreacion;
  int idsGenerados = 0;

  @override
  String nuevoId() => 'pqrs${++idsGenerados}';

  @override
  Future<void> crear(ModeloPqrs pqrs) async {
    await retenerCreacion?.future;
    if (fallarAlCrear) throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    creadas.add(pqrs);
  }

  @override
  Stream<ModeloPqrs?> observar(String id) => flujo.stream;

  /// Simula la Cloud Function escribiendo el radicado en el documento.
  void asignarRadicado(String radicado) {
    final creada = creadas.last;
    flujo.add(ModeloPqrs(
      id: creada.id,
      uid: creada.uid,
      tipo: creada.tipo,
      descripcion: creada.descripcion,
      evidencias: creada.evidencias,
      radicado: radicado,
      estado: 'recibida',
      creadoEn: DateTime(2026, 9, 27, 10, 30),
    ));
  }
}

class StorageFalso implements ServicioStorage {
  final subidas = <String>[];
  final eliminadas = <String>[];

  /// Número de evidencia (1 a 3) cuya subida falla.
  int? fallarEnNumero;

  @override
  Future<String> subirEvidenciaPqrs(String uid, String pqrsId, int numero, ModeloArchivoAdjunto archivo) async {
    if (numero == fallarEnNumero) {
      throw FirebaseException(plugin: 'firebase_storage', code: 'retry-limit-exceeded');
    }
    final ruta = ServicioStorage.rutaEvidenciaPqrs(uid, pqrsId, numero, archivo.tipoContenido);
    subidas.add(ruta);
    return ruta;
  }

  @override
  Future<void> eliminarRutas(Iterable<String> rutas) async => eliminadas.addAll(rutas);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ModeloArchivoAdjunto archivoDePrueba(String nombre, String tipoContenido) {
  return ModeloArchivoAdjunto(
    nombreArchivo: nombre,
    tipoContenido: tipoContenido,
    tamanio: 4,
    bytes: Uint8List.fromList([1, 2, 3, 4]),
  );
}
