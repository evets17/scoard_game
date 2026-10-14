/// A short line a template shows under a player's score, such as
/// "from 4" or "Rack-o". The app shows the text; the template decides what
/// it means.
class ScoreNoteDefinition {
  const ScoreNoteDefinition({
    required this.when,
    required this.text,
    this.color,
  });

  /// Formula; the note shows when it is not 0.
  final String when;

  /// The note, where `{name}` shows that value, for example
  /// `from {round-score}`.
  final String text;

  /// `#RRGGBB`, or null for the usual quiet colour.
  final String? color;
}
