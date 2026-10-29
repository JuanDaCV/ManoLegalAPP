import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Los tres diseños de la guía: una columna de tarjetas (teléfono), una
/// columna más ancha (tableta) y escenas con riel lateral (escritorio).
enum ModoComoFunciona { compacto, medio, ancho }

/// Todas las medidas de la guía, calculadas a partir del tamaño visible de la
/// sección. Es una función pura: las mismas entradas dan las mismas medidas,
/// así que se prueba sin montar widgets y el diseño no depende de estado.
@immutable
class MedidasComoFunciona {
  final ModoComoFunciona modo;

  /// Ancho de la sección tal como llega.
  final double ancho;

  /// Alto visible de la sección, redondeado hacia abajo a múltiplos de 80.
  ///
  /// Varias medidas dependen del alto (tamaño del video, riel compacto). Si
  /// siguieran el alto exacto, en los navegadores móviles todo se movería un
  /// poco cada vez que la barra de direcciones aparece o se esconde. Con el
  /// escalón, solo cambian cuando el alto cruza un múltiplo de 80.
  final double alto;

  /// Margen mínimo a cada lado de la pantalla.
  final double margen;

  /// Ancho del contenido, centrado en la sección.
  final double anchoContenido;

  /// Ancho del riel lateral y separación con los capítulos. Son cero fuera
  /// del modo ancho.
  final double anchoRiel;
  final double separacionRiel;

  /// Ancho disponible para los capítulos. En modo ancho es lo que queda
  /// junto al riel; en los otros, todo el contenido.
  final double anchoColumna;

  /// Ancho del video 16:9. En modo ancho nunca pasa de 976 px, que en una
  /// pantalla de 1920 es poco más de la mitad: más grande no aporta nitidez
  /// (el video es 1080p) y dominaría la página.
  final double anchoVideoHorizontal;

  /// Ancho del video vertical 9:16 (capítulo 2) y su alto.
  final double anchoVideoVertical;
  double get altoVideoVertical => anchoVideoVertical * 16 / 9;

  /// En modo medio, el capítulo vertical se pone al lado del texto en vez de
  /// debajo, si hay espacio para ambos.
  final bool verticalAlLado;

  /// El riel usa filas más bajas cuando la pantalla es corta, para que los
  /// seis capítulos entren sin desplazarse.
  final bool rielCompacto;

  // Tamaños de texto por modo.
  final double tamTituloEncabezado;
  final double tamLeadEncabezado;

  /// Ancho máximo de la frase de presentación del encabezado. En teléfono el
  /// ancho disponible ya es angosto y no hay tope; en tableta (modo medio) se
  /// limita a 620 px para que las líneas no pasen de unos 75 caracteres, y en
  /// escritorio a 520 porque comparte la fila con la lista de capítulos.
  final double anchoMaxLead;
  final double tamTituloCapitulo;
  final double tamDescripcion;

  /// Ancho máximo de la descripción de un capítulo, con el mismo criterio:
  /// sin tope en teléfono, 620 px en modo medio (alineada a la izquierda de la
  /// tarjeta) y 560 px en la escena de escritorio.
  final double anchoMaxDescripcion;
  final double tamNumeralFantasma;

  const MedidasComoFunciona._({
    required this.modo,
    required this.ancho,
    required this.alto,
    required this.margen,
    required this.anchoContenido,
    required this.anchoRiel,
    required this.separacionRiel,
    required this.anchoColumna,
    required this.anchoVideoHorizontal,
    required this.anchoVideoVertical,
    required this.verticalAlLado,
    required this.rielCompacto,
    required this.tamTituloEncabezado,
    required this.tamLeadEncabezado,
    required this.anchoMaxLead,
    required this.tamTituloCapitulo,
    required this.tamDescripcion,
    required this.anchoMaxDescripcion,
    required this.tamNumeralFantasma,
  });

