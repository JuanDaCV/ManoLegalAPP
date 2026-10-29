import 'package:flutter/material.dart';

import '../../../modelo/modelo_archivo_adjunto.dart';
import '../../tema/tema_app.dart';
import '../../utilidades/abridor_archivo.dart';

/// Muestra un documento de imagen dentro del panel, con zoom, y ofrece
/// abrirlo también en el visor del sistema.
///
/// Los documentos que exige el registro son PDF, pero las reglas de Storage
/// también admiten imágenes. Para esos casos, verlos aquí evita guardar un
/// archivo temporal o abrir una pestaña nueva solo para mirar una foto.
Future<void> mostrarVisorImagenDocumento(
  BuildContext context, {
  required String titulo,
  required ModeloArchivoAdjunto archivo,
}) {
  return showDialog<void>(
    context: context,
    builder: (contextoDialogo) {
      final alto = MediaQuery.sizeOf(contextoDialogo).height;
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 960, maxHeight: alto * 0.88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ColoresApp.azulTurquiOscuro,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            archivo.nombreArchivo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Abrir en el visor externo',
                      icon: const Icon(Icons.open_in_new_rounded, color: ColoresApp.azulTurqui),
                      onPressed: () => _abrirExterno(contextoDialogo, archivo),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.close_rounded, color: ColoresApp.azulTurqui),
                      onPressed: () => Navigator.of(contextoDialogo).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ColoredBox(
                  color: ColoresApp.grisClaro,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5,
                    child: Center(
                      child: Image.memory(
                        archivo.bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No se pudo mostrar la imagen. Prueba abrirla en el visor externo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ColoresApp.grisTexto),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _abrirExterno(BuildContext context, ModeloArchivoAdjunto archivo) async {
  final mensajero = ScaffoldMessenger.maybeOf(context);
  try {
    await abrirArchivo(archivo);
  } catch (_) {
    mensajero?.showSnackBar(const SnackBar(content: Text('No se pudo abrir el documento en el visor externo.')));
  }
}
