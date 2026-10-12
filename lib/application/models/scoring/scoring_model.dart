/// How a template's scores are entered, which decides the scoring screen.
enum ScoringModel {
  /// One score per player, entered when the game is over.
  finalScore,

  /// One score per player per round, adding up across rounds.
  rounds,
}
