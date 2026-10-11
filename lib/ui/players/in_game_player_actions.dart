import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';

enum InGamePlayerAction {
  edit,
  switchPlayer,
}

Future<InGamePlayerAction?> showInGamePlayerActionsSheet(
  BuildContext context, {
  required String playerName,
}) {
  return showModalBottomSheet<InGamePlayerAction>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(playerName, style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text('Edit $playerName'),
                subtitle: const Text(
                  'Fix this player\'s name everywhere, including past games.',
                ),
                onTap: () => Navigator.of(context).pop(InGamePlayerAction.edit),
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: const Text('Switch player'),
                subtitle: Text(
                  'Wrong player picked? Replace $playerName in this game. Scores stay.',
                ),
                onTap: () =>
                    Navigator.of(context).pop(InGamePlayerAction.switchPlayer),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SwitchPlayerChoice {
  const SwitchPlayerChoice.existing(QuickScoreAvailablePlayer this.player)
      : isNewPlayer = false;

  const SwitchPlayerChoice.newPlayer()
      : player = null,
        isNewPlayer = true;

  final QuickScoreAvailablePlayer? player;
  final bool isNewPlayer;
}

Future<SwitchPlayerChoice?> showSwitchPlayerSheet(
  BuildContext context, {
  required String replacingPlayerName,
  required List<QuickScoreAvailablePlayer> candidates,
}) {
  return showModalBottomSheet<SwitchPlayerChoice>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Replace $replacingPlayerName with',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ...candidates.map(
                        (player) => ListTile(
                          leading: const Icon(Icons.person_outline_rounded),
                          title: Text(player.displayName),
                          onTap: () => Navigator.of(context)
                              .pop(SwitchPlayerChoice.existing(player)),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_add_alt_1_rounded),
                        title: const Text('New Player...'),
                        onTap: () => Navigator.of(context)
                            .pop(const SwitchPlayerChoice.newPlayer()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
