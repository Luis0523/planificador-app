import 'package:flutter/material.dart';

/// Planazo Design System (context/mock/planazo_design_system/DESIGN.md).
/// Paleta centrada en morado/lavanda, tipografía Plus Jakarta Sans,
/// formas redondeadas y elevación "soft-layer".
class PlanazoColors {
  PlanazoColors._();

  // Neutros
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F4);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF4A454E);
  static const Color outline = Color(0xFF7C757F);
  static const Color outlineVariant = Color(0xFFCCC4CF);

  // Primario (lavanda)
  static const Color primary = Color(0xFF6E528B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFC9A9E9);
  static const Color onPrimaryContainer = Color(0xFF563B73);
  static const Color primaryFixedDim = Color(0xFFDAB9FA);

  // Secundario (morado oscuro — botones, texto funcional)
  static const Color secondary = Color(0xFF714E98);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD2ABFD);
  static const Color onSecondaryContainer = Color(0xFF5D3B83);

  // Terciario (amarillo pálido — badges, acentos)
  static const Color tertiary = Color(0xFF6E5D1E);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFCBB56D);
  static const Color onTertiaryContainer = Color(0xFF564607);

  // Errores
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Sombra "soft-layer" de las tarjetas (0px 4px 12px rgba(74,40,112,0.08))
  static const Color cardShadow = Color(0x14722870);

  // Radios (DESIGN.md: 8px chicos, 16px botones/inputs, 24px tarjetas)
  static const double radiusSm = 8;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: PlanazoColors.primary,
      onPrimary: PlanazoColors.onPrimary,
      primaryContainer: PlanazoColors.primaryContainer,
      onPrimaryContainer: PlanazoColors.onPrimaryContainer,
      secondary: PlanazoColors.secondary,
      onSecondary: PlanazoColors.onSecondary,
      secondaryContainer: PlanazoColors.secondaryContainer,
      onSecondaryContainer: PlanazoColors.onSecondaryContainer,
      tertiary: PlanazoColors.tertiary,
      onTertiary: PlanazoColors.onTertiary,
      tertiaryContainer: PlanazoColors.tertiaryContainer,
      onTertiaryContainer: PlanazoColors.onTertiaryContainer,
      error: PlanazoColors.error,
      onError: PlanazoColors.onError,
      errorContainer: PlanazoColors.errorContainer,
      onErrorContainer: PlanazoColors.onErrorContainer,
      surface: PlanazoColors.surface,
      onSurface: PlanazoColors.onSurface,
      onSurfaceVariant: PlanazoColors.onSurfaceVariant,
      surfaceContainerLowest: PlanazoColors.surfaceContainerLowest,
      surfaceContainerLow: PlanazoColors.surfaceContainerLow,
      surfaceContainer: PlanazoColors.surfaceContainer,
      surfaceContainerHigh: PlanazoColors.surfaceContainerHigh,
      surfaceContainerHighest: PlanazoColors.surfaceContainerHighest,
      outline: PlanazoColors.outline,
      outlineVariant: PlanazoColors.outlineVariant,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Plus Jakarta Sans',
      scaffoldBackgroundColor: PlanazoColors.surface,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.02,
        ),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.25,
          letterSpacing: -0.01,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.33,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.55,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        labelMedium: base.textTheme.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.33,
        ),
        labelSmall: base.textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PlanazoColors.surface,
        foregroundColor: PlanazoColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: PlanazoColors.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PlanazoColors.primary.withValues(alpha: 0.10),
        hintStyle: const TextStyle(color: PlanazoColors.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
          borderSide: const BorderSide(color: PlanazoColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
          borderSide: const BorderSide(color: PlanazoColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
          borderSide: const BorderSide(
            color: PlanazoColors.secondary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
          borderSide: const BorderSide(color: PlanazoColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
          borderSide: const BorderSide(color: PlanazoColors.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PlanazoColors.secondary,
          foregroundColor: PlanazoColors.onSecondary,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PlanazoColors.secondary,
          textStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PlanazoColors.secondary,
          side: const BorderSide(color: PlanazoColors.primary),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: PlanazoColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlanazoColors.radiusXl),
          side: const BorderSide(color: PlanazoColors.primary, width: 0.5),
        ),
        shadowColor: PlanazoColors.cardShadow,
      ),
      dividerTheme: const DividerThemeData(
        color: PlanazoColors.outlineVariant,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
        ),
      ),
    );
  }
}
