import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/core/templates/order_templates.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';

/// The templates offered in Score a Game, in the order they are listed.
class LoadScoreGameChoices {
  const LoadScoreGameChoices({
    required this.templateCatalog,
    required this.sessionRepository,
  });

  final TemplateCatalog templateCatalog;
  final SessionRepository sessionRepository;

  Future<ScoreGameChoices> call() async {
    return orderTemplatesForPicker(
      templateCatalog.templates,
      await sessionRepository.loadLastPlayedAtByTemplateId(),
    );
  }

  /// Names [templateId] was played under before, most recent first.
  Future<List<String>> recentGameNames(String templateId) {
    return sessionRepository.loadRecentGameNames(templateId: templateId);
  }
}
