import 'package:flutter/material.dart';

/// The built-in ways to enter a score. Templates can add their own value
/// pickers beside these.
enum ScoreEntryMode {
  calculator('Calculator', Icons.calculate_outlined),
  quickPick('Quick pick', Icons.grid_view_rounded);

  const ScoreEntryMode(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// What the score entry sheet remembers between uses within one game.
///
/// Before anything is chosen, the sheet opens in the template's first value
/// picker if it has one, otherwise in the calculator.
class ScoreEntryMemory {
  /// The built-in mode last used, or null.
  ScoreEntryMode? mode;

  /// The template value picker last used, or null.
  String? valuePickerId;

  /// The quick pick column of the last number entered, or null before any.
  int? quickPickColumn;
}
