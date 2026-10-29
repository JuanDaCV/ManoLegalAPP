import 'package:flutter/material.dart';

import '../tema/tema_app.dart';

/// Campo de texto reutilizable con soporte para contraseñas y contador de caracteres.
class CampoTextoPersonalizado extends StatefulWidget {
  final String etiqueta;
  final TextEditingController? controlador;
  final String? Function(String?)? validador;
  final bool obscureText;
  final int? contadorMaximo;
  final TextInputType? tecladoTipo;
  final void Function(String)? onChanged;

  /// Acción al confirmar el campo con la tecla Enter. La usa el buscador para
  /// lanzar la consulta sin obligar a pulsar el botón.
  final void Function(String)? onEnviado;

  /// Texto de ayuda dentro del campo. La etiqueta se muestra siempre encima,
  /// para no depender de un texto que desaparece al escribir.
  final String? pista;

  /// Si es `true`, el campo no se puede editar (p. ej. el correo cuando
  /// viene de una cuenta de Google), pero conserva la misma apariencia: usa
  /// `readOnly`, no `enabled: false` (que sí lo pintaría gris).
  final bool soloLectura;

  const CampoTextoPersonalizado({
    super.key,
    required this.etiqueta,
    this.controlador,
    this.validador,
    this.obscureText = false,
    this.contadorMaximo,
    this.tecladoTipo,
    this.onChanged,
    this.onEnviado,
    this.pista,
    this.soloLectura = false,
  });

  @override
  State<CampoTextoPersonalizado> createState() => _CampoTextoPersonalizadoState();
}

class _CampoTextoPersonalizadoState extends State<CampoTextoPersonalizado> {
  bool _mostrarTexto = false;

  /// Borde redondeado reutilizado en los distintos estados del campo.
  /// Los campos de una línea son tipo píldora; los multilínea usan un radio
  /// menor para que el texto no choque contra la curva.
  OutlineInputBorder _borde(Color color, double ancho) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.contadorMaximo != null ? 20 : 28),
      borderSide: BorderSide(color: color, width: ancho),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esMultilinea = widget.contadorMaximo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.etiqueta,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ColoresApp.azulTurquiOscuro,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controlador,
          validator: widget.validador,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onEnviado,
          readOnly: widget.soloLectura,
          obscureText: widget.obscureText && !_mostrarTexto,
          keyboardType: widget.tecladoTipo,
          maxLength: widget.contadorMaximo,
          maxLines: esMultilinea ? 4 : 1,
          decoration: InputDecoration(
            hintText: widget.pista,
            hintStyle: TextStyle(color: ColoresApp.grisTexto.withValues(alpha: 0.7)),
            filled: true,
            fillColor: ColoresApp.blanco,
            contentPadding: EdgeInsets.symmetric(vertical: esMultilinea ? 16 : 18, horizontal: 20),
            border: _borde(Colors.transparent, 1),
            enabledBorder: _borde(ColoresApp.grisTexto.withValues(alpha: 0.28), 1),
            focusedBorder: _borde(ColoresApp.azulTurqui, 1.5),
            errorBorder: _borde(ColoresApp.rojoNoVerificado.withValues(alpha: 0.6), 1),
            focusedErrorBorder: _borde(ColoresApp.rojoNoVerificado, 1.5),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(_mostrarTexto ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _mostrarTexto = !_mostrarTexto),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
