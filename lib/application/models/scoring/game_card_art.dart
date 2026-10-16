/// A picture behind a game's card on the Score a Game screen. It fills the
/// card's width and drifts as the list scrolls, by however much taller it
/// is than the card.
class GameCardArt {
  const GameCardArt({required this.image, this.showName = true});

  /// A file in the template images folder.
  final String image;

  /// Whether the game's name and subtitle show over the picture. Off when
  /// the picture already names the game, such as a logo.
  final bool showName;
}
