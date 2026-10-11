import 'package:flutter/material.dart';
import 'package:scoard_game/ui/navigation/app_title_bar.dart';

class AppScreenScaffold extends StatelessWidget {
  const AppScreenScaffold({
    required this.title,
    required this.child,
    this.showBackButton = true,
    this.showSettingsButton = true,
    this.actions = const [],
    this.maxBodyWidth = 560,
    super.key,
  });

  final String title;
  final Widget child;
  final bool showBackButton;
  final bool showSettingsButton;
  final List<Widget> actions;
  final double maxBodyWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBodyWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTitleBar(
                    title: title,
                    showBackButton: showBackButton,
                    showSettingsButton: showSettingsButton,
                    actions: actions,
                  ),
                  const SizedBox(height: 24),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}