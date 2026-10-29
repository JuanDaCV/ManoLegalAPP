import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../tema/tema_app.dart';

/// Estilos de la guía en video "Cómo funciona".
///
/// Todo parte de [ColoresApp]. Reglas de contraste que se respetan aquí:
/// - El dorado solo va en detalles (filetes, aros, numerales) o como texto
///   sobre fondos azul turquí, nunca como texto sobre blanco.
/// - El texto de cuerpo sobre el fondo gris claro de la página usa
///   [textoCuerpoSobrePagina]: el gris de texto sobre ese fondo queda en
///   4,47:1, por debajo del 4,5:1 que exige WCAG AA. Sobre blanco puro sí
///   alcanza, por eso las tarjetas pueden seguir usando `grisTexto`.
abstract final class EstilosComoFunciona {
  /// Las pruebas de widget lo desactivan: `google_fonts` intenta descargar la
  /// fuente y en las pruebas no hay red. Con `false`, los títulos usan la
  /// tipografía del tema. En la aplicación siempre es Plus Jakarta Sans.
  @visibleForTesting
  static bool usarTipografiaDeMarca = true;

  /// Títulos con la tipografía de marca.
  static TextStyle titulo({
    double tamanio = 24,
    Color color = ColoresApp.azulTurquiOscuro,
    double? altura,
    double? espaciado,
  }) {
    final base = TextStyle(
      fontSize: tamanio,
      fontWeight: FontWeight.w800,
      color: color,
      height: altura,
      letterSpacing: espaciado,
    );
    return usarTipografiaDeMarca ? GoogleFonts.plusJakartaSans(textStyle: base) : base;
  }

  /// Texto de cuerpo sobre el fondo gris claro de la página.
  static Color get textoCuerpoSobrePagina => ColoresApp.azulTurquiOscuro.withValues(alpha: 0.72);

  /// Rótulo pequeño en mayúsculas sobre los títulos ("CAPÍTULO 03 · 0:48").
  /// Sobre superficies claras va en azul profundo y sobre azul turquí, en
  /// dorado.
  static TextStyle etiquetaSuperior({Color color = ColoresApp.azulProfundo}) {
    return TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.7, color: color);
  }

  /// Cifras de ancho fijo: los tiempos y numerales no "bailan" al cambiar.
  static const List<FontFeature> cifrasTabulares = [FontFeature.tabularFigures()];

  /// Duración de una animación, o cero si el usuario pidió reducir el
  /// movimiento en su sistema.
  static Duration duracion(BuildContext context, Duration base) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : base;
  }

  /// Tarjeta blanca de un capítulo en pantallas pequeñas y medianas.
  static BoxDecoration get tarjeta => BoxDecoration(
    color: ColoresApp.blanco,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: ColoresApp.grisTexto.withValues(alpha: 0.12)),
    boxShadow: [
      BoxShadow(color: ColoresApp.azulTurqui.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 10)),
    ],
  );

  /// Marco azul turquí que rodea al video en pantallas anchas. Con [elevado],
  /// la sombra crece: es el gesto de "levantarse" al pasar el cursor.
  static BoxDecoration marcoAzul({bool elevado = false}) => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [ColoresApp.azulTurqui, ColoresApp.azulProfundo],
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: ColoresApp.azulTurqui.withValues(alpha: elevado ? 0.28 : 0.18),
        blurRadius: elevado ? 44 : 32,
        offset: Offset(0, elevado ? 22 : 16),
      ),
    ],
  );
}
