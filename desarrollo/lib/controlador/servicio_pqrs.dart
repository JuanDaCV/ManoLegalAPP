import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelo/modelo_pqrs.dart';

/// Acceso a la colección `pqrs`. Clase plana, sin estado.
class ServicioPqrs {
  static const String coleccion = 'pqrs';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Genera el id de una PQRS nueva sin escribir nada. Hace falta antes de
  /// crearla, porque sus evidencias se suben a una carpeta con ese id.
  String nuevoId() => _db.collection(coleccion).doc().id;

  /// Crea la PQRS en una sola escritura. El radicado y el estado los agrega
  /// después la Cloud Function.
  Future<void> crear(ModeloPqrs pqrs) {
    return _db.collection(coleccion).doc(pqrs.id).set(pqrs.toMapCreacion());
  }

  /// Observa una PQRS para detectar el momento en que la Cloud Function
  /// escribe su radicado. Emite `null` si el documento no existe.
  Stream<ModeloPqrs?> observar(String id) {
    return _db.collection(coleccion).doc(id).snapshots().map(
          (documento) => documento.exists ? ModeloPqrs.fromMap(documento.id, documento.data()!) : null,
        );
  }
}
