import 'package:scoard_game/application/models/scoring/calculated_line_definition.dart';
import 'package:scoard_game/application/models/scoring/card_text_definition.dart';
import 'package:scoard_game/application/models/scoring/marker_line_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/entered_line_definition.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/sheet_layout.dart';
import 'package:scoard_game/application/models/scoring/template_origin.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

/// A scoring template, as read from a template file.
class ScoringPreset {
  const ScoringPreset({
    required this.id,
    required this.displayName,
    required this.description,
    this.subtitle,
    this.isGeneral = false,
    required this.scoringModel,
    required this.minimumPlayers,
    required this.winnerRule,
    required this.enteredLines,
    this.version = '1.0.0',
    this.maximumPlayers,
    this.source,
    this.promptDefinitions = const [],
    this.calculatedLines = const [],
    this.markerLines = const [],
    this.scoreLabels = const [],
    this.scoreSubLabels = const [],
    this.playerBadges = const [],
    this.scoreLineId,
    this.sheetLayout = const [],
    this.declaredEntryOrder,
    this.origin = TemplateOrigin.bundled,
  });

  final String id;
  final String displayName;

  /// Short line shown under the name in Score a Game, for example to tell
  /// apart two templates for the same game.
  final String? subtitle;

  /// A general scoring style rather than a specific game. Listed first in
  /// Score a Game.
  final bool isGeneral;

  /// Longer explanation shown on the game page.
  final String description;
  final ScoringModel scoringModel;
  final int minimumPlayers;

  /// Informational only; larger games are not blocked.
  final int? maximumPlayers;
  final WinnerRule winnerRule;

  /// The entered lines.
  final List<EnteredLineDefinition> enteredLines;

  /// Lines worked out from formulas.
  final List<CalculatedLineDefinition> calculatedLines;

  /// Flags players set by hand each round, such as "Went out first".
  final List<MarkerLineDefinition> markerLines;

  /// Text shown on the player card instead of the score, such as "Bust".
  /// The first that applies is shown.
  final List<CardTextDefinition> scoreLabels;

  /// Text shown under the score, such as "from 10". The first that applies
  /// is shown.
  final List<CardTextDefinition> scoreSubLabels;

  /// Chips shown after the player's name, such as "1st". Every one that
  /// applies is shown.
  final List<CardTextDefinition> playerBadges;

  /// The line that is each player's score. Defaults to the entered line.
  final String? scoreLineId;
  final List<PresetPromptDefinition> promptDefinitions;
  final String version;

  /// Where the scoring rules came from.
  final String? source;

  /// Where this template was loaded from.
  final TemplateOrigin origin;

  /// The id of the line that is each player's score.
  String get scoreId => scoreLineId ?? enteredLines.first.id;

  /// The sheet top to bottom: section headings and lines, in template
  /// order. Empty means the lines in the order entered, calculated, marker.
  final List<SheetLayoutItem> sheetLayout;

  /// The template's `entryOrder`, or null to use [entryOrder]'s default.
  final SheetEntryOrder? declaredEntryOrder;

  /// Which cell Next opens: the next player when there is one entered line,
  /// the next line when there are several, unless the template says.
  SheetEntryOrder get entryOrder =>
      declaredEntryOrder ??
      (enteredLines.length > 1
          ? SheetEntryOrder.byLine
          : SheetEntryOrder.byPlayer);

  /// Whether this sheet has more than one value to enter per player.
  bool get hasSeveralEnteredLines => enteredLines.length > 1;
}
