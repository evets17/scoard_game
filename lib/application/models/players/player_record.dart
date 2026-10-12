class PlayerRecord {
  const PlayerRecord({
    required this.id,
    required this.displayName,
    required this.isArchived,
    required this.createdAt,
    this.groupIds = const {},
  });

  final String id;
  final String displayName;
  final bool isArchived;
  final DateTime createdAt;

  /// Groups the player belongs to. Archived players keep theirs so restoring
  /// them puts them back where they were.
  final Set<String> groupIds;

  PlayerRecord copyWith({
    String? id,
    String? displayName,
    bool? isArchived,
    DateTime? createdAt,
    Set<String>? groupIds,
  }) {
    return PlayerRecord(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      groupIds: groupIds ?? this.groupIds,
    );
  }
}
