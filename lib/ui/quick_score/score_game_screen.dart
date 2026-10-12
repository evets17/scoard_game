import 'package:scoard_game/application/models/sessions/scoring_session_start_configuration.dart';
import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/services/scoring/load_score_game_choices.dart';
import 'package:scoard_game/core/templates/order_templates.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
import 'package:scoard_game/ui/game_page/game_page_screen.dart';

class ScoreGameScreen extends StatefulWidget {
  const ScoreGameScreen({required this.loadScoreGameChoices, super.key});

  final LoadScoreGameChoices loadScoreGameChoices;

  @override
  State<ScoreGameScreen> createState() => _ScoreGameScreenState();
}

class _ScoreGameScreenState extends State<ScoreGameScreen> {
  late final Future<ScoreGameChoices> _choicesFuture =
      widget.loadScoreGameChoices();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScreenScaffold(
      title: 'Score a Game',
      child: FutureBuilder<ScoreGameChoices>(
        future: _choicesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Games could not load right now.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final choices = snapshot.requireData;
          Widget card(ScoringPreset preset) => _PresetOptionCard(
                preset: preset,
                onTap: () => _startPreset(context, preset),
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you playing?',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ...choices.general.map(card),
                    if (choices.general.isNotEmpty &&
                        choices.games.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Games', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                    ],
                    ...choices.games.map(card),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startPreset(BuildContext context, ScoringPreset preset) async {
    final routeName = _routeFor(preset.scoringModel);

    // Every game opens its game page first, whether or not it has options.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePageScreen(
          preset: preset,
          onStart: (answers) {
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
                    if (preset.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        preset.subtitle!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
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