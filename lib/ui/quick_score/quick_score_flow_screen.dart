import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';
import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/sessions/quick_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/quick_score_session_id_rules.dart';
import 'package:scoard_game/application/models/sessions/quick_score_setup_model.dart';
import 'package:scoard_game/application/services/players/create_player.dart';
import 'package:scoard_game/application/services/scoring/load_quick_score_setup_model.dart';
import 'package:scoard_game/application/services/sessions/delete_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_quick_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_quick_score_session.dart';
import 'package:scoard_game/core/scoring/built_in_templates/built_in_scoring_presets.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
import 'package:scoard_game/ui/players/player_editor_sheet.dart';
import 'package:scoard_game/ui/score_input/numeric_score_field.dart';

class QuickScoreFlowScreen extends StatefulWidget {
  const QuickScoreFlowScreen({
    required this.loadQuickScoreSetupModel,
    required this.createPlayer,
    required this.saveQuickScoreSession,
    required this.saveQuickScoreActiveSession,
    required this.deleteActiveSession,
    this.initialPresetId,
    this.initialPromptAnswers = const [],
    this.initialActiveSession,
    super.key,
  });

  final LoadQuickScoreSetupModel loadQuickScoreSetupModel;
  final CreatePlayer createPlayer;
  final SaveQuickScoreSession saveQuickScoreSession;
  final SaveQuickScoreActiveSession saveQuickScoreActiveSession;
  final DeleteActiveSession deleteActiveSession;
  final String? initialPresetId;
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
  ScoringPreset? _preset;
  List<PresetPromptAnswer> _promptAnswers = const [];
  QuickScoreResult? _result;
  String? _currentSessionId;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _setupModelFuture = widget.loadQuickScoreSetupModel(
      presetId:
          widget.initialActiveSession?.presetId ??
          widget.initialPresetId ??
          'quick-final-score-basic',
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
      _QuickScoreStep.setup => 'Quick Score',
      _QuickScoreStep.entry => 'Enter Scores',
      _QuickScoreStep.result => 'Result',
    };

    return AppScreenScaffold(
      title: title,
      child: FutureBuilder<QuickScoreSetupModel>(
        future: _setupModelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Quick Score could not load right now.'),
            );
          }

          final setupModel = snapshot.requireData;
          _preset ??= setupModel.preset;
          if (_promptAnswers.isEmpty) {
            _promptAnswers = widget.initialPromptAnswers;
          }

          return switch (_step) {
            _QuickScoreStep.setup => _QuickScoreSetupStep(
                setupModel: setupModel,
                selectedPlayerIds: _selectedPlayerIds,
                onTogglePlayer: _togglePlayer,
                onAddPlayer: () => _handleAddPlayer(setupModel),
                onContinue: () => _continueToScoreEntry(setupModel),
              ),
            _QuickScoreStep.entry => _QuickScoreEntryStep(
                players: _selectedPlayers,
                fieldDefinition: _preset!.scoreFields.first,
                controllers: _scoreControllers,
                onBack: () => setState(() => _step = _QuickScoreStep.setup),
                onSave: _saveQuickScoreSession,
              ),
            _QuickScoreStep.result => _QuickScoreResultStep(
                result: _result!,
                onBackToScoring: () => setState(() => _step = _QuickScoreStep.entry),
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

  Future<void> _handleAddPlayer(QuickScoreSetupModel setupModel) async {
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
        _setupModelFuture = widget.loadQuickScoreSetupModel();
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

  void _continueToScoreEntry(QuickScoreSetupModel setupModel) {
    final defaultScoreValue =
        setupModel.preset.scoreFields.first.initialIntegerValue;
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
        () => _createScoreController(defaultScoreValue?.toString() ?? ''),
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
    _preset = getBuiltInScoringPresetById(session.presetId);
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
        '${participant.enteredValues[scoreFieldId] ?? 0}',
      );
    }

    _step = _QuickScoreStep.entry;
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
    if (preset == null || _step != _QuickScoreStep.entry) {
      return;
    }

    if (_selectedPlayers.length < preset.minimumPlayers) {
      return;
    }

    final fieldDefinition = preset.scoreFields.first;
    final scoreFieldId = fieldDefinition.id;
    final participantValues = _buildParticipantValues(
      fieldDefinition: fieldDefinition,
      scoreFieldId: scoreFieldId,
      showErrors: false,
    );
    if (participantValues == null) {
      return;
    }

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
      ),
    );
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
          enteredValues: {scoreFieldId: parsedScore},
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
    required this.onAddPlayer,
    required this.onContinue,
  });

  final QuickScoreSetupModel setupModel;
  final List<String> selectedPlayerIds;
  final void Function(String playerId, bool isSelected) onTogglePlayer;
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
    final availablePlayers = setupModel.availablePlayers
        .where((player) => !selectedPlayerIds.contains(player.id))
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
                ...selectedPlayers.map(
                  (player) => _QuickScorePlayerSelectionTile(
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
                const _QuickScoreSelectionEmptyState(
                  message: 'All saved players are already in this game.',
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
    required this.onBack,
    required this.onSave,
  });

  final List<QuickScoreAvailablePlayer> players;
  final ScoreFieldDefinition fieldDefinition;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap a score to edit it.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: players
                .map(
                  (player) => NumericScoreField(
                    label: player.displayName,
                    fieldDefinition: fieldDefinition,
                    controller: controllers[player.id]!,
                  ),
                )
                .toList(growable: false),
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
    required this.onBackToScoring,
  });

  final QuickScoreResult result;
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
                  (playerResult) => Card(
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
