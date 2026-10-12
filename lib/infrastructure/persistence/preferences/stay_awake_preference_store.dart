import 'package:shared_preferences/shared_preferences.dart';

class StayAwakePreferenceStore {
  StayAwakePreferenceStore._(this._sharedPreferences);

  static const _stayAwakeKey = 'stay_awake_when_scoring';

  final SharedPreferences _sharedPreferences;

  static Future<StayAwakePreferenceStore> create() async {
    final sharedPreferences = await SharedPreferences.getInstance();

    return StayAwakePreferenceStore._(sharedPreferences);
  }

  bool loadStayAwake() => _sharedPreferences.getBool(_stayAwakeKey) ?? false;

  Future<void> saveStayAwake(bool enabled) async {
    await _sharedPreferences.setBool(_stayAwakeKey, enabled);
  }
}
