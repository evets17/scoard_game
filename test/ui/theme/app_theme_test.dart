import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/ui/theme/app_colors.dart';
import 'package:scoard_game/ui/theme/app_theme.dart';

void main() {
  test('scoreboard night builds a dark theme with themed input surfaces', () {
    final theme = AppTheme.light(palette: AppThemePalette.scoreboardNight);

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(
      theme.inputDecorationTheme.fillColor,
      AppThemePalette.scoreboardNight.accentSurface,
    );
    expect(
      theme.bottomSheetTheme.backgroundColor,
      AppThemePalette.scoreboardNight.surfaceBackground,
    );
  });
}