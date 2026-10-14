import 'package:flutter/foundation.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/template_origin.dart';
import 'package:scoard_game/application/models/templates/online_template_status.dart';
import 'package:scoard_game/application/repositories/online_template_repository.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/core/templates/template_sources.dart';

/// This repository's templates, served by GitHub.
const defaultTemplateUrl =
    'https://raw.githubusercontent.com/evets17/scoard_game/main/assets/templates/';

/// Loads templates from the template URL and keeps the catalog up to date.
///
/// See `_specs/restart_slice_11_online_templates_plan.md`. Bundled templates
/// are always the fallback; online files are validated like bundled ones,
/// and a file that fails keeps its last good copy.
class OnlineTemplates extends ChangeNotifier {
  OnlineTemplates({
    required TemplateCatalog catalog,
    required TemplateDownloader downloader,
    required OnlineTemplateCache cache,
    required TemplateSourcePreferences preferences,
    required bool enabledByDefault,
    DateTime Function()? now,
  })  : _catalog = catalog,
        _bundled = catalog.templates,
        _downloader = downloader,
        _cache = cache,
        _preferences = preferences,
        _enabled = preferences.loadEnabled() ?? enabledByDefault,
        _url = preferences.loadUrl() ?? defaultTemplateUrl,
        _now = now ?? DateTime.now;

  final TemplateCatalog _catalog;
  final List<ScoringPreset> _bundled;
  final TemplateDownloader _downloader;
  final OnlineTemplateCache _cache;
  final TemplateSourcePreferences _preferences;
  final DateTime Function() _now;

  bool _enabled;
  String _url;
  OnlineTemplateStatus? _status;
  Future<void>? _running;

  bool get enabled => _enabled;
  String get url => _url;
  bool get isDefaultUrl => _url == defaultTemplateUrl;
  bool get isChecking => _running != null;

  /// The last check's result, or null if the current URL was never checked.
  OnlineTemplateStatus? get status => _status;

  /// Applies the saved copies at startup. Reads only local files.
  Future<void> loadSaved() async {
    _status = await _cache.loadStatus();
    final status = _status;
    if (status != null && status.sourceUrl != _url) {
      await _cache.clear();
      _status = null;
    }
    if (_enabled) {
      _apply(await _cache.loadFiles());
    }
    notifyListeners();
  }

  /// The one check made each time the app starts.
  Future<void> checkOnStart() async {
    if (_enabled) {
      await checkNow();
    }
  }

  /// Downloads the templates now. Waits for a check already running, then
  /// checks again, so a changed URL is always checked.
  Future<void> checkNow() async {
    while (_running != null) {
      await _running;
    }
    final running = _check();
    _running = running;
    notifyListeners();
    try {
      await running;
    } finally {
      _running = null;
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled == _enabled) {
      return;
    }
    _enabled = enabled;
    await _preferences.saveEnabled(enabled);
    if (enabled) {
      _apply(await _cache.loadFiles());
      notifyListeners();
      await checkNow();
    } else {
      _catalog.replaceTemplates(_bundled);
      notifyListeners();
    }
  }

  /// Returns why [rawUrl] can't be used, or null once it is saved.
  Future<String?> setUrl(String rawUrl) async {
    final url = normalizeTemplateUrl(rawUrl);
    if (url == null) {
      return 'Enter an https:// address.';
    }
    if (url == _url) {
      return null;
    }

    _url = url;
    await _preferences.saveUrl(url == defaultTemplateUrl ? null : url);
    // Never mix templates from two sources.
    await _cache.clear();
    _status = null;
    if (_enabled) {
      _catalog.replaceTemplates(_bundled);
    }
    notifyListeners();
    if (_enabled) {
      await checkNow();
    }
    return null;
  }

  Future<void> resetUrl() async {
    await setUrl(defaultTemplateUrl);
  }

  Future<void> _check() async {
    final url = _url;
    final previousFiles = await _cache.loadFiles();
    final previousStatus = _status;

    try {
      final download = await _downloader.download(Uri.parse(url));
      final problems = <String, List<String>>{
        for (final failure in download.failures.entries)
          failure.key: ["Couldn't download: ${failure.value}"],
      };
      final checked = loadTemplateCatalog(
        download.files,
        origin: TemplateOrigin.online,
      );
      for (final entry in checked.problemsByFile.entries) {
        problems[entry.key] = [
          for (final problem in entry.value) problem.toString(),
        ];
      }

      // Good new files, or the last good copy of a file that failed. Files
      // no longer listed are dropped.
      final kept = <String, String>{
        for (final file in download.listedFiles)
          if (download.files.containsKey(file) && !problems.containsKey(file))
            file: download.files[file]!
          else if (previousFiles.containsKey(file))
            file: previousFiles[file]!,
      };

      if (url != _url) {
        return;
      }
      final changed = !mapEquals(kept, previousFiles);
      if (changed) {
        await _cache.replaceFiles(kept);
      }
      _status = OnlineTemplateStatus(
        sourceUrl: url,
        lastChecked: _now(),
        lastUpdated: changed ? _now() : previousStatus?.lastUpdated,
        templateCount: kept.length,
        problems: problems,
      );
      await _cache.saveStatus(_status!);
      if (changed && _enabled) {
        _apply(kept);
      }
    } on TemplateDownloadException catch (error) {
      if (url != _url) {
        return;
      }
      _status = OnlineTemplateStatus(
        sourceUrl: url,
        lastChecked: _now(),
        lastUpdated: previousStatus?.lastUpdated,
        templateCount: previousFiles.length,
        lastError: error.message,
        problems: previousStatus?.problems ?? const {},
      );
      await _cache.saveStatus(_status!);
    }
  }

  void _apply(Map<String, String> files) {
    final online = loadTemplateCatalog(files, origin: TemplateOrigin.online);
    _catalog.replaceTemplates(
      mergeTemplateSources(
        bundled: _bundled,
        online: online.catalog.templates,
      ),
    );
  }
}

/// [rawUrl] as a template URL ending in `/`, or null if it isn't an
/// https:// address.
String? normalizeTemplateUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return null;
  }
  final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
  return Uri(
    scheme: 'https',
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: path,
  ).toString();
}
