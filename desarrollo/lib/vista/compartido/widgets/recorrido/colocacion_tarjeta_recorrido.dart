import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// De qué lado del hueco va la tarjeta del recorrido.
enum LadoTarjetaRecorrido {
  /// Sin hueco: centrada en la pantalla.
  centro,
  abajo,
  arriba,
  derecha,
  izquierda,

  /// Ningún lado tiene espacio útil: la tarjeta se apoya abajo y tapa parte
  /// del elemento señalado.
  superpuesta,
}

/// Resultado de [calcularColocacion]: el lado elegido y los límites de la
/// tarjeta. Es un dato puro, sin widgets, para poder probarlo con una tabla de
/// pantallas.
@immutable
class ColocacionTarjetaRecorrido {
  const ColocacionTarjetaRecorrido({
    required this.lado,
    required this.areaSegura,
    required this.hueco,
    required this.ancho,
    required this.altoMaximo,
    required this.separacion,
  });

  final LadoTarjetaRecorrido lado;

  /// Zona de la pantalla donde la tarjeta puede estar: sin áreas del sistema
  /// (muescas, barras) y con un margen.
  final Rect areaSegura;

  /// Elemento resaltado, o `null` si la tarjeta va centrada.
  final Rect? hueco;

  /// Ancho de la tarjeta.
  final double ancho;

  /// Alto máximo de la tarjeta: lo que sobra del lado elegido. Si el contenido
  /// es más alto, la tarjeta se desplaza por dentro.
  final double altoMaximo;

  /// Distancia entre la tarjeta y el hueco.
  final double separacion;

  /// Esquina superior izquierda de una tarjeta de tamaño [tarjeta]. Siempre
  /// queda dentro de [areaSegura].
  Offset posicionPara(Size tarjeta) {
    final hueco = this.hueco;
    final double x;
    final double y;
    if (hueco == null || lado == LadoTarjetaRecorrido.centro) {
      x = areaSegura.center.dx - tarjeta.width / 2;
      y = areaSegura.center.dy - tarjeta.height / 2;
    } else {
      final centradoEnX = hueco.center.dx - tarjeta.width / 2;
      switch (lado) {
        case LadoTarjetaRecorrido.centro:
        case LadoTarjetaRecorrido.abajo:
          x = centradoEnX;
          y = hueco.bottom + separacion;
        case LadoTarjetaRecorrido.arriba:
          x = centradoEnX;
          y = hueco.top - separacion - tarjeta.height;
        case LadoTarjetaRecorrido.derecha:
          x = hueco.right + separacion;
          y = hueco.top;
        case LadoTarjetaRecorrido.izquierda:
          x = hueco.left - separacion - tarjeta.width;
          y = hueco.top;
        case LadoTarjetaRecorrido.superpuesta:
          x = centradoEnX;
          y = areaSegura.bottom - tarjeta.height;
      }
    }
    return Offset(
      _acotar(x, areaSegura.left, areaSegura.right - tarjeta.width),
      _acotar(y, areaSegura.top, areaSegura.bottom - tarjeta.height),
    );
  }

  /// Si la tarjeta es más grande que el área, gana el borde inicial.
  static double _acotar(double valor, double minimo, double maximo) {
    return valor.clamp(minimo, math.max(minimo, maximo)).toDouble();
  }
}

