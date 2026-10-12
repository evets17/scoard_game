import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/players/player_name_rules.dart';
import 'package:scoard_game/application/models/players/player_record.dart';
import 'package:scoard_game/application/models/results/quick_score_player_result.dart';
import 'package:scoard_game/application/models/results/round_score_player_result.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';

part 'app_database.g.dart';

class PlayersTable extends Table {
  TextColumn get id => text()();

  TextColumn get displayName => text()();

  TextColumn get normalizedDisplayName => text()();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {normalizedDisplayName},
      ];
}

class PlayerGroupsTable extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get normalizedName => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {normalizedName},
      ];
}

class PlayerGroupMembersTable extends Table {
  TextColumn get playerId => text()();

  TextColumn get groupId => text()();

  @override
  Set<Column<Object>> get primaryKey => {playerId, groupId};
}

class QuickScoreSessionsTable extends Table {
  TextColumn get id => text()();

  TextColumn get templateId => text()();

  TextColumn get templateDisplayName => text()();

  TextColumn get winnerRule => text()();

  TextColumn get optionsJson => text().withDefault(const Constant('[]'))();

  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class QuickScorePlayerResultsTable extends Table {
  TextColumn get sessionId => text()();

  TextColumn get playerId => text()();

  TextColumn get displayName => text()();

  IntColumn get finalScore => integer()();

  IntColumn get placement => integer()();

  BoolColumn get isTied => boolean()();
}

class QuickScoreFieldValuesTable extends Table {
  TextColumn get sessionId => text()();

  TextColumn get playerId => text()();

  TextColumn get fieldId => text()();

  IntColumn get integerValue => integer()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId, playerId, fieldId};
}

class RoundScoreSessionsTable extends Table {
  TextColumn get id => text()();

  TextColumn get templateId => text()();

  TextColumn get templateDisplayName => text()();

  TextColumn get winnerRule => text()();

  TextColumn get optionsJson => text().withDefault(const Constant('[]'))();

  IntColumn get roundCount => integer()();

  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RoundScorePlayerResultsTable extends Table {
  TextColumn get sessionId => text()();

  TextColumn get playerId => text()();

  TextColumn get displayName => text()();

  IntColumn get cumulativeScore => integer()();

  IntColumn get placement => integer()();

  BoolColumn get isTied => boolean()();
}

class RoundScoreFieldValuesTable extends Table {
  TextColumn get sessionId => text()();

  IntColumn get roundNumber => integer()();

  TextColumn get playerId => text()();

  TextColumn get displayName => text()();

  TextColumn get fieldId => text()();

  IntColumn get integerValue => integer()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId, roundNumber, playerId, fieldId};
}

class ActiveSessionsTable extends Table {
  TextColumn get id => text()();

  TextColumn get sessionKind => text()();

  TextColumn get templateId => text()();

  TextColumn get templateDisplayName => text()();

  TextColumn get participantLabel => text()();

  TextColumn get progressLabel => text()();

