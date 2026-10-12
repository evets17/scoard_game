/// Choices the game setup screen remembers between games.
abstract class SetupPreferencesRepository {
  Future<String?> loadLastPlayerGroupId();

  /// Null means the All filter.
  Future<void> saveLastPlayerGroupId(String? groupId);
}
