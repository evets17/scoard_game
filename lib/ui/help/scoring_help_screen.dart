import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/marker_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';

class ScoringHelpButton extends StatelessWidget {
  const ScoringHelpButton({
    required this.fieldDefinition,
    this.isRoundScoring = false,
    this.markers = const [],
    super.key,
  });

  final ScoreFieldDefinition fieldDefinition;
  final bool isRoundScoring;

  /// The game's per-round markers, such as "Went out first".
  final List<MarkerFieldDefinition> markers;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ScoringHelpScreen(
            fieldDefinition: fieldDefinition,
            isRoundScoring: isRoundScoring,
            markers: markers,
          ),
        ),
      ),
      icon: const Icon(Icons.help_outline_rounded),
      tooltip: 'Help',
    );
  }
}

class ScoringHelpScreen extends StatelessWidget {
  const ScoringHelpScreen({
    required this.fieldDefinition,
    this.isRoundScoring = false,
    this.markers = const [],
    super.key,
  });

  final ScoreFieldDefinition fieldDefinition;
  final bool isRoundScoring;

  /// The game's per-round markers, such as "Went out first".
  final List<MarkerFieldDefinition> markers;

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Help',
      showSettingsButton: false,
      child: ListView(
        children: [
          _HelpSection(
            title: 'Scores',
            tips: [
              if (fieldDefinition.enableTapToEdit)
                const _HelpTip(
                  icon: Icons.touch_app_outlined,
                  text: 'Tap a score to type a new value.',
                ),
              if (fieldDefinition.enableTapToEdit)
                const _HelpTip(
                  icon: Icons.calculate_outlined,
                  text:
                      'Use + − × ÷ to tally several numbers, like 3 + 4 + 5. It works left to right like a running total, so 3 + 4 × 2 is 14. Division rounds down.',
                ),
              _HelpTip(
                icon: Icons.horizontal_rule_rounded,
                text:
                    'A dash means that player has no score yet. If play moves on, it counts as ${fieldDefinition.initialIntegerValue ?? 0}.',
              ),
              for (final marker in markers)
                _HelpTip(
                  icon: Icons.flag_outlined,
                  text:
                      '${marker.label}: switch it on in that player\'s score sheet. It shows as "${marker.badge}" beside their name${marker.onePerRound ? ', and only one player can have it each round' : ''}.',
                ),
              if (fieldDefinition.enableTapToEdit)
                for (final picker in fieldDefinition.valuePickers)
                  _HelpTip(
                    icon: Icons.style_outlined,
                    text:
                        '${picker.label}: tap each one in front of the player and the score is worked out for you. Tap one in the picked row to take it back.',
                  ),
              if (fieldDefinition.enableTapToEdit)
                const _HelpTip(
                  icon: Icons.grid_view_rounded,
                  text:
                      'Tap the grid button at the top of the score sheet for Quick pick: tap a number instead of typing it. Swipe sideways for negatives and higher numbers. Your choice is remembered for the rest of the game.',
                ),
              if (fieldDefinition.enableTapToEdit &&
                  fieldDefinition.allowReplace)
                const _HelpTip(
                  icon: Icons.swap_vert_rounded,
                  text: 'Replace sets the score to the number you typed.',
                ),
              if (fieldDefinition.enableTapToEdit &&
                  fieldDefinition.allowAdjust)
                const _HelpTip(
                  icon: Icons.add_rounded,
                  text:
                      'Add to Existing adds the number you typed to the current score. Use +/- to subtract.',
                ),
              if (fieldDefinition.enableQuickAdjust)
                const _HelpTip(
                  icon: Icons.exposure_rounded,
                  text: 'Use the - and + buttons to change a score by one.',
                ),
              if (isRoundScoring)
                const _HelpTip(
                  icon: Icons.functions_rounded,
                  text:
                      'The shaded box next to each score is that player\'s running total, including this round.',
                ),
            ],
          ),
          if (isRoundScoring)
            const _HelpSection(
              title: 'Rounds',
              tips: [
                _HelpTip(
                  icon: Icons.arrow_forward_rounded,
                  text: 'Next Round saves this round and starts the next one.',
                ),
                _HelpTip(
                  icon: Icons.arrow_back_rounded,
                  text:
                      'Previous Round goes back so you can fix an earlier round.',
                ),
              ],
            ),
          const _HelpSection(
            title: 'Players',
            tips: [
              _HelpTip(
                icon: Icons.edit_outlined,
                text:
                    'Tap a player\'s name to edit it. A name change applies everywhere, including past games.',
              ),
              _HelpTip(
                icon: Icons.swap_horiz_rounded,
                text:
                    'Tap a player\'s name and choose Switch player if the wrong player was picked. Their scores move to the new player.',
              ),
              _HelpTip(
                icon: Icons.palette_outlined,
                text:
                    'Tap a player\'s name to give them a color for this game, such as their pawn color. It shows as a glow around their row.',
              ),
              _HelpTip(
                icon: Icons.drag_indicator_rounded,
                text:
                    'Long press a player and drag to change the play order. This works when sorted by play order.',
              ),
            ],
          ),
          _HelpSection(
            title: 'Sorting',
            tips: [
              const _HelpTip(
                icon: Icons.sort_rounded,
                text:
                    'Use the sort button to list players by play order, name, or score. Score puts the leader first.',
              ),
              _HelpTip(
                icon: Icons.pause_circle_outline_rounded,
                text: isRoundScoring
                    ? 'Score sort orders players by total when you pick it and again at each new round. Players stay in place while you enter a round.'
                    : 'Score sort updates after you finish typing a score, not on every - or + tap.',
              ),
            ],
          ),
          _HelpSection(
            title: 'Finishing',
            tips: [
              _HelpTip(
                icon: Icons.flag_outlined,
                text: isRoundScoring
                    ? 'Game Over includes any scores entered for this round and shows the final result.'
                    : 'Game Over saves the scores and shows the result.',
              ),
              const _HelpTip(
                icon: Icons.save_outlined,
                text:
                    'Games save as you go. If you leave, resume the game from the home screen.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.tips});

  final String title;
  final List<_HelpTip> tips;

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...tips,
        ],
      ),
    );
  }
}

class _HelpTip extends StatelessWidget {
  const _HelpTip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
