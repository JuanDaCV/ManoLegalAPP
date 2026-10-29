import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Fila de celdas del mismo ancho que se estiran a la altura de la más alta.
///
/// Sustituye a `IntrinsicHeight` + `Row(stretch)`. Mide cada celda con un
/// layout real en lugar de con sus dimensiones intrínsecas: en la Web, cuando
/// `google_fonts` termina de cargar una fuente, Flutter vuelve a medir el texto
/// pero no la caché de intrínsecos de `RenderParagraph`, de modo que
/// `IntrinsicHeight` conservaba la altura de la fuente de reserva y el
/// contenido de las tarjetas se desbordaba en la primera visita.
class FilaAlturaIgual extends MultiChildRenderObjectWidget {
  const FilaAlturaIgual({super.key, required super.children, this.espacio = 0});

  /// Separación horizontal entre celdas.
  final double espacio;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderFilaAlturaIgual(espacio);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderFilaAlturaIgual renderObject,
  ) {
    renderObject.espacio = espacio;
  }
}

class _DatosCelda extends ContainerBoxParentData<RenderBox> {}

class RenderFilaAlturaIgual extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DatosCelda>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DatosCelda> {
  RenderFilaAlturaIgual(this._espacio);

  double _espacio;
  double get espacio => _espacio;
  set espacio(double valor) {
    if (valor == _espacio) return;
    _espacio = valor;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DatosCelda) child.parentData = _DatosCelda();
  }

  double _anchoCelda(double anchoTotal) =>
      math.max(0, (anchoTotal - _espacio * (childCount - 1)) / childCount);

  Iterable<RenderBox> get _celdas sync* {
    var celda = firstChild;
    while (celda != null) {
      yield celda;
      celda = childAfter(celda);
    }
  }

  /// Mayor valor de [medir] entre las celdas.
  double _maximo(double Function(RenderBox celda) medir) =>
      _celdas.fold(0, (alto, celda) => math.max(alto, medir(celda)));

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    final ancho = constraints.maxWidth;
    if (childCount == 0) {
      size = constraints.constrain(Size(ancho, 0));
      return;
    }
    final anchoCelda = _anchoCelda(ancho);
    // Primera pasada: alto natural de cada celda.
    final alto = constraints.constrainHeight(
      _maximo((celda) {
        celda.layout(
          BoxConstraints.tightFor(width: anchoCelda),
          parentUsesSize: true,
        );
        return celda.size.height;
      }),
    );
    // Segunda pasada: todas al alto común. Sin restricción estricta a
    // propósito: así ninguna celda es límite de relayout y, si su contenido
    // crece después (p. ej. al cargar una fuente), la fila vuelve a medirse.
    var x = 0.0;
    for (final celda in _celdas) {
      celda.layout(
        BoxConstraints(
          minWidth: anchoCelda,
          maxWidth: anchoCelda,
          minHeight: alto,
        ),
        parentUsesSize: true,
      );
      (celda.parentData! as _DatosCelda).offset = Offset(x, 0);
      x += anchoCelda + _espacio;
    }
    size = constraints.constrain(
      Size(ancho, _maximo((celda) => celda.size.height)),
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final ancho = constraints.maxWidth;
    if (childCount == 0) return constraints.constrain(Size(ancho, 0));
    final restriccion = BoxConstraints.tightFor(width: _anchoCelda(ancho));
    final alto = _maximo((celda) => celda.getDryLayout(restriccion).height);
    return constraints.constrain(Size(ancho, alto));
  }

  double _anchoIntrinseco(double Function(RenderBox celda) medir) {
    if (childCount == 0) return 0;
    return _maximo(medir) * childCount + _espacio * (childCount - 1);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _anchoIntrinseco((celda) => celda.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _anchoIntrinseco((celda) => celda.getMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _maximo((celda) => celda.getMinIntrinsicHeight(_anchoCelda(width)));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _maximo((celda) => celda.getMaxIntrinsicHeight(_anchoCelda(width)));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
