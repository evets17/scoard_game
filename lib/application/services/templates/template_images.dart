import 'package:flutter/foundation.dart';

/// The pictures template lines use, by file name: those bundled with the app
/// and those downloaded with online templates. Online pictures win, since
/// they came with the online copy of the template.
class TemplateImages extends ChangeNotifier {
  TemplateImages({Set<String> bundled = const {}}) : _bundled = bundled;

  /// Where bundled pictures live in the app's assets.
  static const bundledFolder = 'assets/templates/images/';

  final Set<String> _bundled;
  Map<String, Uint8List> _online = const {};

  bool isBundled(String name) => _bundled.contains(name);

  /// A downloaded picture's bytes, or null.
  Uint8List? online(String name) => _online[name];

  void setOnline(Map<String, Uint8List> images) {
    _online = Map.unmodifiable(images);
    notifyListeners();
  }
}
