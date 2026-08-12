import 'package:scoard_game/application/models/scoring/preset_prompt_kind.dart';

class PresetPromptAnswer {
  const PresetPromptAnswer.boolean({
    required this.id,
    required bool value,
  })  : kind = PresetPromptKind.boolean,
        booleanValue = value,
        integerValue = null;

  const PresetPromptAnswer.integer({
    required this.id,
    required int value,
  })  : kind = PresetPromptKind.integer,
        booleanValue = null,
        integerValue = value;

  final String id;
  final PresetPromptKind kind;
  final bool? booleanValue;
  final int? integerValue;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'booleanValue': booleanValue,
      'integerValue': integerValue,
    };
  }

  factory PresetPromptAnswer.fromJson(Map<String, Object?> json) {
    final kind = PresetPromptKind.values.byName(json['kind']! as String);

    switch (kind) {
      case PresetPromptKind.boolean:
        return PresetPromptAnswer.boolean(
          id: json['id']! as String,
          value: json['booleanValue']! as bool,
        );
      case PresetPromptKind.integer:
        return PresetPromptAnswer.integer(
          id: json['id']! as String,
          value: json['integerValue']! as int,
        );
    }
  }
}