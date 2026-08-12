import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoard_game/ui/theme/app_theme_controller.dart';

class ThemePreferenceStore {
  ThemePreferenceStore._(this._sharedPreferences);

  static const _themeKey = 'selected_theme_choice';

  final SharedPreferences _sharedPreferences;

  static Future<ThemePreferenceStore> create() async {
    final sharedPreferences = await SharedPreferences.getInstance();

    return ThemePreferenceStore._(sharedPreferences);
  }

  Future<AppThemeChoice> loadThemeChoice() async {
    final savedTheme = _sharedPreferences.getString(_themeKey);

    return AppThemeChoice.values.firstWhere(
      (choice) => choice.name == savedTheme,
      orElse: () => AppThemeChoice.scoardLight,
    );
  }

  Future<void> saveThemeChoice(AppThemeChoice choice) async {
    await _sharedPreferences.setString(_themeKey, choice.name);
  }
}