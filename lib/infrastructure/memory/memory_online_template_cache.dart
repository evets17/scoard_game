import 'dart:typed_data';

import 'package:scoard_game/application/models/templates/online_template_status.dart';
import 'package:scoard_game/application/repositories/online_template_repository.dart';

class MemoryOnlineTemplateCache implements OnlineTemplateCache {
  Map<String, String> _files = const {};
  Map<String, Uint8List> _images = const {};
  OnlineTemplateStatus? _status;

  @override
  Future<Map<String, String>> loadFiles() async => _files;

  @override
  Future<Map<String, Uint8List>> loadImages() async => _images;

  @override
  Future<void> replaceFiles(
    Map<String, String> files, {
    Map<String, Uint8List> images = const {},
  }) async {
    _files = Map.unmodifiable(files);
    _images = Map.unmodifiable(images);
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
    _images = const {};
    _status = null;
  }
}
