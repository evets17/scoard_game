import 'package:flutter/material.dart';

/// The ways a score can be entered in the score entry sheet.
enum ScoreEntryMode {
  calculator('Calculator', Icons.calculate_outlined),
  quickPick('Quick pick', Icons.grid_view_rounded);

  const ScoreEntryMode(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// What the score entry sheet remembers between uses within one game.
class ScoreEntryMemory {
  ScoreEntryMode mode = ScoreEntryMode.calculator;

  /// The quick pick column of the last number entered, or null before any.
  int? quickPickColumn;
}
