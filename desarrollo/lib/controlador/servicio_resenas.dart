import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelo/modelo_resena.dart';
import 'servicio_perfil_publico.dart';

/// Acceso a la subcolección de reseñas de un abogado, ubicada en
/// `perfilesPublicosAbogados/{abogadoUid}/resenas`. Clase plana, sin estado.
class ServicioResenas {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _referencia(String abogadoUid) {
    return _db.collection(ServicioPerfilPublico.coleccion).doc(abogadoUid).collection('resenas');
  }

  Future<List<ModeloResena>> obtenerDeAbogado(String abogadoUid) async {
    final instantanea = await _referencia(abogadoUid).orderBy('fecha', descending: true).get();
    return instantanea.docs.map((doc) => ModeloResena.fromMap(doc.id, doc.data())).toList();
  }

  Stream<List<ModeloResena>> observarDeAbogado(String abogadoUid) {
    return _referencia(abogadoUid).orderBy('fecha', descending: true).snapshots().map(
          (instantanea) => instantanea.docs.map((doc) => ModeloResena.fromMap(doc.id, doc.data())).toList(),
        );
  }

  Future<ModeloResena?> obtenerDeCliente({required String abogadoUid, required String clienteUid}) async {
    final documento = await _referencia(abogadoUid).doc(clienteUid).get();
    if (!documento.exists) return null;
    return ModeloResena.fromMap(clienteUid, documento.data()!);
  }

  /// Publica o reemplaza la reseña de este cliente sobre este abogado. El
  /// identificador del documento es el uid del cliente, de modo que una
  /// segunda reseña del mismo cliente sustituye la anterior en lugar de
  /// duplicarla. La Cloud Function recalcula el promedio al detectar la
  /// escritura.
  Future<void> publicar(ModeloResena resena) {
    return _referencia(resena.abogadoUid).doc(resena.clienteUid).set(resena.toMap());
  }

  Future<void> eliminar({required String abogadoUid, required String clienteUid}) {
    return _referencia(abogadoUid).doc(clienteUid).delete();
  }
}
