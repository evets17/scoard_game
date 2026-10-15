import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';
import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/scoring/marker_line_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/card_text.dart';
import 'package:scoard_game/application/models/scoring/entered_line_definition.dart';
import 'package:scoard_game/application/models/scoring/value_picker_pick.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/sheet_layout.dart';
import 'package:scoard_game/application/models/sessions/player_color.dart';
import 'package:scoard_game/application/models/sessions/player_sort_mode.dart';
import 'package:scoard_game/application/models/sessions/quick_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/quick_score_session_id_rules.dart';
import 'package:scoard_game/application/models/sessions/quick_score_setup_model.dart';
import 'package:scoard_game/application/services/players/create_player.dart';
import 'package:scoard_game/application/services/players/rename_player.dart';
import 'package:scoard_game/application/services/scoring/remember_setup_player_group.dart';
import 'package:scoard_game/application/services/scoring/load_quick_score_setup_model.dart';
import 'package:scoard_game/application/services/sessions/delete_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_quick_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_quick_score_session.dart';
import 'package:scoard_game/application/services/templates/template_images.dart';
import 'package:scoard_game/core/players/order_players.dart';
import 'package:scoard_game/core/scoring/resolve_preset_options.dart';
import 'package:scoard_game/core/scoring/score_engine.dart';
import 'package:scoard_game/ui/help/scoring_help_screen.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
import 'package:scoard_game/ui/players/in_game_player_actions.dart';
import 'package:scoard_game/ui/players/player_color_halo.dart';
import 'package:scoard_game/ui/players/player_editor_sheet.dart';
import 'package:scoard_game/ui/players/player_group_filter_chips.dart';
import 'package:scoard_game/ui/players/player_reorderable_list.dart';
import 'package:scoard_game/ui/players/player_sort_menu_button.dart';
import 'package:scoard_game/ui/settings/stay_awake_controller.dart';
import 'package:scoard_game/ui/score_input/numeric_score_field.dart';
import 'package:scoard_game/ui/score_input/numeric_value_picker.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';
import 'package:scoard_game/ui/score_sheet/score_sheet_grid.dart';
import 'package:scoard_game/ui/score_sheet/template_image_provider.dart';
import 'package:scoard_game/ui/score_input/score_entry_mode.dart';

class QuickScoreFlowScreen extends StatefulWidget {
  const QuickScoreFlowScreen({
    required this.loadQuickScoreSetupModel,
    required this.createPlayer,
    required this.renamePlayer,
    required this.stayAwakeController,
    required this.rememberSetupPlayerGroup,
    required this.saveQuickScoreSession,
    required this.saveQuickScoreActiveSession,
    required this.deleteActiveSession,
    required this.preset,
    this.initialPromptAnswers = const [],
    this.initialActiveSession,
    this.templateImages,
    super.key,
  });

  final LoadQuickScoreSetupModel loadQuickScoreSetupModel;
  final CreatePlayer createPlayer;
  final RenamePlayer renamePlayer;
  final StayAwakeController stayAwakeController;
  final RememberSetupPlayerGroup rememberSetupPlayerGroup;
  final SaveQuickScoreSession saveQuickScoreSession;
  final SaveQuickScoreActiveSession saveQuickScoreActiveSession;
  final DeleteActiveSession deleteActiveSession;
  /// The scoring template being played.
  final ScoringPreset preset;
  final List<PresetPromptAnswer> initialPromptAnswers;
  final QuickScoreActiveSession? initialActiveSession;

  /// Pictures for the sheet's line labels. Without them, labels show text.
  final TemplateImages? templateImages;

  @override
  State<QuickScoreFlowScreen> createState() => _QuickScoreFlowScreenState();
}

enum _QuickScoreStep {
  setup,
  entry,
  result,
}

class _QuickScoreFlowScreenState extends State<QuickScoreFlowScreen> {
  late Future<QuickScoreSetupModel> _setupModelFuture;
  _QuickScoreStep _step = _QuickScoreStep.setup;
  final List<String> _selectedPlayerIds = <String>[];
  List<QuickScoreAvailablePlayer> _selectedPlayers = const [];
  final Map<String, TextEditingController> _scoreControllers = {};
  final ScoreEntryMemory _scoreEntryMemory = ScoreEntryMemory();
  String? _setupGroupId;
  bool _hasAppliedInitialGroup = false;
  ScoringPreset? _preset;
  List<PresetPromptAnswer> _promptAnswers = const [];
  QuickScoreResult? _result;
  String? _currentSessionId;
  AppLifecycleListener? _lifecycleListener;
  PlayerSortMode _sortMode = PlayerSortMode.playOrder;
  Map<String, int> _scoreSortSnapshot = const {};

  /// Value picker tiles behind each entry, by player id.
  Map<String, ValuePickerPick> _entryPicks = {};

  /// Markers (such as "Went out first") set for each player, by player id.
  Map<String, Set<String>> _markers = {};

  /// Colours given to players for this game, by player id.
  final Map<String, PlayerColor> _playerColors = {};

  /// Values on entered lines after the first, by player id and then line
  /// id. The first line's value is in [_scoreControllers], which the
  /// player cards edit.
  final Map<String, Map<String, int>> _otherLineValues = {};

  /// Value picker tiles behind values on lines after the first, by player
  /// id and then line id.
  final Map<String, Map<String, ValuePickerPick>> _otherLinePicks = {};

