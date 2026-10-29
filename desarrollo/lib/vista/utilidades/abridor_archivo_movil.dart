import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../modelo/modelo_archivo_adjunto.dart';

/// Guarda [archivo] en el directorio temporal y lo abre con el visor del
/// sistema (móvil/escritorio).
Future<void> abrirArchivo(ModeloArchivoAdjunto archivo) async {
  final directorio = await getTemporaryDirectory();
  final ruta = '${directorio.path}/${archivo.nombreArchivo}';
  final documento = File(ruta);
  await documento.writeAsBytes(archivo.bytes);
  await OpenFilex.open(ruta, type: archivo.tipoContenido);
}
