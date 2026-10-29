import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelo/especialidad_abogado.dart';
import '../modelo/modelo_perfil_publico_abogado.dart';

/// Acceso a la colección pública `perfilesPublicosAbogados`. Clase plana,
/// sin estado.
class ServicioPerfilPublico {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Colección que consulta [buscar]. Es privada a propósito: los dobles de
  /// prueba implementan esta clase con `implements`, y un campo público
  /// los obligaría a todos a declararlo.
  final String _coleccionBusqueda;

  /// `coleccionBusqueda` cambia solo la colección de [buscar]; leer, crear y
  /// editar un perfil siempre usan [coleccion].
  ServicioPerfilPublico({this._coleccionBusqueda = coleccion});

  static const String coleccion = 'perfilesPublicosAbogados';

  /// Proyección pública que lee el visitante web sin sesión: solo los campos
  /// de la tarjeta y de la búsqueda, y solo de abogados verificados. La
  /// escribe la Cloud Function `sincronizarTarjetaAbogado`; las reglas de
  /// Firestore permiten leerla sin sesión y no dejan escribirla a nadie.
  static const String coleccionTarjetas = 'tarjetasAbogados';

  CollectionReference<Map<String, dynamic>> get _referencia => _db.collection(coleccion);

  Future<ModeloPerfilPublicoAbogado?> obtener(String uid) async {
    final documento = await _referencia.doc(uid).get();
    if (!documento.exists) return null;
    return ModeloPerfilPublicoAbogado.fromMap(uid, documento.data()!);
  }

  Stream<ModeloPerfilPublicoAbogado?> observar(String uid) {
    return _referencia.doc(uid).snapshots().map((documento) {
      if (!documento.exists) return null;
      return ModeloPerfilPublicoAbogado.fromMap(uid, documento.data()!);
    });
  }

  /// Crea el perfil público por primera vez. Escribe explícitamente
  /// `calificacionPromedio: 0` y `cantidadResenas: 0` porque las reglas los
  /// exigen presentes y el buscador ordena por el primero.
  Future<void> crear(ModeloPerfilPublicoAbogado perfil) {
    return _referencia.doc(perfil.uid).set({
      ...perfil.toMap(),
      'calificacionPromedio': 0,
      'cantidadResenas': 0,
    });
  }

  /// Actualiza los campos que el abogado puede editar. Quita `verificado`
  /// del mapa: ese campo lo administra únicamente el administrador, y
  /// reenviar un valor desactualizado haría que las reglas rechacen toda la
  /// escritura.
  Future<void> actualizar(ModeloPerfilPublicoAbogado perfil) {
    final datos = perfil.toMap()..remove('verificado');
    return _referencia.doc(perfil.uid).set(datos, SetOptions(merge: true));
  }

  /// Cambia la verificación. Solo el administrador puede ejecutarlo.
  Future<void> actualizarVerificado(String uid, bool verificado) {
    return _referencia.doc(uid).update({
      'verificado': verificado,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminar(String uid) {
    return _referencia.doc(uid).delete();
  }

  /// Consulta del buscador. Aplica al servidor todo lo que Firestore puede
  /// resolver; la ubicación y el texto se filtran después en memoria sobre
  /// este conjunto ya acotado (ver `filtros_abogados.dart`).
  ///
  /// La ubicación no se filtra aquí: sería un segundo `whereIn` en la misma
  /// consulta, y combinar varias disyunciones tiene límites en Firestore que
  /// no vale la pena tocar para un directorio de este tamaño.
  ///
  /// Con [coleccionTarjetas] la consulta es la misma: las tarjetas tienen los
  /// mismos nombres de campo y [ModeloPerfilPublicoAbogado.fromMap] tolera
  /// los que no traen. El `limite` también lo exigen sus reglas (100 o menos).
  Future<List<ModeloPerfilPublicoAbogado>> buscar({
    bool soloVerificados = true,
    double calificacionMinima = 0,
    List<EspecialidadAbogado> especialidades = const [],
    int limite = 100,
  }) async {
    Query<Map<String, dynamic>> consulta = _db.collection(_coleccionBusqueda);

    // La especialidad se filtra primero: Firestore solo permite un
    // `whereIn` por consulta, así que este es el único filtro de
    // disyunción posible aquí.
    if (especialidades.isNotEmpty) {
      consulta = consulta.where('especialidad', whereIn: especialidades.map((e) => e.clave).toList());
    }

    // Filtro por defecto del buscador público; el panel de administrador no
    // lo usa porque necesita ver también los perfiles pendientes.
    if (soloVerificados) {
      consulta = consulta.where('verificado', isEqualTo: true);
    }

    // Firestore exige que una desigualdad esté sobre el mismo campo por el
    // que se ordena, así que este filtro solo tiene sentido junto al
    // `orderBy` de abajo.
    if (calificacionMinima > 0) {
      consulta = consulta.where('calificacionPromedio', isGreaterThanOrEqualTo: calificacionMinima);
    }

    // Orden por defecto del buscador; `limite` evita traer todo el
    // directorio en una sola consulta.
    consulta = consulta.orderBy('calificacionPromedio', descending: true).limit(limite);

    final instantanea = await consulta.get();
    return instantanea.docs.map((doc) => ModeloPerfilPublicoAbogado.fromMap(doc.id, doc.data())).toList();
  }
}
