/// Metadatos de un archivo guardado en Firebase Storage, leídos sin
/// descargar su contenido.
///
/// El panel de administrador lo usa para confirmar que un documento de
/// verificación existe de verdad en Storage, y no solo que Firestore registra
/// su ruta, y para mostrar su nombre original, tipo, tamaño y fecha de subida.
class ModeloInfoArchivo {
  final String nombreArchivo;
  final String tipoContenido;
  final int tamanio;
  final DateTime? fechaSubida;

  const ModeloInfoArchivo({
    required this.nombreArchivo,
    required this.tipoContenido,
    required this.tamanio,
    this.fechaSubida,
  });

  bool get esPdf => tipoContenido == 'application/pdf';

  bool get esImagen => tipoContenido.startsWith('image/');
}
