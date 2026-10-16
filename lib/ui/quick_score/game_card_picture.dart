import 'package:flutter/material.dart';

/// A picture filling a card's width that drifts as the list scrolls, as if
/// the card were a window onto a larger picture underneath.
///
/// Its top edge shows when the card is at the top of the list, its bottom
/// edge when the card is at the bottom, so how far it drifts is however
/// much taller it is than the card. A picture the card's shape or wider
/// stays still. With the phone's remove animations setting on, it holds its
/// middle.
class GameCardPicture extends StatelessWidget {
  const GameCardPicture({required this.image, super.key});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Decoded at the card's width, not the picture's, to keep memory
        // low on a long list.
        final picture = Image(
          image: ResizeImage.resizeIfNeeded(
            (constraints.maxWidth * pixelRatio).round(),
            null,
            image,
          ),
          fit: BoxFit.fitWidth,
          gaplessPlayback: true,
        );
        return Flow(
          delegate: _DriftDelegate(
            scrollable: still ? null : scrollable,
            card: context,
          ),
          children: [picture],
        );
      },
    );
  }
}

class _DriftDelegate extends FlowDelegate {
  _DriftDelegate({required this.scrollable, required this.card})
      : super(repaint: scrollable?.position);

  /// The list the card scrolls in, or null to hold the picture's middle.
  final ScrollableState? scrollable;
  final BuildContext card;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    // As wide as the card, as tall as the picture's shape makes it.
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final pictureHeight = context.getChildSize(0)?.height ?? 0;
    final cardHeight = context.size.height;
    if (pictureHeight <= 0) {
      return;
    }

    // A picture wider in shape than the card fills its height instead,
    // centred, and stays still.
    if (pictureHeight < cardHeight) {
      final scale = cardHeight / pictureHeight;
      final width = context.size.width;
      context.paintChild(
        0,
        transform: Matrix4.translationValues(-(width * scale - width) / 2, 0, 0)
          ..scaleByDouble(scale, scale, 1, 1),
      );
      return;
    }

    final travel = pictureHeight - cardHeight;

    var place = 0.5;
    final viewport = scrollable?.context.findRenderObject();
    final cardBox = card.findRenderObject();
    if (viewport is RenderBox &&
        cardBox is RenderBox &&
        cardBox.attached &&
        viewport.size.height > cardHeight) {
      final top = cardBox.localToGlobal(Offset.zero, ancestor: viewport).dy;
      place = (top / (viewport.size.height - cardHeight)).clamp(0.0, 1.0);
    }

    context.paintChild(
      0,
      transform: Matrix4.translationValues(0, -travel * place, 0),
    );
  }

  @override
  bool shouldRepaint(_DriftDelegate oldDelegate) =>
      oldDelegate.scrollable != scrollable || oldDelegate.card != card;
}
