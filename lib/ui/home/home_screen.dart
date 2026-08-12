import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/home_shell_model.dart';
import 'package:scoard_game/application/services/load_home_shell_model.dart';
import 'package:scoard_game/ui/navigation/app_title_bar.dart';
import 'package:scoard_game/ui/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.loadHomeShellModel,
    super.key,
  });

  final LoadHomeShellModel loadHomeShellModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeShellModel> _homeModel;

  @override
  void initState() {
    super.initState();
    _reloadHomeModel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<HomeShellModel>(
          future: _homeModel,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Scoard Game could not open right now.',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final model = snapshot.requireData;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTitleBar(title: model.appName),
                      const SizedBox(height: 10),
                      Text(
                        model.tagline,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: palette.secondaryText,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Column(
                        children: model.primaryActions
                            .map(
                              (action) => _ActionButton(
                                action: action,
                                onTap: () => _handleActionTap(action),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleActionTap(HomeActionModel action) async {
    await Navigator.of(context).pushNamed(
      action.route,
      arguments: action.arguments,
    );

    if (mounted) {
      _reloadHomeModel();
    }
  }

  void _reloadHomeModel() {
    setState(() {
      _homeModel = widget.loadHomeShellModel();
    });
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onTap});

  final HomeActionModel action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: palette.accentSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconForAction(action.icon),
                    color: palette.primaryAction,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(action.title, style: theme.textTheme.titleLarge),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.primaryAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForAction(String icon) {
    switch (icon) {
      case 'resume':
        return Icons.play_circle_fill_rounded;
      case 'players':
        return Icons.people_alt_rounded;
      case 'new-game':
        return Icons.scoreboard_rounded;
      case 'stats':
        return Icons.query_stats_rounded;
      default:
        return Icons.extension_rounded;
    }
  }
}
