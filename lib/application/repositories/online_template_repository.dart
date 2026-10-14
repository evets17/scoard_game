import 'package:scoard_game/application/models/templates/online_template_status.dart';

/// Downloads the template files listed at a template URL.
abstract class TemplateDownloader {
  /// Throws [TemplateDownloadException] if the index can't be read, in
  /// which case nothing should change.
  Future<TemplateDownload> download(Uri baseUrl);
}

class TemplateDownload {
  const TemplateDownload({
    required this.listedFiles,
    required this.files,
    required this.failures,
  });

  /// Every file the index lists, for example `skyjo.json`.
  final List<String> listedFiles;

  /// The contents of each listed file that downloaded.
  final Map<String, String> files;

  /// Why each other listed file did not download.
  final Map<String, String> failures;
}

class TemplateDownloadException implements Exception {
  const TemplateDownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The last good copies of the online templates, kept on the device so the
/// app works offline.
abstract class OnlineTemplateCache {
  /// Saved template files by file name.
  Future<Map<String, String>> loadFiles();

  /// Replaces every saved file at once.
  Future<void> replaceFiles(Map<String, String> files);

  Future<OnlineTemplateStatus?> loadStatus();

  Future<void> saveStatus(OnlineTemplateStatus status);

  /// Removes the saved files and status.
  Future<void> clear();
}

/// The online template settings.
abstract class TemplateSourcePreferences {
  /// Null when never set.
  bool? loadEnabled();

  Future<void> saveEnabled(bool enabled);

  /// Null when never set.
  String? loadUrl();

  /// Null goes back to the default.
  Future<void> saveUrl(String? url);
}