  /// [playerId]'s value on [lineId], or null if nothing is entered yet.
  int? _lineValue(String playerId, String lineId) {
    if (lineId == _preset!.enteredLines.first.id) {
      return int.tryParse(_scoreControllers[playerId]?.text.trim() ?? '');
    }
    return _otherLineValues[playerId]?[lineId];
  }

  ValuePickerPick? _linePick(String playerId, String lineId) {
    if (lineId == _preset!.enteredLines.first.id) {
      return _entryPicks[playerId];
    }
    return _otherLinePicks[playerId]?[lineId];
  }

  /// Sets [playerId]'s value on [lineId]. Only a value picker's Replace
  /// keeps the [entryPick] it came from.
  void _setLineValue(
    String playerId,
    String lineId,
    int value,
    ValuePickerPick? entryPick,
  ) {
    if (lineId == _preset!.enteredLines.first.id) {
      if (entryPick != _entryPicks[playerId]) {
        _setEntryPick(playerId, entryPick);
      }
      setState(() => _scoreControllers[playerId]?.text = '$value');
      return;
    }
    setState(() {
      _otherLineValues.putIfAbsent(playerId, () => {})[lineId] = value;
      final picks = _otherLinePicks.putIfAbsent(playerId, () => {});
      if (entryPick == null) {
        picks.remove(lineId);
      } else {
        picks[lineId] = entryPick;
      }
    });
    unawaited(_autosaveCurrentSession());
  }

  /// Every entered line's tiles for [playerId], by line id.
  Map<String, ValuePickerPick> _linePicksFor(String playerId) => {
        for (final line in _preset!.enteredLines)
          if (_linePick(playerId, line.id) case final ValuePickerPick pick)
            line.id: pick,
      };

  /// Opens the entry sheet for [playerId]'s value on [lineId]. Next saves it
  /// and opens the next cell in the template's entry order: the player's
  /// next entered line, or the next player in play order.
  Future<void> _editLine(String playerId, String lineId) async {
    final preset = _preset!;
    final line =
        preset.enteredLines.where((line) => line.id == lineId).firstOrNull;
    final playerIndex =
        _selectedPlayers.indexWhere((player) => player.id == playerId);
    if (line == null || playerIndex < 0) {
      return;
    }
    final player = _selectedPlayers[playerIndex];

    final (String, String)? next;
    final String? nextLabel;
    switch (preset.entryOrder) {
      case SheetEntryOrder.byLine:
        final lines = preset.enteredLines;
        final lineIndex = lines.indexOf(line);
        next = lineIndex + 1 < lines.length
            ? (playerId, lines[lineIndex + 1].id)
            : null;
        nextLabel = next == null ? null : lines[lineIndex + 1].label;
      case SheetEntryOrder.byPlayer:
        next = playerIndex + 1 < _selectedPlayers.length
            ? (_selectedPlayers[playerIndex + 1].id, lineId)
            : null;
        nextLabel = next == null
            ? null
            : _selectedPlayers[playerIndex + 1].displayName;
    }

    final entered = _lineValue(playerId, lineId);
    final currentValue = entered ?? line.initialIntegerValue ?? 0;
    final request = await showNumericValuePicker(
      context,
      title: '${player.displayName} · ${line.label}',
      currentValue: currentValue,
      hasCurrentValue: entered != null,
      allowReplace: line.allowReplace,
      allowAdjust: line.allowAdjust,
      entryMemory: _scoreEntryMemory,
      valuePickers: line.valuePickers,
      quickPickRange: line.quickPickRange,
      initialPick: _linePick(playerId, lineId),
      nextLabel: nextLabel,
    );
    if (request == null || !mounted) {
      return;
    }

    switch (request.action) {
      case ScoreValueEditAction.replace:
        _setLineValue(playerId, lineId, request.value, request.entryPick);
      case ScoreValueEditAction.add:
        _setLineValue(playerId, lineId, currentValue + request.value, null);
    }
    _refreshScoreSort();

    if (request.goToNext && next != null) {
      await _editLine(next.$1, next.$2);
    }
  }

