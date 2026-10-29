import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa un archivo (PDF o imagen) guardado como bytes dentro de un
/// documento de Firestore (el proyecto usa el plan Spark, sin Storage).
class ModeloArchivoAdjunto {
  final String nombreArchivo;
  final String tipoContenido;
  final int tamanio;
  final Uint8List bytes;

  const ModeloArchivoAdjunto({
    required this.nombreArchivo,
    required this.tipoContenido,
    required this.tamanio,
    required this.bytes,
  });

  factory ModeloArchivoAdjunto.fromMap(Map<String, dynamic> mapa) {
    return ModeloArchivoAdjunto(
      nombreArchivo: mapa['nombreArchivo'] as String,
      tipoContenido: mapa['tipoContenido'] as String,
      tamanio: mapa['tamanio'] as int,
      bytes: (mapa['bytes'] as Blob).bytes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombreArchivo': nombreArchivo,
      'tipoContenido': tipoContenido,
      'tamanio': tamanio,
      'bytes': Blob(bytes),
      'fechaSubida': FieldValue.serverTimestamp(),
    };
  }
}
