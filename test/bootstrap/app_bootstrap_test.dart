import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/infrastructure/templates/bundled_template_files.dart';
import 'package:scoard_game/ui/theme/app_theme_controller.dart';

import '../support/test_templates.dart';

void main() {
  test('bootstrap creates an environment that can load the home shell', () async {
    final environment = await AppBootstrap.initialize(
      templateCatalog: loadTestTemplateCatalog(),
    );
    final homeModel = await environment.loadHomeShellModel();

    expect(homeModel.appName, 'Scoard Game');
    expect(homeModel.tagline, 'Fast scorekeeping for game night.');
    expect(homeModel.primaryActions.length, 4);
    expect(homeModel.primaryActions.first.title, 'Resume Cascadia');
    expect(homeModel.primaryActions[1].title, 'Score a Game');
    expect(
      environment.themeController.selectedChoice,
      AppThemeChoice.scoardLight,
    );
  });

  testWidgets('bundled template assets load into the catalog', (tester) async {
    final files = await tester.runAsync(
      () => loadBundledTemplateFiles(rootBundle),
    );
    final result = loadTemplateCatalog(files!);

    expect(result.describeProblems(), isEmpty);
    expect(
      result.catalog.templates.map((template) => template.id),
      containsAll(['quick-final-score-basic', 'round-score-basic']),
    );
    expect(
      result.catalog.templates.length,
      loadTestTemplateCatalog().templates.length,
    );
  });
}