  TextColumn get payloadJson => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [
  PlayersTable,
  QuickScoreSessionsTable,
  QuickScorePlayerResultsTable,
  QuickScoreFieldValuesTable,
  RoundScoreSessionsTable,
  RoundScorePlayerResultsTable,
  RoundScoreFieldValuesTable,
  ActiveSessionsTable,
  PlayerGroupsTable,
  PlayerGroupMembersTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async => migrator.createAll(),
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(quickScoreSessionsTable);
            await migrator.createTable(quickScorePlayerResultsTable);
          }
          if (from < 3) {
            await migrator.createTable(quickScoreFieldValuesTable);
          }
          if (from < 4) {
            await migrator.createTable(roundScoreSessionsTable);
            await migrator.createTable(roundScorePlayerResultsTable);
            await migrator.createTable(roundScoreFieldValuesTable);
          }
          if (from < 5) {
            await migrator.createTable(activeSessionsTable);
          }
          if (from < 6) {
            await migrator.addColumn(
              quickScoreSessionsTable,
              quickScoreSessionsTable.optionsJson as GeneratedColumn<Object>,
            );
            await migrator.addColumn(
              roundScoreSessionsTable,
              roundScoreSessionsTable.optionsJson as GeneratedColumn<Object>,
            );
          }
          if (from < 7) {
            await migrator.createTable(playerGroupsTable);
            await migrator.createTable(playerGroupMembersTable);
          }
        },
      );

  Future<List<PlayerRecord>> loadPlayers() async {
    final rows = await select(playersTable).get();
    final memberships = await select(playerGroupMembersTable).get();
    final groupIdsByPlayerId = <String, Set<String>>{};
    for (final membership in memberships) {
      groupIdsByPlayerId
          .putIfAbsent(membership.playerId, () => <String>{})
          .add(membership.groupId);
    }

    return rows
        .map(
          (row) => PlayerRecord(
            id: row.id,
            displayName: row.displayName,
            isArchived: row.isArchived,
            createdAt: row.createdAt,
            groupIds: groupIdsByPlayerId[row.id] ?? const {},
          ),
        )
        .toList(growable: false);
  }

  Future<List<PlayerGroup>> loadPlayerGroups() async {
    final rows = await select(playerGroupsTable).get();

    return rows
        .map(
          (row) => PlayerGroup(
            id: row.id,
            name: row.name,
            createdAt: row.createdAt,
          ),
        )
        .toList(growable: false);
  }

  Future<void> createPlayerGroup({
    required String id,
    required String name,
    required DateTime createdAt,
  }) {
    return into(playerGroupsTable).insert(
      PlayerGroupsTableCompanion.insert(
        id: id,
        name: name,
        normalizedName: normalizePlayerName(name),
        createdAt: createdAt,
      ),
    );
  }

  Future<void> renamePlayerGroup({
    required String id,
    required String name,
  }) {
    return (update(playerGroupsTable)..where((table) => table.id.equals(id)))
        .write(
      PlayerGroupsTableCompanion(
        name: Value(name),
        normalizedName: Value(normalizePlayerName(name)),
      ),
    );
  }

  Future<void> deletePlayerGroup({required String id}) {
    return transaction(() async {
      await (delete(playerGroupMembersTable)
            ..where((table) => table.groupId.equals(id)))
          .go();
      await (delete(playerGroupsTable)..where((table) => table.id.equals(id)))
          .go();
    });
  }

  Future<void> setPlayerGroups({
    required String playerId,
    required Set<String> groupIds,
  }) {
    return transaction(() async {
      await (delete(playerGroupMembersTable)
            ..where((table) => table.playerId.equals(playerId)))
          .go();
      await batch((batch) {
        batch.insertAll(
          playerGroupMembersTable,
          groupIds.map(
            (groupId) => PlayerGroupMembersTableCompanion.insert(
              playerId: playerId,
              groupId: groupId,
            ),
          ),
        );
      });
    });
  }

  Future<void> createPlayer({
    required String id,
    required String displayName,
    required DateTime createdAt,
  }) {
    return into(playersTable).insert(
      PlayersTableCompanion.insert(
        id: id,
        displayName: displayName,
        normalizedDisplayName: normalizePlayerName(displayName),
        createdAt: createdAt,
      ),
    );
  }

  Future<void> renamePlayer({
    required String id,
    required String displayName,
  }) {
    return (update(playersTable)..where((table) => table.id.equals(id))).write(
      PlayersTableCompanion(
        displayName: Value(displayName),
        normalizedDisplayName: Value(normalizePlayerName(displayName)),
      ),
    );
  }

  Future<void> setPlayerArchived({
    required String id,
    required bool isArchived,
  }) {
    return (update(playersTable)..where((table) => table.id.equals(id))).write(
      PlayersTableCompanion(isArchived: Value(isArchived)),
    );
  }

  Future<int> countCompletedQuickScoreSessions() async {
    final countExpression = quickScoreSessionsTable.id.count();
    final query = selectOnly(quickScoreSessionsTable)
      ..addColumns([countExpression]);

    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<int> countCompletedRoundScoreSessions() async {
    final countExpression = roundScoreSessionsTable.id.count();
    final query = selectOnly(roundScoreSessionsTable)
      ..addColumns([countExpression]);

    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<List<QuickScoreSessionsTableData>> loadQuickScoreSessions({
    int limit = 20,
  }) {
    return (select(quickScoreSessionsTable)
          ..orderBy([
            (table) => OrderingTerm.desc(table.completedAt),
          ])
          ..limit(limit))
        .get();
  }

  Future<List<QuickScorePlayerResultsTableData>> loadQuickScorePlayerResults({
    required String sessionId,
  }) {
    return (select(quickScorePlayerResultsTable)
          ..where((table) => table.sessionId.equals(sessionId))
          ..orderBy([
            (table) => OrderingTerm.asc(table.placement),
            (table) => OrderingTerm.asc(table.displayName),
          ]))
        .get();
  }

  Future<List<QuickScoreFieldValuesTableData>> loadQuickScoreFieldValues({
    required String sessionId,
  }) {
    return (select(quickScoreFieldValuesTable)
          ..where((table) => table.sessionId.equals(sessionId))
          ..orderBy([
            (table) => OrderingTerm.asc(table.playerId),
            (table) => OrderingTerm.asc(table.fieldId),
          ]))
        .get();
  }

  Future<List<RoundScoreSessionsTableData>> loadRoundScoreSessions({
    int limit = 20,
  }) {
    return (select(roundScoreSessionsTable)
          ..orderBy([
            (table) => OrderingTerm.desc(table.completedAt),
          ])
          ..limit(limit))
        .get();
  }

  Future<List<RoundScorePlayerResultsTableData>> loadRoundScorePlayerResults({
    required String sessionId,
  }) {
    return (select(roundScorePlayerResultsTable)
          ..where((table) => table.sessionId.equals(sessionId))
          ..orderBy([
            (table) => OrderingTerm.asc(table.placement),
            (table) => OrderingTerm.asc(table.displayName),
          ]))
        .get();
  }

  Future<List<RoundScoreFieldValuesTableData>> loadRoundScoreFieldValues({
    required String sessionId,
  }) {
    return (select(roundScoreFieldValuesTable)
          ..where((table) => table.sessionId.equals(sessionId))
          ..orderBy([
            (table) => OrderingTerm.asc(table.roundNumber),
            (table) => OrderingTerm.asc(table.displayName),
          ]))
        .get();
  }

  Future<List<ActiveSessionsTableData>> loadActiveSessions({
    int limit = 20,
  }) {
    return (select(activeSessionsTable)
          ..orderBy([
            (table) => OrderingTerm.desc(table.updatedAt),
          ])
          ..limit(limit))
        .get();
  }

  Future<ActiveSessionsTableData?> loadActiveSession({
    required String sessionId,
  }) {
    return (select(activeSessionsTable)
          ..where((table) => table.id.equals(sessionId)))
        .getSingleOrNull();
  }

  Future<void> saveQuickScoreResult({
    required String sessionId,
    required String templateId,
    required String templateDisplayName,
    required String winnerRule,
    required String optionsJson,
    required DateTime completedAt,
    required List<QuickScoreParticipantValues> participantValues,
    required List<QuickScorePlayerResult> playerResults,
  }) {
    return transaction(() async {
      await (delete(quickScoreFieldValuesTable)
            ..where((table) => table.sessionId.equals(sessionId)))
          .go();
      await (delete(quickScorePlayerResultsTable)
            ..where((table) => table.sessionId.equals(sessionId)))
          .go();
      await (delete(quickScoreSessionsTable)
            ..where((table) => table.id.equals(sessionId)))
          .go();
      await (delete(activeSessionsTable)
        ..where((table) => table.id.equals(sessionId)))
          .go();

      await into(quickScoreSessionsTable).insert(
        QuickScoreSessionsTableCompanion.insert(
          id: sessionId,
          templateId: templateId,
          templateDisplayName: templateDisplayName,
          winnerRule: winnerRule,
          optionsJson: Value(optionsJson),
          completedAt: completedAt,
        ),
      );

      await batch((batch) {
        batch.insertAll(
          quickScorePlayerResultsTable,
          playerResults
              .map(
                (playerResult) => QuickScorePlayerResultsTableCompanion.insert(
                  sessionId: sessionId,
                  playerId: playerResult.playerId,
                  displayName: playerResult.displayName,
                  finalScore: playerResult.finalScore,
                  placement: playerResult.placement,
                  isTied: playerResult.isTied,
                ),
              )
              .toList(growable: false),
        );

        batch.insertAll(
          quickScoreFieldValuesTable,
          participantValues
              .expand(
                (participant) => participant.enteredValues.entries.map(
                  (fieldValue) => QuickScoreFieldValuesTableCompanion.insert(
                    sessionId: sessionId,
                    playerId: participant.playerId,
                    fieldId: fieldValue.key,
                    integerValue: fieldValue.value,
                  ),
                ),
              )
              .toList(growable: false),
        );
      });
    });
  }

  Future<void> saveRoundScoreResult({
    required String sessionId,
    required String templateId,
    required String templateDisplayName,
    required String winnerRule,
    required String optionsJson,
    required int roundCount,
    required DateTime completedAt,
    required List<RoundScoreRoundValues> rounds,
    required List<RoundScorePlayerResult> playerResults,
  }) {
    return transaction(() async {
      await (delete(roundScoreFieldValuesTable)
            ..where((table) => table.sessionId.equals(sessionId)))
          .go();
      await (delete(roundScorePlayerResultsTable)
            ..where((table) => table.sessionId.equals(sessionId)))
          .go();
      await (delete(roundScoreSessionsTable)
            ..where((table) => table.id.equals(sessionId)))
          .go();
      await (delete(activeSessionsTable)
        ..where((table) => table.id.equals(sessionId)))
          .go();

      await into(roundScoreSessionsTable).insert(
        RoundScoreSessionsTableCompanion.insert(
          id: sessionId,
          templateId: templateId,
          templateDisplayName: templateDisplayName,
          winnerRule: winnerRule,
          optionsJson: Value(optionsJson),
          roundCount: roundCount,
          completedAt: completedAt,
        ),
      );

      await batch((batch) {
        batch.insertAll(
          roundScorePlayerResultsTable,
          playerResults
              .map(
                (playerResult) => RoundScorePlayerResultsTableCompanion.insert(
                  sessionId: sessionId,
                  playerId: playerResult.playerId,
                  displayName: playerResult.displayName,
                  cumulativeScore: playerResult.cumulativeScore,
                  placement: playerResult.placement,
                  isTied: playerResult.isTied,
                ),
              )
              .toList(growable: false),
        );

        batch.insertAll(
          roundScoreFieldValuesTable,
          rounds
              .expand(
                (round) => round.participantValues.expand(
                  (participant) => participant.enteredValues.entries.map(
                    (fieldValue) => RoundScoreFieldValuesTableCompanion.insert(
                      sessionId: sessionId,
                      roundNumber: round.roundNumber,
                      playerId: participant.playerId,
                      displayName: participant.displayName,
                      fieldId: fieldValue.key,
                      integerValue: fieldValue.value,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      });
    });
  }

  Future<void> saveActiveSession({
    required String sessionId,
    required String sessionKind,
    required String templateId,
    required String templateDisplayName,
    required String participantLabel,
    required String progressLabel,
    required String payloadJson,
    required DateTime updatedAt,
  }) {
    return into(activeSessionsTable).insertOnConflictUpdate(
      ActiveSessionsTableData(
        id: sessionId,
        sessionKind: sessionKind,
        templateId: templateId,
        templateDisplayName: templateDisplayName,
        participantLabel: participantLabel,
        progressLabel: progressLabel,
        payloadJson: payloadJson,
        updatedAt: updatedAt,
      ),
    );
  }

  Future<void> deleteActiveSession({required String sessionId}) {
    return (delete(activeSessionsTable)
          ..where((table) => table.id.equals(sessionId)))
        .go();
  }

  /// The latest finished game for each template, across both scoring styles.
  Future<Map<String, DateTime>> loadLastCompletedAtByTemplateId() async {
    final lastCompletedAt = <String, DateTime>{};

    void record(String? templateId, DateTime? completedAt) {
      if (templateId == null || completedAt == null) {
        return;
      }
      final existing = lastCompletedAt[templateId];
      if (existing == null || completedAt.isAfter(existing)) {
        lastCompletedAt[templateId] = completedAt;
      }
    }

    final quickLatest = quickScoreSessionsTable.completedAt.max();
    final quickQuery = selectOnly(quickScoreSessionsTable)
      ..addColumns([quickScoreSessionsTable.templateId, quickLatest])
      ..groupBy([quickScoreSessionsTable.templateId]);
    for (final row in await quickQuery.get()) {
      record(row.read(quickScoreSessionsTable.templateId), row.read(quickLatest));
    }

    final roundLatest = roundScoreSessionsTable.completedAt.max();
    final roundQuery = selectOnly(roundScoreSessionsTable)
      ..addColumns([roundScoreSessionsTable.templateId, roundLatest])
      ..groupBy([roundScoreSessionsTable.templateId]);
    for (final row in await roundQuery.get()) {
      record(row.read(roundScoreSessionsTable.templateId), row.read(roundLatest));
    }

    return lastCompletedAt;
  }

  /// The latest finished game for each player, across both scoring styles.
  Future<Map<String, DateTime>> loadLastCompletedAtByPlayerId() async {
    final lastCompletedAt = <String, DateTime>{};

    void record(String? playerId, DateTime? completedAt) {
      if (playerId == null || completedAt == null) {
        return;
      }
      final existing = lastCompletedAt[playerId];
      if (existing == null || completedAt.isAfter(existing)) {
        lastCompletedAt[playerId] = completedAt;
      }
    }

    final quickLatest = quickScoreSessionsTable.completedAt.max();
    final quickQuery = selectOnly(quickScorePlayerResultsTable).join([
      innerJoin(
        quickScoreSessionsTable,
        quickScoreSessionsTable.id
            .equalsExp(quickScorePlayerResultsTable.sessionId),
      ),
    ])
      ..addColumns([quickScorePlayerResultsTable.playerId, quickLatest])
      ..groupBy([quickScorePlayerResultsTable.playerId]);
    for (final row in await quickQuery.get()) {
      record(
        row.read(quickScorePlayerResultsTable.playerId),
        row.read(quickLatest),
      );
    }

    final roundLatest = roundScoreSessionsTable.completedAt.max();
    final roundQuery = selectOnly(roundScorePlayerResultsTable).join([
      innerJoin(
        roundScoreSessionsTable,
        roundScoreSessionsTable.id
            .equalsExp(roundScorePlayerResultsTable.sessionId),
      ),
    ])
      ..addColumns([roundScorePlayerResultsTable.playerId, roundLatest])
      ..groupBy([roundScorePlayerResultsTable.playerId]);
    for (final row in await roundQuery.get()) {
      record(
        row.read(roundScorePlayerResultsTable.playerId),
        row.read(roundLatest),
      );
    }

    return lastCompletedAt;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databaseFile = File(
      p.join(documentsDirectory.path, 'scoard_game.sqlite'),
    );

    return NativeDatabase.createInBackground(databaseFile);
  });
}