import 'package:scoard_game/application/models/scoring/preset_prompt_behavior.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_kind.dart';

class PresetPromptDefinition {
  const PresetPromptDefinition.boolean({
    required this.id,
    required this.label,
    this.promptText,
    this.behavior,
    this.defaultBooleanValue = false,
  })  : kind = PresetPromptKind.boolean,
        defaultIntegerValue = null;

  const PresetPromptDefinition.integer({
    required this.id,
    required this.label,
    this.promptText,
    this.behavior,
    this.defaultIntegerValue,
  })  : kind = PresetPromptKind.integer,
        defaultBooleanValue = null;

  final String id;
  final String label;
  final String? promptText;
  final PresetPromptKind kind;
  final PresetPromptBehavior? behavior;
  final bool? defaultBooleanValue;
  final int? defaultIntegerValue;
}