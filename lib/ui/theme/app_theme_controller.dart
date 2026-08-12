import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:scoard_game/ui/theme/app_colors.dart';

enum AppThemeChoice {
  scoardLight,
  scoreboardNight,
}

class AppThemeOption {
  const AppThemeOption({
    required this.choice,
    required this.label,
    required this.description,
    required this.palette,
  });

  final AppThemeChoice choice;
  final String label;
  final String description;
  final AppThemePalette palette;
}

class AppThemeController extends ChangeNotifier {
  AppThemeController({
    AppThemeChoice initialChoice = AppThemeChoice.scoardLight,
    Future<void> Function(AppThemeChoice choice)? onThemeChanged,
  })  : _selectedChoice = initialChoice,
        _onThemeChanged = onThemeChanged;

  static const List<AppThemeOption> options = [
    AppThemeOption(
      choice: AppThemeChoice.scoardLight,
      label: 'Scoard Light',
      description: 'Warm tabletop tones with a paper-like background.',
      palette: AppThemePalette.scoardLight,
    ),
    AppThemeOption(
      choice: AppThemeChoice.scoreboardNight,
      label: 'Scoreboard Night',
      description: 'A darker scoreboard look with brighter action accents.',
      palette: AppThemePalette.scoreboardNight,
    ),
  ];

  AppThemeChoice _selectedChoice;
  final Future<void> Function(AppThemeChoice choice)? _onThemeChanged;

  AppThemeChoice get selectedChoice => _selectedChoice;

  AppThemePalette get selectedPalette => selectedOption.palette;

  AppThemeOption get selectedOption =>
      options.firstWhere((option) => option.choice == _selectedChoice);

  void selectTheme(AppThemeChoice choice) {
    if (_selectedChoice == choice) {
      return;
    }

    _selectedChoice = choice;
    notifyListeners();

    if (_onThemeChanged != null) {
      unawaited(_onThemeChanged(choice));
    }
  }
}