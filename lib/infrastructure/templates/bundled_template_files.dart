import 'package:flutter/services.dart';

const bundledTemplateDirectory = 'assets/templates/';

/// Reads every template file bundled under `assets/templates/`, keyed by
/// asset path.
Future<Map<String, String>> loadBundledTemplateFiles(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  final paths = manifest
      .listAssets()
      .where(
        (path) =>
            path.startsWith(bundledTemplateDirectory) && path.endsWith('.json'),
      )
      .toList()
    ..sort();

  return {
    for (final path in paths) path: await bundle.loadString(path),
  };
}