  /// The sheet view's rows, top to bottom as the template lays them out,
  /// each with the entered line it edits (null for headings and calculated
  /// lines). The score line is the totals row, so it isn't repeated.
  List<(ScoreSheetRow, String?)> _sheetRows(
    List<QuickScoreAvailablePlayer> players,
  ) {
    final preset = _preset!;
    final engine = ScoreEngine.of(preset);
    final participants = _currentParticipants();
    final values = engine.lineValues(
      participants,
      roundNumber: 1,
      options: _formulaOptions,
    );
    final subLabels = engine.lineSubLabels(
      participants,
      roundNumber: 1,
      options: _formulaOptions,
    );
    final entered = {for (final line in preset.enteredLines) line.id: line};
    final calculated = {
      for (final line in preset.calculatedLines) line.id: line,
    };
    // A line's picture, when its label shows one and the picture exists;
    // otherwise the label shows its text.
    LineLabelDisplay displayOf(SheetLayoutItem item) =>
        item.style.label ?? preset.lineLabels;
    ImageProvider? imageFor(SheetLayoutItem item) {
      if (displayOf(item) == LineLabelDisplay.text) {
        return null;
      }
      final images = widget.templateImages;
      return images == null ? null : templateImageProvider(images, item.image);
    }

    bool imageOnly(SheetLayoutItem item) =>
        displayOf(item) == LineLabelDisplay.image;

    final layout = preset.sheetLayout.isNotEmpty
        ? preset.sheetLayout
        : [
            for (final line in preset.enteredLines) SheetLayoutItem.line(line.id),
            for (final line in preset.calculatedLines)
              if (!line.hidden) SheetLayoutItem.line(line.id),
          ];

    return [
      for (final item in layout)
        if (item.heading case final String heading)
          (ScoreSheetRow.heading(heading, style: item.style), null)
        else if (item.lineId case final String lineId
            when lineId != preset.scoreId)
          if (entered[lineId] case final line?)
            (
              ScoreSheetRow(
                label: line.label,
                style: item.style,
                image: imageFor(item),
                imageOnly: imageOnly(item),
                cells: [
                  for (final player in players)
                    switch (_lineValue(player.id, lineId)) {
                      final int value => ScoreSheetCell(
                          score: value,
                          scoreSubLabel: subLabels[player.id]?[lineId],
                        ),
                      null => ScoreSheetCell.empty,
                    },
                ],
              ),
              lineId,
            )
          else if (calculated[lineId] case final line?)
            (
              ScoreSheetRow(
                label: line.label,
                editable: false,
                image: imageFor(item),
                imageOnly: imageOnly(item),
                style: item.style,
                cells: [
                  for (final player in players)
                    ScoreSheetCell(
                      score: values[player.id]?[lineId] ?? 0,
                      scoreSubLabel: subLabels[player.id]?[lineId],
                    ),
                ],
              ),
              null,
            ),
    ];
  }

  /// The label of the line that is the score, such as "Total".
  String get _scoreLineLabel {
    final preset = _preset!;
    return [
          for (final line in preset.enteredLines)
            if (line.id == preset.scoreId) line.label,
          for (final line in preset.calculatedLines)
            if (line.id == preset.scoreId) line.label,
        ].firstOrNull ??
        'Total';
  }

