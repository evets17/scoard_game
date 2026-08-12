class PlayerRecord {
  const PlayerRecord({
    required this.id,
    required this.displayName,
    required this.isArchived,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final bool isArchived;
  final DateTime createdAt;

  PlayerRecord copyWith({
    String? id,
    String? displayName,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return PlayerRecord(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}