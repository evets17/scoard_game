/// A score note's text can show values, written like formula names:
/// `from {round-score}`.
final _placeholder = RegExp(r'\{([^{}]*)\}');

/// The names a note's text shows, in order.
List<String> scoreNoteTextNames(String text) => [
      for (final match in _placeholder.allMatches(text)) match.group(1)!,
    ];

/// [text] with each `{name}` replaced by [valueOf] that name.
String fillScoreNoteText(String text, int Function(String name) valueOf) {
  return text.replaceAllMapped(
    _placeholder,
    (match) => '${valueOf(match.group(1)!)}',
  );
}