  /// The sheet view: the template's lines down, players across, each
  /// player's score in the totals row. Tapping an entered cell opens it.
  Widget _buildSheet(List<QuickScoreAvailablePlayer> players) {
    final rows = _sheetRows(players);
    final scores = _currentScores();
    final cardTexts = _currentCardTexts();
    return ScoreSheetGrid(
      // The score line is the totals row, under its own label.
      totalLabel: _scoreLineLabel,
      players: [
        for (final player in players)
          ScoreSheetPlayer(
            id: player.id,
            name: player.displayName,
            color: _playerColors[player.id],
            total: scores[player.id] ?? 0,
            badges: [
              for (final marker in _preset!.markerLines)
                if (_markers[player.id]?.contains(marker.id) ?? false)
                  CardText(text: marker.badge, color: marker.color),
              ...?cardTexts[player.id]?.playerBadges,
            ],
          ),
      ],
      rows: [for (final (row, _) in rows) row],
      onCellTap: (row, column) {
        if (rows[row].$2 case final String lineId) {
          unawaited(_editLine(players[column].id, lineId));
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _preset = widget.preset;
    _setupModelFuture = widget.loadQuickScoreSetupModel(
      presetId: widget.preset.id,
    );
    _restoreInitialSession();
    _lifecycleListener = AppLifecycleListener(
      onHide: _autosaveCurrentSession,
      onInactive: _autosaveCurrentSession,
      onPause: _autosaveCurrentSession,
      onDetach: _autosaveCurrentSession,
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    for (final controller in _scoreControllers.values) {
      controller.removeListener(_handleScoreChanged);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      _QuickScoreStep.setup => widget.preset.displayName,
      _QuickScoreStep.entry => 'Enter Scores',
      _QuickScoreStep.result => 'Result',
    };

    final preset = _preset;

    return StayAwakeWhileScoring(
      controller: widget.stayAwakeController,
      active: _step == _QuickScoreStep.entry,
      child: AppScreenScaffold(
        title: title,
        subtitle: _step == _QuickScoreStep.setup ? null : _gameName,
        actions: [
          if (_step == _QuickScoreStep.entry && preset != null) ...[
            PlayerSortMenuButton(
              sortMode: _sortMode,
              onSelected: _setSortMode,
            ),
            ScoringHelpButton(
              lineDefinition: preset.enteredLines.first,
              markers: preset.markerLines,
            ),
          ],
        ],
        child: FutureBuilder<QuickScoreSetupModel>(
          future: _setupModelFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Quick Score could not load right now.'),
              );
            }
  
            // Keep showing the previous model while player changes reload it.
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
  
            final setupModel = snapshot.requireData;
          if (!_hasAppliedInitialGroup) {
            _setupGroupId = setupModel.initialGroupId;
            _hasAppliedInitialGroup = true;
          }
            _preset ??= setupModel.preset;
            if (_promptAnswers.isEmpty) {
              _promptAnswers = widget.initialPromptAnswers;
            }
  
            return switch (_step) {
              _QuickScoreStep.setup => _QuickScoreSetupStep(
                  setupModel: setupModel,
                  selectedPlayerIds: _selectedPlayerIds,
                  onTogglePlayer: _togglePlayer,
                  onReorderSelected: _reorderSelectedPlayerIds,
                  selectedGroupId: _setupGroupId,
                  onGroupSelected: _selectSetupGroup,
                  onAddPlayer: () => _handleAddPlayer(setupModel),
                  onContinue: () => _continueToScoreEntry(setupModel),
                ),
              _QuickScoreStep.entry => _QuickScoreEntryStep(
                  players: orderPlayersForDisplay(
                    _selectedPlayers,
                    sortMode: _sortMode,
                    winnerRule: resolvePresetOptions(
                      preset: _preset!,
                      promptAnswers: _promptAnswers,
                    ).winnerRule,
                    scoresByPlayerId: _scoreSortSnapshot,
                  ),
                  canReorder: _sortMode == PlayerSortMode.playOrder,
                  lineDefinition: _preset!.enteredLines.first,
                  controllers: _scoreControllers,
                  entryMemory: _scoreEntryMemory,
                  onPlayerTap: (player) => _handlePlayerTap(setupModel, player),
                  onReorder: _reorderPlayers,
                  onScoreEditorClosed: _refreshScoreSort,
                  entryPicks: _entryPicks,
                  onEntryPickChanged: _setEntryPick,
                  markers: _preset!.markerLines,
                  activeMarkers: _markers,
                  onMarkerChanged: _setMarker,
                  playerColors: _playerColors,
                  roundScores: _preset!.calculatedLines.isEmpty
                      ? null
                      : _currentScores(),
                  cardTexts: _currentCardTexts(),
                  onBack: () => setState(() => _step = _QuickScoreStep.setup),
                  onSave: _saveQuickScoreSession,
                  buildSheet: _preset!.hasSeveralEnteredLines ? _buildSheet : null,
                ),
              _QuickScoreStep.result => _QuickScoreResultStep(
                  result: _result!,
                  playerColors: _playerColors,
                  onBackToScoring: () => setState(() => _step = _QuickScoreStep.entry),
                ),
            };
          },
        ),
      ),
    );
  }

  void _setSortMode(PlayerSortMode sortMode) {
    setState(() {
      _sortMode = sortMode;
      _scoreSortSnapshot = _currentScores();
    });

    unawaited(_autosaveCurrentSession());
  }

  // Score sorting uses a snapshot so rows don't jump on every +/- tap.
  /// Markers set for a player, as entered values (1 when set).
  Map<String, int> _markerValuesFor(String playerId) => {
        for (final markerId in _markers[playerId] ?? const <String>{})
          markerId: 1,
      };

  void _setMarker(String playerId, String markerId, bool isSet) {
    final marker =
        _preset!.markerLines.firstWhere((marker) => marker.id == markerId);
    setState(() {
      // A one-per-round marker moves to the player it was just set for.
      if (isSet && marker.onePerRound) {
        for (final markers in _markers.values) {
          markers.remove(markerId);
        }
      }
      final markers = _markers.putIfAbsent(playerId, () => <String>{});
      if (isSet) {
        markers.add(markerId);
      } else {
        markers.remove(markerId);
      }
      _scoreSortSnapshot = _currentScores();
    });
    unawaited(_autosaveCurrentSession());
  }

  void _setEntryPick(String playerId, ValuePickerPick? entryPick) {
    setState(() {
      if (entryPick == null) {
        _entryPicks.remove(playerId);
      } else {
        _entryPicks[playerId] = entryPick;
      }
    });
    unawaited(_autosaveCurrentSession());
  }

  void _refreshScoreSort() {
    if (_sortMode != PlayerSortMode.score) {
      return;
    }

    setState(() => _scoreSortSnapshot = _currentScores());
  }

  /// The game's prompt answers, as formulas read them.
  Map<String, int> get _formulaOptions => resolvePresetOptions(
        preset: _preset!,
        promptAnswers: _promptAnswers,
      ).formulaValues;

  /// The name the game is played under, such as the name typed in for
  /// Quick Score, or the template's name.
  String get _gameName => resolvePresetOptions(
        preset: _preset ?? widget.preset,
        promptAnswers: _promptAnswers,
      ).gameName;

  Map<String, int> _currentScores() {
    return ScoreEngine.of(_preset!).scores(
      _currentParticipants(),
      roundNumber: 1,
      options: _formulaOptions,
    );
  }

  /// What the template shows on each player's card.
  Map<String, PlayerCardTexts> _currentCardTexts() {
    return ScoreEngine.of(_preset!).cardTexts(
      _currentParticipants(),
      roundNumber: 1,
      options: _formulaOptions,
    );
  }

  /// What is entered so far, with any tiles picked.
  List<QuickScoreParticipantValues> _currentParticipants() {
    final lines = _preset!.enteredLines;
    return [
      for (final player in _selectedPlayers)
        QuickScoreParticipantValues(
          playerId: player.id,
          displayName: player.displayName,
          // A line not entered yet counts as its starting value.
          enteredValues: {
            for (final line in lines)
              line.id: _lineValue(player.id, line.id) ??
                  line.initialIntegerValue ??
                  0,
            ..._markerValuesFor(player.id),
          },
          entryPicks: _linePicksFor(player.id),
        ),
    ];
  }

  void _reorderPlayers(int oldIndex, int newIndex) {
    setState(() {
      _selectedPlayers = moveListItem(_selectedPlayers, oldIndex, newIndex);
      _applySelectedPlayerOrder(
        _selectedPlayers.map((player) => player.id).toList(growable: false),
      );
    });

    unawaited(_autosaveCurrentSession());
  }

  void _reorderSelectedPlayerIds(List<String> orderedPlayerIds) {
    setState(() => _applySelectedPlayerOrder(orderedPlayerIds));
  }

  void _applySelectedPlayerOrder(List<String> orderedPlayerIds) {
    final remainingIds = _selectedPlayerIds
        .where((playerId) => !orderedPlayerIds.contains(playerId))
        .toList(growable: false);
    _selectedPlayerIds
      ..clear()
      ..addAll(orderedPlayerIds)
      ..addAll(remainingIds);
  }

  void _selectSetupGroup(String? groupId) {
    setState(() => _setupGroupId = groupId);
    unawaited(widget.rememberSetupPlayerGroup(groupId: groupId));
  }

  void _togglePlayer(String playerId, bool isSelected) {
    setState(() {
      if (isSelected) {
        if (!_selectedPlayerIds.contains(playerId)) {
          _selectedPlayerIds.add(playerId);
        }
      } else {
        _selectedPlayerIds.remove(playerId);
      }
    });
  }

  Future<void> _handleAddPlayer(QuickScoreSetupModel setupModel) async {
    final playerName = await showPlayerEditorSheet(
      context,
      title: 'Add Player',
      confirmLabel: 'Save Player',
      existingPlayers: _existingPlayerItems(setupModel),
    );

    if (playerName == null) {
      return;
    }

    try {
      final createdPlayer = await widget.createPlayer(displayName: playerName);

      if (!mounted) {
        return;
      }

      setState(() {
        _setupModelFuture = widget.loadQuickScoreSetupModel(presetId: widget.preset.id);
        if (!_selectedPlayerIds.contains(createdPlayer.id)) {
          _selectedPlayerIds.add(createdPlayer.id);
        }
      });
    } on PlayerValidationException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  List<PlayerListItemModel> _existingPlayerItems(
    QuickScoreSetupModel setupModel,
  ) {
    return setupModel.availablePlayers
        .map(
          (player) => PlayerListItemModel(
            id: player.id,
            displayName: player.displayName,
            isArchived: false,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _handlePlayerTap(
    QuickScoreSetupModel setupModel,
    QuickScoreAvailablePlayer player,
  ) async {
    final action = await showInGamePlayerActionsSheet(
      context,
      playerName: player.displayName,
      color: _playerColors[player.id],
      colorOwners: playerColorOwners(
        _playerColors,
        players: _selectedPlayers,
        exceptPlayerId: player.id,
      ),
      onColorChanged: (color) => _setPlayerColor(player.id, color),
    );

    if (action == null || !mounted) {
      return;
    }

    switch (action) {
      case InGamePlayerAction.edit:
        await _editPlayerInGame(setupModel, player);
      case InGamePlayerAction.switchPlayer:
        await _switchPlayerInGame(setupModel, player);
    }
  }

  void _setPlayerColor(String playerId, PlayerColor? color) {
    setState(() {
      if (color == null) {
        _playerColors.remove(playerId);
      } else {
        _playerColors[playerId] = color;
      }
    });
    unawaited(_autosaveCurrentSession());
  }

  Future<void> _editPlayerInGame(
    QuickScoreSetupModel setupModel,
    QuickScoreAvailablePlayer player,
  ) async {
    final updatedName = await showPlayerEditorSheet(
      context,
      title: 'Edit Player',
      confirmLabel: 'Save Changes',
      initialValue: player.displayName,
      existingPlayers: _existingPlayerItems(setupModel),
      editingPlayerId: player.id,
    );

    if (updatedName == null) {
      return;
    }

    try {
      final renamedPlayer = await widget.renamePlayer(
        playerId: player.id,
        displayName: updatedName,
      );

      if (!mounted) {
        return;
      }

      final playerNames = {renamedPlayer.id: renamedPlayer.displayName};
      setState(() {
        _selectedPlayers = _selectedPlayers
            .map((selected) => selected.withCurrentPlayerName(playerNames))
            .toList(growable: false);
        _setupModelFuture = widget.loadQuickScoreSetupModel(
          presetId: _preset!.id,
        );
      });

      unawaited(_autosaveCurrentSession());
    } on PlayerValidationException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _switchPlayerInGame(
    QuickScoreSetupModel setupModel,
    QuickScoreAvailablePlayer player,
  ) async {
    final choice = await showSwitchPlayerSheet(
      context,
      replacingPlayerName: player.displayName,
      candidates: setupModel.availablePlayers
          .where((candidate) => !_selectedPlayerIds.contains(candidate.id))
          .toList(growable: false),
    );

    if (choice == null || !mounted) {
      return;
    }

    final replacement = choice.isNewPlayer
        ? await _createReplacementPlayer(setupModel)
        : choice.player;

    if (replacement == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPlayers = _selectedPlayers
          .map((selected) => selected.id == player.id ? replacement : selected)
          .toList(growable: false);
      final selectedIndex = _selectedPlayerIds.indexOf(player.id);
      if (selectedIndex >= 0) {
        _selectedPlayerIds[selectedIndex] = replacement.id;
      }
      final controller = _scoreControllers.remove(player.id);
      if (controller != null) {
        _scoreControllers[replacement.id] = controller;
      }
      final markers = _markers.remove(player.id);
      if (markers != null) {
        _markers[replacement.id] = markers;
      }
      final entryPick = _entryPicks.remove(player.id);
      if (entryPick != null) {
        _entryPicks[replacement.id] = entryPick;
      }
      if (_otherLineValues.remove(player.id) case final values?) {
        _otherLineValues[replacement.id] = values;
      }
      if (_otherLinePicks.remove(player.id) case final picks?) {
        _otherLinePicks[replacement.id] = picks;
      }
      // The colour belongs to the place in the game, so it moves too.
      final color = _playerColors.remove(player.id);
      if (color != null) {
        _playerColors[replacement.id] = color;
      }
      _scoreSortSnapshot = _currentScores();
      _setupModelFuture = widget.loadQuickScoreSetupModel(
        presetId: _preset!.id,
      );
    });

    unawaited(_autosaveCurrentSession());
  }

  Future<QuickScoreAvailablePlayer?> _createReplacementPlayer(
    QuickScoreSetupModel setupModel,
  ) async {
    final playerName = await showPlayerEditorSheet(
      context,
      title: 'Add Player',
      confirmLabel: 'Save Player',
      existingPlayers: _existingPlayerItems(setupModel),
    );

    if (playerName == null) {
      return null;
    }

    try {
      final createdPlayer = await widget.createPlayer(displayName: playerName);
      return QuickScoreAvailablePlayer(
        id: createdPlayer.id,
        displayName: createdPlayer.displayName,
      );
    } on PlayerValidationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
      return null;
    }
  }

  void _continueToScoreEntry(QuickScoreSetupModel setupModel) {
    final playersById = {
      for (final player in setupModel.availablePlayers) player.id: player,
    };
    final selectedPlayers = _selectedPlayerIds
        .map((playerId) => playersById[playerId])
        .whereType<QuickScoreAvailablePlayer>()
        .toList(growable: false);

    if (selectedPlayers.length < setupModel.preset.minimumPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Choose at least ${setupModel.preset.minimumPlayers} players to continue.',
          ),
        ),
      );
      return;
    }

    for (final player in selectedPlayers) {
      _scoreControllers.putIfAbsent(
        player.id,
        () => _createScoreController(''),
      );
    }

    final removedPlayerIds = _scoreControllers.keys
        .where((playerId) => !selectedPlayers.any((player) => player.id == playerId))
        .toList(growable: false);
    for (final playerId in removedPlayerIds) {
      _scoreControllers.remove(playerId)?.dispose();
      _otherLineValues.remove(playerId);
      _otherLinePicks.remove(playerId);
    }

    setState(() {
      _selectedPlayers = selectedPlayers;
      _step = _QuickScoreStep.entry;
    });

    unawaited(_autosaveCurrentSession());
  }

  Future<void> _saveQuickScoreSession() async {
    final preset = _preset!;
    final lineDefinition = preset.enteredLines.first;
    final scoreLineId = preset.enteredLines.first.id;
    final participantValues = _buildParticipantValues(
      lineDefinition: lineDefinition,
      scoreLineId: scoreLineId,
      showErrors: true,
    );
    if (participantValues == null) {
      return;
    }

    try {
      final result = await widget.saveQuickScoreSession(
        preset: preset,
        participantValues: participantValues,
        promptAnswers: _promptAnswers,
        sessionId: _currentSessionId,
      );

      if (!mounted) {
        return;
      }

      await widget.deleteActiveSession(sessionId: result.sessionId);

      setState(() {
        _currentSessionId = result.sessionId;
        _result = result;
        _step = _QuickScoreStep.result;
      });
    } on QuickScoreValidationException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  void _restoreInitialSession() {
    final session = widget.initialActiveSession;
    if (session == null) {
      return;
    }

    _currentSessionId = session.sessionId;
    _promptAnswers = session.promptAnswers;
    _selectedPlayers = session.participantValues
        .map(
          (participant) => QuickScoreAvailablePlayer(
            id: participant.playerId,
            displayName: participant.displayName,
          ),
        )
        .toList(growable: false);
    _selectedPlayerIds.addAll(
      session.participantValues.map((participant) => participant.playerId),
    );

    final scoreLineId = _preset!.enteredLines.first.id;
    for (final participant in session.participantValues) {
      _scoreControllers[participant.playerId] = _createScoreController(
        participant.enteredValues[scoreLineId]?.toString() ?? '',
      );
    }
    for (final line in _preset!.enteredLines.skip(1)) {
      for (final participant in session.participantValues) {
        if (participant.enteredValues[line.id] case final int value) {
          _otherLineValues.putIfAbsent(participant.playerId, () => {})[line.id] =
              value;
        }
        if (participant.entryPicks[line.id] case final ValuePickerPick pick) {
          _otherLinePicks.putIfAbsent(participant.playerId, () => {})[line.id] =
              pick;
        }
      }
    }

    _entryPicks = {
      for (final participant in session.participantValues)
        if (participant.entryPicks[scoreLineId] case final ValuePickerPick pick)
          participant.playerId: pick,
    };
    _markers = {
      for (final participant in session.participantValues)
        participant.playerId: {
          for (final marker in _preset!.markerLines)
            if ((participant.enteredValues[marker.id] ?? 0) != 0) marker.id,
        },
    };
    _sortMode = session.sortMode;
    _playerColors.addAll(session.playerColors);
    _scoreSortSnapshot = _currentScores();
    _step = _QuickScoreStep.entry;
  }

  TextEditingController _createScoreController(String initialText) {
    final controller = TextEditingController(text: initialText);
    controller.addListener(_handleScoreChanged);
    return controller;
  }

  void _handleScoreChanged() {
    // A calculated score can depend on other players' entries, so every
    // row has to refresh, not just the one that changed.
    if (mounted && (_preset?.calculatedLines.isNotEmpty ?? false)) {
      setState(() {});
    }
    unawaited(_autosaveCurrentSession());
  }

  Future<void> _autosaveCurrentSession() async {
    final preset = _preset;
    if (preset == null || _step != _QuickScoreStep.entry) {
      return;
    }

    if (_selectedPlayers.length < preset.minimumPlayers) {
      return;
    }

    // Untouched rows are saved without a value, so they come back empty
    // (shown as "–") when the game is resumed.
    final participantValues = [
      for (final player in _selectedPlayers)
        QuickScoreParticipantValues(
          playerId: player.id,
          displayName: player.displayName,
          enteredValues: _enteredValuesFor(player.id),
          entryPicks: _linePicksFor(player.id),
        ),
    ];

    final sessionId =
        _currentSessionId ?? createQuickScoreSessionId(timestamp: DateTime.now());
    _currentSessionId = sessionId;

    await widget.saveQuickScoreActiveSession(
      session: QuickScoreActiveSession(
        sessionId: sessionId,
        presetId: preset.id,
        templateDisplayName: _gameName,
        promptAnswers: _promptAnswers,
        participantValues: participantValues,
        updatedAt: DateTime.now(),
        sortMode: _sortMode,
        playerColors: Map.of(_playerColors),
      ),
    );
  }

  /// What a player has entered so far, by line id: only the lines they
  /// have filled in, plus their markers.
  Map<String, int> _enteredValuesFor(String playerId) {
    return {
      for (final line in _preset!.enteredLines)
        line.id: ?_lineValue(playerId, line.id),
      ..._markerValuesFor(playerId),
    };
  }

  List<QuickScoreParticipantValues>? _buildParticipantValues({
    required EnteredLineDefinition lineDefinition,
    required String scoreLineId,
    required bool showErrors,
  }) {
    // A sheet saves what is entered; empty lines count as their starting
    // value, and the save refuses a player with nothing entered at all.
    if (_preset!.hasSeveralEnteredLines) {
      return [
        for (final player in _selectedPlayers)
          QuickScoreParticipantValues(
            playerId: player.id,
            displayName: player.displayName,
            enteredValues: _enteredValuesFor(player.id),
            entryPicks: _linePicksFor(player.id),
          ),
      ];
    }

    final participantValues = <QuickScoreParticipantValues>[];

    for (final player in _selectedPlayers) {
      final rawValue = _scoreControllers[player.id]!.text.trim();
      final parsedScore = _parseEnteredScore(
        rawValue: rawValue,
        lineDefinition: lineDefinition,
      );

      if (parsedScore == null) {
        if (showErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Enter a whole-number score for ${player.displayName}.',
              ),
            ),
          );
        }
        return null;
      }

      participantValues.add(
        QuickScoreParticipantValues(
          playerId: player.id,
          displayName: player.displayName,
          enteredValues: {
            scoreLineId: parsedScore,
            ..._markerValuesFor(player.id),
          },
        ),
      );
    }

