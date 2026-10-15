import 'package:scoard_game/application/models/scoring/preset_prompt_kind.dart';

class PresetPromptAnswer {
  const PresetPromptAnswer.boolean({
    required this.id,
    required bool value,
  })  : kind = PresetPromptKind.boolean,
        booleanValue = value,
        integerValue = null,
        textValue = null;

  const PresetPromptAnswer.integer({
    required this.id,
    required int value,
  })  : kind = PresetPromptKind.integer,
        booleanValue = null,
        integerValue = value,
        textValue = null;

  const PresetPromptAnswer.text({
    required this.id,
    required String value,
  })  : kind = PresetPromptKind.text,
        booleanValue = null,
        integerValue = null,
        textValue = value;

  final String id;
  final PresetPromptKind kind;
  final bool? booleanValue;
  final int? integerValue;
  final String? textValue;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'booleanValue': booleanValue,
      'integerValue': integerValue,
      if (textValue != null) 'textValue': textValue,
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
      case PresetPromptKind.text:
        return PresetPromptAnswer.text(
          id: json['id']! as String,
          value: json['textValue']! as String,
        );
    }
  }
}
