import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';
import 'package:scoard_game/application/models/results/round_score_result.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/player_sort_mode.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/quick_score_session_id_rules.dart';
import 'package:scoard_game/application/models/sessions/round_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_setup_model.dart';
import 'package:scoard_game/application/services/players/create_player.dart';
import 'package:scoard_game/application/services/players/rename_player.dart';
import 'package:scoard_game/application/services/scoring/remember_setup_player_group.dart';
import 'package:scoard_game/application/services/scoring/load_round_score_setup_model.dart';
import 'package:scoard_game/application/services/sessions/delete_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_round_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_round_score_session.dart';
import 'package:scoard_game/core/players/order_players.dart';
import 'package:scoard_game/core/scoring/built_in_templates/built_in_scoring_presets.dart';
import 'package:scoard_game/core/scoring/resolve_preset_options.dart';
import 'package:scoard_game/ui/help/scoring_help_screen.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
import 'package:scoard_game/ui/players/in_game_player_actions.dart';
import 'package:scoard_game/ui/players/player_editor_sheet.dart';
import 'package:scoard_game/ui/players/player_group_filter_chips.dart';
import 'package:scoard_game/ui/players/player_reorderable_list.dart';
import 'package:scoard_game/ui/players/player_sort_menu_button.dart';
import 'package:scoard_game/ui/settings/stay_awake_controller.dart';
import 'package:scoard_game/ui/score_input/numeric_score_field.dart';
import 'package:scoard_game/ui/score_input/score_entry_mode.dart';

class RoundScoreFlowScreen extends StatefulWidget {
  const RoundScoreFlowScreen({
    required this.loadRoundScoreSetupModel,
    required this.createPlayer,
    required this.renamePlayer,
    required this.stayAwakeController,
    required this.rememberSetupPlayerGroup,
    required this.saveRoundScoreSession,
    required this.saveRoundScoreActiveSession,
    required this.deleteActiveSession,
    this.initialPresetId,
    this.initialPromptAnswers = const [],
    this.initialActiveSession,
    super.key,
  });

  final LoadRoundScoreSetupModel loadRoundScoreSetupModel;
  final CreatePlayer createPlayer;
  final RenamePlayer renamePlayer;
  final StayAwakeController stayAwakeController;
  final RememberSetupPlayerGroup rememberSetupPlayerGroup;
  final SaveRoundScoreSession saveRoundScoreSession;
  final SaveRoundScoreActiveSession saveRoundScoreActiveSession;
  final DeleteActiveSession deleteActiveSession;
  final String? initialPresetId;
  final List<PresetPromptAnswer> initialPromptAnswers;
  final RoundScoreActiveSession? initialActiveSession;

  @override
  State<RoundScoreFlowScreen> createState() => _RoundScoreFlowScreenState();
}

enum _RoundScoreStep {
  setup,
  roundEntry,
  result,
}

class _RoundScoreFlowScreenState extends State<RoundScoreFlowScreen> {
  late Future<RoundScoreSetupModel> _setupModelFuture;
  _RoundScoreStep _step = _RoundScoreStep.setup;
  final List<String> _selectedPlayerIds = <String>[];
  final Map<String, TextEditingController> _scoreControllers = {};
  final ScoreEntryMemory _scoreEntryMemory = ScoreEntryMemory();
  String? _setupGroupId;
  bool _hasAppliedInitialGroup = false;
  final List<RoundScoreRoundValues> _savedRounds = <RoundScoreRoundValues>[];
  List<QuickScoreAvailablePlayer> _selectedPlayers = const [];
  ScoringPreset? _preset;
  List<PresetPromptAnswer> _promptAnswers = const [];
  RoundScoreResult? _result;
  String? _currentSessionId;
  int _currentRoundNumber = 1;
  AppLifecycleListener? _lifecycleListener;
  PlayerSortMode _sortMode = PlayerSortMode.playOrder;

