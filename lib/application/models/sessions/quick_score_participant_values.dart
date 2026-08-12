class QuickScoreParticipantValues {
  const QuickScoreParticipantValues({
    required this.playerId,
    required this.displayName,
    required this.enteredValues,
  });

  final String playerId;
  final String displayName;
  final Map<String, int> enteredValues;
}