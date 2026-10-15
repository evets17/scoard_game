/// How a template asks for a sheet row to look.
class SheetRowStyle {
  const SheetRowStyle({
    this.shade,
    this.bold = false,
    this.ruleAbove = false,
  });

  static const plain = SheetRowStyle();

  /// `#RRGGBB` to tint the row with. The app sets how strong the tint is,
  /// so text stays readable in every theme.
  final String? shade;

  /// Bold label and values.
  final bool bold;

  /// A heavier line above the row, such as before a subtotal.
  final bool ruleAbove;
}

/// One row of the score sheet as the template lays it out: a section
/// heading, or a line.
class SheetLayoutItem {
  const SheetLayoutItem.heading(
    String this.heading, {
    this.style = SheetRowStyle.plain,
  }) : lineId = null;

  const SheetLayoutItem.line(
    String this.lineId, {
    this.style = SheetRowStyle.plain,
  }) : heading = null;

  /// The section's name, such as "Wildlife", for a heading.
  final String? heading;

  /// The line's id, for a line.
  final String? lineId;

  /// How the template asks for the row to look.
  final SheetRowStyle style;

  bool get isHeading => heading != null;
}

/// Which cell the entry sheet's Next opens.
enum SheetEntryOrder {
  /// The next player, same line: how a round is scored.
  byPlayer,

  /// The same player's next entered line: how a paper sheet is filled, one
  /// player's column at a time.
  byLine,
}
