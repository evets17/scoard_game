import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/sessions/player_color.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/ui/players/player_color_halo.dart';

enum InGamePlayerAction {
  edit,
  switchPlayer,
}

/// Offers Edit and Switch for a player in a game, plus their colour for the
/// game. Picking a colour calls [onColorChanged] and closes the sheet.
/// [colorOwners] names the other players already using each colour.
Future<InGamePlayerAction?> showInGamePlayerActionsSheet(
  BuildContext context, {
  required String playerName,
  PlayerColor? color,
  Map<PlayerColor, List<String>> colorOwners = const {},
  ValueChanged<PlayerColor?>? onColorChanged,
}) {
  return showModalBottomSheet<InGamePlayerAction>(
    context: context,
    isScrollControlled: true,
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
              if (onColorChanged != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _PlayerColorChooser(
                    selected: color,
                    owners: colorOwners,
                    onSelected: (picked) {
                      onColorChanged(picked);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// The players using each colour, in play order, leaving out
/// [exceptPlayerId] (the player whose colour is being picked).
Map<PlayerColor, List<String>> playerColorOwners(
  Map<String, PlayerColor> playerColors, {
  required List<QuickScoreAvailablePlayer> players,
  required String exceptPlayerId,
}) {
  final owners = <PlayerColor, List<String>>{};
  for (final player in players) {
    final color = playerColors[player.id];
    if (color != null && player.id != exceptPlayerId) {
      owners.putIfAbsent(color, () => []).add(player.displayName);
    }
  }
  return owners;
}

class _PlayerColorChooser extends StatelessWidget {
  const _PlayerColorChooser({
    required this.selected,
    required this.owners,
    required this.onSelected,
  });

  final PlayerColor? selected;
  final Map<PlayerColor, List<String>> owners;
  final ValueChanged<PlayerColor?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ColorSwatchButton(
          color: null,
          isSelected: selected == null,
          owners: const [],
          onTap: () => onSelected(null),
        ),
        for (final color in PlayerColor.values)
          _ColorSwatchButton(
            color: color,
            isSelected: selected == color,
            owners: owners[color] ?? const [],
            onTap: () => onSelected(color),
          ),
      ],
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  const _ColorSwatchButton({
    required this.color,
    required this.isSelected,
    required this.owners,
    required this.onTap,
  });

  /// Null is the "no colour" choice.
  final PlayerColor? color;
  final bool isSelected;

  /// Other players already using this colour.
  final List<String> owners;
  final VoidCallback onTap;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = this.color;
    final fill = color?.swatch ?? theme.colorScheme.surfaceContainerHighest;
    final onFill = ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : Colors.black;

    final Widget? content;
    if (isSelected) {
      content = Icon(Icons.check_rounded, color: onFill, size: 22);
    } else if (color == null) {
      content = Icon(
        Icons.format_color_reset_outlined,
        color: theme.colorScheme.onSurfaceVariant,
        size: 20,
      );
    } else if (owners.isNotEmpty) {
      content = Text(
        owners.first.characters.first.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(color: onFill),
      );
    } else {
      content = null;
    }

    final name = color?.label ?? 'No color';
    final usedBy = owners.isEmpty ? '' : ', used by ${owners.join(', ')}';

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$name$usedBy',
      excludeSemantics: true,
      child: Tooltip(
        message: name,
        child: InkResponse(
          onTap: onTap,
          radius: _size / 2 + 4,
          child: Container(
            width: _size,
            height: _size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
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
