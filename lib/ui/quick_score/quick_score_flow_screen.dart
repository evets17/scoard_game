import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';
import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/scoring/marker_field_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/score_row_label.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/value_picker_pick.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
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
        actions: [
          if (_step == _QuickScoreStep.entry && preset != null) ...[
            PlayerSortMenuButton(
              sortMode: _sortMode,
              onSelected: _setSortMode,
            ),
            ScoringHelpButton(
              fieldDefinition: preset.scoreFields.first,
              markers: preset.markerFields,
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
                  fieldDefinition: _preset!.scoreFields.first,
                  controllers: _scoreControllers,
                  entryMemory: _scoreEntryMemory,
                  onPlayerTap: (player) => _handlePlayerTap(setupModel, player),
                  onReorder: _reorderPlayers,
                  onScoreEditorClosed: _refreshScoreSort,
                  entryPicks: _entryPicks,
                  onEntryPickChanged: _setEntryPick,
                  markers: _preset!.markerFields,
                  activeMarkers: _markers,
                  onMarkerChanged: _setMarker,
                  playerColors: _playerColors,
                  roundScores: _preset!.calculatedFields.isEmpty
                      ? null
                      : _currentScores(),
                  scoreNotes: _currentNotes(),
                  onBack: () => setState(() => _step = _QuickScoreStep.setup),
                  onSave: _saveQuickScoreSession,
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
        _preset!.markerFields.firstWhere((marker) => marker.id == markerId);
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

  Map<String, int> _currentScores() {
    return ScoreEngine.of(_preset!).scores(
      _currentParticipants(),
      roundNumber: 1,
      options: _formulaOptions,
    );
  }

  /// The template's note under each player's score.
  Map<String, ScoreRowLabel> _currentNotes() {
    return ScoreEngine.of(_preset!).scoreNotes(
      _currentParticipants(),
      roundNumber: 1,
      options: _formulaOptions,
    );
  }

  /// What is entered so far, with any tiles picked.
  List<QuickScoreParticipantValues> _currentParticipants() {
    final fieldDefinition = _preset!.scoreFields.first;
    return [
      for (final player in _selectedPlayers)
        QuickScoreParticipantValues(
          playerId: player.id,
          displayName: player.displayName,
          enteredValues: {
            fieldDefinition.id: _parseEnteredScore(
                  rawValue: _scoreControllers[player.id]?.text.trim() ?? '',
                  fieldDefinition: fieldDefinition,
                ) ??
                0,
            ..._markerValuesFor(player.id),
          },
          entryPicks: {
            if (_entryPicks[player.id] case final ValuePickerPick pick)
              fieldDefinition.id: pick,
          },
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
    }

    setState(() {
      _selectedPlayers = selectedPlayers;
      _step = _QuickScoreStep.entry;
    });

    unawaited(_autosaveCurrentSession());
  }

  Future<void> _saveQuickScoreSession() async {
    final preset = _preset!;
    final fieldDefinition = preset.scoreFields.first;
    final scoreFieldId = preset.scoreFields.first.id;
    final participantValues = _buildParticipantValues(
      fieldDefinition: fieldDefinition,
      scoreFieldId: scoreFieldId,
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

    final scoreFieldId = _preset!.scoreFields.first.id;
    for (final participant in session.participantValues) {
      _scoreControllers[participant.playerId] = _createScoreController(
        participant.enteredValues[scoreFieldId]?.toString() ?? '',
      );
    }

    _entryPicks = {
      for (final participant in session.participantValues)
        if (participant.entryPicks[scoreFieldId] case final ValuePickerPick pick)
          participant.playerId: pick,
    };
    _markers = {
      for (final participant in session.participantValues)
        participant.playerId: {
          for (final marker in _preset!.markerFields)
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
    if (mounted && (_preset?.calculatedFields.isNotEmpty ?? false)) {
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
    final scoreFieldId = preset.scoreFields.first.id;
    final participantValues = [
      for (final player in _selectedPlayers)
        QuickScoreParticipantValues(
          playerId: player.id,
          displayName: player.displayName,
          enteredValues: _enteredValuesFor(player.id, scoreFieldId),
          entryPicks: {
            if (_entryPicks[player.id] case final ValuePickerPick entryPick)
              scoreFieldId: entryPick,
          },
        ),
    ];

    final sessionId =
        _currentSessionId ?? createQuickScoreSessionId(timestamp: DateTime.now());
    _currentSessionId = sessionId;

    await widget.saveQuickScoreActiveSession(
      session: QuickScoreActiveSession(
        sessionId: sessionId,
        presetId: preset.id,
        templateDisplayName: preset.displayName,
        promptAnswers: _promptAnswers,
        participantValues: participantValues,
        updatedAt: DateTime.now(),
        sortMode: _sortMode,
        playerColors: Map.of(_playerColors),
      ),
    );
  }

  /// What a player has entered so far: empty if their row is untouched.
  Map<String, int> _enteredValuesFor(String playerId, String scoreFieldId) {
    final rawValue = _scoreControllers[playerId]?.text.trim() ?? '';
    final value = int.tryParse(rawValue);
    return {scoreFieldId: ?value, ..._markerValuesFor(playerId)};
  }

  List<QuickScoreParticipantValues>? _buildParticipantValues({
    required ScoreFieldDefinition fieldDefinition,
    required String scoreFieldId,
    required bool showErrors,
  }) {
    final participantValues = <QuickScoreParticipantValues>[];

    for (final player in _selectedPlayers) {
      final rawValue = _scoreControllers[player.id]!.text.trim();
      final parsedScore = _parseEnteredScore(
        rawValue: rawValue,
        fieldDefinition: fieldDefinition,
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
            scoreFieldId: parsedScore,
            ..._markerValuesFor(player.id),
          },
        ),
      );
    }

    return participantValues;
  }

  int? _parseEnteredScore({
    required String rawValue,
    required ScoreFieldDefinition fieldDefinition,
  }) {
    if (rawValue.isEmpty) {
      return fieldDefinition.initialIntegerValue;
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
    required this.fieldDefinition,
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
    required this.scoreNotes,
    required this.onBack,
    required this.onSave,
  });

  final List<QuickScoreAvailablePlayer> players;
  final ScoreFieldDefinition fieldDefinition;
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
  final List<MarkerFieldDefinition> markers;
  final Map<String, Set<String>> activeMarkers;
  final void Function(String playerId, String markerId, bool isSet)
      onMarkerChanged;

  /// Colours given to players for this game, by player id.
  final Map<String, PlayerColor> playerColors;

  /// Each player's calculated score, or null when the score is what was
  /// entered.
  final Map<String, int>? roundScores;

  /// The template's note under each player's score, by player id.
  final Map<String, ScoreRowLabel> scoreNotes;

  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = NumericScoreField.shouldUseCompact(
                context,
                rowCount: players.length,
                availableHeight: constraints.maxHeight,
                fieldDefinition: fieldDefinition,
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
                    fieldDefinition: fieldDefinition,
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
                    scoreNote: scoreNotes[player.id],
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
