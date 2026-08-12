import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/core/scoring/built_in_templates/built_in_scoring_presets.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';

class ScoreGameScreen extends StatelessWidget {
  const ScoreGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const presets = builtInScoreGamePresets;
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
                      onTap: () => Navigator.of(context).pushNamed(
                        _routeForPreset(preset.id),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  String _routeForPreset(String presetId) {
    switch (presetId) {
      case 'quick-final-score-basic':
        return AppRoutes.quickScore;
      case 'round-score-basic':
        return AppRoutes.roundScore;
      default:
        return AppRoutes.quickScore;
    }
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