import 'package:scoard_game/application/repositories/online_template_repository.dart';

class MemoryTemplateSourcePreferences implements TemplateSourcePreferences {
  MemoryTemplateSourcePreferences({bool? enabled, String? url})
      : _enabled = enabled,
        _url = url;

  bool? _enabled;
  String? _url;

  @override
  bool? loadEnabled() => _enabled;

  @override
  Future<void> saveEnabled(bool enabled) async => _enabled = enabled;

  @override
  String? loadUrl() => _url;

  @override
  Future<void> saveUrl(String? url) async => _url = url;
}
