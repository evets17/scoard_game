String createQuickScoreSessionId({DateTime? timestamp}) {
  final resolvedTimestamp = timestamp ?? DateTime.now();
  return 'quick-score-${resolvedTimestamp.microsecondsSinceEpoch}';
}