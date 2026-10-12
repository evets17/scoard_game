class PlayerListItemModel {
  const PlayerListItemModel({
    required this.id,
    required this.displayName,
    required this.isArchived,
    this.groupIds = const {},
  });

  final String id;
  final String displayName;
  final bool isArchived;
  final Set<String> groupIds;
}
