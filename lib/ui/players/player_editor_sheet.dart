import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';
import 'package:scoard_game/application/models/players/player_name_rules.dart';

Future<String?> showPlayerEditorSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialValue = '',
  List<PlayerListItemModel> existingPlayers = const [],
  String? editingPlayerId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PlayerEditorSheet(
      title: title,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
      existingPlayers: existingPlayers,
      editingPlayerId: editingPlayerId,
    ),
  );
}

class _PlayerEditorSheet extends StatefulWidget {
  const _PlayerEditorSheet({
    required this.title,
    required this.confirmLabel,
    required this.initialValue,
    required this.existingPlayers,
    this.editingPlayerId,
  });

  final String title;
  final String confirmLabel;
  final String initialValue;
  final List<PlayerListItemModel> existingPlayers;
  final String? editingPlayerId;

  @override
  State<_PlayerEditorSheet> createState() => _PlayerEditorSheetState();
}

class _PlayerEditorSheetState extends State<_PlayerEditorSheet> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final matchingPlayers = _matchingPlayers(_controller.text);
    final hasExactDuplicate = _hasExactDuplicate(_controller.text);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, viewInsets + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Player name',
              errorText: _errorText,
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (matchingPlayers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Current players', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              hasExactDuplicate
                  ? 'A saved player with this exact name already exists.'
                  : 'Players with similar names',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasExactDuplicate
                    ? theme.colorScheme.error
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            ...matchingPlayers.take(3).map(
              (player) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        player.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (player.isArchived)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Archived',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _submit,
                child: Text(widget.confirmLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      setState(() => _errorText = 'Player name is required.');
      return;
    }

    if (_hasExactDuplicate(value)) {
      setState(
        () => _errorText = 'That player already exists. Use a more specific name.',
      );
      return;
    }

    Navigator.of(context).pop(value);
  }

  void _handleTextChanged() {
    setState(() {
      if (_errorText != null) {
        _errorText = null;
      }
    });
  }

  bool _hasExactDuplicate(String value) {
    final candidates = widget.existingPlayers.where(
      (player) => player.id != widget.editingPlayerId,
    );

    return hasExactNormalizedPlayerNameMatch(
      proposedName: value,
      existingNames: candidates.map((player) => player.displayName),
    );
  }

  List<PlayerListItemModel> _matchingPlayers(String value) {
    return widget.existingPlayers.where((player) {
      return player.id != widget.editingPlayerId &&
          hasPartialPlayerNameMatch(
            query: value,
            existingName: player.displayName,
          );
    }).toList(growable: false);
  }
}