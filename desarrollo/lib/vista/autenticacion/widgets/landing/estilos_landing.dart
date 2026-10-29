import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../tema/tema_app.dart';

enum TamanoLanding { compacto, medio, ancho, amplio }

/// Tokens de diseño de la landing web.
///
/// Contraste: el dorado solo va en detalles (nunca texto sobre claro) y
/// `grisTexto` solo alcanza 4,5:1 sobre blanco puro, por eso el texto
/// secundario sobre blanco o gris claro usa [textoSuave].
abstract final class EstilosLanding {
  /// Las pruebas de widget lo desactivan: `google_fonts` intenta descargar la
  /// fuente y en las pruebas no hay red.
  @visibleForTesting
  static bool usarTipografiaDeMarca = true;

  // Colores adicionales.
  static const Color noche = Color(0xFF050B16);
  static const Color textoCuerpo = Color(0xFF374151);
  static const Color textoSuave = Color(0xFF4B5563);
  static const Color textoSobreAzul = Color(0xCCFFFFFF);
  static const Color textoSobreAzulSuave = Color(0xA6FFFFFF);
  static const Color borde = Color(0x140A1930);
  static const Color doradoSuave = Color(0x59C9A227);

  /// Dorado oscurecido para texto sobre fondos claros (≈5:1 sobre blanco,
  /// WCAG AA). `ColoresApp.dorado` queda para filetes, anillos y texto sobre
  /// azul, donde sí contrasta.
  static const Color doradoTexto = Color(0xFF8C6A0B);

  // Radios.
  static const double radioS = 12;
  static const double radioM = 16;
  static const double radioL = 24;
  static const double radioXL = 32;

  // Sombras.
  static const List<BoxShadow> sombraTarjeta = [
    BoxShadow(color: Color(0x120A1930), blurRadius: 32, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0A0A1930), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> sombraElevada = [
    BoxShadow(color: Color(0x230A1930), blurRadius: 44, offset: Offset(0, 18)),
    BoxShadow(color: Color(0x120A1930), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static TamanoLanding tamano(double ancho) {
    if (ancho >= 1440) return TamanoLanding.amplio;
    if (ancho >= 1024) return TamanoLanding.ancho;
    if (ancho >= 600) return TamanoLanding.medio;
    return TamanoLanding.compacto;
  }

  static double margenLateral(TamanoLanding t) => switch (t) {
    TamanoLanding.compacto => 20,
    TamanoLanding.medio => 32,
    TamanoLanding.ancho => 48,
    TamanoLanding.amplio => 64,
  };

  static double anchoMaximo(TamanoLanding t) =>
      t == TamanoLanding.amplio ? 1280 : 1200;

  static double relleno(TamanoLanding t) => switch (t) {
    TamanoLanding.compacto => 72,
    TamanoLanding.medio => 96,
    TamanoLanding.ancho => 112,
    TamanoLanding.amplio => 120,
  };

  static double tamanioTituloHero(TamanoLanding t, double ancho) => switch (t) {
    TamanoLanding.compacto => ancho < 360 ? 34 : 40,
    TamanoLanding.medio => 50,
    TamanoLanding.ancho => 60,
    TamanoLanding.amplio => 66,
  };

  static double tamanioTituloSeccion(TamanoLanding t) => switch (t) {
    TamanoLanding.compacto => 30,
    TamanoLanding.medio => 36,
    TamanoLanding.ancho => 42,
    TamanoLanding.amplio => 44,
  };

  static TextStyle titulo({
    required double tamanio,
    Color color = ColoresApp.azulTurquiOscuro,
    double alto = 1.1,
    double espaciado = -0.5,
  }) {
    final base = TextStyle(
      fontSize: tamanio,
      fontWeight: FontWeight.w800,
      color: color,
      height: alto,
      letterSpacing: espaciado,
    );
    return marca(base);
  }

  /// Aplica Plus Jakarta Sans a [base] (salvo en pruebas).
  static TextStyle marca(TextStyle base) {
    return usarTipografiaDeMarca
        ? GoogleFonts.plusJakartaSans(textStyle: base)
        : base;
  }

  /// Sobretítulo de sección. El texto en mayúsculas lo entrega quien llama.
  static TextStyle etiqueta({Color color = ColoresApp.azulTurqui}) {
    return TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: color,
    );
  }

  static TextStyle cuerpo({double tamanio = 17, Color color = textoCuerpo}) {
    return TextStyle(fontSize: tamanio, height: 1.6, color: color);
  }

  static Duration duracion(BuildContext context, int ms) {
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duration(milliseconds: ms);
  }
}
