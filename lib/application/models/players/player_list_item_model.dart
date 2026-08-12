class PlayerListItemModel {
  const PlayerListItemModel({
    required this.id,
    required this.displayName,
    required this.isArchived,
  });

  final String id;
  final String displayName;
  final bool isArchived;
}