    return participantValues;
  }

  int? _parseEnteredScore({
    required String rawValue,
    required EnteredLineDefinition lineDefinition,
  }) {
    if (rawValue.isEmpty) {
      return lineDefinition.initialIntegerValue;
    }

    return int.tryParse(rawValue);
  }
}

class _QuickScoreSetupStep extends StatelessWidget {
  const _QuickScoreSetupStep({
    required this.setupModel,
    required this.selectedPlayerIds,
    required this.onTogglePlayer,
    required this.onReorderSelected,
    required this.selectedGroupId,
    required this.onGroupSelected,
    required this.onAddPlayer,
    required this.onContinue,
  });

  final QuickScoreSetupModel setupModel;
  final List<String> selectedPlayerIds;
  final void Function(String playerId, bool isSelected) onTogglePlayer;
  final ValueChanged<List<String>> onReorderSelected;
  final String? selectedGroupId;
  final ValueChanged<String?> onGroupSelected;
  final VoidCallback onAddPlayer;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedPlayers = selectedPlayerIds
        .map(
          (playerId) => setupModel.availablePlayers
              .where((player) => player.id == playerId)
              .firstOrNull,
        )
        .whereType<QuickScoreAvailablePlayer>()
        .toList(growable: false);
    // A remembered group that has since been deleted falls back to All.
    final groupId =
        setupModel.groups.any((group) => group.id == selectedGroupId)
            ? selectedGroupId
            : null;
    final availablePlayers = setupModel.availablePlayers
        .where((player) => !selectedPlayerIds.contains(player.id))
        .where((player) => groupId == null || player.groupIds.contains(groupId))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose who is playing, then continue to enter scores.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              Text('Who\'s Playing', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              if (selectedPlayers.isEmpty)
                const _QuickScoreSelectionEmptyState(
                  message: 'Tap players below to add them to this game.',
                )
              else
                PlayerReorderableList(
                  shrinkWrap: true,
                  playerIds: selectedPlayers
                      .map((player) => player.id)
                      .toList(growable: false),
                  onReorder: (oldIndex, newIndex) => onReorderSelected(
                    moveListItem(selectedPlayers, oldIndex, newIndex)
                        .map((player) => player.id)
                        .toList(growable: false),
                  ),
                  itemBuilder: (context, index) {
                    final player = selectedPlayers[index];
                    return _QuickScorePlayerSelectionTile(
                      player: player,
                      onTap: () => onTogglePlayer(player.id, false),
                      trailingIcon: Icons.close_rounded,
                    );
                  },
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Available Players',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAddPlayer,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('New Player...'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (setupModel.groups.isNotEmpty) ...[
                PlayerGroupFilterChips(
                  groups: setupModel.groups,
                  selectedGroupId: groupId,
                  onSelected: onGroupSelected,
                ),
                const SizedBox(height: 10),
              ],
              if (availablePlayers.isEmpty)
                _QuickScoreSelectionEmptyState(
                  message: groupId == null
                      ? 'All saved players are already in this game.'
                      : 'Everyone in this group is already in the game.',
                )
              else
                ...availablePlayers.map(
                  (player) => _QuickScorePlayerSelectionTile(
                    player: player,
                    onTap: () => onTogglePlayer(player.id, true),
                    trailingIcon: Icons.add_rounded,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onContinue,
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _QuickScorePlayerSelectionTile extends StatelessWidget {
  const _QuickScorePlayerSelectionTile({
    required this.player,
    required this.onTap,
    required this.trailingIcon,
  });

  final QuickScoreAvailablePlayer player;
  final VoidCallback onTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  player.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                ),
              ),
              Icon(trailingIcon),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickScoreSelectionEmptyState extends StatelessWidget {
  const _QuickScoreSelectionEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _QuickScoreEntryStep extends StatelessWidget {
  const _QuickScoreEntryStep({
    required this.players,
    required this.lineDefinition,
    required this.controllers,
    required this.entryMemory,
    required this.canReorder,
    required this.onPlayerTap,
    required this.onReorder,
    required this.onScoreEditorClosed,
    required this.entryPicks,
    required this.onEntryPickChanged,
    required this.markers,
    required this.activeMarkers,
    required this.onMarkerChanged,
    required this.playerColors,
    required this.roundScores,
    required this.cardTexts,
    required this.onBack,
    required this.onSave,
    this.buildSheet,
  });

  final List<QuickScoreAvailablePlayer> players;
  final EnteredLineDefinition lineDefinition;

  /// Builds the sheet view for these players, shown instead of player cards
  /// when the sheet has several entered lines.
  final Widget Function(List<QuickScoreAvailablePlayer> players)? buildSheet;
  final Map<String, TextEditingController> controllers;
  final ScoreEntryMemory entryMemory;
  final bool canReorder;
  final ValueChanged<QuickScoreAvailablePlayer> onPlayerTap;
  final ReorderCallback onReorder;
  final VoidCallback onScoreEditorClosed;

  /// Value picker tiles behind each player's entry, by player id.
  final Map<String, ValuePickerPick> entryPicks;
  final void Function(String playerId, ValuePickerPick? entryPick)
      onEntryPickChanged;

  /// The template's markers and the ones set, by player id.
  final List<MarkerLineDefinition> markers;
  final Map<String, Set<String>> activeMarkers;
  final void Function(String playerId, String markerId, bool isSet)
      onMarkerChanged;

  /// Colours given to players for this game, by player id.
  final Map<String, PlayerColor> playerColors;

  /// Each player's calculated score, or null when the score is what was
  /// entered.
  final Map<String, int>? roundScores;

  /// What the template shows on each player's card, by player id.
  final Map<String, PlayerCardTexts> cardTexts;

  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: buildSheet != null
              ? buildSheet!(players)
              : LayoutBuilder(
            builder: (context, constraints) {
              final compact = NumericScoreField.shouldUseCompact(
                context,
                rowCount: players.length,
                availableHeight: constraints.maxHeight,
                lineDefinition: lineDefinition,
              );

              return PlayerReorderableList(
                playerIds:
                    players.map((player) => player.id).toList(growable: false),
                canReorder: canReorder,
                onReorder: onReorder,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return NumericScoreField(
                    label: player.displayName,
                    lineDefinition: lineDefinition,
                    controller: controllers[player.id]!,
                    compact: compact,
                    entryMemory: entryMemory,
                    onLabelTap: () => onPlayerTap(player),
                    entryPick: entryPicks[player.id],
                    onEntryPickChanged: (entryPick) =>
                        onEntryPickChanged(player.id, entryPick),
                    markers: markers,
                    activeMarkers: activeMarkers[player.id] ?? const {},
                    onMarkerChanged: (markerId, isSet) =>
                        onMarkerChanged(player.id, markerId, isSet),
                    roundScore: roundScores?[player.id],
                    cardTexts: cardTexts[player.id] ?? PlayerCardTexts.none,
                    playerColor: playerColors[player.id],
                    onEditorClosed: onScoreEditorClosed,
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(onPressed: onBack, child: const Text('Back')),
            const Spacer(),
            FilledButton(onPressed: onSave, child: const Text('Game Over')),
          ],
        ),
      ],
    );
  }
}

class _QuickScoreResultStep extends StatelessWidget {
  const _QuickScoreResultStep({
    required this.result,
    required this.playerColors,
    required this.onBackToScoring,
  });

  final QuickScoreResult result;
  final Map<String, PlayerColor> playerColors;
  final VoidCallback onBackToScoring;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winnerLabel =
        result.winners.map((winner) => winner.displayName).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.winners.length > 1 ? 'Tie for first' : 'Winner',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(winnerLabel, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: result.playerResults
                .map(
                  (playerResult) => PlayerHaloCard(
                    color: playerColors[playerResult.playerId],
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${playerResult.placement}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              playerResult.displayName,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${playerResult.finalScore}',
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: onBackToScoring,
              child: const Text('Back to Scoring'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.home,
                (route) => false,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ],
    );
  }
}
