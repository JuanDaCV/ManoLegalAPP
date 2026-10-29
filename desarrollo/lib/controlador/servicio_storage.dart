import 'package:firebase_storage/firebase_storage.dart';

import '../modelo/modelo_archivo_adjunto.dart';
import '../modelo/modelo_info_archivo.dart';

/// Acceso a Firebase Storage para la foto de perfil y los documentos de
/// verificación de un abogado, y para las evidencias de las PQRS. Clase
/// plana, sin estado.
class ServicioStorage {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Límite de tamaño para la foto de perfil.
  static const int tamanioMaximoFotoBytes = 5 * 1024 * 1024;

  /// Límite de tamaño para un documento de verificación.
  static const int tamanioMaximoDocumentoBytes = 10 * 1024 * 1024;

  /// Ruta en Storage de la foto de perfil de un abogado.
  static String rutaFotoPerfil(String uid) => 'abogados/$uid/foto_perfil.jpg';

  /// Ruta en Storage de un documento de verificación identificado por
  /// [clave] (por ejemplo `cedula`, `tarjeta_profesional`, `certificado_rna`,
  /// `diploma` o `antecedentes`).
  static String rutaDocumento(String uid, String clave) => 'abogados/$uid/documentos/$clave';

  /// Sube la foto de perfil y devuelve su URL de descarga pública: el perfil
  /// público del abogado necesita una URL directa para mostrarla en las
  /// tarjetas del buscador sin pasar por las reglas de Storage en cada carga.
  Future<String> subirFotoPerfil(String uid, ModeloArchivoAdjunto archivo) async {
    _validarTamanio(archivo, tamanioMaximoFotoBytes, 'La foto de perfil');
    final referencia = _storage.ref(rutaFotoPerfil(uid));
    await referencia.putData(
      archivo.bytes,
      SettableMetadata(
        contentType: archivo.tipoContenido,
        customMetadata: {'nombreArchivo': archivo.nombreArchivo},
      ),
    );
    return referencia.getDownloadURL();
  }

  /// Sube un documento de verificación y devuelve su RUTA en Storage.
  ///
  /// Nunca devuelve una URL de descarga: los documentos son privados y solo
  /// se leen con [obtenerArchivo], que sí pasa por las reglas de Storage.
  Future<String> subirDocumento(String uid, String clave, ModeloArchivoAdjunto archivo) async {
    _validarTamanio(archivo, tamanioMaximoDocumentoBytes, 'El documento');
    final ruta = rutaDocumento(uid, clave);
    await _storage.ref(ruta).putData(
      archivo.bytes,
      SettableMetadata(
        contentType: archivo.tipoContenido,
        customMetadata: {'nombreArchivo': archivo.nombreArchivo},
      ),
    );
    return ruta;
  }

  /// Ruta en Storage de la evidencia número [numero] (1 a 3) de una PQRS.
  /// La extensión sale del tipo de contenido; ruta y extensión coinciden con
  /// lo que exigen las reglas de Firestore y de Storage.
  static String rutaEvidenciaPqrs(String uid, String pqrsId, int numero, String tipoContenido) {
    final extension = switch (tipoContenido) {
      'application/pdf' => 'pdf',
      'image/png' => 'png',
      'image/jpeg' => 'jpg',
      _ => throw ArgumentError('Tipo de evidencia no admitido: $tipoContenido'),
    };
    return 'pqrs/$uid/$pqrsId/evidencia_$numero.$extension';
  }

  /// Sube una evidencia de PQRS y devuelve su RUTA en Storage.
  ///
  /// Igual que [subirDocumento], nunca pide una URL de descarga: las
  /// evidencias son privadas y solo se leen pasando por las reglas.
  Future<String> subirEvidenciaPqrs(String uid, String pqrsId, int numero, ModeloArchivoAdjunto archivo) async {
    _validarTamanio(archivo, tamanioMaximoDocumentoBytes, 'La evidencia');
    final ruta = rutaEvidenciaPqrs(uid, pqrsId, numero, archivo.tipoContenido);
    await _storage.ref(ruta).putData(
      archivo.bytes,
      SettableMetadata(
        contentType: archivo.tipoContenido,
        customMetadata: {'nombreArchivo': archivo.nombreArchivo},
      ),
    );
    return ruta;
  }

  /// Descarga los bytes del archivo guardado en [ruta]. Devuelve `null` si
  /// no existe.
  Future<ModeloArchivoAdjunto?> obtenerArchivo(String ruta) async {
    final referencia = _storage.ref(ruta);
    try {
      final metadatos = await referencia.getMetadata();
      final bytes = await referencia.getData(tamanioMaximoDocumentoBytes);
      if (bytes == null) return null;
      final nombreArchivo = metadatos.customMetadata?['nombreArchivo'] ?? referencia.name;
      return ModeloArchivoAdjunto(
        nombreArchivo: nombreArchivo,
        tipoContenido: metadatos.contentType ?? 'application/octet-stream',
        tamanio: bytes.length,
        bytes: bytes,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return null;
      rethrow;
    }
  }

  /// Lee solo los metadatos del archivo en [ruta], sin descargarlo. Devuelve
  /// `null` si el archivo no existe.
  ///
  /// Para las reglas de Storage es una lectura, así que sobre los documentos
  /// de verificación solo la pueden hacer su dueño y el administrador.
  Future<ModeloInfoArchivo?> obtenerInfoArchivo(String ruta) async {
    final referencia = _storage.ref(ruta);
    try {
      final metadatos = await referencia.getMetadata();
      return ModeloInfoArchivo(
        nombreArchivo: metadatos.customMetadata?['nombreArchivo'] ?? referencia.name,
        tipoContenido: metadatos.contentType ?? 'application/octet-stream',
        tamanio: metadatos.size ?? 0,
        fechaSubida: metadatos.timeCreated,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return null;
      rethrow;
    }
  }

  /// Elimina el archivo en [ruta]. Borrar un archivo que ya no existe no se
  /// considera un error.
  Future<void> eliminarRuta(String ruta) async {
    try {
      await _storage.ref(ruta).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  Future<void> eliminarRutas(Iterable<String> rutas) {
    return Future.wait(rutas.map(eliminarRuta));
  }

  /// Borra la foto de perfil y los documentos conocidos de un abogado. Las
  /// claves de documento incluyen `foto_perfil` por compatibilidad con datos
  /// guardados por versiones anteriores; intentar borrar una ruta que nunca
  /// existió no falla, [eliminarRuta] la ignora en silencio.
  Future<void> eliminarTodoDelAbogado(String uid) {
    const clavesConocidas = [
      'cedula',
      'tarjeta_profesional',
      'certificado_rna',
      'diploma',
      'antecedentes',
      'foto_perfil',
    ];
    final rutas = <String>[
      rutaFotoPerfil(uid),
      ...clavesConocidas.map((clave) => rutaDocumento(uid, clave)),
    ];
    return eliminarRutas(rutas);
  }

  void _validarTamanio(ModeloArchivoAdjunto archivo, int maximoBytes, String etiqueta) {
    if (archivo.tamanio > maximoBytes) {
      final maximoMb = (maximoBytes / (1024 * 1024)).toStringAsFixed(0);
      throw ArgumentError('$etiqueta supera el máximo de $maximoMb MB');
    }
  }
}
