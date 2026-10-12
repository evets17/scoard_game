// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PlayersTableTable extends PlayersTable
    with TableInfo<$PlayersTableTable, PlayersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedDisplayNameMeta =
      const VerificationMeta('normalizedDisplayName');
  @override
  late final GeneratedColumn<String> normalizedDisplayName =
      GeneratedColumn<String>(
        'normalized_display_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    normalizedDisplayName,
    isArchived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('normalized_display_name')) {
      context.handle(
        _normalizedDisplayNameMeta,
        normalizedDisplayName.isAcceptableOrUnknown(
          data['normalized_display_name']!,
          _normalizedDisplayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedDisplayNameMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {normalizedDisplayName},
  ];
  @override
  PlayersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      normalizedDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_display_name'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlayersTableTable createAlias(String alias) {
    return $PlayersTableTable(attachedDatabase, alias);
  }
}

class PlayersTableData extends DataClass
    implements Insertable<PlayersTableData> {
  final String id;
  final String displayName;
  final String normalizedDisplayName;
  final bool isArchived;
  final DateTime createdAt;
  const PlayersTableData({
    required this.id,
    required this.displayName,
    required this.normalizedDisplayName,
    required this.isArchived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['normalized_display_name'] = Variable<String>(normalizedDisplayName);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlayersTableCompanion toCompanion(bool nullToAbsent) {
    return PlayersTableCompanion(
      id: Value(id),
      displayName: Value(displayName),
      normalizedDisplayName: Value(normalizedDisplayName),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
    );
  }

  factory PlayersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayersTableData(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      normalizedDisplayName: serializer.fromJson<String>(
        json['normalizedDisplayName'],
      ),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'normalizedDisplayName': serializer.toJson<String>(normalizedDisplayName),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlayersTableData copyWith({
    String? id,
    String? displayName,
    String? normalizedDisplayName,
    bool? isArchived,
    DateTime? createdAt,
  }) => PlayersTableData(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    normalizedDisplayName: normalizedDisplayName ?? this.normalizedDisplayName,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
  );
  PlayersTableData copyWithCompanion(PlayersTableCompanion data) {
    return PlayersTableData(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      normalizedDisplayName: data.normalizedDisplayName.present
          ? data.normalizedDisplayName.value
          : this.normalizedDisplayName,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayersTableData(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('normalizedDisplayName: $normalizedDisplayName, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    normalizedDisplayName,
    isArchived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayersTableData &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.normalizedDisplayName == this.normalizedDisplayName &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt);
}

class PlayersTableCompanion extends UpdateCompanion<PlayersTableData> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> normalizedDisplayName;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlayersTableCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.normalizedDisplayName = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayersTableCompanion.insert({
    required String id,
    required String displayName,
    required String normalizedDisplayName,
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       normalizedDisplayName = Value(normalizedDisplayName),
       createdAt = Value(createdAt);
  static Insertable<PlayersTableData> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? normalizedDisplayName,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (normalizedDisplayName != null)
        'normalized_display_name': normalizedDisplayName,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? normalizedDisplayName,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlayersTableCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      normalizedDisplayName:
          normalizedDisplayName ?? this.normalizedDisplayName,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (normalizedDisplayName.present) {
      map['normalized_display_name'] = Variable<String>(
        normalizedDisplayName.value,
      );
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersTableCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('normalizedDisplayName: $normalizedDisplayName, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuickScoreSessionsTableTable extends QuickScoreSessionsTable
    with TableInfo<$QuickScoreSessionsTableTable, QuickScoreSessionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuickScoreSessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateDisplayNameMeta =
      const VerificationMeta('templateDisplayName');
  @override
  late final GeneratedColumn<String> templateDisplayName =
      GeneratedColumn<String>(
        'template_display_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _winnerRuleMeta = const VerificationMeta(
    'winnerRule',
  );
  @override
  late final GeneratedColumn<String> winnerRule = GeneratedColumn<String>(
    'winner_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    templateDisplayName,
    winnerRule,
    optionsJson,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quick_score_sessions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuickScoreSessionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('template_display_name')) {
      context.handle(
        _templateDisplayNameMeta,
        templateDisplayName.isAcceptableOrUnknown(
          data['template_display_name']!,
          _templateDisplayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateDisplayNameMeta);
    }
    if (data.containsKey('winner_rule')) {
      context.handle(
        _winnerRuleMeta,
        winnerRule.isAcceptableOrUnknown(data['winner_rule']!, _winnerRuleMeta),
      );
    } else if (isInserting) {
      context.missing(_winnerRuleMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuickScoreSessionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuickScoreSessionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      templateDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_display_name'],
      )!,
      winnerRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}winner_rule'],
      )!,
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $QuickScoreSessionsTableTable createAlias(String alias) {
    return $QuickScoreSessionsTableTable(attachedDatabase, alias);
  }
}

class QuickScoreSessionsTableData extends DataClass
    implements Insertable<QuickScoreSessionsTableData> {
  final String id;
  final String templateId;
  final String templateDisplayName;
  final String winnerRule;
  final String optionsJson;
  final DateTime completedAt;
  const QuickScoreSessionsTableData({
    required this.id,
    required this.templateId,
    required this.templateDisplayName,
    required this.winnerRule,
    required this.optionsJson,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['template_display_name'] = Variable<String>(templateDisplayName);
    map['winner_rule'] = Variable<String>(winnerRule);
    map['options_json'] = Variable<String>(optionsJson);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  QuickScoreSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return QuickScoreSessionsTableCompanion(
      id: Value(id),
      templateId: Value(templateId),
      templateDisplayName: Value(templateDisplayName),
      winnerRule: Value(winnerRule),
      optionsJson: Value(optionsJson),
      completedAt: Value(completedAt),
    );
  }

  factory QuickScoreSessionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuickScoreSessionsTableData(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      templateDisplayName: serializer.fromJson<String>(
        json['templateDisplayName'],
      ),
      winnerRule: serializer.fromJson<String>(json['winnerRule']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'templateDisplayName': serializer.toJson<String>(templateDisplayName),
      'winnerRule': serializer.toJson<String>(winnerRule),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  QuickScoreSessionsTableData copyWith({
    String? id,
    String? templateId,
    String? templateDisplayName,
    String? winnerRule,
    String? optionsJson,
    DateTime? completedAt,
  }) => QuickScoreSessionsTableData(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    templateDisplayName: templateDisplayName ?? this.templateDisplayName,
    winnerRule: winnerRule ?? this.winnerRule,
    optionsJson: optionsJson ?? this.optionsJson,
    completedAt: completedAt ?? this.completedAt,
  );
  QuickScoreSessionsTableData copyWithCompanion(
    QuickScoreSessionsTableCompanion data,
  ) {
    return QuickScoreSessionsTableData(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      templateDisplayName: data.templateDisplayName.present
          ? data.templateDisplayName.value
          : this.templateDisplayName,
      winnerRule: data.winnerRule.present
          ? data.winnerRule.value
          : this.winnerRule,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuickScoreSessionsTableData(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('templateDisplayName: $templateDisplayName, ')
          ..write('winnerRule: $winnerRule, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    templateDisplayName,
    winnerRule,
    optionsJson,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuickScoreSessionsTableData &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.templateDisplayName == this.templateDisplayName &&
          other.winnerRule == this.winnerRule &&
          other.optionsJson == this.optionsJson &&
          other.completedAt == this.completedAt);
}

class QuickScoreSessionsTableCompanion
    extends UpdateCompanion<QuickScoreSessionsTableData> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> templateDisplayName;
  final Value<String> winnerRule;
  final Value<String> optionsJson;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const QuickScoreSessionsTableCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateDisplayName = const Value.absent(),
    this.winnerRule = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuickScoreSessionsTableCompanion.insert({
    required String id,
    required String templateId,
    required String templateDisplayName,
    required String winnerRule,
    this.optionsJson = const Value.absent(),
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateId = Value(templateId),
       templateDisplayName = Value(templateDisplayName),
       winnerRule = Value(winnerRule),
       completedAt = Value(completedAt);
  static Insertable<QuickScoreSessionsTableData> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? templateDisplayName,
    Expression<String>? winnerRule,
    Expression<String>? optionsJson,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (templateDisplayName != null)
        'template_display_name': templateDisplayName,
      if (winnerRule != null) 'winner_rule': winnerRule,
      if (optionsJson != null) 'options_json': optionsJson,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuickScoreSessionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? templateId,
    Value<String>? templateDisplayName,
    Value<String>? winnerRule,
    Value<String>? optionsJson,
    Value<DateTime>? completedAt,
    Value<int>? rowid,
  }) {
    return QuickScoreSessionsTableCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateDisplayName: templateDisplayName ?? this.templateDisplayName,
      winnerRule: winnerRule ?? this.winnerRule,
      optionsJson: optionsJson ?? this.optionsJson,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (templateDisplayName.present) {
      map['template_display_name'] = Variable<String>(
        templateDisplayName.value,
      );
    }
    if (winnerRule.present) {
      map['winner_rule'] = Variable<String>(winnerRule.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuickScoreSessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('templateDisplayName: $templateDisplayName, ')
          ..write('winnerRule: $winnerRule, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuickScorePlayerResultsTableTable extends QuickScorePlayerResultsTable
    with
        TableInfo<
          $QuickScorePlayerResultsTableTable,
          QuickScorePlayerResultsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuickScorePlayerResultsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finalScoreMeta = const VerificationMeta(
    'finalScore',
  );
  @override
  late final GeneratedColumn<int> finalScore = GeneratedColumn<int>(
    'final_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placementMeta = const VerificationMeta(
    'placement',
  );
  @override
  late final GeneratedColumn<int> placement = GeneratedColumn<int>(
    'placement',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTiedMeta = const VerificationMeta('isTied');
  @override
  late final GeneratedColumn<bool> isTied = GeneratedColumn<bool>(
    'is_tied',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tied" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    playerId,
    displayName,
    finalScore,
    placement,
    isTied,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quick_score_player_results_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuickScorePlayerResultsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('final_score')) {
      context.handle(
        _finalScoreMeta,
        finalScore.isAcceptableOrUnknown(data['final_score']!, _finalScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_finalScoreMeta);
    }
    if (data.containsKey('placement')) {
      context.handle(
        _placementMeta,
        placement.isAcceptableOrUnknown(data['placement']!, _placementMeta),
      );
    } else if (isInserting) {
      context.missing(_placementMeta);
    }
    if (data.containsKey('is_tied')) {
      context.handle(
        _isTiedMeta,
        isTied.isAcceptableOrUnknown(data['is_tied']!, _isTiedMeta),
      );
    } else if (isInserting) {
      context.missing(_isTiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  QuickScorePlayerResultsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuickScorePlayerResultsTableData(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      finalScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}final_score'],
      )!,
      placement: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}placement'],
      )!,
      isTied: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tied'],
      )!,
    );
  }

  @override
  $QuickScorePlayerResultsTableTable createAlias(String alias) {
    return $QuickScorePlayerResultsTableTable(attachedDatabase, alias);
  }
}

class QuickScorePlayerResultsTableData extends DataClass
    implements Insertable<QuickScorePlayerResultsTableData> {
  final String sessionId;
  final String playerId;
  final String displayName;
  final int finalScore;
  final int placement;
  final bool isTied;
  const QuickScorePlayerResultsTableData({
    required this.sessionId,
    required this.playerId,
    required this.displayName,
    required this.finalScore,
    required this.placement,
    required this.isTied,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['player_id'] = Variable<String>(playerId);
    map['display_name'] = Variable<String>(displayName);
    map['final_score'] = Variable<int>(finalScore);
    map['placement'] = Variable<int>(placement);
    map['is_tied'] = Variable<bool>(isTied);
    return map;
  }

  QuickScorePlayerResultsTableCompanion toCompanion(bool nullToAbsent) {
    return QuickScorePlayerResultsTableCompanion(
      sessionId: Value(sessionId),
      playerId: Value(playerId),
      displayName: Value(displayName),
      finalScore: Value(finalScore),
      placement: Value(placement),
      isTied: Value(isTied),
    );
  }

  factory QuickScorePlayerResultsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuickScorePlayerResultsTableData(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      playerId: serializer.fromJson<String>(json['playerId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      finalScore: serializer.fromJson<int>(json['finalScore']),
      placement: serializer.fromJson<int>(json['placement']),
      isTied: serializer.fromJson<bool>(json['isTied']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'playerId': serializer.toJson<String>(playerId),
      'displayName': serializer.toJson<String>(displayName),
      'finalScore': serializer.toJson<int>(finalScore),
      'placement': serializer.toJson<int>(placement),
      'isTied': serializer.toJson<bool>(isTied),
    };
  }

  QuickScorePlayerResultsTableData copyWith({
    String? sessionId,
    String? playerId,
    String? displayName,
    int? finalScore,
    int? placement,
    bool? isTied,
  }) => QuickScorePlayerResultsTableData(
    sessionId: sessionId ?? this.sessionId,
    playerId: playerId ?? this.playerId,
    displayName: displayName ?? this.displayName,
    finalScore: finalScore ?? this.finalScore,
    placement: placement ?? this.placement,
    isTied: isTied ?? this.isTied,
  );
  QuickScorePlayerResultsTableData copyWithCompanion(
    QuickScorePlayerResultsTableCompanion data,
  ) {
    return QuickScorePlayerResultsTableData(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      finalScore: data.finalScore.present
          ? data.finalScore.value
          : this.finalScore,
      placement: data.placement.present ? data.placement.value : this.placement,
      isTied: data.isTied.present ? data.isTied.value : this.isTied,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuickScorePlayerResultsTableData(')
          ..write('sessionId: $sessionId, ')
          ..write('playerId: $playerId, ')
          ..write('displayName: $displayName, ')
          ..write('finalScore: $finalScore, ')
          ..write('placement: $placement, ')
          ..write('isTied: $isTied')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    playerId,
    displayName,
    finalScore,
    placement,
    isTied,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuickScorePlayerResultsTableData &&
          other.sessionId == this.sessionId &&
          other.playerId == this.playerId &&
          other.displayName == this.displayName &&
          other.finalScore == this.finalScore &&
          other.placement == this.placement &&
          other.isTied == this.isTied);
}

class QuickScorePlayerResultsTableCompanion
    extends UpdateCompanion<QuickScorePlayerResultsTableData> {
  final Value<String> sessionId;
  final Value<String> playerId;
  final Value<String> displayName;
  final Value<int> finalScore;
  final Value<int> placement;
  final Value<bool> isTied;
  final Value<int> rowid;
  const QuickScorePlayerResultsTableCompanion({
    this.sessionId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.finalScore = const Value.absent(),
    this.placement = const Value.absent(),
    this.isTied = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuickScorePlayerResultsTableCompanion.insert({
    required String sessionId,
    required String playerId,
    required String displayName,
    required int finalScore,
    required int placement,
    required bool isTied,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       playerId = Value(playerId),
       displayName = Value(displayName),
       finalScore = Value(finalScore),
       placement = Value(placement),
       isTied = Value(isTied);
  static Insertable<QuickScorePlayerResultsTableData> custom({
    Expression<String>? sessionId,
    Expression<String>? playerId,
    Expression<String>? displayName,
    Expression<int>? finalScore,
    Expression<int>? placement,
    Expression<bool>? isTied,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (playerId != null) 'player_id': playerId,
      if (displayName != null) 'display_name': displayName,
      if (finalScore != null) 'final_score': finalScore,
      if (placement != null) 'placement': placement,
      if (isTied != null) 'is_tied': isTied,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuickScorePlayerResultsTableCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? playerId,
    Value<String>? displayName,
    Value<int>? finalScore,
    Value<int>? placement,
    Value<bool>? isTied,
    Value<int>? rowid,
  }) {
    return QuickScorePlayerResultsTableCompanion(
      sessionId: sessionId ?? this.sessionId,
      playerId: playerId ?? this.playerId,
      displayName: displayName ?? this.displayName,
      finalScore: finalScore ?? this.finalScore,
      placement: placement ?? this.placement,
      isTied: isTied ?? this.isTied,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (finalScore.present) {
      map['final_score'] = Variable<int>(finalScore.value);
    }
    if (placement.present) {
      map['placement'] = Variable<int>(placement.value);
    }
    if (isTied.present) {
      map['is_tied'] = Variable<bool>(isTied.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuickScorePlayerResultsTableCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('playerId: $playerId, ')
          ..write('displayName: $displayName, ')
          ..write('finalScore: $finalScore, ')
          ..write('placement: $placement, ')
          ..write('isTied: $isTied, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuickScoreFieldValuesTableTable extends QuickScoreFieldValuesTable
    with
        TableInfo<
          $QuickScoreFieldValuesTableTable,
          QuickScoreFieldValuesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuickScoreFieldValuesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldIdMeta = const VerificationMeta(
    'fieldId',
  );
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
    'field_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _integerValueMeta = const VerificationMeta(
    'integerValue',
  );
  @override
  late final GeneratedColumn<int> integerValue = GeneratedColumn<int>(
    'integer_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    playerId,
    fieldId,
    integerValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quick_score_field_values_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuickScoreFieldValuesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('field_id')) {
      context.handle(
        _fieldIdMeta,
        fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('integer_value')) {
      context.handle(
        _integerValueMeta,
        integerValue.isAcceptableOrUnknown(
          data['integer_value']!,
          _integerValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_integerValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, playerId, fieldId};
  @override
  QuickScoreFieldValuesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuickScoreFieldValuesTableData(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      fieldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_id'],
      )!,
      integerValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}integer_value'],
      )!,
    );
  }

  @override
  $QuickScoreFieldValuesTableTable createAlias(String alias) {
    return $QuickScoreFieldValuesTableTable(attachedDatabase, alias);
  }
}

class QuickScoreFieldValuesTableData extends DataClass
    implements Insertable<QuickScoreFieldValuesTableData> {
  final String sessionId;
  final String playerId;
  final String fieldId;
  final int integerValue;
  const QuickScoreFieldValuesTableData({
    required this.sessionId,
    required this.playerId,
    required this.fieldId,
    required this.integerValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['player_id'] = Variable<String>(playerId);
    map['field_id'] = Variable<String>(fieldId);
    map['integer_value'] = Variable<int>(integerValue);
    return map;
  }

  QuickScoreFieldValuesTableCompanion toCompanion(bool nullToAbsent) {
    return QuickScoreFieldValuesTableCompanion(
      sessionId: Value(sessionId),
      playerId: Value(playerId),
      fieldId: Value(fieldId),
      integerValue: Value(integerValue),
    );
  }

  factory QuickScoreFieldValuesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuickScoreFieldValuesTableData(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      playerId: serializer.fromJson<String>(json['playerId']),
      fieldId: serializer.fromJson<String>(json['fieldId']),
      integerValue: serializer.fromJson<int>(json['integerValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'playerId': serializer.toJson<String>(playerId),
      'fieldId': serializer.toJson<String>(fieldId),
      'integerValue': serializer.toJson<int>(integerValue),
    };
  }

  QuickScoreFieldValuesTableData copyWith({
    String? sessionId,
    String? playerId,
    String? fieldId,
    int? integerValue,
  }) => QuickScoreFieldValuesTableData(
    sessionId: sessionId ?? this.sessionId,
    playerId: playerId ?? this.playerId,
    fieldId: fieldId ?? this.fieldId,
    integerValue: integerValue ?? this.integerValue,
  );
  QuickScoreFieldValuesTableData copyWithCompanion(
    QuickScoreFieldValuesTableCompanion data,
  ) {
    return QuickScoreFieldValuesTableData(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      integerValue: data.integerValue.present
          ? data.integerValue.value
          : this.integerValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuickScoreFieldValuesTableData(')
          ..write('sessionId: $sessionId, ')
          ..write('playerId: $playerId, ')
          ..write('fieldId: $fieldId, ')
          ..write('integerValue: $integerValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, playerId, fieldId, integerValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuickScoreFieldValuesTableData &&
          other.sessionId == this.sessionId &&
          other.playerId == this.playerId &&
          other.fieldId == this.fieldId &&
          other.integerValue == this.integerValue);
}

class QuickScoreFieldValuesTableCompanion
    extends UpdateCompanion<QuickScoreFieldValuesTableData> {
  final Value<String> sessionId;
  final Value<String> playerId;
  final Value<String> fieldId;
  final Value<int> integerValue;
  final Value<int> rowid;
  const QuickScoreFieldValuesTableCompanion({
    this.sessionId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.integerValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuickScoreFieldValuesTableCompanion.insert({
    required String sessionId,
    required String playerId,
    required String fieldId,
    required int integerValue,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       playerId = Value(playerId),
       fieldId = Value(fieldId),
       integerValue = Value(integerValue);
  static Insertable<QuickScoreFieldValuesTableData> custom({
    Expression<String>? sessionId,
    Expression<String>? playerId,
    Expression<String>? fieldId,
    Expression<int>? integerValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (playerId != null) 'player_id': playerId,
      if (fieldId != null) 'field_id': fieldId,
      if (integerValue != null) 'integer_value': integerValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuickScoreFieldValuesTableCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? playerId,
    Value<String>? fieldId,
    Value<int>? integerValue,
    Value<int>? rowid,
  }) {
    return QuickScoreFieldValuesTableCompanion(
      sessionId: sessionId ?? this.sessionId,
      playerId: playerId ?? this.playerId,
      fieldId: fieldId ?? this.fieldId,
      integerValue: integerValue ?? this.integerValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (integerValue.present) {
      map['integer_value'] = Variable<int>(integerValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuickScoreFieldValuesTableCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('playerId: $playerId, ')
          ..write('fieldId: $fieldId, ')
          ..write('integerValue: $integerValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoundScoreSessionsTableTable extends RoundScoreSessionsTable
    with TableInfo<$RoundScoreSessionsTableTable, RoundScoreSessionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoundScoreSessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateDisplayNameMeta =
      const VerificationMeta('templateDisplayName');
  @override
  late final GeneratedColumn<String> templateDisplayName =
      GeneratedColumn<String>(
        'template_display_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _winnerRuleMeta = const VerificationMeta(
    'winnerRule',
  );
  @override
  late final GeneratedColumn<String> winnerRule = GeneratedColumn<String>(
    'winner_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _roundCountMeta = const VerificationMeta(
    'roundCount',
  );
  @override
  late final GeneratedColumn<int> roundCount = GeneratedColumn<int>(
    'round_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    templateDisplayName,
    winnerRule,
    optionsJson,
    roundCount,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'round_score_sessions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoundScoreSessionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('template_display_name')) {
      context.handle(
        _templateDisplayNameMeta,
        templateDisplayName.isAcceptableOrUnknown(
          data['template_display_name']!,
          _templateDisplayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateDisplayNameMeta);
    }
    if (data.containsKey('winner_rule')) {
      context.handle(
        _winnerRuleMeta,
        winnerRule.isAcceptableOrUnknown(data['winner_rule']!, _winnerRuleMeta),
      );
    } else if (isInserting) {
      context.missing(_winnerRuleMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('round_count')) {
      context.handle(
        _roundCountMeta,
        roundCount.isAcceptableOrUnknown(data['round_count']!, _roundCountMeta),
      );
    } else if (isInserting) {
      context.missing(_roundCountMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoundScoreSessionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoundScoreSessionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      templateDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_display_name'],
      )!,
      winnerRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}winner_rule'],
      )!,
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      roundCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_count'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $RoundScoreSessionsTableTable createAlias(String alias) {
    return $RoundScoreSessionsTableTable(attachedDatabase, alias);
  }
}

class RoundScoreSessionsTableData extends DataClass
    implements Insertable<RoundScoreSessionsTableData> {
  final String id;
  final String templateId;
  final String templateDisplayName;
  final String winnerRule;
  final String optionsJson;
  final int roundCount;
  final DateTime completedAt;
  const RoundScoreSessionsTableData({
    required this.id,
    required this.templateId,
    required this.templateDisplayName,
    required this.winnerRule,
    required this.optionsJson,
    required this.roundCount,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['template_display_name'] = Variable<String>(templateDisplayName);
    map['winner_rule'] = Variable<String>(winnerRule);
    map['options_json'] = Variable<String>(optionsJson);
    map['round_count'] = Variable<int>(roundCount);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  RoundScoreSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return RoundScoreSessionsTableCompanion(
      id: Value(id),
      templateId: Value(templateId),
      templateDisplayName: Value(templateDisplayName),
      winnerRule: Value(winnerRule),
      optionsJson: Value(optionsJson),
      roundCount: Value(roundCount),
      completedAt: Value(completedAt),
    );
  }

  factory RoundScoreSessionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoundScoreSessionsTableData(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      templateDisplayName: serializer.fromJson<String>(
        json['templateDisplayName'],
      ),
      winnerRule: serializer.fromJson<String>(json['winnerRule']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      roundCount: serializer.fromJson<int>(json['roundCount']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'templateDisplayName': serializer.toJson<String>(templateDisplayName),
      'winnerRule': serializer.toJson<String>(winnerRule),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'roundCount': serializer.toJson<int>(roundCount),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  RoundScoreSessionsTableData copyWith({
    String? id,
    String? templateId,
    String? templateDisplayName,
    String? winnerRule,
    String? optionsJson,
    int? roundCount,
    DateTime? completedAt,
  }) => RoundScoreSessionsTableData(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    templateDisplayName: templateDisplayName ?? this.templateDisplayName,
    winnerRule: winnerRule ?? this.winnerRule,
    optionsJson: optionsJson ?? this.optionsJson,
    roundCount: roundCount ?? this.roundCount,
    completedAt: completedAt ?? this.completedAt,
  );
  RoundScoreSessionsTableData copyWithCompanion(
    RoundScoreSessionsTableCompanion data,
  ) {
    return RoundScoreSessionsTableData(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      templateDisplayName: data.templateDisplayName.present
          ? data.templateDisplayName.value
          : this.templateDisplayName,
      winnerRule: data.winnerRule.present
          ? data.winnerRule.value
          : this.winnerRule,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      roundCount: data.roundCount.present
          ? data.roundCount.value
          : this.roundCount,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoundScoreSessionsTableData(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('templateDisplayName: $templateDisplayName, ')
          ..write('winnerRule: $winnerRule, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('roundCount: $roundCount, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    templateDisplayName,
    winnerRule,
    optionsJson,
    roundCount,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoundScoreSessionsTableData &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.templateDisplayName == this.templateDisplayName &&
          other.winnerRule == this.winnerRule &&
          other.optionsJson == this.optionsJson &&
          other.roundCount == this.roundCount &&
          other.completedAt == this.completedAt);
}

class RoundScoreSessionsTableCompanion
    extends UpdateCompanion<RoundScoreSessionsTableData> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> templateDisplayName;
  final Value<String> winnerRule;
  final Value<String> optionsJson;
  final Value<int> roundCount;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const RoundScoreSessionsTableCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateDisplayName = const Value.absent(),
    this.winnerRule = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.roundCount = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoundScoreSessionsTableCompanion.insert({
    required String id,
    required String templateId,
    required String templateDisplayName,
    required String winnerRule,
    this.optionsJson = const Value.absent(),
    required int roundCount,
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateId = Value(templateId),
       templateDisplayName = Value(templateDisplayName),
       winnerRule = Value(winnerRule),
       roundCount = Value(roundCount),
       completedAt = Value(completedAt);
  static Insertable<RoundScoreSessionsTableData> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? templateDisplayName,
    Expression<String>? winnerRule,
    Expression<String>? optionsJson,
    Expression<int>? roundCount,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (templateDisplayName != null)
        'template_display_name': templateDisplayName,
      if (winnerRule != null) 'winner_rule': winnerRule,
      if (optionsJson != null) 'options_json': optionsJson,
      if (roundCount != null) 'round_count': roundCount,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoundScoreSessionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? templateId,
    Value<String>? templateDisplayName,
    Value<String>? winnerRule,
    Value<String>? optionsJson,
    Value<int>? roundCount,
    Value<DateTime>? completedAt,
    Value<int>? rowid,
  }) {
    return RoundScoreSessionsTableCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateDisplayName: templateDisplayName ?? this.templateDisplayName,
      winnerRule: winnerRule ?? this.winnerRule,
      optionsJson: optionsJson ?? this.optionsJson,
      roundCount: roundCount ?? this.roundCount,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (templateDisplayName.present) {
      map['template_display_name'] = Variable<String>(
        templateDisplayName.value,
      );
    }
    if (winnerRule.present) {
      map['winner_rule'] = Variable<String>(winnerRule.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (roundCount.present) {
      map['round_count'] = Variable<int>(roundCount.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoundScoreSessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('templateDisplayName: $templateDisplayName, ')
          ..write('winnerRule: $winnerRule, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('roundCount: $roundCount, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoundScorePlayerResultsTableTable extends RoundScorePlayerResultsTable
    with
        TableInfo<
          $RoundScorePlayerResultsTableTable,
          RoundScorePlayerResultsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoundScorePlayerResultsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cumulativeScoreMeta = const VerificationMeta(
    'cumulativeScore',
  );
  @override
  late final GeneratedColumn<int> cumulativeScore = GeneratedColumn<int>(
    'cumulative_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placementMeta = const VerificationMeta(
    'placement',
  );
  @override
  late final GeneratedColumn<int> placement = GeneratedColumn<int>(
    'placement',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTiedMeta = const VerificationMeta('isTied');
  @override
  late final GeneratedColumn<bool> isTied = GeneratedColumn<bool>(
    'is_tied',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tied" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    playerId,
    displayName,
    cumulativeScore,
    placement,
    isTied,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'round_score_player_results_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoundScorePlayerResultsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('cumulative_score')) {
      context.handle(
        _cumulativeScoreMeta,
        cumulativeScore.isAcceptableOrUnknown(
          data['cumulative_score']!,
          _cumulativeScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cumulativeScoreMeta);
    }
    if (data.containsKey('placement')) {
      context.handle(
        _placementMeta,
        placement.isAcceptableOrUnknown(data['placement']!, _placementMeta),
      );
    } else if (isInserting) {
      context.missing(_placementMeta);
    }
    if (data.containsKey('is_tied')) {
      context.handle(
        _isTiedMeta,
        isTied.isAcceptableOrUnknown(data['is_tied']!, _isTiedMeta),
      );
    } else if (isInserting) {
      context.missing(_isTiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  RoundScorePlayerResultsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoundScorePlayerResultsTableData(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      cumulativeScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cumulative_score'],
      )!,
      placement: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}placement'],
      )!,
      isTied: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tied'],
      )!,
    );
  }

  @override
  $RoundScorePlayerResultsTableTable createAlias(String alias) {
    return $RoundScorePlayerResultsTableTable(attachedDatabase, alias);
  }
}

class RoundScorePlayerResultsTableData extends DataClass
    implements Insertable<RoundScorePlayerResultsTableData> {
  final String sessionId;
  final String playerId;
  final String displayName;
  final int cumulativeScore;
  final int placement;
  final bool isTied;
  const RoundScorePlayerResultsTableData({
    required this.sessionId,
    required this.playerId,
    required this.displayName,
    required this.cumulativeScore,
    required this.placement,
    required this.isTied,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['player_id'] = Variable<String>(playerId);
    map['display_name'] = Variable<String>(displayName);
    map['cumulative_score'] = Variable<int>(cumulativeScore);
    map['placement'] = Variable<int>(placement);
    map['is_tied'] = Variable<bool>(isTied);
    return map;
  }

  RoundScorePlayerResultsTableCompanion toCompanion(bool nullToAbsent) {
    return RoundScorePlayerResultsTableCompanion(
      sessionId: Value(sessionId),
      playerId: Value(playerId),
      displayName: Value(displayName),
      cumulativeScore: Value(cumulativeScore),
      placement: Value(placement),
      isTied: Value(isTied),
    );
  }

  factory RoundScorePlayerResultsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoundScorePlayerResultsTableData(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      playerId: serializer.fromJson<String>(json['playerId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      cumulativeScore: serializer.fromJson<int>(json['cumulativeScore']),
      placement: serializer.fromJson<int>(json['placement']),
      isTied: serializer.fromJson<bool>(json['isTied']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'playerId': serializer.toJson<String>(playerId),
      'displayName': serializer.toJson<String>(displayName),
      'cumulativeScore': serializer.toJson<int>(cumulativeScore),
      'placement': serializer.toJson<int>(placement),
      'isTied': serializer.toJson<bool>(isTied),
    };
  }

  RoundScorePlayerResultsTableData copyWith({
    String? sessionId,
    String? playerId,
    String? displayName,
    int? cumulativeScore,
    int? placement,
    bool? isTied,
  }) => RoundScorePlayerResultsTableData(
    sessionId: sessionId ?? this.sessionId,
    playerId: playerId ?? this.playerId,
    displayName: displayName ?? this.displayName,
    cumulativeScore: cumulativeScore ?? this.cumulativeScore,
    placement: placement ?? this.placement,
    isTied: isTied ?? this.isTied,
  );
  RoundScorePlayerResultsTableData copyWithCompanion(
    RoundScorePlayerResultsTableCompanion data,
  ) {
    return RoundScorePlayerResultsTableData(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      cumulativeScore: data.cumulativeScore.present
          ? data.cumulativeScore.value
          : this.cumulativeScore,
      placement: data.placement.present ? data.placement.value : this.placement,
      isTied: data.isTied.present ? data.isTied.value : this.isTied,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoundScorePlayerResultsTableData(')
          ..write('sessionId: $sessionId, ')
          ..write('playerId: $playerId, ')
          ..write('displayName: $displayName, ')
          ..write('cumulativeScore: $cumulativeScore, ')
          ..write('placement: $placement, ')
          ..write('isTied: $isTied')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    playerId,
    displayName,
    cumulativeScore,
    placement,
    isTied,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoundScorePlayerResultsTableData &&
          other.sessionId == this.sessionId &&
          other.playerId == this.playerId &&
          other.displayName == this.displayName &&
          other.cumulativeScore == this.cumulativeScore &&
          other.placement == this.placement &&
          other.isTied == this.isTied);
}

class RoundScorePlayerResultsTableCompanion
    extends UpdateCompanion<RoundScorePlayerResultsTableData> {
  final Value<String> sessionId;
  final Value<String> playerId;
  final Value<String> displayName;
  final Value<int> cumulativeScore;
  final Value<int> placement;
  final Value<bool> isTied;
  final Value<int> rowid;
  const RoundScorePlayerResultsTableCompanion({
    this.sessionId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.cumulativeScore = const Value.absent(),
    this.placement = const Value.absent(),
    this.isTied = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoundScorePlayerResultsTableCompanion.insert({
    required String sessionId,
    required String playerId,
    required String displayName,
    required int cumulativeScore,
    required int placement,
    required bool isTied,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       playerId = Value(playerId),
       displayName = Value(displayName),
       cumulativeScore = Value(cumulativeScore),
       placement = Value(placement),
       isTied = Value(isTied);
  static Insertable<RoundScorePlayerResultsTableData> custom({
    Expression<String>? sessionId,
    Expression<String>? playerId,
    Expression<String>? displayName,
    Expression<int>? cumulativeScore,
    Expression<int>? placement,
    Expression<bool>? isTied,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (playerId != null) 'player_id': playerId,
      if (displayName != null) 'display_name': displayName,
      if (cumulativeScore != null) 'cumulative_score': cumulativeScore,
      if (placement != null) 'placement': placement,
      if (isTied != null) 'is_tied': isTied,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoundScorePlayerResultsTableCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? playerId,
    Value<String>? displayName,
    Value<int>? cumulativeScore,
    Value<int>? placement,
    Value<bool>? isTied,
    Value<int>? rowid,
  }) {
    return RoundScorePlayerResultsTableCompanion(
      sessionId: sessionId ?? this.sessionId,
      playerId: playerId ?? this.playerId,
      displayName: displayName ?? this.displayName,
      cumulativeScore: cumulativeScore ?? this.cumulativeScore,
      placement: placement ?? this.placement,
      isTied: isTied ?? this.isTied,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (cumulativeScore.present) {
      map['cumulative_score'] = Variable<int>(cumulativeScore.value);
    }
    if (placement.present) {
      map['placement'] = Variable<int>(placement.value);
    }
    if (isTied.present) {
      map['is_tied'] = Variable<bool>(isTied.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoundScorePlayerResultsTableCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('playerId: $playerId, ')
          ..write('displayName: $displayName, ')
          ..write('cumulativeScore: $cumulativeScore, ')
          ..write('placement: $placement, ')
          ..write('isTied: $isTied, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoundScoreFieldValuesTableTable extends RoundScoreFieldValuesTable
    with
        TableInfo<
          $RoundScoreFieldValuesTableTable,
          RoundScoreFieldValuesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoundScoreFieldValuesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundNumberMeta = const VerificationMeta(
    'roundNumber',
  );
  @override
  late final GeneratedColumn<int> roundNumber = GeneratedColumn<int>(
    'round_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldIdMeta = const VerificationMeta(
    'fieldId',
  );
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
    'field_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _integerValueMeta = const VerificationMeta(
    'integerValue',
  );
  @override
  late final GeneratedColumn<int> integerValue = GeneratedColumn<int>(
    'integer_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    roundNumber,
    playerId,
    displayName,
    fieldId,
    integerValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'round_score_field_values_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoundScoreFieldValuesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('round_number')) {
      context.handle(
        _roundNumberMeta,
        roundNumber.isAcceptableOrUnknown(
          data['round_number']!,
          _roundNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_roundNumberMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('field_id')) {
      context.handle(
        _fieldIdMeta,
        fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('integer_value')) {
      context.handle(
        _integerValueMeta,
        integerValue.isAcceptableOrUnknown(
          data['integer_value']!,
          _integerValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_integerValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    sessionId,
    roundNumber,
    playerId,
    fieldId,
  };
  @override
  RoundScoreFieldValuesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoundScoreFieldValuesTableData(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      roundNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_number'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      fieldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_id'],
      )!,
      integerValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}integer_value'],
      )!,
    );
  }

  @override
  $RoundScoreFieldValuesTableTable createAlias(String alias) {
    return $RoundScoreFieldValuesTableTable(attachedDatabase, alias);
  }
}

class RoundScoreFieldValuesTableData extends DataClass
    implements Insertable<RoundScoreFieldValuesTableData> {
  final String sessionId;
  final int roundNumber;
  final String playerId;
  final String displayName;
  final String fieldId;
  final int integerValue;
  const RoundScoreFieldValuesTableData({
    required this.sessionId,
    required this.roundNumber,
    required this.playerId,
    required this.displayName,
    required this.fieldId,
    required this.integerValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['round_number'] = Variable<int>(roundNumber);
    map['player_id'] = Variable<String>(playerId);
    map['display_name'] = Variable<String>(displayName);
    map['field_id'] = Variable<String>(fieldId);
    map['integer_value'] = Variable<int>(integerValue);
    return map;
  }

  RoundScoreFieldValuesTableCompanion toCompanion(bool nullToAbsent) {
    return RoundScoreFieldValuesTableCompanion(
      sessionId: Value(sessionId),
      roundNumber: Value(roundNumber),
      playerId: Value(playerId),
      displayName: Value(displayName),
      fieldId: Value(fieldId),
      integerValue: Value(integerValue),
    );
  }

  factory RoundScoreFieldValuesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoundScoreFieldValuesTableData(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      roundNumber: serializer.fromJson<int>(json['roundNumber']),
      playerId: serializer.fromJson<String>(json['playerId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      fieldId: serializer.fromJson<String>(json['fieldId']),
      integerValue: serializer.fromJson<int>(json['integerValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'roundNumber': serializer.toJson<int>(roundNumber),
      'playerId': serializer.toJson<String>(playerId),
      'displayName': serializer.toJson<String>(displayName),
      'fieldId': serializer.toJson<String>(fieldId),
      'integerValue': serializer.toJson<int>(integerValue),
    };
  }

  RoundScoreFieldValuesTableData copyWith({
    String? sessionId,
    int? roundNumber,
    String? playerId,
    String? displayName,
    String? fieldId,
    int? integerValue,
  }) => RoundScoreFieldValuesTableData(
    sessionId: sessionId ?? this.sessionId,
    roundNumber: roundNumber ?? this.roundNumber,
    playerId: playerId ?? this.playerId,
    displayName: displayName ?? this.displayName,
    fieldId: fieldId ?? this.fieldId,
    integerValue: integerValue ?? this.integerValue,
  );
  RoundScoreFieldValuesTableData copyWithCompanion(
    RoundScoreFieldValuesTableCompanion data,
  ) {
    return RoundScoreFieldValuesTableData(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      roundNumber: data.roundNumber.present
          ? data.roundNumber.value
          : this.roundNumber,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      integerValue: data.integerValue.present
          ? data.integerValue.value
          : this.integerValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoundScoreFieldValuesTableData(')
          ..write('sessionId: $sessionId, ')
          ..write('roundNumber: $roundNumber, ')
          ..write('playerId: $playerId, ')
          ..write('displayName: $displayName, ')
          ..write('fieldId: $fieldId, ')
          ..write('integerValue: $integerValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    roundNumber,
    playerId,
    displayName,
    fieldId,
    integerValue,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoundScoreFieldValuesTableData &&
          other.sessionId == this.sessionId &&
          other.roundNumber == this.roundNumber &&
          other.playerId == this.playerId &&
          other.displayName == this.displayName &&
          other.fieldId == this.fieldId &&
          other.integerValue == this.integerValue);
}

class RoundScoreFieldValuesTableCompanion
    extends UpdateCompanion<RoundScoreFieldValuesTableData> {
  final Value<String> sessionId;
  final Value<int> roundNumber;
  final Value<String> playerId;
  final Value<String> displayName;
  final Value<String> fieldId;
  final Value<int> integerValue;
  final Value<int> rowid;
  const RoundScoreFieldValuesTableCompanion({
    this.sessionId = const Value.absent(),
    this.roundNumber = const Value.absent(),
    this.playerId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.integerValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoundScoreFieldValuesTableCompanion.insert({
    required String sessionId,
    required int roundNumber,
    required String playerId,
    required String displayName,
    required String fieldId,
    required int integerValue,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       roundNumber = Value(roundNumber),
       playerId = Value(playerId),
       displayName = Value(displayName),
       fieldId = Value(fieldId),
       integerValue = Value(integerValue);
  static Insertable<RoundScoreFieldValuesTableData> custom({
    Expression<String>? sessionId,
    Expression<int>? roundNumber,
    Expression<String>? playerId,
    Expression<String>? displayName,
    Expression<String>? fieldId,
    Expression<int>? integerValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (roundNumber != null) 'round_number': roundNumber,
      if (playerId != null) 'player_id': playerId,
      if (displayName != null) 'display_name': displayName,
      if (fieldId != null) 'field_id': fieldId,
      if (integerValue != null) 'integer_value': integerValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoundScoreFieldValuesTableCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? roundNumber,
    Value<String>? playerId,
    Value<String>? displayName,
    Value<String>? fieldId,
    Value<int>? integerValue,
    Value<int>? rowid,
  }) {
    return RoundScoreFieldValuesTableCompanion(
      sessionId: sessionId ?? this.sessionId,
      roundNumber: roundNumber ?? this.roundNumber,
      playerId: playerId ?? this.playerId,
      displayName: displayName ?? this.displayName,
      fieldId: fieldId ?? this.fieldId,
      integerValue: integerValue ?? this.integerValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (roundNumber.present) {
      map['round_number'] = Variable<int>(roundNumber.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (integerValue.present) {
      map['integer_value'] = Variable<int>(integerValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoundScoreFieldValuesTableCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('roundNumber: $roundNumber, ')
          ..write('playerId: $playerId, ')
          ..write('displayName: $displayName, ')
          ..write('fieldId: $fieldId, ')
          ..write('integerValue: $integerValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActiveSessionsTableTable extends ActiveSessionsTable
    with TableInfo<$ActiveSessionsTableTable, ActiveSessionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActiveSessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionKindMeta = const VerificationMeta(
    'sessionKind',
  );
  @override
  late final GeneratedColumn<String> sessionKind = GeneratedColumn<String>(
    'session_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateDisplayNameMeta =
      const VerificationMeta('templateDisplayName');
  @override
  late final GeneratedColumn<String> templateDisplayName =
      GeneratedColumn<String>(
        'template_display_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _participantLabelMeta = const VerificationMeta(
    'participantLabel',
  );
  @override
  late final GeneratedColumn<String> participantLabel = GeneratedColumn<String>(
    'participant_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressLabelMeta = const VerificationMeta(
    'progressLabel',
  );
  @override
  late final GeneratedColumn<String> progressLabel = GeneratedColumn<String>(
    'progress_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionKind,
    templateId,
    templateDisplayName,
    participantLabel,
    progressLabel,
    payloadJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_sessions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActiveSessionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_kind')) {
      context.handle(
        _sessionKindMeta,
        sessionKind.isAcceptableOrUnknown(
          data['session_kind']!,
          _sessionKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionKindMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('template_display_name')) {
      context.handle(
        _templateDisplayNameMeta,
        templateDisplayName.isAcceptableOrUnknown(
          data['template_display_name']!,
          _templateDisplayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateDisplayNameMeta);
    }
    if (data.containsKey('participant_label')) {
      context.handle(
        _participantLabelMeta,
        participantLabel.isAcceptableOrUnknown(
          data['participant_label']!,
          _participantLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantLabelMeta);
    }
    if (data.containsKey('progress_label')) {
      context.handle(
        _progressLabelMeta,
        progressLabel.isAcceptableOrUnknown(
          data['progress_label']!,
          _progressLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_progressLabelMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActiveSessionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActiveSessionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_kind'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      templateDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_display_name'],
      )!,
      participantLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_label'],
      )!,
      progressLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}progress_label'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ActiveSessionsTableTable createAlias(String alias) {
    return $ActiveSessionsTableTable(attachedDatabase, alias);
  }
}

class ActiveSessionsTableData extends DataClass
    implements Insertable<ActiveSessionsTableData> {
  final String id;
  final String sessionKind;
  final String templateId;
  final String templateDisplayName;
  final String participantLabel;
  final String progressLabel;
  final String payloadJson;
  final DateTime updatedAt;
  const ActiveSessionsTableData({
    required this.id,
    required this.sessionKind,
    required this.templateId,
    required this.templateDisplayName,
    required this.participantLabel,
    required this.progressLabel,
    required this.payloadJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_kind'] = Variable<String>(sessionKind);
    map['template_id'] = Variable<String>(templateId);
    map['template_display_name'] = Variable<String>(templateDisplayName);
    map['participant_label'] = Variable<String>(participantLabel);
    map['progress_label'] = Variable<String>(progressLabel);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ActiveSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return ActiveSessionsTableCompanion(
      id: Value(id),
      sessionKind: Value(sessionKind),
      templateId: Value(templateId),
      templateDisplayName: Value(templateDisplayName),
      participantLabel: Value(participantLabel),
      progressLabel: Value(progressLabel),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory ActiveSessionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActiveSessionsTableData(
      id: serializer.fromJson<String>(json['id']),
      sessionKind: serializer.fromJson<String>(json['sessionKind']),
      templateId: serializer.fromJson<String>(json['templateId']),
      templateDisplayName: serializer.fromJson<String>(
        json['templateDisplayName'],
      ),
      participantLabel: serializer.fromJson<String>(json['participantLabel']),
      progressLabel: serializer.fromJson<String>(json['progressLabel']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionKind': serializer.toJson<String>(sessionKind),
      'templateId': serializer.toJson<String>(templateId),
      'templateDisplayName': serializer.toJson<String>(templateDisplayName),
      'participantLabel': serializer.toJson<String>(participantLabel),
      'progressLabel': serializer.toJson<String>(progressLabel),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ActiveSessionsTableData copyWith({
    String? id,
    String? sessionKind,
    String? templateId,
    String? templateDisplayName,
    String? participantLabel,
    String? progressLabel,
    String? payloadJson,
    DateTime? updatedAt,
  }) => ActiveSessionsTableData(
    id: id ?? this.id,
    sessionKind: sessionKind ?? this.sessionKind,
    templateId: templateId ?? this.templateId,
    templateDisplayName: templateDisplayName ?? this.templateDisplayName,
    participantLabel: participantLabel ?? this.participantLabel,
    progressLabel: progressLabel ?? this.progressLabel,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ActiveSessionsTableData copyWithCompanion(ActiveSessionsTableCompanion data) {
    return ActiveSessionsTableData(
      id: data.id.present ? data.id.value : this.id,
      sessionKind: data.sessionKind.present
          ? data.sessionKind.value
          : this.sessionKind,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      templateDisplayName: data.templateDisplayName.present
          ? data.templateDisplayName.value
          : this.templateDisplayName,
      participantLabel: data.participantLabel.present
          ? data.participantLabel.value
          : this.participantLabel,
      progressLabel: data.progressLabel.present
          ? data.progressLabel.value
          : this.progressLabel,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActiveSessionsTableData(')
          ..write('id: $id, ')
          ..write('sessionKind: $sessionKind, ')
          ..write('templateId: $templateId, ')
          ..write('templateDisplayName: $templateDisplayName, ')
          ..write('participantLabel: $participantLabel, ')
          ..write('progressLabel: $progressLabel, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionKind,
    templateId,
    templateDisplayName,
    participantLabel,
    progressLabel,
    payloadJson,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActiveSessionsTableData &&
          other.id == this.id &&
          other.sessionKind == this.sessionKind &&
          other.templateId == this.templateId &&
          other.templateDisplayName == this.templateDisplayName &&
          other.participantLabel == this.participantLabel &&
          other.progressLabel == this.progressLabel &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt);
}

class ActiveSessionsTableCompanion
    extends UpdateCompanion<ActiveSessionsTableData> {
  final Value<String> id;
  final Value<String> sessionKind;
  final Value<String> templateId;
  final Value<String> templateDisplayName;
  final Value<String> participantLabel;
  final Value<String> progressLabel;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ActiveSessionsTableCompanion({
    this.id = const Value.absent(),
    this.sessionKind = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateDisplayName = const Value.absent(),
    this.participantLabel = const Value.absent(),
    this.progressLabel = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActiveSessionsTableCompanion.insert({
    required String id,
    required String sessionKind,
    required String templateId,
    required String templateDisplayName,
    required String participantLabel,
    required String progressLabel,
    required String payloadJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionKind = Value(sessionKind),
       templateId = Value(templateId),
       templateDisplayName = Value(templateDisplayName),
       participantLabel = Value(participantLabel),
       progressLabel = Value(progressLabel),
       payloadJson = Value(payloadJson),
       updatedAt = Value(updatedAt);
  static Insertable<ActiveSessionsTableData> custom({
    Expression<String>? id,
    Expression<String>? sessionKind,
    Expression<String>? templateId,
    Expression<String>? templateDisplayName,
    Expression<String>? participantLabel,
    Expression<String>? progressLabel,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionKind != null) 'session_kind': sessionKind,
      if (templateId != null) 'template_id': templateId,
      if (templateDisplayName != null)
        'template_display_name': templateDisplayName,
      if (participantLabel != null) 'participant_label': participantLabel,
      if (progressLabel != null) 'progress_label': progressLabel,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActiveSessionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionKind,
    Value<String>? templateId,
    Value<String>? templateDisplayName,
    Value<String>? participantLabel,
    Value<String>? progressLabel,
    Value<String>? payloadJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ActiveSessionsTableCompanion(
      id: id ?? this.id,
      sessionKind: sessionKind ?? this.sessionKind,
      templateId: templateId ?? this.templateId,
      templateDisplayName: templateDisplayName ?? this.templateDisplayName,
      participantLabel: participantLabel ?? this.participantLabel,
      progressLabel: progressLabel ?? this.progressLabel,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionKind.present) {
      map['session_kind'] = Variable<String>(sessionKind.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (templateDisplayName.present) {
      map['template_display_name'] = Variable<String>(
        templateDisplayName.value,
      );
    }
    if (participantLabel.present) {
      map['participant_label'] = Variable<String>(participantLabel.value);
    }
    if (progressLabel.present) {
      map['progress_label'] = Variable<String>(progressLabel.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActiveSessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('sessionKind: $sessionKind, ')
          ..write('templateId: $templateId, ')
          ..write('templateDisplayName: $templateDisplayName, ')
          ..write('participantLabel: $participantLabel, ')
          ..write('progressLabel: $progressLabel, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayerGroupsTableTable extends PlayerGroupsTable
    with TableInfo<$PlayerGroupsTableTable, PlayerGroupsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerGroupsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, normalizedName, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_groups_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayerGroupsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {normalizedName},
  ];
  @override
  PlayerGroupsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerGroupsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlayerGroupsTableTable createAlias(String alias) {
    return $PlayerGroupsTableTable(attachedDatabase, alias);
  }
}

class PlayerGroupsTableData extends DataClass
    implements Insertable<PlayerGroupsTableData> {
  final String id;
  final String name;
  final String normalizedName;
  final DateTime createdAt;
  const PlayerGroupsTableData({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlayerGroupsTableCompanion toCompanion(bool nullToAbsent) {
    return PlayerGroupsTableCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      createdAt: Value(createdAt),
    );
  }

  factory PlayerGroupsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerGroupsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlayerGroupsTableData copyWith({
    String? id,
    String? name,
    String? normalizedName,
    DateTime? createdAt,
  }) => PlayerGroupsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    createdAt: createdAt ?? this.createdAt,
  );
  PlayerGroupsTableData copyWithCompanion(PlayerGroupsTableCompanion data) {
    return PlayerGroupsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerGroupsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, normalizedName, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerGroupsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.createdAt == this.createdAt);
}

class PlayerGroupsTableCompanion
    extends UpdateCompanion<PlayerGroupsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlayerGroupsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayerGroupsTableCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalizedName = Value(normalizedName),
       createdAt = Value(createdAt);
  static Insertable<PlayerGroupsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayerGroupsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlayerGroupsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerGroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayerGroupMembersTableTable extends PlayerGroupMembersTable
    with TableInfo<$PlayerGroupMembersTableTable, PlayerGroupMembersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerGroupMembersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playerId, groupId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_group_members_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayerGroupMembersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId, groupId};
  @override
  PlayerGroupMembersTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerGroupMembersTableData(
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
    );
  }

  @override
  $PlayerGroupMembersTableTable createAlias(String alias) {
    return $PlayerGroupMembersTableTable(attachedDatabase, alias);
  }
}

class PlayerGroupMembersTableData extends DataClass
    implements Insertable<PlayerGroupMembersTableData> {
  final String playerId;
  final String groupId;
  const PlayerGroupMembersTableData({
    required this.playerId,
    required this.groupId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<String>(playerId);
    map['group_id'] = Variable<String>(groupId);
    return map;
  }

  PlayerGroupMembersTableCompanion toCompanion(bool nullToAbsent) {
    return PlayerGroupMembersTableCompanion(
      playerId: Value(playerId),
      groupId: Value(groupId),
    );
  }

  factory PlayerGroupMembersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerGroupMembersTableData(
      playerId: serializer.fromJson<String>(json['playerId']),
      groupId: serializer.fromJson<String>(json['groupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<String>(playerId),
      'groupId': serializer.toJson<String>(groupId),
    };
  }

  PlayerGroupMembersTableData copyWith({String? playerId, String? groupId}) =>
      PlayerGroupMembersTableData(
        playerId: playerId ?? this.playerId,
        groupId: groupId ?? this.groupId,
      );
  PlayerGroupMembersTableData copyWithCompanion(
    PlayerGroupMembersTableCompanion data,
  ) {
    return PlayerGroupMembersTableData(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerGroupMembersTableData(')
          ..write('playerId: $playerId, ')
          ..write('groupId: $groupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playerId, groupId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerGroupMembersTableData &&
          other.playerId == this.playerId &&
          other.groupId == this.groupId);
}

class PlayerGroupMembersTableCompanion
    extends UpdateCompanion<PlayerGroupMembersTableData> {
  final Value<String> playerId;
  final Value<String> groupId;
  final Value<int> rowid;
  const PlayerGroupMembersTableCompanion({
    this.playerId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayerGroupMembersTableCompanion.insert({
    required String playerId,
    required String groupId,
    this.rowid = const Value.absent(),
  }) : playerId = Value(playerId),
       groupId = Value(groupId);
  static Insertable<PlayerGroupMembersTableData> custom({
    Expression<String>? playerId,
    Expression<String>? groupId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (groupId != null) 'group_id': groupId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayerGroupMembersTableCompanion copyWith({
    Value<String>? playerId,
    Value<String>? groupId,
    Value<int>? rowid,
  }) {
    return PlayerGroupMembersTableCompanion(
      playerId: playerId ?? this.playerId,
      groupId: groupId ?? this.groupId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerGroupMembersTableCompanion(')
          ..write('playerId: $playerId, ')
          ..write('groupId: $groupId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayersTableTable playersTable = $PlayersTableTable(this);
  late final $QuickScoreSessionsTableTable quickScoreSessionsTable =
      $QuickScoreSessionsTableTable(this);
  late final $QuickScorePlayerResultsTableTable quickScorePlayerResultsTable =
      $QuickScorePlayerResultsTableTable(this);
  late final $QuickScoreFieldValuesTableTable quickScoreFieldValuesTable =
      $QuickScoreFieldValuesTableTable(this);
  late final $RoundScoreSessionsTableTable roundScoreSessionsTable =
      $RoundScoreSessionsTableTable(this);
  late final $RoundScorePlayerResultsTableTable roundScorePlayerResultsTable =
      $RoundScorePlayerResultsTableTable(this);
  late final $RoundScoreFieldValuesTableTable roundScoreFieldValuesTable =
      $RoundScoreFieldValuesTableTable(this);
  late final $ActiveSessionsTableTable activeSessionsTable =
      $ActiveSessionsTableTable(this);
  late final $PlayerGroupsTableTable playerGroupsTable =
      $PlayerGroupsTableTable(this);
  late final $PlayerGroupMembersTableTable playerGroupMembersTable =
      $PlayerGroupMembersTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    playersTable,
    quickScoreSessionsTable,
    quickScorePlayerResultsTable,
    quickScoreFieldValuesTable,
    roundScoreSessionsTable,
    roundScorePlayerResultsTable,
    roundScoreFieldValuesTable,
    activeSessionsTable,
    playerGroupsTable,
    playerGroupMembersTable,
  ];
}

typedef $$PlayersTableTableCreateCompanionBuilder =
    PlayersTableCompanion Function({
      required String id,
      required String displayName,
      required String normalizedDisplayName,
      Value<bool> isArchived,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PlayersTableTableUpdateCompanionBuilder =
    PlayersTableCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> normalizedDisplayName,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PlayersTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTableTable> {
  $$PlayersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedDisplayName => $composableBuilder(
    column: $table.normalizedDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTableTable> {
  $$PlayersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedDisplayName => $composableBuilder(
    column: $table.normalizedDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTableTable> {
  $$PlayersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedDisplayName => $composableBuilder(
    column: $table.normalizedDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlayersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTableTable,
          PlayersTableData,
          $$PlayersTableTableFilterComposer,
          $$PlayersTableTableOrderingComposer,
          $$PlayersTableTableAnnotationComposer,
          $$PlayersTableTableCreateCompanionBuilder,
          $$PlayersTableTableUpdateCompanionBuilder,
          (
            PlayersTableData,
            BaseReferences<_$AppDatabase, $PlayersTableTable, PlayersTableData>,
          ),
          PlayersTableData,
          PrefetchHooks Function()
        > {
  $$PlayersTableTableTableManager(_$AppDatabase db, $PlayersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> normalizedDisplayName = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayersTableCompanion(
                id: id,
                displayName: displayName,
                normalizedDisplayName: normalizedDisplayName,
                isArchived: isArchived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String normalizedDisplayName,
                Value<bool> isArchived = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlayersTableCompanion.insert(
                id: id,
                displayName: displayName,
                normalizedDisplayName: normalizedDisplayName,
                isArchived: isArchived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTableTable,
      PlayersTableData,
      $$PlayersTableTableFilterComposer,
      $$PlayersTableTableOrderingComposer,
      $$PlayersTableTableAnnotationComposer,
      $$PlayersTableTableCreateCompanionBuilder,
      $$PlayersTableTableUpdateCompanionBuilder,
      (
        PlayersTableData,
        BaseReferences<_$AppDatabase, $PlayersTableTable, PlayersTableData>,
      ),
      PlayersTableData,
      PrefetchHooks Function()
    >;
typedef $$QuickScoreSessionsTableTableCreateCompanionBuilder =
    QuickScoreSessionsTableCompanion Function({
      required String id,
      required String templateId,
      required String templateDisplayName,
      required String winnerRule,
      Value<String> optionsJson,
      required DateTime completedAt,
      Value<int> rowid,
    });
typedef $$QuickScoreSessionsTableTableUpdateCompanionBuilder =
    QuickScoreSessionsTableCompanion Function({
      Value<String> id,
      Value<String> templateId,
      Value<String> templateDisplayName,
      Value<String> winnerRule,
      Value<String> optionsJson,
      Value<DateTime> completedAt,
      Value<int> rowid,
    });

class $$QuickScoreSessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $QuickScoreSessionsTableTable> {
  $$QuickScoreSessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateDisplayName => $composableBuilder(
    column: $table.templateDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get winnerRule => $composableBuilder(
    column: $table.winnerRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuickScoreSessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $QuickScoreSessionsTableTable> {
  $$QuickScoreSessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateDisplayName => $composableBuilder(
    column: $table.templateDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get winnerRule => $composableBuilder(
    column: $table.winnerRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuickScoreSessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuickScoreSessionsTableTable> {
  $$QuickScoreSessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateDisplayName => $composableBuilder(
    column: $table.templateDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get winnerRule => $composableBuilder(
    column: $table.winnerRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$QuickScoreSessionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuickScoreSessionsTableTable,
          QuickScoreSessionsTableData,
          $$QuickScoreSessionsTableTableFilterComposer,
          $$QuickScoreSessionsTableTableOrderingComposer,
          $$QuickScoreSessionsTableTableAnnotationComposer,
          $$QuickScoreSessionsTableTableCreateCompanionBuilder,
          $$QuickScoreSessionsTableTableUpdateCompanionBuilder,
          (
            QuickScoreSessionsTableData,
            BaseReferences<
              _$AppDatabase,
              $QuickScoreSessionsTableTable,
              QuickScoreSessionsTableData
            >,
          ),
          QuickScoreSessionsTableData,
          PrefetchHooks Function()
        > {
  $$QuickScoreSessionsTableTableTableManager(
    _$AppDatabase db,
    $QuickScoreSessionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuickScoreSessionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$QuickScoreSessionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$QuickScoreSessionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> templateDisplayName = const Value.absent(),
                Value<String> winnerRule = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuickScoreSessionsTableCompanion(
                id: id,
                templateId: templateId,
                templateDisplayName: templateDisplayName,
                winnerRule: winnerRule,
                optionsJson: optionsJson,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateId,
                required String templateDisplayName,
                required String winnerRule,
                Value<String> optionsJson = const Value.absent(),
                required DateTime completedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuickScoreSessionsTableCompanion.insert(
                id: id,
                templateId: templateId,
                templateDisplayName: templateDisplayName,
                winnerRule: winnerRule,
                optionsJson: optionsJson,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuickScoreSessionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuickScoreSessionsTableTable,
      QuickScoreSessionsTableData,
      $$QuickScoreSessionsTableTableFilterComposer,
      $$QuickScoreSessionsTableTableOrderingComposer,
      $$QuickScoreSessionsTableTableAnnotationComposer,
      $$QuickScoreSessionsTableTableCreateCompanionBuilder,
      $$QuickScoreSessionsTableTableUpdateCompanionBuilder,
      (
        QuickScoreSessionsTableData,
        BaseReferences<
          _$AppDatabase,
          $QuickScoreSessionsTableTable,
          QuickScoreSessionsTableData
        >,
      ),
      QuickScoreSessionsTableData,
      PrefetchHooks Function()
    >;
typedef $$QuickScorePlayerResultsTableTableCreateCompanionBuilder =
    QuickScorePlayerResultsTableCompanion Function({
      required String sessionId,
      required String playerId,
      required String displayName,
      required int finalScore,
      required int placement,
      required bool isTied,
      Value<int> rowid,
    });
typedef $$QuickScorePlayerResultsTableTableUpdateCompanionBuilder =
    QuickScorePlayerResultsTableCompanion Function({
      Value<String> sessionId,
      Value<String> playerId,
      Value<String> displayName,
      Value<int> finalScore,
      Value<int> placement,
      Value<bool> isTied,
      Value<int> rowid,
    });

class $$QuickScorePlayerResultsTableTableFilterComposer
    extends Composer<_$AppDatabase, $QuickScorePlayerResultsTableTable> {
  $$QuickScorePlayerResultsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finalScore => $composableBuilder(
    column: $table.finalScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get placement => $composableBuilder(
    column: $table.placement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTied => $composableBuilder(
    column: $table.isTied,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuickScorePlayerResultsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $QuickScorePlayerResultsTableTable> {
  $$QuickScorePlayerResultsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finalScore => $composableBuilder(
    column: $table.finalScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get placement => $composableBuilder(
    column: $table.placement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTied => $composableBuilder(
    column: $table.isTied,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuickScorePlayerResultsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuickScorePlayerResultsTableTable> {
  $$QuickScorePlayerResultsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get finalScore => $composableBuilder(
    column: $table.finalScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get placement =>
      $composableBuilder(column: $table.placement, builder: (column) => column);

  GeneratedColumn<bool> get isTied =>
      $composableBuilder(column: $table.isTied, builder: (column) => column);
}

class $$QuickScorePlayerResultsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuickScorePlayerResultsTableTable,
          QuickScorePlayerResultsTableData,
          $$QuickScorePlayerResultsTableTableFilterComposer,
          $$QuickScorePlayerResultsTableTableOrderingComposer,
          $$QuickScorePlayerResultsTableTableAnnotationComposer,
          $$QuickScorePlayerResultsTableTableCreateCompanionBuilder,
          $$QuickScorePlayerResultsTableTableUpdateCompanionBuilder,
          (
            QuickScorePlayerResultsTableData,
            BaseReferences<
              _$AppDatabase,
              $QuickScorePlayerResultsTableTable,
              QuickScorePlayerResultsTableData
            >,
          ),
          QuickScorePlayerResultsTableData,
          PrefetchHooks Function()
        > {
  $$QuickScorePlayerResultsTableTableTableManager(
    _$AppDatabase db,
    $QuickScorePlayerResultsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuickScorePlayerResultsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$QuickScorePlayerResultsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$QuickScorePlayerResultsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> finalScore = const Value.absent(),
                Value<int> placement = const Value.absent(),
                Value<bool> isTied = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuickScorePlayerResultsTableCompanion(
                sessionId: sessionId,
                playerId: playerId,
                displayName: displayName,
                finalScore: finalScore,
                placement: placement,
                isTied: isTied,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String playerId,
                required String displayName,
                required int finalScore,
                required int placement,
                required bool isTied,
                Value<int> rowid = const Value.absent(),
              }) => QuickScorePlayerResultsTableCompanion.insert(
                sessionId: sessionId,
                playerId: playerId,
                displayName: displayName,
                finalScore: finalScore,
                placement: placement,
                isTied: isTied,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuickScorePlayerResultsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuickScorePlayerResultsTableTable,
      QuickScorePlayerResultsTableData,
      $$QuickScorePlayerResultsTableTableFilterComposer,
      $$QuickScorePlayerResultsTableTableOrderingComposer,
      $$QuickScorePlayerResultsTableTableAnnotationComposer,
      $$QuickScorePlayerResultsTableTableCreateCompanionBuilder,
      $$QuickScorePlayerResultsTableTableUpdateCompanionBuilder,
      (
        QuickScorePlayerResultsTableData,
        BaseReferences<
          _$AppDatabase,
          $QuickScorePlayerResultsTableTable,
          QuickScorePlayerResultsTableData
        >,
      ),
      QuickScorePlayerResultsTableData,
      PrefetchHooks Function()
    >;
typedef $$QuickScoreFieldValuesTableTableCreateCompanionBuilder =
    QuickScoreFieldValuesTableCompanion Function({
      required String sessionId,
      required String playerId,
      required String fieldId,
      required int integerValue,
      Value<int> rowid,
    });
typedef $$QuickScoreFieldValuesTableTableUpdateCompanionBuilder =
    QuickScoreFieldValuesTableCompanion Function({
      Value<String> sessionId,
      Value<String> playerId,
      Value<String> fieldId,
      Value<int> integerValue,
      Value<int> rowid,
    });

class $$QuickScoreFieldValuesTableTableFilterComposer
    extends Composer<_$AppDatabase, $QuickScoreFieldValuesTableTable> {
  $$QuickScoreFieldValuesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldId => $composableBuilder(
    column: $table.fieldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get integerValue => $composableBuilder(
    column: $table.integerValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuickScoreFieldValuesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $QuickScoreFieldValuesTableTable> {
  $$QuickScoreFieldValuesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldId => $composableBuilder(
    column: $table.fieldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get integerValue => $composableBuilder(
    column: $table.integerValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuickScoreFieldValuesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuickScoreFieldValuesTableTable> {
  $$QuickScoreFieldValuesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get fieldId =>
      $composableBuilder(column: $table.fieldId, builder: (column) => column);

  GeneratedColumn<int> get integerValue => $composableBuilder(
    column: $table.integerValue,
    builder: (column) => column,
  );
}

class $$QuickScoreFieldValuesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuickScoreFieldValuesTableTable,
          QuickScoreFieldValuesTableData,
          $$QuickScoreFieldValuesTableTableFilterComposer,
          $$QuickScoreFieldValuesTableTableOrderingComposer,
          $$QuickScoreFieldValuesTableTableAnnotationComposer,
          $$QuickScoreFieldValuesTableTableCreateCompanionBuilder,
          $$QuickScoreFieldValuesTableTableUpdateCompanionBuilder,
          (
            QuickScoreFieldValuesTableData,
            BaseReferences<
              _$AppDatabase,
              $QuickScoreFieldValuesTableTable,
              QuickScoreFieldValuesTableData
            >,
          ),
          QuickScoreFieldValuesTableData,
          PrefetchHooks Function()
        > {
  $$QuickScoreFieldValuesTableTableTableManager(
    _$AppDatabase db,
    $QuickScoreFieldValuesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuickScoreFieldValuesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$QuickScoreFieldValuesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$QuickScoreFieldValuesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<String> fieldId = const Value.absent(),
                Value<int> integerValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuickScoreFieldValuesTableCompanion(
                sessionId: sessionId,
                playerId: playerId,
                fieldId: fieldId,
                integerValue: integerValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String playerId,
                required String fieldId,
                required int integerValue,
                Value<int> rowid = const Value.absent(),
              }) => QuickScoreFieldValuesTableCompanion.insert(
                sessionId: sessionId,
                playerId: playerId,
                fieldId: fieldId,
                integerValue: integerValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuickScoreFieldValuesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuickScoreFieldValuesTableTable,
      QuickScoreFieldValuesTableData,
      $$QuickScoreFieldValuesTableTableFilterComposer,
      $$QuickScoreFieldValuesTableTableOrderingComposer,
      $$QuickScoreFieldValuesTableTableAnnotationComposer,
      $$QuickScoreFieldValuesTableTableCreateCompanionBuilder,
      $$QuickScoreFieldValuesTableTableUpdateCompanionBuilder,
      (
        QuickScoreFieldValuesTableData,
        BaseReferences<
          _$AppDatabase,
          $QuickScoreFieldValuesTableTable,
          QuickScoreFieldValuesTableData
        >,
      ),
      QuickScoreFieldValuesTableData,
      PrefetchHooks Function()
    >;
typedef $$RoundScoreSessionsTableTableCreateCompanionBuilder =
    RoundScoreSessionsTableCompanion Function({
      required String id,
      required String templateId,
      required String templateDisplayName,
      required String winnerRule,
      Value<String> optionsJson,
      required int roundCount,
      required DateTime completedAt,
      Value<int> rowid,
    });
typedef $$RoundScoreSessionsTableTableUpdateCompanionBuilder =
    RoundScoreSessionsTableCompanion Function({
      Value<String> id,
      Value<String> templateId,
      Value<String> templateDisplayName,
      Value<String> winnerRule,
      Value<String> optionsJson,
      Value<int> roundCount,
      Value<DateTime> completedAt,
      Value<int> rowid,
    });

class $$RoundScoreSessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $RoundScoreSessionsTableTable> {
  $$RoundScoreSessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateDisplayName => $composableBuilder(
    column: $table.templateDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get winnerRule => $composableBuilder(
    column: $table.winnerRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundCount => $composableBuilder(
    column: $table.roundCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RoundScoreSessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RoundScoreSessionsTableTable> {
  $$RoundScoreSessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateDisplayName => $composableBuilder(
    column: $table.templateDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get winnerRule => $composableBuilder(
    column: $table.winnerRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundCount => $composableBuilder(
    column: $table.roundCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoundScoreSessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoundScoreSessionsTableTable> {
  $$RoundScoreSessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateDisplayName => $composableBuilder(
    column: $table.templateDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get winnerRule => $composableBuilder(
    column: $table.winnerRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundCount => $composableBuilder(
    column: $table.roundCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$RoundScoreSessionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoundScoreSessionsTableTable,
          RoundScoreSessionsTableData,
          $$RoundScoreSessionsTableTableFilterComposer,
          $$RoundScoreSessionsTableTableOrderingComposer,
          $$RoundScoreSessionsTableTableAnnotationComposer,
          $$RoundScoreSessionsTableTableCreateCompanionBuilder,
          $$RoundScoreSessionsTableTableUpdateCompanionBuilder,
          (
            RoundScoreSessionsTableData,
            BaseReferences<
              _$AppDatabase,
              $RoundScoreSessionsTableTable,
              RoundScoreSessionsTableData
            >,
          ),
          RoundScoreSessionsTableData,
          PrefetchHooks Function()
        > {
  $$RoundScoreSessionsTableTableTableManager(
    _$AppDatabase db,
    $RoundScoreSessionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoundScoreSessionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RoundScoreSessionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RoundScoreSessionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> templateDisplayName = const Value.absent(),
                Value<String> winnerRule = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<int> roundCount = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoundScoreSessionsTableCompanion(
                id: id,
                templateId: templateId,
                templateDisplayName: templateDisplayName,
                winnerRule: winnerRule,
                optionsJson: optionsJson,
                roundCount: roundCount,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateId,
                required String templateDisplayName,
                required String winnerRule,
                Value<String> optionsJson = const Value.absent(),
                required int roundCount,
                required DateTime completedAt,
                Value<int> rowid = const Value.absent(),
              }) => RoundScoreSessionsTableCompanion.insert(
                id: id,
                templateId: templateId,
                templateDisplayName: templateDisplayName,
                winnerRule: winnerRule,
                optionsJson: optionsJson,
                roundCount: roundCount,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RoundScoreSessionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoundScoreSessionsTableTable,
      RoundScoreSessionsTableData,
      $$RoundScoreSessionsTableTableFilterComposer,
      $$RoundScoreSessionsTableTableOrderingComposer,
      $$RoundScoreSessionsTableTableAnnotationComposer,
      $$RoundScoreSessionsTableTableCreateCompanionBuilder,
      $$RoundScoreSessionsTableTableUpdateCompanionBuilder,
      (
        RoundScoreSessionsTableData,
        BaseReferences<
          _$AppDatabase,
          $RoundScoreSessionsTableTable,
          RoundScoreSessionsTableData
        >,
      ),
      RoundScoreSessionsTableData,
      PrefetchHooks Function()
    >;
typedef $$RoundScorePlayerResultsTableTableCreateCompanionBuilder =
    RoundScorePlayerResultsTableCompanion Function({
      required String sessionId,
      required String playerId,
      required String displayName,
      required int cumulativeScore,
      required int placement,
      required bool isTied,
      Value<int> rowid,
    });
typedef $$RoundScorePlayerResultsTableTableUpdateCompanionBuilder =
    RoundScorePlayerResultsTableCompanion Function({
      Value<String> sessionId,
      Value<String> playerId,
      Value<String> displayName,
      Value<int> cumulativeScore,
      Value<int> placement,
      Value<bool> isTied,
      Value<int> rowid,
    });

class $$RoundScorePlayerResultsTableTableFilterComposer
    extends Composer<_$AppDatabase, $RoundScorePlayerResultsTableTable> {
  $$RoundScorePlayerResultsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cumulativeScore => $composableBuilder(
    column: $table.cumulativeScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get placement => $composableBuilder(
    column: $table.placement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTied => $composableBuilder(
    column: $table.isTied,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RoundScorePlayerResultsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RoundScorePlayerResultsTableTable> {
  $$RoundScorePlayerResultsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cumulativeScore => $composableBuilder(
    column: $table.cumulativeScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get placement => $composableBuilder(
    column: $table.placement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTied => $composableBuilder(
    column: $table.isTied,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoundScorePlayerResultsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoundScorePlayerResultsTableTable> {
  $$RoundScorePlayerResultsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cumulativeScore => $composableBuilder(
    column: $table.cumulativeScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get placement =>
      $composableBuilder(column: $table.placement, builder: (column) => column);

  GeneratedColumn<bool> get isTied =>
      $composableBuilder(column: $table.isTied, builder: (column) => column);
}

class $$RoundScorePlayerResultsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoundScorePlayerResultsTableTable,
          RoundScorePlayerResultsTableData,
          $$RoundScorePlayerResultsTableTableFilterComposer,
          $$RoundScorePlayerResultsTableTableOrderingComposer,
          $$RoundScorePlayerResultsTableTableAnnotationComposer,
          $$RoundScorePlayerResultsTableTableCreateCompanionBuilder,
          $$RoundScorePlayerResultsTableTableUpdateCompanionBuilder,
          (
            RoundScorePlayerResultsTableData,
            BaseReferences<
              _$AppDatabase,
              $RoundScorePlayerResultsTableTable,
              RoundScorePlayerResultsTableData
            >,
          ),
          RoundScorePlayerResultsTableData,
          PrefetchHooks Function()
        > {
  $$RoundScorePlayerResultsTableTableTableManager(
    _$AppDatabase db,
    $RoundScorePlayerResultsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoundScorePlayerResultsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RoundScorePlayerResultsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RoundScorePlayerResultsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> cumulativeScore = const Value.absent(),
                Value<int> placement = const Value.absent(),
                Value<bool> isTied = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoundScorePlayerResultsTableCompanion(
                sessionId: sessionId,
                playerId: playerId,
                displayName: displayName,
                cumulativeScore: cumulativeScore,
                placement: placement,
                isTied: isTied,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String playerId,
                required String displayName,
                required int cumulativeScore,
                required int placement,
                required bool isTied,
                Value<int> rowid = const Value.absent(),
              }) => RoundScorePlayerResultsTableCompanion.insert(
                sessionId: sessionId,
                playerId: playerId,
                displayName: displayName,
                cumulativeScore: cumulativeScore,
                placement: placement,
                isTied: isTied,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RoundScorePlayerResultsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoundScorePlayerResultsTableTable,
      RoundScorePlayerResultsTableData,
      $$RoundScorePlayerResultsTableTableFilterComposer,
      $$RoundScorePlayerResultsTableTableOrderingComposer,
      $$RoundScorePlayerResultsTableTableAnnotationComposer,
      $$RoundScorePlayerResultsTableTableCreateCompanionBuilder,
      $$RoundScorePlayerResultsTableTableUpdateCompanionBuilder,
      (
        RoundScorePlayerResultsTableData,
        BaseReferences<
          _$AppDatabase,
          $RoundScorePlayerResultsTableTable,
          RoundScorePlayerResultsTableData
        >,
      ),
      RoundScorePlayerResultsTableData,
      PrefetchHooks Function()
    >;
typedef $$RoundScoreFieldValuesTableTableCreateCompanionBuilder =
    RoundScoreFieldValuesTableCompanion Function({
      required String sessionId,
      required int roundNumber,
      required String playerId,
      required String displayName,
      required String fieldId,
      required int integerValue,
      Value<int> rowid,
    });
typedef $$RoundScoreFieldValuesTableTableUpdateCompanionBuilder =
    RoundScoreFieldValuesTableCompanion Function({
      Value<String> sessionId,
      Value<int> roundNumber,
      Value<String> playerId,
      Value<String> displayName,
      Value<String> fieldId,
      Value<int> integerValue,
      Value<int> rowid,
    });

class $$RoundScoreFieldValuesTableTableFilterComposer
    extends Composer<_$AppDatabase, $RoundScoreFieldValuesTableTable> {
  $$RoundScoreFieldValuesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldId => $composableBuilder(
    column: $table.fieldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get integerValue => $composableBuilder(
    column: $table.integerValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RoundScoreFieldValuesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RoundScoreFieldValuesTableTable> {
  $$RoundScoreFieldValuesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldId => $composableBuilder(
    column: $table.fieldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get integerValue => $composableBuilder(
    column: $table.integerValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoundScoreFieldValuesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoundScoreFieldValuesTableTable> {
  $$RoundScoreFieldValuesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldId =>
      $composableBuilder(column: $table.fieldId, builder: (column) => column);

  GeneratedColumn<int> get integerValue => $composableBuilder(
    column: $table.integerValue,
    builder: (column) => column,
  );
}

class $$RoundScoreFieldValuesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoundScoreFieldValuesTableTable,
          RoundScoreFieldValuesTableData,
          $$RoundScoreFieldValuesTableTableFilterComposer,
          $$RoundScoreFieldValuesTableTableOrderingComposer,
          $$RoundScoreFieldValuesTableTableAnnotationComposer,
          $$RoundScoreFieldValuesTableTableCreateCompanionBuilder,
          $$RoundScoreFieldValuesTableTableUpdateCompanionBuilder,
          (
            RoundScoreFieldValuesTableData,
            BaseReferences<
              _$AppDatabase,
              $RoundScoreFieldValuesTableTable,
              RoundScoreFieldValuesTableData
            >,
          ),
          RoundScoreFieldValuesTableData,
          PrefetchHooks Function()
        > {
  $$RoundScoreFieldValuesTableTableTableManager(
    _$AppDatabase db,
    $RoundScoreFieldValuesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoundScoreFieldValuesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RoundScoreFieldValuesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RoundScoreFieldValuesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> roundNumber = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> fieldId = const Value.absent(),
                Value<int> integerValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoundScoreFieldValuesTableCompanion(
                sessionId: sessionId,
                roundNumber: roundNumber,
                playerId: playerId,
                displayName: displayName,
                fieldId: fieldId,
                integerValue: integerValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required int roundNumber,
                required String playerId,
                required String displayName,
                required String fieldId,
                required int integerValue,
                Value<int> rowid = const Value.absent(),
              }) => RoundScoreFieldValuesTableCompanion.insert(
                sessionId: sessionId,
                roundNumber: roundNumber,
                playerId: playerId,
                displayName: displayName,
                fieldId: fieldId,
                integerValue: integerValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RoundScoreFieldValuesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoundScoreFieldValuesTableTable,
      RoundScoreFieldValuesTableData,
      $$RoundScoreFieldValuesTableTableFilterComposer,
      $$RoundScoreFieldValuesTableTableOrderingComposer,
      $$RoundScoreFieldValuesTableTableAnnotationComposer,
      $$RoundScoreFieldValuesTableTableCreateCompanionBuilder,
      $$RoundScoreFieldValuesTableTableUpdateCompanionBuilder,
      (
        RoundScoreFieldValuesTableData,
        BaseReferences<
          _$AppDatabase,
          $RoundScoreFieldValuesTableTable,
          RoundScoreFieldValuesTableData
        >,
      ),
      RoundScoreFieldValuesTableData,
      PrefetchHooks Function()
    >;
typedef $$ActiveSessionsTableTableCreateCompanionBuilder =
    ActiveSessionsTableCompanion Function({
      required String id,
      required String sessionKind,
      required String templateId,
      required String templateDisplayName,
      required String participantLabel,
      required String progressLabel,
      required String payloadJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ActiveSessionsTableTableUpdateCompanionBuilder =
    ActiveSessionsTableCompanion Function({
      Value<String> id,
      Value<String> sessionKind,
      Value<String> templateId,
      Value<String> templateDisplayName,
      Value<String> participantLabel,
      Value<String> progressLabel,
      Value<String> payloadJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ActiveSessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ActiveSessionsTableTable> {
  $$ActiveSessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionKind => $composableBuilder(
    column: $table.sessionKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateDisplayName => $composableBuilder(
    column: $table.templateDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantLabel => $composableBuilder(
    column: $table.participantLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get progressLabel => $composableBuilder(
    column: $table.progressLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActiveSessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ActiveSessionsTableTable> {
  $$ActiveSessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionKind => $composableBuilder(
    column: $table.sessionKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateDisplayName => $composableBuilder(
    column: $table.templateDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantLabel => $composableBuilder(
    column: $table.participantLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get progressLabel => $composableBuilder(
    column: $table.progressLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActiveSessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActiveSessionsTableTable> {
  $$ActiveSessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionKind => $composableBuilder(
    column: $table.sessionKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateDisplayName => $composableBuilder(
    column: $table.templateDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get participantLabel => $composableBuilder(
    column: $table.participantLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get progressLabel => $composableBuilder(
    column: $table.progressLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ActiveSessionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActiveSessionsTableTable,
          ActiveSessionsTableData,
          $$ActiveSessionsTableTableFilterComposer,
          $$ActiveSessionsTableTableOrderingComposer,
          $$ActiveSessionsTableTableAnnotationComposer,
          $$ActiveSessionsTableTableCreateCompanionBuilder,
          $$ActiveSessionsTableTableUpdateCompanionBuilder,
          (
            ActiveSessionsTableData,
            BaseReferences<
              _$AppDatabase,
              $ActiveSessionsTableTable,
              ActiveSessionsTableData
            >,
          ),
          ActiveSessionsTableData,
          PrefetchHooks Function()
        > {
  $$ActiveSessionsTableTableTableManager(
    _$AppDatabase db,
    $ActiveSessionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActiveSessionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActiveSessionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ActiveSessionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionKind = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> templateDisplayName = const Value.absent(),
                Value<String> participantLabel = const Value.absent(),
                Value<String> progressLabel = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActiveSessionsTableCompanion(
                id: id,
                sessionKind: sessionKind,
                templateId: templateId,
                templateDisplayName: templateDisplayName,
                participantLabel: participantLabel,
                progressLabel: progressLabel,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionKind,
                required String templateId,
                required String templateDisplayName,
                required String participantLabel,
                required String progressLabel,
                required String payloadJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ActiveSessionsTableCompanion.insert(
                id: id,
                sessionKind: sessionKind,
                templateId: templateId,
                templateDisplayName: templateDisplayName,
                participantLabel: participantLabel,
                progressLabel: progressLabel,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActiveSessionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActiveSessionsTableTable,
      ActiveSessionsTableData,
      $$ActiveSessionsTableTableFilterComposer,
      $$ActiveSessionsTableTableOrderingComposer,
      $$ActiveSessionsTableTableAnnotationComposer,
      $$ActiveSessionsTableTableCreateCompanionBuilder,
      $$ActiveSessionsTableTableUpdateCompanionBuilder,
      (
        ActiveSessionsTableData,
        BaseReferences<
          _$AppDatabase,
          $ActiveSessionsTableTable,
          ActiveSessionsTableData
        >,
      ),
      ActiveSessionsTableData,
      PrefetchHooks Function()
    >;
typedef $$PlayerGroupsTableTableCreateCompanionBuilder =
    PlayerGroupsTableCompanion Function({
      required String id,
      required String name,
      required String normalizedName,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PlayerGroupsTableTableUpdateCompanionBuilder =
    PlayerGroupsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> normalizedName,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PlayerGroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerGroupsTableTable> {
  $$PlayerGroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayerGroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerGroupsTableTable> {
  $$PlayerGroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayerGroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerGroupsTableTable> {
  $$PlayerGroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlayerGroupsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayerGroupsTableTable,
          PlayerGroupsTableData,
          $$PlayerGroupsTableTableFilterComposer,
          $$PlayerGroupsTableTableOrderingComposer,
          $$PlayerGroupsTableTableAnnotationComposer,
          $$PlayerGroupsTableTableCreateCompanionBuilder,
          $$PlayerGroupsTableTableUpdateCompanionBuilder,
          (
            PlayerGroupsTableData,
            BaseReferences<
              _$AppDatabase,
              $PlayerGroupsTableTable,
              PlayerGroupsTableData
            >,
          ),
          PlayerGroupsTableData,
          PrefetchHooks Function()
        > {
  $$PlayerGroupsTableTableTableManager(
    _$AppDatabase db,
    $PlayerGroupsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerGroupsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerGroupsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerGroupsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayerGroupsTableCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String normalizedName,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlayerGroupsTableCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayerGroupsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayerGroupsTableTable,
      PlayerGroupsTableData,
      $$PlayerGroupsTableTableFilterComposer,
      $$PlayerGroupsTableTableOrderingComposer,
      $$PlayerGroupsTableTableAnnotationComposer,
      $$PlayerGroupsTableTableCreateCompanionBuilder,
      $$PlayerGroupsTableTableUpdateCompanionBuilder,
      (
        PlayerGroupsTableData,
        BaseReferences<
          _$AppDatabase,
          $PlayerGroupsTableTable,
          PlayerGroupsTableData
        >,
      ),
      PlayerGroupsTableData,
      PrefetchHooks Function()
    >;
typedef $$PlayerGroupMembersTableTableCreateCompanionBuilder =
    PlayerGroupMembersTableCompanion Function({
      required String playerId,
      required String groupId,
      Value<int> rowid,
    });
typedef $$PlayerGroupMembersTableTableUpdateCompanionBuilder =
    PlayerGroupMembersTableCompanion Function({
      Value<String> playerId,
      Value<String> groupId,
      Value<int> rowid,
    });

class $$PlayerGroupMembersTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerGroupMembersTableTable> {
  $$PlayerGroupMembersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayerGroupMembersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerGroupMembersTableTable> {
  $$PlayerGroupMembersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayerGroupMembersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerGroupMembersTableTable> {
  $$PlayerGroupMembersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);
}

class $$PlayerGroupMembersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayerGroupMembersTableTable,
          PlayerGroupMembersTableData,
          $$PlayerGroupMembersTableTableFilterComposer,
          $$PlayerGroupMembersTableTableOrderingComposer,
          $$PlayerGroupMembersTableTableAnnotationComposer,
          $$PlayerGroupMembersTableTableCreateCompanionBuilder,
          $$PlayerGroupMembersTableTableUpdateCompanionBuilder,
          (
            PlayerGroupMembersTableData,
            BaseReferences<
              _$AppDatabase,
              $PlayerGroupMembersTableTable,
              PlayerGroupMembersTableData
            >,
          ),
          PlayerGroupMembersTableData,
          PrefetchHooks Function()
        > {
  $$PlayerGroupMembersTableTableTableManager(
    _$AppDatabase db,
    $PlayerGroupMembersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerGroupMembersTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PlayerGroupMembersTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlayerGroupMembersTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> playerId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayerGroupMembersTableCompanion(
                playerId: playerId,
                groupId: groupId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playerId,
                required String groupId,
                Value<int> rowid = const Value.absent(),
              }) => PlayerGroupMembersTableCompanion.insert(
                playerId: playerId,
                groupId: groupId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayerGroupMembersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayerGroupMembersTableTable,
      PlayerGroupMembersTableData,
      $$PlayerGroupMembersTableTableFilterComposer,
      $$PlayerGroupMembersTableTableOrderingComposer,
      $$PlayerGroupMembersTableTableAnnotationComposer,
      $$PlayerGroupMembersTableTableCreateCompanionBuilder,
      $$PlayerGroupMembersTableTableUpdateCompanionBuilder,
      (
        PlayerGroupMembersTableData,
        BaseReferences<
          _$AppDatabase,
          $PlayerGroupMembersTableTable,
          PlayerGroupMembersTableData
        >,
      ),
      PlayerGroupMembersTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlayersTableTableTableManager get playersTable =>
      $$PlayersTableTableTableManager(_db, _db.playersTable);
  $$QuickScoreSessionsTableTableTableManager get quickScoreSessionsTable =>
      $$QuickScoreSessionsTableTableTableManager(
        _db,
        _db.quickScoreSessionsTable,
      );
  $$QuickScorePlayerResultsTableTableTableManager
  get quickScorePlayerResultsTable =>
      $$QuickScorePlayerResultsTableTableTableManager(
        _db,
        _db.quickScorePlayerResultsTable,
      );
  $$QuickScoreFieldValuesTableTableTableManager
  get quickScoreFieldValuesTable =>
      $$QuickScoreFieldValuesTableTableTableManager(
        _db,
        _db.quickScoreFieldValuesTable,
      );
  $$RoundScoreSessionsTableTableTableManager get roundScoreSessionsTable =>
      $$RoundScoreSessionsTableTableTableManager(
        _db,
        _db.roundScoreSessionsTable,
      );
  $$RoundScorePlayerResultsTableTableTableManager
  get roundScorePlayerResultsTable =>
      $$RoundScorePlayerResultsTableTableTableManager(
        _db,
        _db.roundScorePlayerResultsTable,
      );
  $$RoundScoreFieldValuesTableTableTableManager
  get roundScoreFieldValuesTable =>
      $$RoundScoreFieldValuesTableTableTableManager(
        _db,
        _db.roundScoreFieldValuesTable,
      );
  $$ActiveSessionsTableTableTableManager get activeSessionsTable =>
      $$ActiveSessionsTableTableTableManager(_db, _db.activeSessionsTable);
  $$PlayerGroupsTableTableTableManager get playerGroupsTable =>
      $$PlayerGroupsTableTableTableManager(_db, _db.playerGroupsTable);
  $$PlayerGroupMembersTableTableTableManager get playerGroupMembersTable =>
      $$PlayerGroupMembersTableTableTableManager(
        _db,
        _db.playerGroupMembersTable,
      );
}
