import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/bootstrap/app_restarter.dart';
import 'package:scoard_game/ui/app/scoard_game_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Future<AppEnvironment> open() =>
      AppBootstrap.initialize(usePersistentStorage: !kIsWeb);
  final environment = await open();

  runApp(
    AppRestarter(
      initialEnvironment: environment,
      openEnvironment: open,
      builder: (environment, restore, messenger) => ScoardGameApp(
        environment: environment,
        restoreBackup: restore,
        scaffoldMessengerKey: messenger,
      ),
    ),
  );

  // One check for template updates per start, once the first screen shows.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(environment.onlineTemplates.checkOnStart());
  });
}
