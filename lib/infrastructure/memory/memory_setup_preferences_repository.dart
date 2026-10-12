import 'package:scoard_game/application/repositories/setup_preferences_repository.dart';

class MemorySetupPreferencesRepository implements SetupPreferencesRepository {
  String? _lastPlayerGroupId;

  @override
  Future<String?> loadLastPlayerGroupId() async => _lastPlayerGroupId;

  @override
  Future<void> saveLastPlayerGroupId(String? groupId) async {
    _lastPlayerGroupId = groupId;
  }
}
