class QuickScoreParticipantValues {
  const QuickScoreParticipantValues({
    required this.playerId,
    required this.displayName,
    required this.enteredValues,
  });

  final String playerId;
  final String displayName;
  final Map<String, int> enteredValues;

  QuickScoreParticipantValues withCurrentPlayerName(
    Map<String, String> playerNames,
  ) {
    return QuickScoreParticipantValues(
      playerId: playerId,
      displayName: playerNames[playerId] ?? displayName,
      enteredValues: enteredValues,
    );
  }
}
