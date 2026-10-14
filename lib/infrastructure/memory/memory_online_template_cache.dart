import 'package:scoard_game/application/models/templates/online_template_status.dart';
import 'package:scoard_game/application/repositories/online_template_repository.dart';

class MemoryOnlineTemplateCache implements OnlineTemplateCache {
  Map<String, String> _files = const {};
  OnlineTemplateStatus? _status;

  @override
  Future<Map<String, String>> loadFiles() async => _files;

  @override
  Future<void> replaceFiles(Map<String, String> files) async {
    _files = Map.unmodifiable(files);
  }

  @override
  Future<OnlineTemplateStatus?> loadStatus() async => _status;

  @override
  Future<void> saveStatus(OnlineTemplateStatus status) async {
    _status = status;
  }

  @override
  Future<void> clear() async {
    _files = const {};
    _status = null;
  }
}