/// Elige dónde poner la tarjeta del recorrido para que no tape el [hueco] y
/// quepa en la pantalla, con cualquier tamaño de ventana, de texto o área del
/// sistema.
///
/// - Sin [hueco]: centrada.
/// - Hueco alto (más del 55 % del área segura, como el panel de filtros de
///   escritorio): al costado con más espacio, si hay al menos
///   [anchoMinimoLateral].
/// - Si no: debajo o encima, donde sobre más espacio, si hay al menos
///   [altoMinimoUtil]: lo mínimo que la tarjeta necesita para mostrar su
///   cabecera, algo de texto y los botones.
/// - Si nada cabe: superpuesta, apoyada abajo, con el 60 % del alto del área
///   segura, o [altoMinimoUtil] si es más (sin pasar del área).
ColocacionTarjetaRecorrido calcularColocacion({
  required Size pantalla,
  required EdgeInsets relleno,
  Rect? hueco,
  double margen = 16,
  double separacion = 14,
  double anchoMaximo = 400,
  double anchoMinimoLateral = 300,
  double altoMinimoUtil = 150,
}) {
  final izquierda = relleno.left + margen;
  final arriba = relleno.top + margen;
  final areaSegura = Rect.fromLTRB(
    izquierda,
    arriba,
    math.max(izquierda, pantalla.width - relleno.right - margen),
    math.max(arriba, pantalla.height - relleno.bottom - margen),
  );

  ColocacionTarjetaRecorrido colocar(
    LadoTarjetaRecorrido lado, {
    double? ancho,
    double? altoMaximo,
  }) {
    return ColocacionTarjetaRecorrido(
      lado: lado,
      areaSegura: areaSegura,
      hueco: hueco,
      ancho: ancho ?? math.min(anchoMaximo, areaSegura.width),
      altoMaximo: altoMaximo ?? areaSegura.height,
      separacion: separacion,
    );
  }

  if (hueco == null) return colocar(LadoTarjetaRecorrido.centro);

  if (hueco.height > 0.55 * areaSegura.height) {
    final espacioDerecha = areaSegura.right - (hueco.right + separacion);
    final espacioIzquierda = (hueco.left - separacion) - areaSegura.left;
    final mayor = math.max(espacioDerecha, espacioIzquierda);
    if (mayor >= anchoMinimoLateral) {
      return colocar(
        espacioDerecha >= espacioIzquierda
            ? LadoTarjetaRecorrido.derecha
            : LadoTarjetaRecorrido.izquierda,
        ancho: math.min(anchoMaximo, mayor),
      );
    }
  }

  final espacioAbajo = areaSegura.bottom - (hueco.bottom + separacion);
  final espacioArriba = (hueco.top - separacion) - areaSegura.top;
  final mayor = math.max(espacioAbajo, espacioArriba);
  if (mayor >= altoMinimoUtil) {
    return colocar(
      espacioAbajo >= espacioArriba
          ? LadoTarjetaRecorrido.abajo
          : LadoTarjetaRecorrido.arriba,
      altoMaximo: mayor,
    );
  }

  return colocar(
    LadoTarjetaRecorrido.superpuesta,
    altoMaximo: math.min(
      areaSegura.height,
      math.max(areaSegura.height * 0.6, altoMinimoUtil),
    ),
  );
}

/// Ocupa toda la pantalla y pone a su hijo, la tarjeta del recorrido, donde
/// diga [calcularColocacion].
///
/// Antes de elegir el lado mide la tarjeta: su alto mínimo intrínseco es lo
/// que necesita para mostrar la cabecera, unas líneas de texto y los botones,
/// porque el resto del texto se desplaza dentro de ella. Medir en lugar de
/// suponer un alto es lo que mantiene los botones a la vista con cualquier
/// fuente y tamaño de texto.
class DisposicionTarjetaRecorrido extends SingleChildRenderObjectWidget {
  const DisposicionTarjetaRecorrido({
    super.key,
    required this.relleno,
    required this.hueco,
    super.child,
  });

  /// Áreas del sistema (muescas, barras) que la tarjeta no debe tapar.
  final EdgeInsets relleno;

  /// Borde visible del elemento resaltado, o `null` para centrar la tarjeta.
  final Rect? hueco;

  @override
  RenderDisposicionTarjetaRecorrido createRenderObject(BuildContext context) {
    return RenderDisposicionTarjetaRecorrido(relleno: relleno, hueco: hueco);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderDisposicionTarjetaRecorrido renderObject,
  ) {
    renderObject
      ..relleno = relleno
      ..hueco = hueco;
  }
}

class RenderDisposicionTarjetaRecorrido extends RenderShiftedBox {
  RenderDisposicionTarjetaRecorrido({
    required this._relleno,
    required this._hueco,
  }) : super(null);

  EdgeInsets get relleno => _relleno;
  EdgeInsets _relleno;
  set relleno(EdgeInsets valor) {
    if (valor == _relleno) return;
    _relleno = valor;
    markNeedsLayout();
  }

  Rect? get hueco => _hueco;
  Rect? _hueco;
  set hueco(Rect? valor) {
    if (valor == _hueco) return;
    _hueco = valor;
    markNeedsLayout();
  }

  /// Colocación del último layout: las pruebas la usan para saber de qué lado
  /// quedó la tarjeta.
  @visibleForTesting
  ColocacionTarjetaRecorrido? get colocacion => _colocacion;
  ColocacionTarjetaRecorrido? _colocacion;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = constraints.biggest;
    final tarjeta = child;
    if (tarjeta == null) {
      _colocacion = null;
      return;
    }
    // Arriba o abajo del hueco la tarjeta tiene el mismo ancho que centrada:
    // a ese ancho se mide lo que necesita como mínimo.
    final ancho = calcularColocacion(pantalla: size, relleno: relleno).ancho;
    final colocacion = calcularColocacion(
      pantalla: size,
      relleno: relleno,
      hueco: hueco,
      altoMinimoUtil: tarjeta.getMinIntrinsicHeight(ancho),
    );
    _colocacion = colocacion;
    tarjeta.layout(
      BoxConstraints(
        minWidth: colocacion.ancho,
        maxWidth: colocacion.ancho,
        maxHeight: colocacion.altoMaximo,
      ),
      parentUsesSize: true,
    );
    (tarjeta.parentData! as BoxParentData).offset = colocacion.posicionPara(
      tarjeta.size,
    );
  }
}
