# Restart Slice 14 Plan: Game Card Art

## 1. Purpose

This document defines how a template gives its game card on the Score a Game screen a picture, such as the game's logo or box, so the list is easier to scan and each game is recognisable at a glance.

The card is a window onto the picture. As the list scrolls, the picture drifts behind the card, as if a larger picture lay underneath. How far it drifts comes from the picture's shape alone: a picture about the card's shape barely moves, a tall one travels a long way. There is one behaviour, and the template chooses the effect by choosing the picture.

This plan should be read alongside:

* `restart_slice_11_online_templates_plan.md` (downloading templates and their pictures)
* `restart_slice_12_score_sheets_plan.md` (line pictures, which this reuses)
* `template_schema.md`

---

## 2. Slice Goal

Implement game card art so that:

* a template can name a card picture, and say whether the game's name shows over it
* the picture fills the card and drifts as the list scrolls, by an amount set by its shape
* a card with a picture is as tall as a card with a subtitle; cards without one are unchanged
* card pictures are bundled and downloaded exactly like line pictures
* the phone's "remove animations" setting holds pictures still

This slice is successful when Flip 7 and Skyjo show their art on the Score a Game screen, the art drifts while scrolling, and the same template served online shows the same art on a phone with no bundled copy of the picture.

---

## 3. What Was Checked Before Planning

| Question | Finding | Consequence |
|---|---|---|
| Where do template pictures live? | `assets/templates/images/`, bundled with the app and served online from the same folder. Names are checked against `templateImagePattern` (lowercase, `png`, `jpg`, `jpeg`, `webp`). | Card pictures go in the same folder under the same rules. |
| How are pictures downloaded? | `OnlineTemplates` downloads the pictures that kept templates name (`ScoringPreset.lineImages`), at most 1 MB each, checked to really be a PNG, JPEG, or WebP. | Renaming `lineImages` to `images` and adding the card picture to it is all the download needs. |
| Is a missing picture caught? | `template_images_exist_test.dart` fails when a template names a picture not in the folder. | It covers card pictures once they are in `images`. |
| What does a game card look like now? | `_PresetOptionCard` in `score_game_screen.dart`: an icon, the name, the subtitle if there is one, and an arrow. About 87 high with a subtitle and 64 without. | A card with a picture lays out a name and subtitle (shown or not), so it is always subtitle height. |
| How big are the sample pictures? | The Flip 7 box is 3000×3814 and 7.5 MB; the Flip 7 banner is 1920×640 and 1.6 MB. At 1080 wide as JPEG they are 284 KB and 100 KB. | Pictures are shrunk to 1080 wide before they are added (5.5). |
| Was the drift tried? | Yes, rendered with the real card and theme. The box travelled from its logo band to its top as the card moved up the screen; the banner drifted slightly; a 2:1 logo travelled far enough to cut its lettering. | One behaviour, and guidance on picture shapes (5.4). The Skyjo logo is not used as it is. |

---

## 4. Core Direction For This Slice

### 4.1 The Picture Decides The Effect

There are no modes. Every card picture fills the card's width and drifts by however much taller it is than the card. A template wanting a still picture uses one about the card's shape or wider.

### 4.2 Art Never Hides What The Card Is

A card with a picture still says what game it is: either the picture shows it (a logo) and the name is hidden, or the name shows over a fade. The name is always there for screen readers.

### 4.3 Pictures Arrive Like Every Other Template Picture

Card pictures use the folder, name rules, download, size limit, and checks that line pictures already have. A picture that is missing or fails to download leaves a plain card.

---

## 5. In Scope

### 5.1 Template Key

A new optional top-level key:

```json
"card": { "image": "flip7_banner.jpg", "showName": false }
```

| Key | Required | Type | Rules |
|---|---|---|---|
| `image` | yes | string | A file in the template `images/` folder, named by the same rules as line pictures. |
| `showName` | no | boolean | Default `true`. Shows the name and subtitle over the picture. Turn it off when the picture already names the game. |

### 5.2 The Card

* The picture fills the card's width and is clipped to the card's rounded shape.
* Its position follows the card's place on the screen: its top edge shows when the card is at the top of the list area, its bottom edge when the card is at the bottom, and its middle when the card is halfway.
* With `showName`, the name and subtitle are white with a soft shadow, over a dark fade from the left edge. Without it, they are laid out but invisible, so the card keeps its height and screen readers still read the name.
* The arrow stays, white with a shadow, so the card still reads as a button.
* The leading scoreboard icon is left out on cards with a picture.
* While the picture loads, or if there is none, the card is the plain card.

### 5.3 Remove Animations

When the phone asks for fewer animations (`MediaQuery.disableAnimations`), pictures hold their middle and do not drift.

### 5.4 Picture Shape Guidance

Documented in `template_schema.md`. On phones a card is about 87 high and 320 to 370 wide, roughly 4:1; on tablets up to about 6:1.

| Picture shape | Effect |
|---|---|
| About 6:1 or wider | Still. On phones the sides are trimmed a little. |
| About 3:1 | A gentle drift. |
| About 2:1 | A noticeable drift. |
| Portrait, like a box | A long travel, revealing a large picture as the list scrolls. |

