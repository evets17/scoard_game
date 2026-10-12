import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/players/players_screen.dart';

void main() {
  Future<void> openPlayers(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final environment = await AppBootstrap.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: PlayersScreen(
          loadPlayersScreenModel: environment.loadPlayersScreenModel,
          createPlayer: environment.createPlayer,
          renamePlayer: environment.renamePlayer,
          archivePlayer: environment.archivePlayer,
          unarchivePlayer: environment.unarchivePlayer,
          createPlayerGroup: environment.createPlayerGroup,
          renamePlayerGroup: environment.renamePlayerGroup,
          deletePlayerGroup: environment.deletePlayerGroup,
          setPlayerGroups: environment.setPlayerGroups,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder chip(String label) => find.widgetWithText(ChoiceChip, label);

  Future<void> tapChip(WidgetTester tester, String label) async {
    await tester.ensureVisible(chip(label));
    await tester.pumpAndSettle();
    await tester.tap(chip(label));
    await tester.pumpAndSettle();
  }

  Future<void> createGroupInEditor(WidgetTester tester, String name) async {
    await tester.tap(find.text('New group'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      name,
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
  }

  testWidgets('a player can be added to a new group and filtered by it', (
    tester,
  ) async {
    await openPlayers(tester);

    await tester.tap(find.text('Mina'));
    await tester.pumpAndSettle();
    await createGroupInEditor(tester, 'Family');

    expect(
      tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Family')).selected,
      isTrue,
    );

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Family'), findsWidgets);

    await tapChip(tester, 'Family');

    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Avery'), findsNothing);
  });

  testWidgets('archiving from the editor keeps the player\'s groups', (
    tester,
  ) async {
    await openPlayers(tester);

    await tester.tap(find.text('Owen'));
    await tester.pumpAndSettle();
    await createGroupInEditor(tester, 'Friends');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Owen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive player'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Owen'), findsNothing);

    await tapChip(tester, 'Friends');
    expect(find.text('Owen'), findsNothing);

    await tapChip(tester, 'Archived');
    expect(find.text('Owen'), findsOneWidget);

    await tester.tap(find.text('Owen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore player'));
    await tester.pumpAndSettle();

    await tapChip(tester, 'Friends');
    expect(find.text('Owen'), findsOneWidget);
  });

  testWidgets('groups can be created and deleted from Manage groups', (
    tester,
  ) async {
    await openPlayers(tester);

    await tester.tap(find.byTooltip('Manage groups'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Group'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'All');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.textContaining('already used by the app'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Game Night');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(chip('Game Night'), findsOneWidget);

    await tester.tap(find.byTooltip('Manage groups'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete Game Night'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(chip('Game Night'), findsNothing);
    expect(find.text('Avery'), findsOneWidget);
  });
}
