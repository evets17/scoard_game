import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';

class PresetOptionsScreen extends StatefulWidget {
  const PresetOptionsScreen({
    required this.preset,
    required this.onContinue,
    super.key,
  });

  final ScoringPreset preset;
  final ValueChanged<List<PresetPromptAnswer>> onContinue;

  @override
  State<PresetOptionsScreen> createState() => _PresetOptionsScreenState();
}

class _PresetOptionsScreenState extends State<PresetOptionsScreen> {
  late final Map<String, bool> _booleanAnswers;
  late final Map<String, TextEditingController> _integerControllers;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _booleanAnswers = {
      for (final prompt in widget.preset.promptDefinitions)
        if (prompt.kind == PresetPromptKind.boolean)
          prompt.id: prompt.defaultBooleanValue ?? false,
    };
    _integerControllers = {
      for (final prompt in widget.preset.promptDefinitions)
        if (prompt.kind == PresetPromptKind.integer)
          prompt.id: TextEditingController(
            text: prompt.defaultIntegerValue?.toString() ?? '',
          ),
    };
  }

  @override
  void dispose() {
    for (final controller in _integerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScreenScaffold(
      title: widget.preset.displayName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game options',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the options for this game before you start scoring.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              children: widget.preset.promptDefinitions
                  .map((prompt) => _buildPromptField(context, prompt))
                  .toList(growable: false),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _continue,
                child: const Text('Continue'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptField(BuildContext context, PresetPromptDefinition prompt) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: switch (prompt.kind) {
          PresetPromptKind.boolean => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(prompt.label),
                  subtitle: prompt.promptText == null
                      ? null
                      : Text(prompt.promptText!),
                  value: _booleanAnswers[prompt.id] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _errorText = null;
                      _booleanAnswers[prompt.id] = value;
                    });
                  },
                ),
              ],
            ),
          PresetPromptKind.integer => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prompt.label, style: theme.textTheme.titleMedium),
                if (prompt.promptText != null) ...[
                  const SizedBox(height: 6),
                  Text(prompt.promptText!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _integerControllers[prompt.id],
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: false,
                  ),
                  decoration: InputDecoration(labelText: prompt.label),
                ),
              ],
            ),
        },
      ),
    );
  }

  void _continue() {
    final answers = <PresetPromptAnswer>[];

    for (final prompt in widget.preset.promptDefinitions) {
      switch (prompt.kind) {
        case PresetPromptKind.boolean:
          answers.add(
            PresetPromptAnswer.boolean(
              id: prompt.id,
              value: _booleanAnswers[prompt.id] ?? false,
            ),
          );
        case PresetPromptKind.integer:
          final rawValue = _integerControllers[prompt.id]!.text.trim();
          final parsedValue = int.tryParse(rawValue);
          if (parsedValue == null) {
            setState(() => _errorText = 'Enter a whole number for ${prompt.label}.');
            return;
          }
          answers.add(
            PresetPromptAnswer.integer(
              id: prompt.id,
              value: parsedValue,
            ),
          );
      }
    }

    widget.onContinue(answers);
  }
}