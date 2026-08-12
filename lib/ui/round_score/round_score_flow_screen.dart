import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';
import 'package:scoard_game/application/models/results/round_score_result.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/quick_score_session_id_rules.dart';
import 'package:scoard_game/application/models/sessions/round_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_setup_model.dart';
import 'package:scoard_game/application/services/players/create_player.dart';
import 'package:scoard_game/application/services/scoring/load_round_score_setup_model.dart';
import 'package:scoard_game/application/services/sessions/delete_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_round_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_round_score_session.dart';
import 'package:scoard_game/core/scoring/built_in_templates/built_in_scoring_presets.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
import 'package:scoard_game/ui/players/player_editor_sheet.dart';
import 'package:scoard_game/ui/score_input/numeric_score_field.dart';

class RoundScoreFlowScreen extends StatefulWidget {
  const RoundScoreFlowScreen({
    required this.loadRoundScoreSetupModel,
    required this.createPlayer,
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
  final List<RoundScoreRoundValues> _savedRounds = <RoundScoreRoundValues>[];
  List<QuickScoreAvailablePlayer> _selectedPlayers = const [];
  ScoringPreset? _preset;
  List<PresetPromptAnswer> _promptAnswers = const [];
  RoundScoreResult? _result;
  String? _currentSessionId;
  int _currentRoundNumber = 1;
  AppLifecycleListener? _lifecycleListener;

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

    return AppScreenScaffold(
      title: title,
      child: FutureBuilder<RoundScoreSetupModel>(
        future: _setupModelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Round Score could not load right now.'));
          }

          final setupModel = snapshot.requireData;
          _preset ??= setupModel.preset;
          if (_promptAnswers.isEmpty) {
            _promptAnswers = widget.initialPromptAnswers;
          }

          return switch (_step) {
            _RoundScoreStep.setup => _RoundScoreSetupStep(
                setupModel: setupModel,
                selectedPlayerIds: _selectedPlayerIds,
                onTogglePlayer: _togglePlayer,
                onAddPlayer: () => _handleAddPlayer(setupModel),
                onContinue: () => _continueToRoundEntry(setupModel),
              ),
            _RoundScoreStep.roundEntry => _RoundScoreEntryStep(
                currentRoundNumber: _currentRoundNumber,
                fieldDefinition: _preset!.scoreFields.first,
                players: _selectedPlayers,
                controllers: _scoreControllers,
                savedRounds: _savedRounds,
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
    );
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
    final existingPlayers = setupModel.availablePlayers
        .map(
          (player) => PlayerListItemModel(
            id: player.id,
            displayName: player.displayName,
            isArchived: false,
          ),
        )
        .toList(growable: false);

    final playerName = await showPlayerEditorSheet(
      context,
      title: 'Add Player',
      confirmLabel: 'Save Player',
      existingPlayers: existingPlayers,
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
    required this.onAddPlayer,
    required this.onContinue,
  });

  final RoundScoreSetupModel setupModel;
  final List<String> selectedPlayerIds;
  final void Function(String playerId, bool isSelected) onTogglePlayer;
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
    final availablePlayers = setupModel.availablePlayers
        .where((player) => !selectedPlayerIds.contains(player.id))
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
                ...selectedPlayers.map(
                  (player) => _RoundScorePlayerSelectionTile(
                    player: player,
                    onTap: () => onTogglePlayer(player.id, false),
                    trailingIcon: Icons.close_rounded,
                  ),
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
              if (availablePlayers.isEmpty)
                const _RoundScoreSelectionEmptyState(
                  message: 'All saved players are already in this game.',
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
    required this.controllers,
    required this.savedRounds,
    required this.onBack,
    required this.onPreviousRound,
    required this.onCompleteRound,
    required this.onGameOver,
  });

  final int currentRoundNumber;
  final ScoreFieldDefinition fieldDefinition;
  final List<QuickScoreAvailablePlayer> players;
  final Map<String, TextEditingController> controllers;
  final List<RoundScoreRoundValues> savedRounds;
  final VoidCallback onBack;
  final VoidCallback onPreviousRound;
  final VoidCallback onCompleteRound;
  final VoidCallback onGameOver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorRoundTotals = _calculatePriorRoundTotals();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the scores for round $currentRoundNumber.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
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
          child: ListView(
            children: [
              ...players.map(
                (player) => NumericScoreField(
                  label: player.displayName,
                  fieldDefinition: fieldDefinition,
                  controller: controllers[player.id]!,
                  valueLabelMinimumDigits: 3,
                  valueLabelBuilder: (currentValue) =>
                      '${((priorRoundTotals[player.id] ?? 0) + currentValue)}',
                ),
              ),
            ],
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