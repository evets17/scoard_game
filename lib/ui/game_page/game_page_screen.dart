import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_behavior.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/template_origin.dart';
import 'package:scoard_game/core/templates/template_validator.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

/// The page shown after a game is picked: what the game is, who it is for,
/// any options, and Start.
class GamePageScreen extends StatefulWidget {
  const GamePageScreen({
    required this.preset,
    required this.onStart,
    this.openLink = _openInBrowser,
    this.loadRecentGameNames,
    super.key,
  });

  final ScoringPreset preset;
  final ValueChanged<List<PresetPromptAnswer>> onStart;

  /// Names this game was played under before, most recent first, offered
  /// as quick picks for a game name prompt.
  final Future<List<String>> Function()? loadRecentGameNames;

  /// Opens a rules link. Returns false if it could not be opened.
  final Future<bool> Function(Uri uri) openLink;

  @override
  State<GamePageScreen> createState() => _GamePageScreenState();
}

/// "v2.1.0 · online" or "v2.1.0 · built in", so it is clear which copy of a
/// template a game will use.
String templateVersionLabel(ScoringPreset preset) {
  final origin = switch (preset.origin) {
    TemplateOrigin.bundled => 'built in',
    TemplateOrigin.online => 'online',
  };
  return 'Template v${preset.version} · $origin';
}

Future<bool> _openInBrowser(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// "2–8 players", "2+ players", or "2 players".
String playerCountLabel(ScoringPreset preset) {
  final minimum = preset.minimumPlayers;
  final maximum = preset.maximumPlayers;
  final noun = (maximum ?? minimum) == 1 ? 'player' : 'players';

  if (maximum == null) {
    return '$minimum+ players';
  }
  if (maximum == minimum) {
    return '$minimum $noun';
  }
  return '$minimum–$maximum $noun';
}

class _GamePageScreenState extends State<GamePageScreen> {
  late final Map<String, bool> _booleanAnswers;
  late final Map<String, TextEditingController> _integerControllers;
  late final Map<String, TextEditingController> _textControllers;
  List<String> _recentGameNames = const [];
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
    _textControllers = {
      for (final prompt in widget.preset.promptDefinitions)
        if (prompt.kind == PresetPromptKind.text)
          prompt.id: TextEditingController(text: prompt.defaultTextValue ?? ''),
    };
    if (widget.preset.promptDefinitions
        .any((prompt) => prompt.behavior == PresetPromptBehavior.gameName)) {
      unawaited(_loadRecentGameNames());
    }
  }

  Future<void> _loadRecentGameNames() async {
    final names = await widget.loadRecentGameNames?.call() ?? const [];
    if (mounted) {
      setState(() => _recentGameNames = names);
    }
  }

  @override
  void dispose() {
    for (final controller in _integerControllers.values) {
      controller.dispose();
    }
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preset = widget.preset;
    final secondaryStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return AppScreenScaffold(
      title: preset.displayName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              children: [
                if (preset.subtitle != null) ...[
                  Text(preset.subtitle!, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                ],
                Text(preset.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(playerCountLabel(preset), style: secondaryStyle),
                  ],
                ),
                if (preset.source != null) ...[
                  const SizedBox(height: 8),
                  _RulesSource(
                    source: preset.source!,
                    style: secondaryStyle,
                    openLink: widget.openLink,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(templateVersionLabel(preset), style: secondaryStyle),
                  ],
                ),
                if (preset.promptDefinitions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Options', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...preset.promptDefinitions.map(
                    (prompt) => _buildPromptField(context, prompt),
                  ),
                ],
              ],
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
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _start,
              child: const Text('Start'),
            ),
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
          PresetPromptKind.boolean => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(prompt.label),
              subtitle:
                  prompt.promptText == null ? null : Text(prompt.promptText!),
              value: _booleanAnswers[prompt.id] ?? false,
              onChanged: (value) {
                setState(() {
                  _errorText = null;
                  _booleanAnswers[prompt.id] = value;
                });
              },
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
          PresetPromptKind.text => _buildTextPrompt(context, prompt),
        },
      ),
    );
  }

  /// A text answer, such as a game name. A game name offers the names this
  /// game was played under before, so a regular game is one tap.
  Widget _buildTextPrompt(BuildContext context, PresetPromptDefinition prompt) {
    final theme = Theme.of(context);
    final controller = _textControllers[prompt.id]!;
    final defaultName = prompt.defaultTextValue?.trim() ?? '';
    final suggestions = prompt.behavior == PresetPromptBehavior.gameName
        ? _recentGameNames.where((name) => name != defaultName).toList()
        : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt.label, style: theme.textTheme.titleMedium),
        if (prompt.promptText != null) ...[
          const SizedBox(height: 6),
          Text(prompt.promptText!, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                maxLength: maximumPromptTextLength,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: prompt.label,
                  hintText: defaultName.isEmpty ? null : defaultName,
                  counterText: '',
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: controller.clear,
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: 'Clear',
                        ),
                ),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final name in suggestions)
                      ChoiceChip(
                        label: Text(name),
                        selected: controller.text.trim() == name,
                        onSelected: (_) => controller.text = name,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _start() {
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
        case PresetPromptKind.text:
          // Left blank, it falls back to the template's default.
          answers.add(
            PresetPromptAnswer.text(
              id: prompt.id,
              value: _textControllers[prompt.id]!.text.trim(),
            ),
          );
      }
    }

    widget.onStart(answers);
  }
}

/// "Scoring rules: …", as a link when the source is a web address.
class _RulesSource extends StatelessWidget {
  const _RulesSource({
    required this.source,
    required this.style,
    required this.openLink,
  });

  final String source;
  final TextStyle? style;
  final Future<bool> Function(Uri uri) openLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uri = Uri.tryParse(source.trim());
    final isLink = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isLink ? Icons.open_in_new_rounded : Icons.menu_book_outlined,
          size: 20,
          color: isLink
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isLink ? 'Scoring rules' : 'Scoring rules: $source',
            style: isLink
                ? style?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  )
                : style,
          ),
        ),
      ],
    );

    if (!isLink) {
      return row;
    }

    return InkWell(
      onTap: () async {
        var opened = false;
        try {
          opened = await openLink(uri);
        } on Exception {
          opened = false;
        }
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The rules link could not be opened.')),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }
}
