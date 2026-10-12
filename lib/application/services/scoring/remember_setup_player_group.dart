import 'package:scoard_game/application/repositories/setup_preferences_repository.dart';

class RememberSetupPlayerGroup {
  const RememberSetupPlayerGroup({required this.setupPreferences});

  final SetupPreferencesRepository setupPreferences;

  /// Null means the All filter.
  Future<void> call({required String? groupId}) {
    return setupPreferences.saveLastPlayerGroupId(groupId);
  }
}
