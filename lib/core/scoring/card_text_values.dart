/// Card text can show values, written like formula names:
/// `from {round-score}`.
final _placeholder = RegExp(r'\{([^{}]*)\}');

/// The names a card text shows, in order.
List<String> cardTextNames(String text) => [
      for (final match in _placeholder.allMatches(text)) match.group(1)!,
    ];

/// [text] with each `{name}` replaced by [valueOf] that name.
String fillCardText(String text, int Function(String name) valueOf) {
  return text.replaceAllMapped(
    _placeholder,
    (match) => '${valueOf(match.group(1)!)}',
  );
}