  factory MedidasComoFunciona.de({required double ancho, required double alto}) {
    final altoVisible = alto.isFinite ? alto : 800.0;
    final altoEscalonado = (altoVisible / 80).floorToDouble() * 80;

    // El corte de 1100 px en modo ancho garantiza que, con el riel (264 px) y
    // su separación (40 px), a cada capítulo le quedan al menos 640 px: con
    // menos, el texto de un video 16:9 pierde legibilidad.
    final modo = ancho < 600
        ? ModoComoFunciona.compacto
        : ancho < 1100
        ? ModoComoFunciona.medio
        : ModoComoFunciona.ancho;

    final margen = switch (modo) {
      ModoComoFunciona.compacto => 16.0,
      ModoComoFunciona.medio => ancho < 768 ? 24.0 : 32.0,
      ModoComoFunciona.ancho => math.max(32.0, (ancho - 1360) / 2),
    };
    final anchoContenido = switch (modo) {
      ModoComoFunciona.compacto => ancho - 2 * margen,
      ModoComoFunciona.medio => math.min(ancho - 2 * margen, 800.0),
      ModoComoFunciona.ancho => math.min(ancho - 2 * margen, 1360.0),
    };

    final esAncho = modo == ModoComoFunciona.ancho;
    final anchoRiel = esAncho ? (ancho < 1280 ? 264.0 : 280.0) : 0.0;
    final separacionRiel = esAncho ? (ancho < 1280 ? 40.0 : 56.0) : 0.0;
    final anchoColumna = anchoContenido - anchoRiel - separacionRiel;

    // 24 px del marco azul que rodea al video; 234 px de texto y espacios
    // que deben entrar junto al video sin obligar a desplazarse.
    final anchoVideoHorizontal = esAncho
        ? _acotar(math.min(anchoColumna - 24, (altoEscalonado - 234) * 16 / 9), 480, 976)
        : anchoContenido;

    var verticalAlLado = false;
    final double anchoVideoVertical;
    if (esAncho) {
      anchoVideoVertical = _acotar(altoEscalonado - 190, 480, 720) * 9 / 16;
    } else if (modo == ModoComoFunciona.medio && anchoContenido >= 680) {
      verticalAlLado = true;
      anchoVideoVertical = _acotar(altoEscalonado * 0.78, 460, 600) * 9 / 16;
    } else {
      anchoVideoVertical = _acotar(altoEscalonado * 0.72 * 9 / 16, 200, math.min(300, anchoContenido - 48));
    }

    return MedidasComoFunciona._(
      modo: modo,
      ancho: ancho,
      alto: altoEscalonado,
      margen: margen,
      anchoContenido: anchoContenido,
      anchoRiel: anchoRiel,
      separacionRiel: separacionRiel,
      anchoColumna: anchoColumna,
      anchoVideoHorizontal: anchoVideoHorizontal,
      anchoVideoVertical: anchoVideoVertical,
      verticalAlLado: verticalAlLado,
      rielCompacto: altoEscalonado < 720,
      tamTituloEncabezado: switch (modo) {
        ModoComoFunciona.compacto => 26.0,
        ModoComoFunciona.medio => 32.0,
        ModoComoFunciona.ancho => 40.0,
      },
      tamLeadEncabezado: switch (modo) {
        ModoComoFunciona.compacto => 14.5,
        ModoComoFunciona.medio => 16.0,
        ModoComoFunciona.ancho => 17.0,
      },
      anchoMaxLead: switch (modo) {
        ModoComoFunciona.compacto => double.infinity,
        ModoComoFunciona.medio => 620.0,
        ModoComoFunciona.ancho => 520.0,
      },
      tamTituloCapitulo: switch (modo) {
        ModoComoFunciona.compacto => 20.0,
        ModoComoFunciona.medio => 24.0,
        ModoComoFunciona.ancho => 30.0,
      },
      tamDescripcion: switch (modo) {
        ModoComoFunciona.compacto => 14.0,
        ModoComoFunciona.medio => 15.0,
        ModoComoFunciona.ancho => 16.0,
      },
      anchoMaxDescripcion: switch (modo) {
        ModoComoFunciona.compacto => double.infinity,
        ModoComoFunciona.medio => 620.0,
        ModoComoFunciona.ancho => 560.0,
      },
      tamNumeralFantasma: switch (modo) {
        ModoComoFunciona.compacto => 0.0,
        ModoComoFunciona.medio => 64.0,
        ModoComoFunciona.ancho => 96.0,
      },
    );
  }

  /// Ancho a cada lado del contenido para centrarlo en la sección. Es mayor
  /// que [margen] cuando el contenido tiene un ancho máximo (modo medio).
  double get rellenoHorizontal => (ancho - anchoContenido) / 2;

  /// Como `clamp`, pero si el mínimo supera al máximo (pantallas diminutas)
  /// gana el máximo en vez de lanzar una excepción.
  static double _acotar(double valor, double minimo, double maximo) {
    return math.max(math.min(minimo, maximo), math.min(valor, maximo));
  }
}
