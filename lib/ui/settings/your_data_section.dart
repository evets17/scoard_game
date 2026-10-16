import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/backup/backup_check_result.dart';
import 'package:scoard_game/application/models/backup/backup_summary.dart';
import 'package:scoard_game/application/repositories/backup_files.dart';
import 'package:scoard_game/infrastructure/backup/app_data_backup.dart';
import 'package:scoard_game/infrastructure/backup/file_backup_files.dart';
import 'package:scoard_game/ui/settings/online_templates_section.dart';

/// Back up the app's players and games to a file, and restore one.
class YourDataSection extends StatefulWidget {
  const YourDataSection({
    required this.dataBackup,
    required this.restoreBackup,
    this.files = const FileBackupFiles(),
    this.now,
    super.key,
  });

  final AppDataBackup dataBackup;

  /// Restores the checked backup and opens the app on it. Returns whether
  /// it was restored.
  final Future<bool> Function() restoreBackup;

  final BackupFiles files;

  /// The clock; tests set it.
  final DateTime Function()? now;

  @override
  State<YourDataSection> createState() => _YourDataSectionState();
}

class _YourDataSectionState extends State<YourDataSection> {
  bool _busy = false;

  DateTime _now() => (widget.now ?? DateTime.now)();

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _backUp() async {
    setState(() => _busy = true);
    try {
      final now = _now();
      final bytes = await widget.dataBackup.backUp();
      final saved = await widget.files.save(
        fileName: backupFileName(now),
        bytes: bytes,
      );
      if (saved) {
        await widget.dataBackup.recordBackedUp(now);
        if (mounted) {
          _say('Backup saved.');
        }
      }
    } on Object catch (error) {
      debugPrint('Backup failed: $error');
      if (mounted) {
        _say("The backup couldn't be saved. Try again.");
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final bytes = await widget.files.open();
      if (bytes == null || !mounted) {
        return;
      }
      switch (await widget.dataBackup.check(bytes)) {
        case BackupRefused(:final reason):
          if (mounted) {
            await _showRefusal(reason);
          }
        case BackupAccepted(:final summary):
          final current = await widget.dataBackup.summarizeCurrent();
          if (!mounted) {
            return;
          }
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) =>
                _ConfirmRestoreDialog(backup: summary, current: current),
          );
          if (confirmed ?? false) {
            // The app opens afresh on the restored data, and says how it
            // went; this screen is gone by then.
            await widget.restoreBackup();
            return;
          }
      }
    } on Object catch (error) {
      debugPrint('Restore failed: $error');
      if (mounted) {
        _say("The backup couldn't be read. Try again.");
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showRefusal(BackupRefusal reason) {
    final message = switch (reason) {
      BackupRefusal.notABackup => "This file isn't a Scoard backup.",
      BackupRefusal.newerApp =>
        'This backup was made by a newer version of the app. Update the '
            'app, then restore.',
      BackupRefusal.damaged => "This backup is damaged and can't be restored.",
    };
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Can't restore"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastBackedUpAt = widget.dataBackup.lastBackedUpAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your data', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Players and games stay on this phone and are removed if the app '
          'is uninstalled. Keep a backup somewhere safe.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                enabled: !_busy,
                leading: const Icon(Icons.save_alt_rounded),
                title: const Text('Back up'),
                subtitle: Text(
                  lastBackedUpAt == null
                      ? 'Save your players and games to a file. '
                          'Not backed up yet.'
                      : 'Save your players and games to a file. Last backed '
                          'up ${describeWhen(lastBackedUpAt, _now())}.',
                ),
                onTap: _backUp,
              ),
              const Divider(height: 1),
              ListTile(
                enabled: !_busy,
                leading: const Icon(Icons.settings_backup_restore_rounded),
                title: const Text('Restore'),
                subtitle: const Text(
                  "Replace this phone's players and games with a backup file.",
                ),
                onTap: _restore,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "scoard-backup-2026-10-15.db".
String backupFileName(DateTime when) {
  String two(int value) => value.toString().padLeft(2, '0');
  return 'scoard-backup-${when.year}-${two(when.month)}-${two(when.day)}.db';
}

class _ConfirmRestoreDialog extends StatelessWidget {
  const _ConfirmRestoreDialog({required this.backup, required this.current});

  final BackupSummary backup;
  final BackupSummary current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    String date(DateTime? when) => when == null ? '–' : describeDate(when);

    TableRow row(String label, String inBackup, String onPhone) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(label),
            ),
            Text(inBackup, textAlign: TextAlign.end),
            Text(onPhone, textAlign: TextAlign.end),
          ],
        );

    return AlertDialog(
      title: const Text('Restore this backup?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  const SizedBox.shrink(),
                  Text('Backup', style: heading, textAlign: TextAlign.end),
                  Text('This phone', style: heading, textAlign: TextAlign.end),
                ],
              ),
              row('Players', '${backup.players}', '${current.players}'),
              row(
                'Finished games',
                '${backup.finishedGames}',
                '${current.finishedGames}',
              ),
              row(
                'Games in progress',
                '${backup.gamesInProgress}',
                '${current.gamesInProgress}',
              ),
              row(
                'Latest game',
                date(backup.latestGameAt),
                date(current.latestGameAt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "This phone's players and games will be replaced. This can't be "
            'undone.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Replace this phone's data"),
        ),
      ],
    );
  }
}
