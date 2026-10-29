import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';

/// Abre un editor modal para un bloque del perfil: `showDialog` en
/// escritorio y `showModalBottomSheet` (respetando el teclado) en móvil.
///
/// [onGuardar] persiste el cambio en Firestore y devuelve `null` si la
/// escritura fue aceptada, o el mensaje de error a mostrar si fue rechazada.
/// El aviso de éxito solo aparece cuando el servidor confirmó el guardado:
/// nunca se le dice al usuario que se guardó algo que en realidad falló.
Future<void> mostrarEditorPerfil(
  BuildContext context, {
  required bool esEscritorio,
  required String titulo,
  required Widget contenido,
  required Future<String?> Function() onGuardar,
}) {
  // El mensajero se captura antes del `await`: después de cerrar el modal, el
  // contexto del diálogo ya no sirve para mostrar un SnackBar.
  final mensajero = ScaffoldMessenger.of(context);

  Future<void> confirmarGuardado() async {
    final error = await onGuardar();
    mensajero.showSnackBar(
      SnackBar(content: Text(error ?? 'Cambios guardados.')),
    );
  }

  if (esEscritorio) {
    return showDialog(
      context: context,
      builder: (contextDialogo) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, color: ColoresApp.azulTurquiOscuro)),
          content: SizedBox(width: 420, child: contenido),
          actions: [
            TextButton(onPressed: () => Navigator.of(contextDialogo).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(contextDialogo).pop();
                confirmarGuardado();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (contextHoja) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(contextHoja).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: ColoresApp.grisTexto.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: ColoresApp.azulTurquiOscuro),
                  ),
                  const SizedBox(height: 16),
                  contenido,
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(contextHoja).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(contextHoja).pop();
                            confirmarGuardado();
                          },
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
