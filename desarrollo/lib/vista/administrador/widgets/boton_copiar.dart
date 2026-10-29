import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tema/tema_app.dart';

/// Botón compacto que copia un valor al portapapeles y lo confirma. Se usa
/// para el UID, que en la tabla se muestra abreviado.
class BotonCopiar extends StatelessWidget {
  final String valor;

  /// Qué se copia, para el tooltip y la confirmación: "UID", "correo".
  final String etiqueta;
  final Color color;

  const BotonCopiar({super.key, required this.valor, required this.etiqueta, this.color = ColoresApp.grisTexto});

  Future<void> _copiar(BuildContext context) async {
    final mensajero = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: valor));
    mensajero?.showSnackBar(SnackBar(content: Text('$etiqueta copiado al portapapeles.')));
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _copiar(context),
      tooltip: 'Copiar $etiqueta',
      icon: Icon(Icons.copy_rounded, size: 15, color: color),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    );
  }
}
