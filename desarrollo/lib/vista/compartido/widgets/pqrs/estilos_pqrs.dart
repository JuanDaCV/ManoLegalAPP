import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../tema/tema_app.dart';

/// Estilos de texto de la sección PQRS.
///
/// Mismo recurso que `EstilosAdmin`: en las pruebas no hay red para
/// descargar la fuente de marca, así que la desactivan y el texto usa la
/// tipografía del tema. En la aplicación siempre es Plus Jakarta Sans.
class EstilosPqrs {
  const EstilosPqrs._();

  @visibleForTesting
  static bool usarTipografiaDeMarca = true;

  /// Títulos con la tipografía de marca.
  static TextStyle titulo({
    double tamanio = 24,
    Color color = ColoresApp.azulTurquiOscuro,
    double? espaciado,
  }) {
    final base = TextStyle(fontSize: tamanio, fontWeight: FontWeight.w800, color: color, letterSpacing: espaciado);
    return usarTipografiaDeMarca ? GoogleFonts.plusJakartaSans(textStyle: base) : base;
  }
}
