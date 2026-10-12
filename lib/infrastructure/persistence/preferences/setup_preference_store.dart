import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoard_game/application/repositories/setup_preferences_repository.dart';

class SetupPreferenceStore implements SetupPreferencesRepository {
  SetupPreferenceStore._(this._sharedPreferences);

  static const _lastPlayerGroupKey = 'setup_last_player_group_id';

  final SharedPreferences _sharedPreferences;

  static Future<SetupPreferenceStore> create() async {
    final sharedPreferences = await SharedPreferences.getInstance();

    return SetupPreferenceStore._(sharedPreferences);
  }

  @override
  Future<String?> loadLastPlayerGroupId() async {
    return _sharedPreferences.getString(_lastPlayerGroupKey);
  }

  @override
  Future<void> saveLastPlayerGroupId(String? groupId) async {
    if (groupId == null) {
      await _sharedPreferences.remove(_lastPlayerGroupKey);
    } else {
      await _sharedPreferences.setString(_lastPlayerGroupKey, groupId);
    }
  }
}
