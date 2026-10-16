import 'package:scoard_game/application/models/sessions/scoring_session_start_configuration.dart';
import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/services/scoring/load_score_game_choices.dart';
import 'package:scoard_game/application/services/templates/template_images.dart';
import 'package:scoard_game/core/templates/order_templates.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
import 'package:scoard_game/ui/game_page/game_page_screen.dart';
import 'package:scoard_game/ui/quick_score/game_card_picture.dart';
import 'package:scoard_game/ui/score_sheet/template_image_provider.dart';

class ScoreGameScreen extends StatefulWidget {
  const ScoreGameScreen({
    required this.loadScoreGameChoices,
    this.templatesChanged,
    this.templateImages,
    super.key,
  });

  final LoadScoreGameChoices loadScoreGameChoices;

  /// Fires when the templates change, for example after an online update.
  final Listenable? templatesChanged;

  /// Template pictures, for game card art; without them cards are plain.
  final TemplateImages? templateImages;

  @override
  State<ScoreGameScreen> createState() => _ScoreGameScreenState();
}

class _ScoreGameScreenState extends State<ScoreGameScreen> {
  late Future<ScoreGameChoices> _choicesFuture = widget.loadScoreGameChoices();

  @override
  void initState() {
    super.initState();
    widget.templatesChanged?.addListener(_reload);
  }

  @override
  void dispose() {
    widget.templatesChanged?.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    setState(() => _choicesFuture = widget.loadScoreGameChoices());
  }

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
                picture: _pictureFor(preset),
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
          loadRecentGameNames: () =>
              widget.loadScoreGameChoices.recentGameNames(preset.id),
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

  ImageProvider? _pictureFor(ScoringPreset preset) {
    final images = widget.templateImages;
    final card = preset.card;
    if (images == null || card == null) {
      return null;
    }
    return templateImageProvider(images, card.image);
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
    this.picture,
  });

  final ScoringPreset preset;
  final VoidCallback onTap;

  /// The template's card art, when it has some and the picture is here.
  final ImageProvider? picture;

  static const _textShadow = [Shadow(blurRadius: 6, color: Colors.black54)];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picture = this.picture;
    final showName = preset.card?.showName ?? true;
    final onArt = picture == null ? null : Colors.white;
    final shadows = picture == null ? null : _textShadow;

    // A card with art always lays out a name and a subtitle, shown or not,
    // so it is as tall as a card with a subtitle, and screen readers still
    // read the name.
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          preset.displayName,
          style: theme.textTheme.titleLarge
              ?.copyWith(color: onArt, shadows: shadows),
        ),
        if (preset.subtitle != null || picture != null) ...[
          const SizedBox(height: 4),
          // Without a subtitle, an invisible line keeps the height.
          Visibility(
            visible: preset.subtitle != null,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text(
              preset.subtitle ?? preset.displayName,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: onArt, shadows: shadows),
            ),
          ),
        ],
      ],
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          if (picture == null) ...[
            const Icon(Icons.scoreboard_rounded),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Visibility(
              visible: picture == null || showName,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              maintainSemantics: true,
              child: text,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.chevron_right_rounded,
            color: onArt,
            shadows: picture == null ? null : const [Shadow(blurRadius: 6)],
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: picture == null
            ? content
            : Stack(
                children: [
                  Positioned.fill(child: GameCardPicture(image: picture)),
                  if (showName)
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xCC000000),
                              Color(0x55000000),
                              Color(0x00000000),
                            ],
                            stops: [0, 0.55, 1],
                          ),
                        ),
                      ),
                    ),
                  content,
                ],
              ),
      ),
    );
  }
}
