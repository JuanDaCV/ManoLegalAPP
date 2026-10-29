import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../tema/tema_app.dart';

/// Estilos y medidas de la sección Lexus.
///
/// Reglas de contraste que se respetan aquí: el dorado solo va en detalles
/// (aros, puntos, filetes), nunca como texto sobre blanco, y sobre el fondo
/// gris claro el texto secundario usa [textoSobreGris] porque `grisTexto` solo
/// alcanza 4,5:1 sobre blanco puro.
abstract final class EstilosLexus {
  /// Las pruebas de widget lo desactivan: `google_fonts` intenta descargar la
  /// fuente y en las pruebas no hay red. En la aplicación siempre es Plus
  /// Jakarta Sans.
  @visibleForTesting
  static bool usarTipografiaDeMarca = true;

  /// Por debajo de este ancho el chat ocupa toda la pantalla.
  static const double anchoCompacto = 600;

  /// Desde este ancho aparece el panel lateral junto al chat.
  static const double anchoPanelLateral = 1100;

  static const double anchoMaximoChat = 760;

  static TextStyle titulo({
    double tamanio = 22,
    Color color = ColoresApp.azulTurquiOscuro,
    double? altura,
  }) {
    final base = TextStyle(
      fontSize: tamanio,
      fontWeight: FontWeight.w800,
      color: color,
      height: altura,
    );
    return usarTipografiaDeMarca
        ? GoogleFonts.plusJakartaSans(textStyle: base)
        : base;
  }

  /// Texto de las burbujas y de los bloques sobre blanco.
  static Color get textoCuerpo =>
      ColoresApp.azulTurquiOscuro.withValues(alpha: 0.85);

  /// Texto secundario sobre el fondo gris claro de la página.
  static Color get textoSobreGris =>
      ColoresApp.azulTurquiOscuro.withValues(alpha: 0.72);

  static TextStyle cuerpo({
    double tamanio = 15,
    Color? color,
    double altura = 1.45,
  }) {
    return TextStyle(
      fontSize: tamanio,
      height: altura,
      color: color ?? textoCuerpo,
    );
  }

  /// Duración de una animación, o cero si el usuario pidió reducir el
  /// movimiento en su sistema.
  static Duration duracion(BuildContext context, Duration base) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : base;
  }

  static BoxDecoration tarjeta({double radio = 20}) => BoxDecoration(
    color: ColoresApp.blanco,
    borderRadius: BorderRadius.circular(radio),
    border: Border.all(color: ColoresApp.grisTexto.withValues(alpha: 0.15)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0D0A1930),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
  );
}
