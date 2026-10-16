import 'package:shared_preferences/shared_preferences.dart';

/// When the app's data was last backed up.
class BackupPreferenceStore {
  BackupPreferenceStore._(this._sharedPreferences);

  static const _lastBackedUpKey = 'last_backed_up_at';

  final SharedPreferences _sharedPreferences;

  static Future<BackupPreferenceStore> create() async {
    final sharedPreferences = await SharedPreferences.getInstance();

    return BackupPreferenceStore._(sharedPreferences);
  }

  DateTime? loadLastBackedUpAt() {
    final value = _sharedPreferences.getString(_lastBackedUpKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> saveLastBackedUpAt(DateTime backedUpAt) async {
    await _sharedPreferences.setString(
      _lastBackedUpKey,
      backedUpAt.toIso8601String(),
    );
  }
}
