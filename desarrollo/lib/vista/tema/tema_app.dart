import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores de la aplicación.
class ColoresApp {
  static const Color azulTurqui = Color(0xFF0A1930);
  static const Color azulTurquiOscuro = Color(0xFF060F1E);
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color grisClaro = Color(0xFFF5F6F8);
  static const Color grisTexto = Color(0xFF6B7280);
  static const Color verdeVerificado = Color(0xFF2E7D32);
  static const Color rojoNoVerificado = Color(0xFFC62828);

  /// Parada intermedia de gradiente, usada en fondos jurídicos (hero, onboarding).
  static const Color azulProfundo = Color(0xFF0F2A52);

  /// Acento decorativo (glow, orbes, detalles). NUNCA usar como color de texto
  /// sobre fondo claro: es solo decorativo, no cumple contraste de texto.
  static const Color azulBrillante = Color(0xFF2E6BE0);

  /// Fondo de [TarjetaCristal] (~12% blanco).
  static const Color superficieCristal = Color(0x1FFFFFFF);

  /// Borde de [TarjetaCristal] (~20% blanco).
  static const Color bordeCristal = Color(0x33FFFFFF);

  /// Acento dorado de la identidad de marca. Solo para detalles (insignias,
  /// estrellas, filetes, íconos): NUNCA como color de texto sobre blanco.
  static const Color dorado = Color(0xFFC9A227);
}

/// Tema visual centralizado de ManoLegal.
class TemaApp {
  static ThemeData get temaClaro {
    final textThemeBase = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ColoresApp.grisClaro,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColoresApp.azulTurqui,
        primary: ColoresApp.azulTurqui,
        surface: ColoresApp.blanco,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColoresApp.azulTurqui,
        foregroundColor: ColoresApp.blanco,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: textThemeBase.copyWith(
        bodyLarge: textThemeBase.bodyLarge?.copyWith(color: ColoresApp.azulTurquiOscuro),
        bodyMedium: textThemeBase.bodyMedium?.copyWith(color: ColoresApp.grisTexto),
      ),
      // Botones tipo píldora: lenguaje visual compartido con las referencias
      // de diseño de las pantallas de autenticación.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColoresApp.azulTurqui,
          foregroundColor: ColoresApp.blanco,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColoresApp.azulTurqui,
          side: const BorderSide(color: ColoresApp.azulTurqui, width: 1.5),
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      // Enlaces en azul brillante, como en las referencias ("Iniciar Sesión",
      // "Regístrate"). Contraste sobre blanco: cumple WCAG AA para texto normal.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColoresApp.azulBrillante,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColoresApp.blanco,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColoresApp.grisTexto),
        ),
        labelStyle: const TextStyle(color: ColoresApp.grisTexto),
      ),
      // Barra de navegación inferior (móvil): superficie blanca propia en
      // vez del estilo Material 3 por defecto, indicador azul turquí suave
      // y etiquetas siempre visibles bajo cada ícono.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColoresApp.blanco,
        indicatorColor: ColoresApp.azulTurqui.withValues(alpha: 0.12),
        elevation: 3,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((estados) {
          final seleccionado = estados.contains(WidgetState.selected);
          return IconThemeData(color: seleccionado ? ColoresApp.azulTurqui : ColoresApp.grisTexto);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((estados) {
          final seleccionado = estados.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
            color: seleccionado ? ColoresApp.azulTurqui : ColoresApp.grisTexto,
          );
        }),
      ),
    );
  }
}
