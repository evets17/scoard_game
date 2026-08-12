import 'package:flutter/material.dart';
import 'package:scoard_game/ui/theme/app_colors.dart';

class AppTheme {
  static ThemeData light({
    AppThemePalette palette = AppThemePalette.scoardLight,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      extensions: <ThemeExtension<dynamic>>[palette],
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primaryAction,
        brightness: palette.brightness,
      ).copyWith(
        primary: palette.primaryAction,
        onPrimary: palette.primaryActionForeground,
        secondary: palette.accent,
        tertiary: palette.supportingAccent,
        surface: palette.surfaceBackground,
        onSurface: palette.primaryText,
      ),
      scaffoldBackgroundColor: palette.screenBackground,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.primaryText,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceBackground,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: palette.divider,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.accentSurface,
        labelStyle: TextStyle(color: palette.secondaryText),
        hintStyle: TextStyle(color: palette.secondaryText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primaryAction, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: base.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: base.colorScheme.error, width: 1.5),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: palette.primaryText,
        displayColor: palette.primaryText,
      ).copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: palette.secondaryText,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.surfaceBackground,
        side: BorderSide(color: palette.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surfaceBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.divider),
        ),
      ),
      cardColor: palette.surfaceBackground,
    );
  }
}