import 'package:flutter/material.dart';
import 'package:scoard_game/application/services/templates/online_templates.dart';
import 'package:scoard_game/infrastructure/backup/app_data_backup.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
import 'package:scoard_game/ui/settings/online_templates_section.dart';
import 'package:scoard_game/ui/settings/stay_awake_controller.dart';
import 'package:scoard_game/ui/settings/your_data_section.dart';
import 'package:scoard_game/ui/theme/app_colors.dart';
import 'package:scoard_game/ui/theme/app_theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.themeController,
    required this.stayAwakeController,
    required this.onlineTemplates,
    this.dataBackup,
    this.restoreBackup,
    super.key,
  });

  final AppThemeController themeController;
  final StayAwakeController stayAwakeController;
  final OnlineTemplates onlineTemplates;

  /// Back up and restore; left out where the data is only in memory.
  final AppDataBackup? dataBackup;
  final Future<bool> Function()? restoreBackup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([themeController, stayAwakeController]),
      builder: (context, _) {
        return AppScreenScaffold(
          title: 'Settings',
          showSettingsButton: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick a color scheme for Scoard Game.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...AppThemeController.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ThemeOptionCard(
                      option: option,
                      selected: option.choice == themeController.selectedChoice,
                      onSelected: () => themeController.selectTheme(option.choice),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'While scoring',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    value: stayAwakeController.enabled,
                    onChanged: stayAwakeController.setEnabled,
                    title: const Text('Stay awake when scoring'),
                    subtitle: const Text(
                      'Keep the screen on while entering scores, even if no one touches it.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OnlineTemplatesSection(onlineTemplates: onlineTemplates),
                if (dataBackup case final dataBackup?)
                  if (restoreBackup case final restoreBackup?) ...[
                    const SizedBox(height: 24),
                    YourDataSection(
                      dataBackup: dataBackup,
                      restoreBackup: restoreBackup,
                    ),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  final AppThemeOption option;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(option.label, style: theme.textTheme.titleLarge),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color:
                        selected ? palette.primaryAction : palette.secondaryText,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(option.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Swatch(color: option.palette.primaryAction),
                  const SizedBox(width: 8),
                  _Swatch(color: option.palette.accent),
                  const SizedBox(width: 8),
                  _Swatch(color: option.palette.surfaceBackground),
                  const SizedBox(width: 8),
                  _Swatch(
                    color: option.palette.primaryText,
                    borderColor: palette.divider,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    this.borderColor,
  });

  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? Colors.transparent),
      ),
    );
  }
}