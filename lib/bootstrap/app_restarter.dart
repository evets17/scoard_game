import 'package:flutter/material.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';

/// Restores the backup checked by [current]'s data backup, then opens the
/// app afresh on it with [open]. Returns the new environment, and whether
/// the restore happened.
///
/// When the restored data can't be opened, the data from before is put
/// back and opened instead, so the app is never left without its data.
Future<(AppEnvironment, bool)> restoreAndReopen(
  AppEnvironment current,
  Future<AppEnvironment> Function() open,
) async {
  final backup = current.dataBackup!;
  await backup.closeAndSwapIn();

  AppEnvironment? restored;
  try {
    restored = await open();
    // Opening is lazy: the first read opens the file and upgrades it.
    await restored.sessionRepository.countCompletedSessions();
    await restored.playerRepository.loadPlayers();
    return (restored, true);
  } on Object catch (error, stackTrace) {
    debugPrint('Restore failed, putting the old data back: $error');
    debugPrintStack(stackTrace: stackTrace);
    await restored?.dataBackup?.close();
    backup.putBackSafetyCopy();
    return (await open(), false);
  }
}

/// Holds the app's environment, and opens it afresh after a restore so
/// every screen reads the restored data.
class AppRestarter extends StatefulWidget {
  const AppRestarter({
    required this.initialEnvironment,
    required this.openEnvironment,
    required this.builder,
    super.key,
  });

  final AppEnvironment initialEnvironment;

  /// Builds an environment on the app's data, as at startup.
  final Future<AppEnvironment> Function() openEnvironment;

  /// The app for an environment. [restore] restores the checked backup and
  /// returns whether it happened. The app gives [messenger] to its
  /// MaterialApp, so the outcome can be shown once it has opened afresh.
  final Widget Function(
    AppEnvironment environment,
    Future<bool> Function() restore,
    GlobalKey<ScaffoldMessengerState> messenger,
  ) builder;

  @override
  State<AppRestarter> createState() => _AppRestarterState();
}

class _AppRestarterState extends State<AppRestarter> {
  late AppEnvironment _environment = widget.initialEnvironment;
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  Future<bool> _restore() async {
    final (environment, restored) =
        await restoreAndReopen(_environment, widget.openEnvironment);
    if (!mounted) {
      return restored;
    }
    setState(() => _environment = environment);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messenger.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            restored
                ? 'Backup restored.'
                : "The backup couldn't be restored. Your data is as it was.",
          ),
        ),
      );
    });
    return restored;
  }

  @override
  Widget build(BuildContext context) {
    // A new key starts the app over, back on the home screen, so nothing
    // from before the restore is left on screen.
    return KeyedSubtree(
      key: ObjectKey(_environment),
      child: widget.builder(_environment, _restore, _messenger),
    );
  }
}
