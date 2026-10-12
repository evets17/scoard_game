import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/app_summaries.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/application/services/players/create_player.dart';
import 'package:scoard_game/application/services/players/rename_player.dart';
import 'package:scoard_game/application/services/scoring/load_quick_score_setup_model.dart';
import 'package:scoard_game/application/services/scoring/load_round_score_setup_model.dart';
import 'package:scoard_game/application/services/sessions/delete_active_session.dart';
import 'package:scoard_game/application/services/sessions/load_quick_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/load_round_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_quick_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_quick_score_session.dart';
import 'package:scoard_game/application/services/sessions/save_round_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_round_score_session.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
import 'package:scoard_game/ui/quick_score/quick_score_flow_screen.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';
import 'package:scoard_game/ui/settings/stay_awake_controller.dart';

class ActiveGamesScreen extends StatefulWidget {
  const ActiveGamesScreen({
    required this.sessionRepository,
    required this.loadQuickScoreActiveSession,
    required this.saveQuickScoreActiveSession,
    required this.loadQuickScoreSetupModel,
    required this.saveQuickScoreSession,
    required this.loadRoundScoreActiveSession,
    required this.saveRoundScoreActiveSession,
    required this.loadRoundScoreSetupModel,
    required this.saveRoundScoreSession,
    required this.deleteActiveSession,
    required this.createPlayer,
    required this.renamePlayer,
    required this.stayAwakeController,
    super.key,
  });

  final SessionRepository sessionRepository;
  final LoadQuickScoreActiveSession loadQuickScoreActiveSession;
  final SaveQuickScoreActiveSession saveQuickScoreActiveSession;
  final LoadQuickScoreSetupModel loadQuickScoreSetupModel;
  final SaveQuickScoreSession saveQuickScoreSession;
  final LoadRoundScoreActiveSession loadRoundScoreActiveSession;
  final SaveRoundScoreActiveSession saveRoundScoreActiveSession;
  final LoadRoundScoreSetupModel loadRoundScoreSetupModel;
  final SaveRoundScoreSession saveRoundScoreSession;
  final DeleteActiveSession deleteActiveSession;
  final CreatePlayer createPlayer;
  final RenamePlayer renamePlayer;
  final StayAwakeController stayAwakeController;

  @override
  State<ActiveGamesScreen> createState() => _ActiveGamesScreenState();
}

class _ActiveGamesScreenState extends State<ActiveGamesScreen> {
  late Future<List<ActiveSessionSummary>> _activeSessionsFuture;
  bool _didAttemptAutoResume = false;
  bool _autoResumeSingle = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    _autoResumeSingle = arguments == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScreenScaffold(
      title: 'Active Games',
      child: FutureBuilder<List<ActiveSessionSummary>>(
        future: _activeSessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Active Games could not load right now.',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            );
          }

          final sessions = snapshot.requireData;

          if (_autoResumeSingle && !_didAttemptAutoResume && sessions.length == 1) {
            _didAttemptAutoResume = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _resumeSession(sessions.single, replaceCurrent: true);
              }
            });

            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (sessions.isEmpty) {
            return Center(
              child: Text(
                'No games are waiting to be resumed.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView(
            children: sessions
                .map(
                  (session) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      title: Text(session.gameName),
                      subtitle: Text(
                        '${session.participantLabel}\n${session.progressLabel}',
                      ),
                      isThreeLine: true,
                      leading: const Icon(Icons.play_circle_fill_rounded),
                      trailing: IconButton(
                        onPressed: () => _deleteSession(session),
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: 'Discard game',
                      ),
                      onTap: () => _resumeSession(session),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }

  Future<void> _resumeSession(
    ActiveSessionSummary session, {
    bool replaceCurrent = false,
  }) async {
    Widget? destination;

    switch (session.kind) {
      case ActiveSessionKind.quickScore:
        final activeSession = await widget.loadQuickScoreActiveSession(
          sessionId: session.id,
        );
        if (activeSession == null || !mounted) {
          return;
        }

        destination = QuickScoreFlowScreen(
          loadQuickScoreSetupModel: widget.loadQuickScoreSetupModel,
          createPlayer: widget.createPlayer,
          renamePlayer: widget.renamePlayer,
          stayAwakeController: widget.stayAwakeController,
          saveQuickScoreSession: widget.saveQuickScoreSession,
          saveQuickScoreActiveSession: widget.saveQuickScoreActiveSession,
          deleteActiveSession: widget.deleteActiveSession,
          initialActiveSession: activeSession,
        );
      case ActiveSessionKind.roundScore:
        final activeSession = await widget.loadRoundScoreActiveSession(
          sessionId: session.id,
        );
        if (activeSession == null || !mounted) {
          return;
        }

        destination = RoundScoreFlowScreen(
          loadRoundScoreSetupModel: widget.loadRoundScoreSetupModel,
          createPlayer: widget.createPlayer,
          renamePlayer: widget.renamePlayer,
          stayAwakeController: widget.stayAwakeController,
          saveRoundScoreSession: widget.saveRoundScoreSession,
          saveRoundScoreActiveSession: widget.saveRoundScoreActiveSession,
          deleteActiveSession: widget.deleteActiveSession,
          initialActiveSession: activeSession,
        );
    }

    final route = MaterialPageRoute<void>(builder: (_) => destination!);

    if (replaceCurrent) {
      await Navigator.of(context).pushReplacement(route);
      return;
    }

    await Navigator.of(context).push(route);
    if (mounted) {
      _reload();
    }
  }

  Future<void> _deleteSession(ActiveSessionSummary session) async {
    await widget.deleteActiveSession(sessionId: session.id);

    if (mounted) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _activeSessionsFuture = widget.sessionRepository.loadActiveSessions(
        limit: 50,
      );
    });
  }
}