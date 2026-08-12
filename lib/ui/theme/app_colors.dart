import 'package:flutter/material.dart';

@immutable
class AppThemePalette extends ThemeExtension<AppThemePalette> {
  const AppThemePalette({
    required this.brightness,
    required this.screenBackground,
    required this.surfaceBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.primaryAction,
    required this.primaryActionForeground,
    required this.accent,
    required this.supportingAccent,
    required this.accentSurface,
    required this.divider,
  });

  static const scoardLight = AppThemePalette(
    brightness: Brightness.light,
    screenBackground: Color(0xFFF6EFE5),
    surfaceBackground: Color(0xFFFFFBF5),
    primaryText: Color(0xFF1F2430),
    secondaryText: Color(0xFF284B63),
    primaryAction: Color(0xFF284B63),
    primaryActionForeground: Color(0xFFFFFFFF),
    accent: Color(0xFFD97D54),
    supportingAccent: Color(0xFF6E8B52),
    accentSurface: Color(0xFFE9F0E5),
    divider: Color(0xFFD7CCBC),
  );

  static const scoreboardNight = AppThemePalette(
    brightness: Brightness.dark,
    screenBackground: Color(0xFF131A24),
    surfaceBackground: Color(0xFF1B2532),
    primaryText: Color(0xFFF4F2EC),
    secondaryText: Color(0xFFC1D2E3),
    primaryAction: Color(0xFF88B4E7),
    primaryActionForeground: Color(0xFF102033),
    accent: Color(0xFFFFB066),
    supportingAccent: Color(0xFF7EC7A2),
    accentSurface: Color(0xFF243447),
    divider: Color(0xFF304154),
  );

  final Brightness brightness;
  final Color screenBackground;
  final Color surfaceBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color primaryAction;
  final Color primaryActionForeground;
  final Color accent;
  final Color supportingAccent;
  final Color accentSurface;
  final Color divider;

  static AppThemePalette of(BuildContext context) {
    return Theme.of(context).extension<AppThemePalette>() ?? scoardLight;
  }

  @override
  AppThemePalette copyWith({
    Brightness? brightness,
    Color? screenBackground,
    Color? surfaceBackground,
    Color? primaryText,
    Color? secondaryText,
    Color? primaryAction,
    Color? primaryActionForeground,
    Color? accent,
    Color? supportingAccent,
    Color? accentSurface,
    Color? divider,
  }) {
    return AppThemePalette(
      brightness: brightness ?? this.brightness,
      screenBackground: screenBackground ?? this.screenBackground,
      surfaceBackground: surfaceBackground ?? this.surfaceBackground,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      primaryAction: primaryAction ?? this.primaryAction,
      primaryActionForeground:
          primaryActionForeground ?? this.primaryActionForeground,
      accent: accent ?? this.accent,
      supportingAccent: supportingAccent ?? this.supportingAccent,
      accentSurface: accentSurface ?? this.accentSurface,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppThemePalette lerp(
    covariant ThemeExtension<AppThemePalette>? other,
    double t,
  ) {
    if (other is! AppThemePalette) {
      return this;
    }

    return AppThemePalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      screenBackground:
          Color.lerp(screenBackground, other.screenBackground, t) ??
              screenBackground,
      surfaceBackground:
          Color.lerp(surfaceBackground, other.surfaceBackground, t) ??
              surfaceBackground,
      primaryText:
          Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      secondaryText:
          Color.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
      primaryAction:
          Color.lerp(primaryAction, other.primaryAction, t) ?? primaryAction,
      primaryActionForeground:
          Color.lerp(
            primaryActionForeground,
            other.primaryActionForeground,
            t,
          ) ??
          primaryActionForeground,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      supportingAccent:
          Color.lerp(supportingAccent, other.supportingAccent, t) ??
              supportingAccent,
      accentSurface:
          Color.lerp(accentSurface, other.accentSurface, t) ?? accentSurface,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
    );
  }
}