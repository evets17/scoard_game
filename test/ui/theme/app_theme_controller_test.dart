import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/ui/theme/app_theme_controller.dart';

void main() {
  test('theme controller switches to alternate theme', () {
    final controller = AppThemeController();

    controller.selectTheme(AppThemeChoice.scoreboardNight);

    expect(controller.selectedChoice, AppThemeChoice.scoreboardNight);
    expect(controller.selectedOption.label, 'Scoreboard Night');
  });
}