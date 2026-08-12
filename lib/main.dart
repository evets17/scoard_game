import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/app/scoard_game_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final environment = await AppBootstrap.initialize(
    usePersistentStorage: !kIsWeb,
  );

  runApp(ScoardGameApp(environment: environment));
}
