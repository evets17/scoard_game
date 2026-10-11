import 'package:flutter/material.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({
    required this.title,
    this.showBackButton = false,
    this.showSettingsButton = true,
    this.actions = const [],
    super.key,
  });

  final String title;
  final bool showBackButton;
  final bool showSettingsButton;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (showBackButton)
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          )
        else
          const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        ...actions,
        if (showSettingsButton)
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }
}