  @override
  void initState() {
    super.initState();
    _setupModelFuture = widget.loadRoundScoreSetupModel(
      presetId:
          widget.initialActiveSession?.presetId ??
          widget.initialPresetId ??
          'round-score-basic',
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
      _RoundScoreStep.setup => 'Round Score',
      _RoundScoreStep.roundEntry => 'Round $_currentRoundNumber',
      _RoundScoreStep.result => 'Final Result',
    };

    final preset = _preset;

    return StayAwakeWhileScoring(
      controller: widget.stayAwakeController,
      active: _step == _RoundScoreStep.roundEntry,
      child: AppScreenScaffold(
        title: title,
        actions: [
          if (_step == _RoundScoreStep.roundEntry && preset != null) ...[
            PlayerSortMenuButton(
              sortMode: _sortMode,
              onSelected: _setSortMode,
            ),
            ScoringHelpButton(
              fieldDefinition: preset.scoreFields.first,
              isRoundScoring: true,
            ),
          ],
        ],
        child: FutureBuilder<RoundScoreSetupModel>(
          future: _setupModelFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Round Score could not load right now.'));
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
              _RoundScoreStep.setup => _RoundScoreSetupStep(
                  setupModel: setupModel,
                  selectedPlayerIds: _selectedPlayerIds,
                  onTogglePlayer: _togglePlayer,
                  onReorderSelected: _reorderSelectedPlayerIds,
                  selectedGroupId: _setupGroupId,
                  onGroupSelected: _selectSetupGroup,
                  onAddPlayer: () => _handleAddPlayer(setupModel),
                  onContinue: () => _continueToRoundEntry(setupModel),
                ),
              _RoundScoreStep.roundEntry => _RoundScoreEntryStep(
                  currentRoundNumber: _currentRoundNumber,
                  fieldDefinition: _preset!.scoreFields.first,
                  players: _selectedPlayers,
                  sortMode: _sortMode,
                  winnerRule: resolvePresetOptions(
                    preset: _preset!,
                    promptAnswers: _promptAnswers,
                  ).winnerRule,
                  controllers: _scoreControllers,
                  entryMemory: _scoreEntryMemory,
                  savedRounds: _savedRounds,
                  onPlayerTap: (player) => _handlePlayerTap(setupModel, player),
                  onReorder: _reorderPlayers,
                  onBack: () => setState(() => _step = _RoundScoreStep.setup),
                  onPreviousRound: _goToPreviousRound,
                  onCompleteRound: _completeRound,
                  onGameOver: _completeGame,
                ),
              _RoundScoreStep.result => _RoundScoreResultStep(
                  result: _result!,
                  onBackToRounds: () => setState(() => _step = _RoundScoreStep.roundEntry),
                ),
            };
          },
        ),
      ),
    );
  }

  void _setSortMode(PlayerSortMode sortMode) {
    setState(() => _sortMode = sortMode);
    unawaited(_autosaveCurrentSession());
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

  Future<void> _handleAddPlayer(RoundScoreSetupModel setupModel) async {
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
        _setupModelFuture = widget.loadRoundScoreSetupModel();
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
    RoundScoreSetupModel setupModel,
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
    RoundScoreSetupModel setupModel,
    QuickScoreAvailablePlayer player,
  ) async {
    final action = await showInGamePlayerActionsSheet(
      context,
      playerName: player.displayName,
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

  Future<void> _editPlayerInGame(
    RoundScoreSetupModel setupModel,
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
        _replaceSavedRoundParticipants(
          (participant) => participant.withCurrentPlayerName(playerNames),
        );
        _setupModelFuture = widget.loadRoundScoreSetupModel(
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
    RoundScoreSetupModel setupModel,
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
      _replaceSavedRoundParticipants(
        (participant) => participant.playerId == player.id
            ? QuickScoreParticipantValues(
                playerId: replacement.id,
                displayName: replacement.displayName,
                enteredValues: participant.enteredValues,
              )
            : participant,
      );
      _setupModelFuture = widget.loadRoundScoreSetupModel(
        presetId: _preset!.id,
      );
    });

    unawaited(_autosaveCurrentSession());
  }

  Future<QuickScoreAvailablePlayer?> _createReplacementPlayer(
    RoundScoreSetupModel setupModel,
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

  void _replaceSavedRoundParticipants(
    QuickScoreParticipantValues Function(QuickScoreParticipantValues) replace,
  ) {
    for (var index = 0; index < _savedRounds.length; index++) {
      final round = _savedRounds[index];
      _savedRounds[index] = RoundScoreRoundValues(
        roundNumber: round.roundNumber,
        participantValues:
            round.participantValues.map(replace).toList(growable: false),
      );
    }
  }

  void _continueToRoundEntry(RoundScoreSetupModel setupModel) {
    final playersById = {
      for (final player in setupModel.availablePlayers) player.id: player,
    };
    final selectedPlayers = _selectedPlayerIds
        .map((playerId) => playersById[playerId])
        .whereType<QuickScoreAvailablePlayer>()
        .toList(growable: false);

    if (selectedPlayers.length < setupModel.preset.minimumPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least two players to continue.')),
      );
      return;
    }

    for (final player in selectedPlayers) {
      _scoreControllers.putIfAbsent(
        player.id,
        () => _createScoreController(''),
      );
    }

    setState(() {
      _selectedPlayers = selectedPlayers;
      _step = _RoundScoreStep.roundEntry;
    });

    unawaited(_autosaveCurrentSession());
  }

  Future<void> _completeRound() async {
    final round = _buildCurrentRoundValues(requireScores: true);
    if (round == null) {
      return;
    }

    setState(() {
      _upsertRound(round);
      _currentRoundNumber += 1;
      _loadRoundIntoInputs(_currentRoundNumber);
    });

    unawaited(_autosaveCurrentSession());
  }

  Future<void> _goToPreviousRound() async {
    if (_currentRoundNumber <= 1) {
      return;
    }

    final shouldContinue = _persistCurrentRoundIfNeeded();
    if (!shouldContinue) {
      return;
    }

    setState(() {
      _currentRoundNumber -= 1;
      _loadRoundIntoInputs(_currentRoundNumber);
    });

    unawaited(_autosaveCurrentSession());
  }

  Future<void> _completeGame() async {
    final rounds = List<RoundScoreRoundValues>.from(_savedRounds);
    final currentRound = _buildCurrentRoundValues(requireScores: false);
    if (currentRound != null) {
      _upsertRound(currentRound, target: rounds);
    }

    try {
      final result = await widget.saveRoundScoreSession(
        preset: _preset!,
        rounds: rounds,
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
        _savedRounds
          ..clear()
          ..addAll(rounds);
        if (rounds.isNotEmpty) {
          _currentRoundNumber = rounds.last.roundNumber;
          _loadRoundIntoInputs(_currentRoundNumber);
        }
        _step = _RoundScoreStep.result;
      });
    } on RoundScoreValidationException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  RoundScoreRoundValues? _buildCurrentRoundValues({required bool requireScores}) {
    final preset = _preset!;
    final fieldDefinition = preset.scoreFields.first;
    final scoreFieldId = preset.scoreFields.first.id;
    final participantValues = <QuickScoreParticipantValues>[];
    final rawValues = _selectedPlayers
        .map((player) => _scoreControllers[player.id]!.text.trim())
        .toList(growable: false);

    if (!requireScores && rawValues.every((value) => value.isEmpty)) {
      return null;
    }

    for (var index = 0; index < _selectedPlayers.length; index++) {
      final player = _selectedPlayers[index];
      final rawValue = rawValues[index];
      final parsedScore = _parseEnteredScore(
        rawValue: rawValue,
        fieldDefinition: fieldDefinition,
      );
      if (parsedScore == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enter a whole-number score for ${player.displayName}.')),
        );
        return null;
      }

      participantValues.add(
        QuickScoreParticipantValues(
          playerId: player.id,
          displayName: player.displayName,
          enteredValues: {scoreFieldId: parsedScore},
        ),
      );
    }

    return RoundScoreRoundValues(
      roundNumber: _currentRoundNumber,
      participantValues: participantValues,
    );
  }

  void _resetCurrentRoundInputs() {
    for (final controller in _scoreControllers.values) {
      controller.clear();
    }
  }

  bool _persistCurrentRoundIfNeeded() {
    final rawValues = _selectedPlayers
        .map((player) => _scoreControllers[player.id]!.text.trim())
        .toList(growable: false);

    if (rawValues.every((value) => value.isEmpty)) {
      final existingRound = _findSavedRound(_currentRoundNumber);
      if (existingRound != null) {
        _loadRoundValues(existingRound);
      }
      return true;
    }

    final round = _buildCurrentRoundValues(requireScores: true);
    if (round == null) {
      return false;
    }

    _upsertRound(round);
    return true;
  }

  RoundScoreRoundValues? _findSavedRound(int roundNumber) {
    for (final round in _savedRounds) {
      if (round.roundNumber == roundNumber) {
        return round;
      }
    }

    return null;
  }

  void _loadRoundIntoInputs(int roundNumber) {
    final existingRound = _findSavedRound(roundNumber);
    if (existingRound == null) {
      _resetCurrentRoundInputs();
      return;
    }

    _loadRoundValues(existingRound);
  }

  void _loadRoundValues(RoundScoreRoundValues round) {
    final scoreFieldId = _preset!.scoreFields.first.id;
    final valuesByPlayerId = {
      for (final participant in round.participantValues)
        participant.playerId: participant.enteredValues[scoreFieldId] ?? 0,
    };

    for (final player in _selectedPlayers) {
      final controller = _scoreControllers[player.id]!;
      final value = valuesByPlayerId[player.id];
      controller.text = value?.toString() ?? '';
    }
  }

  void _upsertRound(
    RoundScoreRoundValues round, {
    List<RoundScoreRoundValues>? target,
  }) {
    final rounds = target ?? _savedRounds;
    final existingIndex = rounds.indexWhere(
      (existingRound) => existingRound.roundNumber == round.roundNumber,
    );

    if (existingIndex >= 0) {
      rounds[existingIndex] = round;
      return;
    }

    rounds.add(round);
    rounds.sort((left, right) => left.roundNumber.compareTo(right.roundNumber));
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

  void _restoreInitialSession() {
    final session = widget.initialActiveSession;
    if (session == null) {
      return;
    }

    _currentSessionId = session.sessionId;
    _preset = getBuiltInScoringPresetById(session.presetId);
    _promptAnswers = session.promptAnswers;
    _selectedPlayers = session.selectedPlayers;
    _selectedPlayerIds.addAll(session.selectedPlayers.map((player) => player.id));
    _savedRounds.addAll(session.savedRounds);
    _currentRoundNumber = session.currentRoundNumber;

    for (final player in session.selectedPlayers) {
      _scoreControllers[player.id] = _createScoreController('');
    }

    final scoreFieldId = _preset!.scoreFields.first.id;
    final currentValuesByPlayerId = {
      for (final participant in session.currentRoundParticipantValues)
        participant.playerId: participant.enteredValues[scoreFieldId] ?? 0,
    };
    for (final player in session.selectedPlayers) {
      _scoreControllers[player.id]!.text =
          '${currentValuesByPlayerId[player.id] ?? 0}';
    }

    _sortMode = session.sortMode;
    _step = _RoundScoreStep.roundEntry;
  }

  TextEditingController _createScoreController(String initialText) {
    final controller = TextEditingController(text: initialText);
    controller.addListener(_handleScoreChanged);
    return controller;
  }

  void _handleScoreChanged() {
    unawaited(_autosaveCurrentSession());
  }

  Future<void> _autosaveCurrentSession() async {
    final preset = _preset;
    if (preset == null || _step != _RoundScoreStep.roundEntry) {
      return;
    }

    if (_selectedPlayers.length < preset.minimumPlayers) {
      return;
    }

    final scoreFieldId = preset.scoreFields.first.id;
    final currentRoundParticipantValues = _selectedPlayers
        .map(
          (player) => QuickScoreParticipantValues(
            playerId: player.id,
            displayName: player.displayName,
            enteredValues: {
              scoreFieldId: _parseEnteredScore(
                    rawValue: _scoreControllers[player.id]!.text.trim(),
                    fieldDefinition: preset.scoreFields.first,
                  ) ??
                  0,
            },
          ),
        )
        .toList(growable: false);

    final sessionId =
        _currentSessionId ?? createQuickScoreSessionId(timestamp: DateTime.now());
    _currentSessionId = sessionId;

    await widget.saveRoundScoreActiveSession(
      session: RoundScoreActiveSession(
        sessionId: sessionId,
        presetId: preset.id,
        templateDisplayName: preset.displayName,
        promptAnswers: _promptAnswers,
        selectedPlayers: _selectedPlayers,
        savedRounds: List<RoundScoreRoundValues>.from(_savedRounds),
        currentRoundParticipantValues: currentRoundParticipantValues,
        currentRoundNumber: _currentRoundNumber,
        sortMode: _sortMode,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class _RoundScoreSetupStep extends StatelessWidget {
  const _RoundScoreSetupStep({
    required this.setupModel,
    required this.selectedPlayerIds,
    required this.onTogglePlayer,
    required this.onReorderSelected,
    required this.selectedGroupId,
    required this.onGroupSelected,
    required this.onAddPlayer,
    required this.onContinue,
  });

  final RoundScoreSetupModel setupModel;
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
          (playerId) => setupModel.availablePlayers.where((player) => player.id == playerId).firstOrNull,
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
          'Choose who is playing, then continue to score rounds.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              Text('Who\'s Playing', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              if (selectedPlayers.isEmpty)
                const _RoundScoreSelectionEmptyState(
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
                    return _RoundScorePlayerSelectionTile(
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
                _RoundScoreSelectionEmptyState(
                  message: groupId == null
                      ? 'All saved players are already in this game.'
                      : 'Everyone in this group is already in the game.',
                )
              else
                ...availablePlayers.map(
                  (player) => _RoundScorePlayerSelectionTile(
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

class _RoundScorePlayerSelectionTile extends StatelessWidget {
  const _RoundScorePlayerSelectionTile({
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

class _RoundScoreSelectionEmptyState extends StatelessWidget {
  const _RoundScoreSelectionEmptyState({required this.message});

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

class _RoundScoreEntryStep extends StatelessWidget {
  const _RoundScoreEntryStep({
    required this.currentRoundNumber,
    required this.fieldDefinition,
    required this.players,
    required this.sortMode,
    required this.winnerRule,
    required this.controllers,
    required this.entryMemory,
    required this.savedRounds,
    required this.onPlayerTap,
    required this.onReorder,
    required this.onBack,
    required this.onPreviousRound,
    required this.onCompleteRound,
    required this.onGameOver,
  });

  final int currentRoundNumber;
  final ScoreFieldDefinition fieldDefinition;
  final List<QuickScoreAvailablePlayer> players;
  final Map<String, TextEditingController> controllers;
  final ScoreEntryMemory entryMemory;
  final PlayerSortMode sortMode;
  final WinnerRule winnerRule;
  final List<RoundScoreRoundValues> savedRounds;
  final ValueChanged<QuickScoreAvailablePlayer> onPlayerTap;
  final ReorderCallback onReorder;
  final VoidCallback onBack;
  final VoidCallback onPreviousRound;
  final VoidCallback onCompleteRound;
  final VoidCallback onGameOver;

  @override
  Widget build(BuildContext context) {
    final priorRoundTotals = _calculatePriorRoundTotals();
    // Score sorting uses earlier rounds only, so rows stay put while this
    // round is being entered.
    final displayedPlayers = orderPlayersForDisplay(
      players,
      sortMode: sortMode,
      winnerRule: winnerRule,
      scoresByPlayerId: priorRoundTotals,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton(
              onPressed: currentRoundNumber > 1 ? onPreviousRound : null,
              child: const Text('<< Previous Round'),
            ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: onCompleteRound,
              child: const Text('Next Round >>'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = NumericScoreField.shouldUseCompact(
                context,
                rowCount: displayedPlayers.length,
                availableHeight: constraints.maxHeight,
                fieldDefinition: fieldDefinition,
                hasValueLabel: true,
              );

              return PlayerReorderableList(
                playerIds: displayedPlayers
                    .map((player) => player.id)
                    .toList(growable: false),
                canReorder: sortMode == PlayerSortMode.playOrder,
                onReorder: onReorder,
                itemBuilder: (context, index) {
                  final player = displayedPlayers[index];
                  return NumericScoreField(
                    label: player.displayName,
                    fieldDefinition: fieldDefinition,
                    controller: controllers[player.id]!,
                    compact: compact,
                    entryMemory: entryMemory,
                    onLabelTap: () => onPlayerTap(player),
                    valueLabelMinimumDigits: 3,
                    valueLabelBuilder: (currentValue) =>
                        '${((priorRoundTotals[player.id] ?? 0) + currentValue)}',
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
            FilledButton(
              onPressed: onGameOver,
              child: const Text('Game Over'),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, int> _calculatePriorRoundTotals() {
    final totals = <String, int>{};

    for (final round in savedRounds) {
      if (round.roundNumber == currentRoundNumber) {
        continue;
      }

      for (final participant in round.participantValues) {
        totals.update(
          participant.playerId,
          (score) => score + (participant.enteredValues[fieldDefinition.id] ?? 0),
          ifAbsent: () => participant.enteredValues[fieldDefinition.id] ?? 0,
        );
      }
    }

    return totals;
  }
}

class _RoundScoreResultStep extends StatelessWidget {
  const _RoundScoreResultStep({
    required this.result,
    required this.onBackToRounds,
  });

  final RoundScoreResult result;
  final VoidCallback onBackToRounds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winnerLabel = result.winners.map((winner) => winner.displayName).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.winners.length > 1 ? 'Tie for first' : 'Winner',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(winnerLabel, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('Rounds played: ${result.roundCount}', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: result.playerResults
                .map(
                  (playerResult) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                            '${playerResult.cumulativeScore}',
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
              onPressed: onBackToRounds,
              child: const Text('Back to Rounds'),
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