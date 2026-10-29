import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../tema/tema_app.dart';

/// Estilos y medidas del recorrido guiado.
///
/// Mismas reglas de contraste que el resto de la app: el dorado solo va en
/// detalles (filetes, aros), nunca como texto sobre blanco.
abstract final class EstilosRecorrido {
  /// Las pruebas de widget lo desactivan: `google_fonts` intenta descargar la
  /// fuente y en las pruebas no hay red. En la aplicación siempre es Plus
  /// Jakarta Sans.
  @visibleForTesting
  static bool usarTipografiaDeMarca = true;

  static const double radio = 20;

  /// Duración de una animación, o cero si el usuario pidió reducir el
  /// movimiento en su sistema.
  static Duration duracion(BuildContext context, Duration base) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : base;
  }

  static TextStyle titulo({double tamanio = 20}) {
    final base = TextStyle(
      fontSize: tamanio,
      fontWeight: FontWeight.w800,
      color: ColoresApp.azulTurquiOscuro,
    );
    return usarTipografiaDeMarca
        ? GoogleFonts.plusJakartaSans(textStyle: base)
        : base;
  }

  static TextStyle cuerpo() {
    return TextStyle(
      fontSize: 15,
      height: 1.45,
      color: ColoresApp.azulTurquiOscuro.withValues(alpha: 0.85),
    );
  }

  /// Texto pequeño en mayúsculas del «PASO 2 DE 5».
  static TextStyle etiqueta() {
    return const TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: ColoresApp.azulProfundo,
    );
  }

  /// Misma tarjeta que Lexus, con una sombra más fuerte: sobre el velo oscuro
  /// la sombra suave de Lexus no se distinguiría.
  static BoxDecoration tarjeta() {
    return BoxDecoration(
      color: ColoresApp.blanco,
      borderRadius: BorderRadius.circular(radio),
      border: Border.all(color: ColoresApp.grisTexto.withValues(alpha: 0.15)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    );
  }
}
