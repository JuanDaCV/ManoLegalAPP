import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../modelo/modelo_archivo_adjunto.dart';

/// Pestaña abierta en blanco dentro del clic del usuario, a la espera de que
/// terminen de descargarse los bytes del documento.
web.Window? _pestanaReservada;

/// Abre ya una pestaña en blanco, dentro del gesto del usuario.
///
/// Hay que llamarla antes de cualquier `await`. El navegador solo permite
/// abrir ventanas nuevas durante unos segundos después de un clic (unos 5 en
/// Chrome, Edge y Firefox; alrededor de 1 en Safari). Descargar un documento
/// de Storage encadena varias peticiones y puede superar ese margen: si la
/// pestaña se abriera recién al final, el bloqueador de ventanas emergentes
/// la descartaría en silencio. Reservándola ahora, [abrirArchivo] solo tiene
/// que navegarla cuando los bytes estén listos.
///
/// Devuelve `false` si el navegador no permitió abrirla.
bool reservarPestanaDocumento() {
  cancelarPestanaReservada();
  _pestanaReservada = web.window.open('', '_blank');
  return _pestanaReservada != null;
}

/// Cierra la pestaña reservada si al final no se va a usar: la descarga
/// falló, o el archivo se mostrará en el visor interno.
void cancelarPestanaReservada() {
  final pestana = _pestanaReservada;
  _pestanaReservada = null;
  if (pestana != null && !pestana.closed) pestana.close();
}

/// Abre [archivo] en una pestaña del navegador, a partir de un blob creado
/// en memoria (no hay almacenamiento en disco en Web).
///
/// Si hay una pestaña reservada con [reservarPestanaDocumento], la usa. Si
/// no, abre una nueva, como antes: sirve cuando se llama directamente desde
/// un botón, con los bytes ya en memoria.
Future<void> abrirArchivo(ModeloArchivoAdjunto archivo) async {
  final blob = web.Blob(
    [archivo.bytes.toJS].toJS,
    web.BlobPropertyBag(type: archivo.tipoContenido),
  );
  final url = web.URL.createObjectURL(blob);

  final pestana = _pestanaReservada;
  _pestanaReservada = null;
  if (pestana != null && !pestana.closed) {
    pestana.location.href = url;
    return;
  }

  final abierta = web.window.open(url, '_blank');
  if (abierta == null) {
    // Sin esto el fallo sería silencioso: window.open no lanza una excepción
    // cuando el navegador bloquea la ventana, solo devuelve null.
    web.URL.revokeObjectURL(url);
    throw StateError('El navegador bloqueó la ventana del documento.');
  }
}
