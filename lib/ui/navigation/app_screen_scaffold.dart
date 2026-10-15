import 'package:flutter/material.dart';
import 'package:scoard_game/ui/navigation/app_title_bar.dart';

class AppScreenScaffold extends StatelessWidget {
  static const double _gapUnderTitle = 24;

  const AppScreenScaffold({
    required this.title,
    required this.child,
    this.subtitle,
    this.showBackButton = true,
    this.showSettingsButton = true,
    this.actions = const [],
    this.maxBodyWidth = 560,
    super.key,
  });

  final String title;

  /// Small text under the title, such as the game being scored. It sits in
  /// the space above the content, so it never moves the content down.
  final String? subtitle;
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
                  SizedBox(
                    height: _gapUnderTitle,
                    child: subtitle == null
                        ? null
                        : _Subtitle(subtitle!, indent: showBackButton ? 48 : 12),
                  ),
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
class _Subtitle extends StatelessWidget {
  const _Subtitle(this.text, {required this.indent});

  final String text;

  /// Lines the text up with the title, past the back button.
  final double indent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Drawn a little up into the title bar's spare space under the title,
    // so it reads as part of the title.
    return Transform.translate(
      offset: const Offset(0, -6),
      child: Padding(
        padding: EdgeInsets.only(left: indent),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
