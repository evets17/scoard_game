import 'package:scoard_game/application/models/sessions/scoring_session_start_configuration.dart';
import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
import 'package:scoard_game/ui/preset_options/preset_options_screen.dart';

class ScoreGameScreen extends StatelessWidget {
  const ScoreGameScreen({required this.templateCatalog, super.key});

  final TemplateCatalog templateCatalog;

  @override
  Widget build(BuildContext context) {
    final presets = templateCatalog.templates;
    final theme = Theme.of(context);

    return AppScreenScaffold(
      title: 'Score a Game',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you want to score this game?',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: presets
                  .map(
                    (preset) => _PresetOptionCard(
                      preset: preset,
                      onTap: () => _startPreset(context, preset),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startPreset(BuildContext context, ScoringPreset preset) async {
    final routeName = _routeFor(preset.scoringModel);

    if (preset.promptDefinitions.isEmpty) {
      await Navigator.of(context).pushNamed(
        routeName,
        arguments: ScoringSessionStartConfiguration(presetId: preset.id),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PresetOptionsScreen(
          preset: preset,
          onContinue: (answers) {
            Navigator.of(context).pushReplacementNamed(
              routeName,
              arguments: ScoringSessionStartConfiguration(
                presetId: preset.id,
                promptAnswers: answers,
              ),
            );
          },
        ),
      ),
    );
  }

  String _routeFor(ScoringModel scoringModel) {
    return switch (scoringModel) {
      ScoringModel.finalScore => AppRoutes.quickScore,
      ScoringModel.rounds => AppRoutes.roundScore,
    };
  }
}

class _PresetOptionCard extends StatelessWidget {
  const _PresetOptionCard({
    required this.preset,
    required this.onTap,
  });

  final ScoringPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              const Icon(Icons.scoreboard_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(preset.displayName, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      preset.chooserDescription,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}