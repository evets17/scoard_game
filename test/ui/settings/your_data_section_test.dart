import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/backup/backup_check_result.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/ui/settings/your_data_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_backup_files.dart';
import '../../support/test_templates.dart';

void main() {
  late Directory folder;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    folder = Directory.systemTemp.createTempSync('your_data');
  });

  tearDown(() => folder.deleteSync(recursive: true));

  Future<AppEnvironment> open(WidgetTester tester) async {
    final environment = (await tester.runAsync(
      () => AppBootstrap.initialize(
        usePersistentStorage: true,
        templateCatalog: loadTestTemplateCatalog(),
        dataFolder: folder,
      ),
    ))!;
    await tester.runAsync(
      () => environment.createPlayer(displayName: 'Avery'),
    );
    addTearDown(() => tester.runAsync(environment.dataBackup!.close));
    return environment;
  }

  Future<void> pumpSection(
    WidgetTester tester,
    AppEnvironment environment,
    FakeBackupFiles files,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YourDataSection(
            dataBackup: environment.dataBackup!,
            restoreBackup: () async => true,
            files: files,
            now: () => DateTime(2026, 10, 15, 9),
          ),
        ),
      ),
    );
  }

  /// Lets the file and database work behind a tap finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 50),
          ));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('Back up saves a dated file and remembers when', (tester) async {
    final environment = await open(tester);
    final files = FakeBackupFiles();
    await pumpSection(tester, environment, files);
    expect(find.textContaining('Not backed up yet'), findsOneWidget);

    await tester.tap(find.text('Back up'));
    await settle(tester);

    expect(files.savedName, 'scoard-backup-2026-10-15.db');
    final check = await tester.runAsync(
      () => environment.dataBackup!.check(files.savedBytes!),
    );
    expect((check! as BackupAccepted).summary.players, 1);
    expect(find.text('Backup saved.'), findsOneWidget);
    expect(environment.dataBackup!.lastBackedUpAt, DateTime(2026, 10, 15, 9));
  });

  testWidgets('a file that is not a backup is refused', (tester) async {
    final environment = await open(tester);
    await pumpSection(
      tester,
      environment,
      FakeBackupFiles(toOpen: Uint8List.fromList('hello'.codeUnits)),
    );

    await tester.tap(find.text('Restore'));
    await settle(tester);

    expect(find.text("This file isn't a Scoard backup."), findsOneWidget);
  });

  testWidgets('a backup shows what it holds beside this phone first', (
    tester,
  ) async {
    final environment = await open(tester);
    final backup = await tester.runAsync(environment.dataBackup!.backUp);
    await tester.runAsync(
      () => environment.createPlayer(displayName: 'Jules'),
    );

    final files = FakeBackupFiles(toOpen: backup);
    var restores = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YourDataSection(
            dataBackup: environment.dataBackup!,
            restoreBackup: () async {
              restores += 1;
              return true;
            },
            files: files,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Restore'));
    await settle(tester);

    expect(find.text('Restore this backup?'), findsOneWidget);
    final players = find.ancestor(
      of: find.text('Players'),
      matching: find.byType(Table),
    );
    expect(players, findsOneWidget);
    // One player in the backup, two on the phone now.
    expect(find.descendant(of: players, matching: find.text('1')), findsOneWidget);
    expect(find.descendant(of: players, matching: find.text('2')), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(restores, 0);

    await tester.tap(find.text('Restore'));
    await settle(tester);
    await tester.tap(find.text("Replace this phone's data"));
    await settle(tester);
    expect(restores, 1);
  });
}
