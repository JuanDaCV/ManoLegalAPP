import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';

/// Dibuja un contorno de 2 px sobre su hijo mientras el teclado tiene el foco
/// en él (o en algo dentro de él).
///
/// Los efectos de foco que traen `InkWell` y `IconButton` son una capa muy
/// tenue; para quien navega con Tab hace falta algo que se distinga a simple
/// vista (WCAG 2.4.7). Solo aparece con el foco del teclado: un toque o un
/// clic no lo dibujan, igual que el resto de resaltados de Flutter.
///
/// No toma el foco por sí mismo: observa el de sus descendientes.
class ContornoDeFoco extends StatefulWidget {
  final Widget child;
  final BoxShape forma;

  /// Esquinas del contorno cuando la forma es rectangular.
  final BorderRadius? radio;
  final Color color;

  const ContornoDeFoco({
    super.key,
    required this.child,
    this.forma = BoxShape.rectangle,
    this.radio,
    this.color = ColoresApp.azulTurqui,
  });

  @override
  State<ContornoDeFoco> createState() => _ContornoDeFocoState();
}

class _ContornoDeFocoState extends State<ContornoDeFoco> {
  bool _conFoco = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (tieneFoco) {
        final visible = tieneFoco && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
        if (visible != _conFoco) setState(() => _conFoco = visible);
      },
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          shape: widget.forma,
          borderRadius: widget.forma == BoxShape.rectangle ? widget.radio : null,
          border: _conFoco ? Border.all(color: widget.color, width: 2) : null,
        ),
        child: widget.child,
      ),
    );
  }
}
