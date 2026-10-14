/// What happened the last time online templates were checked.
class OnlineTemplateStatus {
  const OnlineTemplateStatus({
    required this.sourceUrl,
    this.lastChecked,
    this.lastUpdated,
    this.templateCount = 0,
    this.lastError,
    this.problems = const {},
  });

  /// The template URL these saved copies came from.
  final String sourceUrl;

  /// When a check last finished, whether or not it worked.
  final DateTime? lastChecked;

  /// When the saved copies last changed.
  final DateTime? lastUpdated;

  /// How many online templates are saved.
  final int templateCount;

  /// Why the last check failed, or null if it worked.
  final String? lastError;

  /// Problems per template file from the last check. Those files kept their
  /// last good copy, if there was one.
  final Map<String, List<String>> problems;

  Map<String, Object?> toJson() => {
        'sourceUrl': sourceUrl,
        'lastChecked': lastChecked?.toIso8601String(),
        'lastUpdated': lastUpdated?.toIso8601String(),
        'templateCount': templateCount,
        'lastError': lastError,
        'problems': problems,
      };

  factory OnlineTemplateStatus.fromJson(Map<String, Object?> json) {
    DateTime? date(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;

    return OnlineTemplateStatus(
      sourceUrl: json['sourceUrl']! as String,
      lastChecked: date(json['lastChecked']),
      lastUpdated: date(json['lastUpdated']),
      templateCount: (json['templateCount'] as int?) ?? 0,
      lastError: json['lastError'] as String?,
      problems: {
        for (final entry
            in ((json['problems'] as Map<String, Object?>?) ?? const {})
                .entries)
          entry.key: [
            for (final problem in entry.value! as List<Object?>)
              problem! as String,
          ],
      },
    );
  }
}
