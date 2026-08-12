import 'package:flutter/material.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.description,
    this.callout,
    super.key,
  });

  final String title;
  final String description;
  final String? callout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScreenScaffold(
      title: title,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 48,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (callout != null) ...[
              const SizedBox(height: 16),
              Text(
                callout!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}