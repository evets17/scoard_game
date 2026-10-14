import 'package:scoard_game/application/repositories/online_template_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemplateSourcePreferenceStore implements TemplateSourcePreferences {
  TemplateSourcePreferenceStore._(this._sharedPreferences);

  static const _enabledKey = 'online_templates_enabled';
  static const _urlKey = 'online_templates_url';

  final SharedPreferences _sharedPreferences;

  static Future<TemplateSourcePreferenceStore> create() async {
    final sharedPreferences = await SharedPreferences.getInstance();

    return TemplateSourcePreferenceStore._(sharedPreferences);
  }

  @override
  bool? loadEnabled() => _sharedPreferences.getBool(_enabledKey);

  @override
  Future<void> saveEnabled(bool enabled) async {
    await _sharedPreferences.setBool(_enabledKey, enabled);
  }

  @override
  String? loadUrl() => _sharedPreferences.getString(_urlKey);

  @override
  Future<void> saveUrl(String? url) async {
    if (url == null) {
      await _sharedPreferences.remove(_urlKey);
    } else {
      await _sharedPreferences.setString(_urlKey, url);
    }
  }
}
