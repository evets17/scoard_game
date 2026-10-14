import 'package:scoard_game/application/repositories/online_template_repository.dart';
import 'package:scoard_game/application/services/templates/online_templates.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/infrastructure/memory/memory_online_template_cache.dart';
import 'package:scoard_game/infrastructure/memory/memory_template_source_preferences.dart';

/// Serves template files from memory instead of the network.
class FakeTemplateDownloader implements TemplateDownloader {
  FakeTemplateDownloader({Map<String, String>? files}) : files = files ?? {};

  /// Template files by name. Every file is listed in the index.
  Map<String, String> files;

  /// Listed files that fail to download, with the reason.
  Map<String, String> failures = {};

  /// When set, the index can't be read and this is the error.
  String? indexError;

  final List<Uri> requests = [];

  @override
  Future<TemplateDownload> download(Uri baseUrl) async {
    requests.add(baseUrl);
    final error = indexError;
    if (error != null) {
      throw TemplateDownloadException(error);
    }
    return TemplateDownload(
      listedFiles: [...files.keys, ...failures.keys],
      files: Map.of(files),
      failures: Map.of(failures),
    );
  }
}

/// Online templates for tests: switched off unless [enabled], with nothing
/// saved and no network.
OnlineTemplates testOnlineTemplates({
  TemplateCatalog? catalog,
  TemplateDownloader? downloader,
  bool enabled = false,
}) {
  return OnlineTemplates(
    catalog: catalog ?? TemplateCatalog(const []),
    downloader: downloader ?? FakeTemplateDownloader(),
    cache: MemoryOnlineTemplateCache(),
    preferences: MemoryTemplateSourcePreferences(enabled: enabled),
    enabledByDefault: false,
  );
}
