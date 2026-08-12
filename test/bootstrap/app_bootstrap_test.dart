import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/theme/app_theme_controller.dart';

void main() {
  test('bootstrap creates an environment that can load the home shell', () async {
    final environment = await AppBootstrap.initialize();
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
}