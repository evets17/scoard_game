import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/quick_score/game_card_picture.dart';
import 'package:scoard_game/ui/quick_score/score_game_screen.dart';

import '../../support/test_templates.dart';
import '../score_sheet/cascadia_sheet_test.dart' show bundledImages;

/// A plain picture [width] by [height].
MemoryImage picture(int width, int height) => MemoryImage(
      Uint8List.fromList(
        img.encodePng(img.Image(width: width, height: height)),
      ),
    );

void main() {
  testWidgets('games with art show it, at subtitle height', (tester) async {
    // Wide enough that the test font keeps subtitles on one line.
    tester.view.physicalSize = const Size(2400, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final environment = await AppBootstrap.initialize(
      templateCatalog: loadTestTemplateCatalog(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ScoreGameScreen(
          loadScoreGameChoices: environment.loadScoreGameChoices,
          templateImages: bundledImages(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder cardOf(String name) =>
        find.ancestor(of: find.text(name).first, matching: find.byType(Card));
    Finder pictureIn(String name) => find.descendant(
          of: cardOf(name),
          matching: find.byType(GameCardPicture),
        );

    expect(pictureIn('Flip 7'), findsOneWidget);
    expect(pictureIn('Skyjo'), findsOneWidget);
    expect(pictureIn('Cornhole'), findsNothing);

    // As tall as a card with a subtitle, whether the name shows or not.
    final subtitleHeight = tester.getSize(cardOf('Quick Score')).height;
    expect(tester.getSize(cardOf('Flip 7')).height, subtitleHeight);
    expect(tester.getSize(cardOf('Skyjo')).height, subtitleHeight);
    expect(
      tester.getSize(cardOf('Rack-O')).height,
      lessThan(subtitleHeight),
    );

    // Flip 7's banner names the game, so its name is hidden but still read
    // by screen readers; Skyjo's box shows its name.
    bool nameShows(String name) => tester
        .widget<Visibility>(
          find
              .ancestor(
                of: find.text(name).first,
                matching: find.byType(Visibility),
              )
              .first,
        )
        .visible;
    expect(nameShows('Flip 7'), isFalse);
    expect(nameShows('Skyjo'), isTrue);
    expect(find.bySemanticsLabel(RegExp('Flip 7')), findsWidgets);
  });

  group('the picture drifts as the card scrolls', () {
    const cardHeight = 80.0;
    const listHeight = 600.0;

    Future<ScrollController> pumpList(
      WidgetTester tester, {
      required MemoryImage image,
      bool still = false,
    }) async {
      tester.view.physicalSize = const Size(400, listHeight);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Starts with the card at the top, so it is built.
      final controller = ScrollController(initialScrollOffset: 600);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(400, listHeight),
              disableAnimations: still,
            ),
            child: Scaffold(
              body: ListView(
                controller: controller,
                children: [
                  for (var i = 0; i < 6; i++) const SizedBox(height: 100),
                  SizedBox(
                    key: const Key('card'),
                    height: cardHeight,
                    child: ClipRect(child: GameCardPicture(image: image)),
                  ),
                  for (var i = 0; i < 6; i++) const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(image, tester.element(find.byType(Image))),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    /// The picture's top edge, from the card's top.
    double pictureTop(WidgetTester tester) =>
        tester.getTopLeft(find.byType(Image)).dy -
        tester.getTopLeft(find.byKey(const Key('card'))).dy;

    double cardTop(WidgetTester tester) =>
        tester.getTopLeft(find.byKey(const Key('card'))).dy;

    testWidgets('top edge at the top, bottom edge at the bottom', (
      tester,
    ) async {
      // 400 wide by 800 tall: 800 tall at the card's width, so it travels
      // 720.
      final controller = await pumpList(tester, image: picture(100, 200));
      expect(tester.getSize(find.byType(Image)).height, 800);

      // Card at the top of the list.
      controller.jumpTo(600);
      await tester.pump();
      expect(cardTop(tester), 0);
      expect(pictureTop(tester), 0);

      // Card at the bottom.
      controller.jumpTo(600 - (listHeight - cardHeight));
      await tester.pump();
      expect(cardTop(tester), listHeight - cardHeight);
      expect(pictureTop(tester), cardHeight - 800);

      // Halfway: the picture's middle.
      controller.jumpTo(600 - (listHeight - cardHeight) / 2);
      await tester.pump();
      expect(pictureTop(tester), closeTo((cardHeight - 800) / 2, 0.01));
    });

    testWidgets('remove animations holds the middle', (tester) async {
      final controller = await pumpList(
        tester,
        image: picture(100, 200),
        still: true,
      );
      for (final offset in [600.0, 80.0]) {
        controller.jumpTo(offset);
        await tester.pump();
        expect(pictureTop(tester), closeTo((cardHeight - 800) / 2, 0.01));
      }
    });
  });
}
