import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/tema_app.dart';

/// Medidas y estilos propios del panel de administrador.
///
/// Todo parte de [ColoresApp]: azul turquí para la estructura, blanco para
/// las superficies y dorado para los acentos. El verde se usa únicamente
/// como color semántico de "verificado", igual que en el resto de ManoLegal.
abstract final class EstilosAdmin {
  /// Por debajo de este ancho de pantalla la navegación pasa a la barra
  /// inferior. Es el mismo corte que usan los paneles de cliente y abogado.
  static const double corteMovil = 900;

  /// Desde este ancho de pantalla el sidebar se muestra completo; entre
  /// [corteMovil] y este valor se reduce a un riel de íconos.
  static const double corteSidebarCompleto = 1200;

  static const double anchoSidebar = 256;
  static const double anchoRiel = 84;

  /// Ancho mínimo del área de contenido para mostrar la tabla. Por debajo,
  /// el listado pasa a tarjetas: así la tabla nunca desborda.
  static const double anchoMinimoTabla = 960;

  static const double radioTarjeta = 20;

  static const Color bordeSuave = Color(0x1F6B7280);
  static const Color tintePendiente = Color(0x24C9A227);
  static const Color bordePendiente = Color(0x8CC9A227);
  static const Color tinteVerificado = Color(0x1A2E7D32);
  static const Color bordeVerificado = Color(0x592E7D32);
  static const Color textoSobreOscuro = Color(0xDDFFFFFF);
  static const Color textoSecundarioSobreOscuro = Color(0xA6FFFFFF);

  /// Variante clara del verde de "verificado", solo para fondos azul turquí.
  /// El verde original (#2E7D32) sobre azul oscuro no alcanza el contraste
  /// mínimo de 3:1 que WCAG exige a íconos y barras.
  static const Color verdeSobreOscuro = Color(0xFF7BD389);

  static const LinearGradient degradadoMarca = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ColoresApp.azulTurquiOscuro, ColoresApp.azulTurqui, ColoresApp.azulProfundo],
  );

  static const BoxDecoration tarjeta = BoxDecoration(
    color: ColoresApp.blanco,
    borderRadius: BorderRadius.all(Radius.circular(radioTarjeta)),
    border: Border.fromBorderSide(BorderSide(color: bordeSuave)),
    boxShadow: [BoxShadow(color: Color(0x0D0A1930), blurRadius: 24, offset: Offset(0, 10))],
  );

  static const TextStyle etiquetaColumna = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: ColoresApp.grisTexto,
  );

  static const TextStyle etiquetaGrupoSidebar = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: Color(0x8CFFFFFF),
  );

  /// Las pruebas de widget lo desactivan: `google_fonts` intenta descargar
  /// la fuente, en las pruebas no hay red, y el fallo se relanza como un
  /// error asíncrono que hace fallar la prueba. Con `false`, los títulos
  /// usan la tipografía del tema.
  @visibleForTesting
  static bool usarTipografiaDeMarca = true;

  /// Títulos de sección con la tipografía de marca, Plus Jakarta Sans.
  static TextStyle titulo({double tamanio = 24, Color color = ColoresApp.azulTurquiOscuro}) {
    final base = TextStyle(fontSize: tamanio, fontWeight: FontWeight.w800, color: color, height: 1.2);
    return usarTipografiaDeMarca ? GoogleFonts.plusJakartaSans(textStyle: base) : base;
  }
}
