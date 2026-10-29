import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelo/modelo_abogado.dart';
import '../modelo/modelo_cliente.dart';
import 'servicio_perfil_publico.dart';

/// Acceso a las colecciones de Firestore. Clase plana, sin estado.
class ServicioFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> guardarCliente(ModeloCliente cliente) {
    return _db.collection('clientes').doc(cliente.uid).set(cliente.toMap());
  }

  Future<void> guardarAbogado(ModeloAbogado abogado) {
    return _db.collection('abogados').doc(abogado.uid).set(abogado.toMap());
  }

  Future<ModeloCliente?> obtenerCliente(String uid) async {
    final documento = await _db.collection('clientes').doc(uid).get();
    if (!documento.exists) return null;
    return ModeloCliente.fromMap(uid, documento.data()!);
  }

  Future<ModeloAbogado?> obtenerAbogado(String uid) async {
    final documento = await _db.collection('abogados').doc(uid).get();
    if (!documento.exists) return null;
    return ModeloAbogado.fromMap(uid, documento.data()!);
  }

  Stream<List<ModeloAbogado>> observarAbogados() {
    return _db.collection('abogados').snapshots().map(
          (instantanea) => instantanea.docs
              .map((doc) => ModeloAbogado.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Cambia el estado del abogado sin tocar su perfil público.
  ///
  /// Se conserva por compatibilidad; para reflejar la verificación también
  /// en `perfilesPublicosAbogados` (lo que exige el buscador) usar
  /// [actualizarEstadoAbogadoYPerfil].
  @Deprecated('Usar actualizarEstadoAbogadoYPerfil para mantener el perfil público sincronizado')
  Future<void> actualizarEstadoAbogado(String uid, String nuevoEstado) {
    return _db.collection('abogados').doc(uid).update({'estado': nuevoEstado});
  }

  /// Borra solo el documento privado del abogado, sin su perfil público.
  ///
  /// Se conserva por compatibilidad; usar [eliminarAbogadoCompleto] para
  /// borrar también `perfilesPublicosAbogados/{uid}`.
  @Deprecated('Usar eliminarAbogadoCompleto para borrar también el perfil público')
  Future<void> eliminarDocumentoAbogado(String uid) {
    return _db.collection('abogados').doc(uid).delete();
  }

  /// Guarda el documento privado del abogado y su proyección pública en una
  /// sola operación atómica: o se escriben los dos, o no se escribe ninguno.
  ///
  /// Con [esCreacion] en `true` el perfil público se crea con
  /// `calificacionPromedio: 0` y `cantidadResenas: 0` explícitos, tal como
  /// exigen las reglas de seguridad. Con `false` se actualiza con `merge` y
  /// sin el campo `verificado`, que administra solo el administrador.
  Future<void> guardarAbogadoConPerfilPublico(ModeloAbogado abogado, {required bool esCreacion}) {
    final lote = _db.batch();
    final referenciaAbogado = _db.collection('abogados').doc(abogado.uid);
    final referenciaPerfil = _db.collection(ServicioPerfilPublico.coleccion).doc(abogado.uid);
    final perfilPublico = abogado.aPerfilPublico();

    if (esCreacion) {
      lote.set(referenciaAbogado, abogado.toMap());
      lote.set(referenciaPerfil, {
        ...perfilPublico.toMap(),
        'calificacionPromedio': 0,
        'cantidadResenas': 0,
      });
    } else {
      // En una actualización se quitan de ambos mapas los campos que el
      // abogado no administra. No es solo una cuestión de permisos: si el
      // administrador verificó la cuenta mientras el abogado tenía el perfil
      // abierto, reenviar el valor viejo contaría como una modificación y las
      // reglas rechazarían el lote completo, perdiendo también los cambios
      // legítimos.
      final datosAbogado = abogado.toMap()..remove('estado');
      final datosPerfil = perfilPublico.toMap()..remove('verificado');
      lote.set(referenciaAbogado, datosAbogado, SetOptions(merge: true));
      lote.set(referenciaPerfil, datosPerfil, SetOptions(merge: true));
    }
    return lote.commit();
  }

  /// Actualiza el documento privado del abogado y refleja los cambios en su
  /// perfil público, sin tocar la verificación ni los agregados de reseñas.
  Future<void> actualizarAbogadoConPerfilPublico(ModeloAbogado abogado) {
    return guardarAbogadoConPerfilPublico(abogado, esCreacion: false);
  }

  /// Cambia el estado de verificación en el documento privado y en el
  /// perfil público a la vez. Solo el administrador puede ejecutarlo.
  Future<void> actualizarEstadoAbogadoYPerfil(String uid, String nuevoEstado) {
    final lote = _db.batch();
    final referenciaAbogado = _db.collection('abogados').doc(uid);
    final referenciaPerfil = _db.collection(ServicioPerfilPublico.coleccion).doc(uid);

    lote.update(referenciaAbogado, {'estado': nuevoEstado});
    lote.update(referenciaPerfil, {
      'verificado': nuevoEstado == 'verificado',
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
    return lote.commit();
  }

  /// Borra el documento privado del abogado y su perfil público.
  Future<void> eliminarAbogadoCompleto(String uid) {
    final lote = _db.batch();
    lote.delete(_db.collection('abogados').doc(uid));
    lote.delete(_db.collection(ServicioPerfilPublico.coleccion).doc(uid));
    return lote.commit();
  }
}
