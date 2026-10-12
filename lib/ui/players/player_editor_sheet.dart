import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';
import 'package:scoard_game/application/models/players/player_name_rules.dart';
import 'package:scoard_game/ui/players/group_name_dialog.dart';

/// Asks for a player name only.
Future<String?> showPlayerEditorSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialValue = '',
  List<PlayerListItemModel> existingPlayers = const [],
  String? editingPlayerId,
}) async {
  final result = await showModalBottomSheet<PlayerEditorResult>(
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

  return result?.name;
}

enum PlayerEditorAction {
  save,
  archive,
  restore,
}

class PlayerEditorResult {
  const PlayerEditorResult.save({required this.name, required this.groupIds})
      : action = PlayerEditorAction.save;

  const PlayerEditorResult._status(this.action)
      : name = null,
        groupIds = const {};

  final PlayerEditorAction action;
  final String? name;
  final Set<String> groupIds;
}

/// The full player editor: name, groups, and archiving.
///
/// [statusAction] adds an Archive or Restore button; leave it null to hide it.
Future<PlayerEditorResult?> showPlayerDetailsSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required List<PlayerGroup> groups,
  required Future<PlayerGroup> Function(String name) onCreateGroup,
  String initialValue = '',
  Set<String> initialGroupIds = const {},
  List<PlayerListItemModel> existingPlayers = const [],
  String? editingPlayerId,
  PlayerEditorAction? statusAction,
}) {
  return showModalBottomSheet<PlayerEditorResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PlayerEditorSheet(
      title: title,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
      existingPlayers: existingPlayers,
      editingPlayerId: editingPlayerId,
      groups: groups,
      initialGroupIds: initialGroupIds,
      onCreateGroup: onCreateGroup,
      statusAction: statusAction,
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
    this.groups,
    this.initialGroupIds = const {},
    this.onCreateGroup,
    this.statusAction,
  });

  final String title;
  final String confirmLabel;
  final String initialValue;
  final List<PlayerListItemModel> existingPlayers;
  final String? editingPlayerId;

  /// Null hides the groups section.
  final List<PlayerGroup>? groups;
  final Set<String> initialGroupIds;
  final Future<PlayerGroup> Function(String name)? onCreateGroup;
  final PlayerEditorAction? statusAction;

  @override
  State<_PlayerEditorSheet> createState() => _PlayerEditorSheetState();
}

class _PlayerEditorSheetState extends State<_PlayerEditorSheet> {
  late final TextEditingController _controller;
  late final List<PlayerGroup> _groups = [...?widget.groups];
  late final Set<String> _selectedGroupIds = {...widget.initialGroupIds};
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

    return SingleChildScrollView(
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
          if (widget.groups != null) ...[
            const SizedBox(height: 16),
            Text('Groups', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._groups.map(
                  (group) => FilterChip(
                    label: Text(group.name),
                    selected: _selectedGroupIds.contains(group.id),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _selectedGroupIds.add(group.id);
                      } else {
                        _selectedGroupIds.remove(group.id);
                      }
                    }),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New group'),
                  onPressed: _createGroup,
                ),
              ],
            ),
          ],
          if (widget.statusAction != null) ...[
            const SizedBox(height: 12),
            switch (widget.statusAction!) {
              PlayerEditorAction.restore => TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(
                    const PlayerEditorResult._status(PlayerEditorAction.restore),
                  ),
                  icon: const Icon(Icons.unarchive_rounded),
                  label: const Text('Restore player'),
                ),
              _ => TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(
                    const PlayerEditorResult._status(PlayerEditorAction.archive),
                  ),
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archive player'),
                ),
            },
          ],
          const SizedBox(height: 18),
          // Wraps onto two lines when large text makes the buttons too wide.
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.end,
            overflowSpacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
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

  Future<void> _createGroup() async {
    final onCreateGroup = widget.onCreateGroup;
    if (onCreateGroup == null) {
      return;
    }

    final group = await showGroupNameDialog<PlayerGroup>(
      context,
      title: 'New Group',
      confirmLabel: 'Create',
      onSubmit: onCreateGroup,
    );

    if (group == null || !mounted) {
      return;
    }

    setState(() {
      _groups.add(group);
      _selectedGroupIds.add(group.id);
    });
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

    Navigator.of(context).pop(
      PlayerEditorResult.save(name: value, groupIds: {..._selectedGroupIds}),
    );
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