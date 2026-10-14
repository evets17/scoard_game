import 'package:flutter/services.dart';
import 'package:scoard_game/core/templates/template_index.dart';

const bundledTemplateDirectory = 'assets/templates/';

/// Reads every template file bundled under `assets/templates/`, keyed by
/// asset path. The index is not a template, so it is left out.
Future<Map<String, String>> loadBundledTemplateFiles(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  final paths = manifest
      .listAssets()
      .where(
        (path) =>
            path.startsWith(bundledTemplateDirectory) &&
            isTemplateFilePath(path),
      )
      .toList()
    ..sort();

  return {
    for (final path in paths) path: await bundle.loadString(path),
  };
}