Keep what must always show, such as a logo, in a band across the middle of the picture. Save pictures 1080 wide, as JPEG for photos and box art, which keeps them around 100 to 300 KB, well inside the 1 MB limit.

### 5.5 Shrinking Pictures

A small script, `tool/prepare_template_image.dart`, shrinks a picture to 1080 wide and saves it as JPEG into `assets/templates/images/`:

```text
dart run tool/prepare_template_image.dart _specs/staged_images/flip7-logo.png flip7_banner.jpg
```

It uses the `image` package as a dev dependency, so it runs the same on any computer and nothing is added to the app. It never enlarges a picture narrower than 1080.

### 5.6 First Art

* Flip 7: its banner (`flip7-logo.png`, 3:1), with the name hidden. A gentle drift.
* Skyjo: its box (`skyjo-full.png`, portrait), with the name over a fade. A long travel. The staged picture is only 372 wide, so it looks soft on a phone until a larger one replaces it.
* The Skyjo logo is not used: at 2:1 it drifts far enough to cut its lettering.

---

## 6. Out Of Scope

* Pictures anywhere but the Score a Game list (the game page, the scoring screens, history).
* Choosing which part of a picture shows, other than by cropping the picture.
* A setting to hold one game's picture still. A still picture is a picture of the right shape.
* Pictures for the general Quick Score and Round Score cards.

---

## 7. Product And UX Rules For This Slice

### 7.1 The List Stays Easy To Read

Art adds recognition, not noise: the name shows over a fade or not at all, never over a busy picture unprotected.

### 7.2 Motion Is Gentle And Optional

The drift follows scrolling only; nothing moves on its own. Remove animations stops it.

### 7.3 A Template Never Breaks The List

A bad or missing picture leaves a plain card. The validator rejects bad names and keys before a template is used.

---

## 8. Technical Decisions For This Slice

### 8.1 Drift With A Flow

The picture is drawn by a `Flow` whose delegate repaints on the list's scroll position and moves the picture by the card's place in the viewport. Only painting changes while scrolling; nothing is laid out again.

### 8.2 One List Of Template Pictures

`ScoringPreset.lineImages` becomes `images`: every picture a template names, from lines and its card. Download, the missing-picture test, and the image check use it unchanged.

### 8.3 Pictures Decoded At Card Size

Card pictures are decoded at the card's width in device pixels, not their full size, to keep memory low on a long list.

### 8.4 The Score A Game Screen Gets Template Pictures

`ScoreGameScreen` is given `TemplateImages`, as the scoring screens already are, and uses `templateImageProvider` to find each card's picture, bundled or downloaded.

---

## 9. Recommended Project Shape For Slice 14

```text
lib/
  application/models/scoring/
    game_card_art.dart             // image, showName
    scoring_preset.dart            // card, images (renamed from lineImages)
  core/templates/
    template_parser.dart           // card
    template_validator.dart        // card keys, image name
  ui/quick_score/
    score_game_screen.dart         // art on cards, TemplateImages
    game_card_picture.dart         // the drifting picture
tool/
  prepare_template_image.dart      // shrink to 1080 wide, save JPEG
assets/templates/
  flip-7.json, skyjo.json         // card
  images/flip7_banner.jpg, skyjo_box.jpg
test/
  core/templates/                  // card keys valid and invalid
  ui/quick_score/
    game_card_art_test.dart        // height, hidden name still read, drift, remove animations
```

---

## 10. Concrete Deliverables

* The `card` template key, parsed and validated
* `images` replacing `lineImages`, covering card pictures
* Drifting card pictures on Score a Game, at subtitle height, with remove animations respected
* The name over a fade, or hidden but still read by screen readers
* The picture-shrinking script
* Flip 7 and Skyjo card art
* Template docs: the key, the shape guidance, and the script
* Tests for each item above

---

## 11. Suggested Build Sequence Inside The Slice

1. The `card` key in the model, parser, and validator, with tests.
2. Rename `lineImages` to `images` and add the card picture.
3. The drifting picture and the art card, with widget tests.
4. Pass `TemplateImages` to Score a Game.
5. The shrinking script, then Flip 7's and Skyjo's art.
6. Render the list with the real card and theme, and check it on a phone.
7. Docs.

---

## 12. Validation Rules

### 12.1 Runtime Validation

* Flip 7 and Skyjo show their art; other cards are unchanged.
* Scrolling the list moves the art by the amount its shape gives.
* With remove animations on, the art holds still.
* A template served online shows its card art on a phone without the bundled picture.
* A template naming a missing picture shows a plain card.

### 12.2 Architecture Validation

* Card pictures go through the same name rules, download, and checks as line pictures.
* The drift is painting only; scrolling does not rebuild cards.

### 12.3 Agent Workflow Validation

* Card pictures are added with the script, not at full size.
* The missing-picture test covers card pictures.

---

## 13. Exit Decision After Slice 14

The slice is done when 12.1 passes on a phone and every test passes.

Follow-ups to weigh afterwards:

* art for more games, as good pictures are found
* art on the game page
