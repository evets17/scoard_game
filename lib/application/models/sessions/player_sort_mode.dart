enum PlayerSortMode {
  playOrder,
  name,
  score;

  static PlayerSortMode fromStorage(Object? value) {
    return PlayerSortMode.values.asNameMap()[value] ?? PlayerSortMode.playOrder;
  }
}
