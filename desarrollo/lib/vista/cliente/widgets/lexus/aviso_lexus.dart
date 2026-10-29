import 'package:flutter/material.dart';

import '../../../../configuracion/respuestas_locales_lexus.dart';
import 'estilos_lexus.dart';

/// Nota permanente de que Lexus es una IA. En pantallas pequeñas usa la
/// versión breve; el texto nunca se recorta con puntos suspensivos.
class AvisoLexus extends StatelessWidget {
  const AvisoLexus({super.key, this.compacto = false});

  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final texto = compacto
        ? RespuestasLocalesLexus.avisoIdentidadBreve
        : '${RespuestasLocalesLexus.avisoIdentidad} ${RespuestasLocalesLexus.avisoPrivacidad}';
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 16 : 20,
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline,
              size: 15,
              color: EstilosLexus.textoSobreGris,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: compacto ? 11 : 12,
                height: 1.35,
                color: EstilosLexus.textoSobreGris,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
