# Scoring Template Schema, Version 1

This is the reference for writing a Scoard Game scoring template. A template describes how one game is scored. The app reads it, validates it, and scores the game with it, with no code changes.

Version 1 covers games that need **one score per player**, entered either once at the end (`finalScore`) or once per round (`rounds`), where the entered number is the score. When the score has to be calculated (for example from the other players' results), use [version 2](template_schema_v2.md). Games that need several scoring categories per player are not supported yet.

---

## Files

Each template needs two files. Both use the template's `id` as the file name.

| File | Purpose |
|---|---|
| `assets/templates/<id>.json` | The template. Bundled into the app. |
| `test/templates/scenarios/<id>.json` | Scoring scenarios that prove the template scores the game correctly. Test data only. |

After adding or changing either file, run:

```bash
flutter test test/templates
```

That validates every bundled template and runs every scenario. A template is done when this passes.

---

## Template File

### Example

```json
{
  "schemaVersion": 1,
  "id": "skyjo",
  "version": "1.0.0",
  "name": "Skyjo",
  "description": "Rounds of card scoring. Lowest total wins once someone reaches 100.",
  "source": "Skyjo rulebook, scoring section",
  "players": { "minimum": 2, "maximum": 8 },
  "scoringModel": "rounds",
  "winner": "lowestScore",
  "scoreField": {
    "id": "round-score",
    "label": "Round Score",
    "initialValue": 0,
    "minimumDisplayDigits": 2,
    "entry": { "tapToEdit": true, "quickAdjust": true, "replace": true, "adjust": true }
  }
}
```

### Top-Level Keys

| Key | Required | Type | Rules |
|---|---|---|---|
| `schemaVersion` | yes | integer | Must be `1`. |
| `id` | yes | string | Lowercase letters, digits, and single hyphens (`skyjo`, `love-letter`). Unique across all templates. Must match the file name. Never change it once games have been saved with it. |
| `version` | yes | string | `major.minor.patch`, for example `1.0.0`. |
| `name` | yes | string | Non-empty. Shown in Score a Game, on the game page, and in game history. |
| `subtitle` | no | string | Non-empty. One short line under the name in Score a Game, for example `"Alternate rules"` to tell two templates for the same game apart. |
| `general` | no | boolean | Default `false`. `true` marks a general scoring style rather than a specific game (Quick Score, Round Score). General templates are listed first in Score a Game; games follow, most recently played first. |
| `description` | yes | string | Non-empty. Shown on the game page, which opens after the game is picked. |
| `source` | no | string | Where the scoring rules came from, for example `"Skyjo rulebook, scoring section"` or a URL. Shown on the game page; a URL becomes a link. |
| `players` | yes | object | See below. |
| `scoringModel` | yes | string | `finalScore` or `rounds`. See below. |
| `winner` | yes | string | `highestScore` or `lowestScore`. |
| `prompts` | no | array | Questions asked when a game starts. See below. |
| `scoreField` | yes | object | The score entered for each player. See below. |
| `scoreLabels` | no | array | Text shown instead of the score. See Player Card. |
| `scoreSubLabels` | no | array | Text shown under the score. See Player Card. |
| `playerBadges` | no | array | Chips shown after the player's name. See Player Card. |

Any key not listed here is an error.

### `scoringModel`

| Value | Use when |
|---|---|
| `finalScore` | Each player's score is entered once, when the game is over. |
| `rounds` | A score is entered for each player every round, and totals add up across rounds. The players decide when the game is over. |

### `players`

| Key | Required | Type | Rules |
|---|---|---|---|
| `minimum` | yes | integer | At least 1. The setup screen needs this many players before scoring starts. |
| `maximum` | no | integer | Not less than `minimum`. Shown on the game page. Informational only: the app does not block larger games. |

### `prompts`

Each entry is an option shown on the game page before scoring starts.

| Key | Required | Type | Rules |
|---|---|---|---|
| `id` | yes | string | Same format as the template `id`. Unique within the template. |
| `type` | yes | string | `boolean` or `integer`. |
| `label` | yes | string | Non-empty. |
| `help` | no | string | Helper text under the label. |
| `default` | no | boolean or integer | Must match `type`. |
| `effect` | no | string | What the answer changes. See below. |

Supported `effect` values:

| Effect | Prompt type | Meaning |
|---|---|---|
| `lowScoreWins` | `boolean` | When answered true, the lowest score wins, whatever `winner` says. |

A prompt without an `effect` is asked and saved with the game. In version 2, formulas can read its answer; see `template_schema_v2.md`.

### `scoreField`

| Key | Required | Type | Rules |
|---|---|---|---|
| `id` | yes | string | Same format as the template `id`. Stored with every saved score: never change it once games have been saved. |
| `label` | yes | string | Non-empty. |
| `initialValue` | no | integer | The score a player starts at. |
| `minimumDisplayDigits` | no | integer | At least 1. Default 1. Reserves width so scores don't shift as they grow. |
| `entry` | no | object | See below. |
| `entryModes` | no | array | Extra ways to enter a score in the entry sheet. See below. |

### `scoreField.entry`

All keys are optional booleans.

| Key | Default | Meaning |
|---|---|---|
| `tapToEdit` | `false` | Tapping the score opens the score entry sheet (calculator and quick pick). |
| `quickAdjust` | `false` | Shows - and + buttons beside the score. |
| `replace` | `true` | The entry sheet offers Replace. |
| `adjust` | `false` | The entry sheet offers Add to Existing. |

### `scoreField.entryModes`

Each entry adds a mode to the score entry sheet, offered before the built-in calculator and quick pick. Needs `entry.tapToEdit`. The sheet opens in the first of these until the players switch modes, and then remembers their choice for the rest of the game.

Version 1 supports one type, `valuePicker`: tiles for the values that can be in front of a player, such as cards. Each tap adds a value; the score is the total of everything tapped. Use it when a round's or game's score is a plain sum of items.

```json
"entryModes": [
  {
    "type": "valuePicker",
    "id": "cards",
    "label": "Cards",
    "values": [
      { "value": -2, "color": "#3949AB" },
      { "value": 0, "color": "#4FC3F7" },
      { "value": 3, "label": "Hole" }
    ]
  }
]
```

| Key | Required | Type | Rules |
|---|---|---|---|
| `type` | yes | string | `valuePicker`. |
| `id` | yes | string | Same format as the template `id`. Unique within the field. |
| `label` | yes | string | Non-empty. Names the mode, for example `"Cards"`. |
| `values` | one of `values` or `groups` | array | The tiles. The score is their sum. |
| `groups` | one of `values` or `groups` | array | Tiles in named groups, for when the score is not a plain sum. See below. |
| `total` | no, and only with `groups` | string | Formula for the score from the group totals. See below. Without it, every tapped tile is added up. |

A picker has at most 24 tiles in all, so they fit on a phone.

Each tile, in `values` or in a group's `values`:

| Key | Required | Type | Rules |
|---|---|---|---|
| `value` | yes | integer | What the tile is worth. Negative values are allowed. |
| `text` | no | string | Shown on the tile instead of the value, for example `"+4"`, `"×2"`, or `"Bust"`. At most 6 characters. |
| `label` | no | string | Non-empty. Shown small under the main text, for example `"Hole"`. |
| `color` | no | string | Tile colour as `#RRGGBB`. Match the physical item where it helps players find it. |

Every tile in a picker must look different: its `text`, or its value when it has no `text`, must be unique. So the number card `2` and a `"+2"` modifier can both exist.

#### Groups and `total`

Use groups when tiles count differently, for example Flip 7, where ×2 doubles only the number cards and a bust scores 0:

```json
{
  "type": "valuePicker",
  "id": "cards",
  "label": "Cards",
  "groups": [
    { "id": "numbers", "values": [{ "value": 0 }, { "value": 1 }, { "value": 12 }] },
    { "id": "modifiers", "values": [{ "value": 4, "text": "+4", "color": "#F57C00" }] },
    { "id": "double", "values": [{ "value": 1, "text": "×2", "color": "#F57C00" }] },
    { "id": "bust", "values": [{ "value": 1, "text": "Bust", "color": "#B71C1C" }] }
  ],
  "total": "if({bust} > 0, 0, {numbers} * if({double} > 0, 2, 1) + {modifiers} + if(distinctIn(numbers) >= 7, 15, 0))"
}
```

Group rules:

| Key | Required | Rules |
|---|---|---|
| `id` | yes | Same format as the template `id`. Unique within the picker. |
| `values` | yes | At least one tile. |

The tiles are shown in template order, groups one after another, in one grid. Give groups their own colours so players can tell them apart.

`total` uses the formula language from [version 2](template_schema_v2.md#formula-language) (numbers, operators, `min`, `max`, `abs`, `if`), with these values instead of fields:

| Write | Means |
|---|---|
| `{group}` | The sum of the values of the tapped tiles in that group (0 if none). |
| `countIn(group)` | How many tiles were tapped in that group. |
| `distinctIn(group)` | How many different tiles were tapped in that group. |

The players see the total update as they tap, and Replace or Adjust uses it.

#### Remembered tiles

When a score is entered with a value picker and **Replace**, the tapped tiles are kept with that entry while the game is in progress (through resume, and when going back to an earlier round). Reopening the entry sheet for that player goes straight to the picker with those tiles, ready to adjust. Card text that reads tile groups comes from the kept tiles. Changing the score any other way (− / +, the calculator, quick pick, or **Adjust**) drops the tiles, and with them any text that depended on them.

---

## Player Card

Each player has a card on the scoring screen:

| Part | What it is | Set by |
|---|---|---|
| Player Name | The player | the players |
| Score | This round's score (Round Score), or the game's score in Quick Score | `scoreField` (version 2: `fields` and `score`) |
| Total Score | Running total, round games only | the app |
| Score Label | A word shown **instead of** the score, such as "Bust" | `scoreLabels` |
| Score Sub Label | Small text **under** the score, such as "from 10" | `scoreSubLabels` |
| Player Badge | A chip **after** the name, such as "1st" or "7!" | `playerBadges`, and markers (version 2) |
| Player Color | A halo around the card | the players |

The app shows whatever text the template gives; the template decides what it means. There is no built-in text.

### Card Text: `scoreLabels`, `scoreSubLabels`, `playerBadges`

Three optional top-level lists with the same shape. For Flip 7:

```json
"scoreLabels": [
  { "when": "{bust} > 0", "text": "Bust", "color": "#C62828", "size": "small" }
],
"playerBadges": [
  { "when": "{bust} == 0 and distinctIn(numbers) >= 7", "text": "7!", "color": "#2E7D32" },
  { "when": "({roundNumber} - 1) % {playerCount} + 1 == {playerPosition}", "text": "1st", "color": "#1565C0" }
]
```

| Key | Required | Rules |
|---|---|---|
| `when` | yes | A formula. The text shows when it is not 0. |
| `text` | yes | `{name}` shows a value, for example `"from {round-score}"`. At most 8 characters as written for score labels and player badges, 24 for score sub labels. |
| `color` | no | `#RRGGBB`: the text colour for labels, the chip colour for badges. |
| `size` | no | Score labels only: `small`, `medium`, or `large` (default). Use `small` to keep a word like "Bust" quieter than a score. The score number always keeps its normal size. |

Which entries show:

| List | Shows | When |
|---|---|---|
| `scoreLabels` | the first that applies, instead of the score | once a score is entered |
| `scoreSubLabels` | the first that applies, under the score | once a score is entered, and not with a score label |
| `playerBadges` | every one that applies, in template order | always, even before a score is entered |

Put the most specific entry first in `scoreLabels` and `scoreSubLabels`. Use a score label only when the outcome always has the same score (a Flip 7 bust is always 0); otherwise keep the score showing and use a sub label or badge.

Card text formulas can read:

* the score field, and in version 2 every field, including calculated fields and markers
* the other players, with `highestOther`, `lowestOther`, `sumOthers`, and `countOthers`
* prompts by `id`, `{playerCount}`, `{roundNumber}`, and `{playerPosition}` (the player's seat in play order, from 1)
* the tile groups of the score's value pickers, with `{group}`, `countIn(group)`, and `distinctIn(group)`

Tile groups are 0 unless the score was entered with the picker and **Replace** (see Remembered tiles), so a typed 75 is not a Rack-O. A tile group may not have the same `id` as a field or prompt, so `{name}` always means one thing.

The score sub label also shows in the entry sheet, as "Current score: 75 (Rack-o)".

---

## Scenario File

### Example

```json
{
  "templateId": "skyjo",
  "scenarios": [
    {
      "name": "Lowest total wins after three rounds",
      "players": ["avery", "jules"],
      "rounds": [
        { "avery": 10, "jules": 20 },
        { "avery": 15, "jules": 5 },
        { "avery": 12, "jules": 18 }
      ],
      "expected": {
        "totals": { "avery": 37, "jules": 43 },
        "winners": ["avery"]
      }
    }
  ]
}
```

### Keys

| Key | Required | Rules |
|---|---|---|
| `templateId` | yes | Must match the file name and an existing template. |
| `scenarios` | yes | At least one scenario. |
| `pickerTotals` | when a value picker has a `total` | Checks of the picker's total. See below. |

Each scenario:

| Key | Required | Rules |
|---|---|---|
| `name` | yes | Describes what the scenario proves. |
| `players` | yes | At least `players.minimum` unique player names. |
| `prompts` | no | Prompt answers by prompt `id`, for example `{ "low-score-wins": true }`. Unanswered prompts use their `default`. |
| `scores` | `finalScore` only | One integer per player. |
| `rounds` | `rounds` only | One object per round, with an entry per player. |
| `expected` | yes | At least one of `totals`, `winners`, `placements`, or a `round...` key below. |

A player's entry (in `scores` or a round) is the score as a whole number, or an object:

| Key | Meaning |
|---|---|
| the score field `id` | The score, for example `{ "round-score": 10 }`. |
| a marker `id` | `1` to set the marker (version 2). |
| `tiles` | Tiles tapped in a value picker, by their text or value, for example `{ "tiles": ["9", "Bust"] }`. Without a score, the score is the picker's total. Card text reads these tiles. |
| `picker` | The value picker's `id`, needed only when the score has more than one. |

Players are in play order, which sets `{playerPosition}`.

`expected`:

| Key | Meaning |
|---|---|
| `totals` | Each player's final total. |
| `winners` | The players in first place. More than one means a tie. Order does not matter. |
| `placements` | Each player's place. Tied players share a place. |
| `roundScores` | Each round's score per player, in round order. Every player in every round. |
| `roundScoreLabels` | Each round's score labels by player, for example `[{ "avery": "Bust" }, {}]`. Players left out expect none. |
| `roundScoreSubLabels` | The same for score sub labels, for example `[{ "avery": "from 10" }]`. |
| `roundPlayerBadges` | Each round's player badges by player, in template order, for example `[{ "avery": ["1st"], "jules": ["7!"] }]`. Players left out expect none. |

The `round...` keys apply to `rounds` templates only and need one entry per round.

### `pickerTotals`

Each check taps tiles in a value picker and states the score they should give. What tiles show on the player card is checked in scenarios, with `tiles` entries. Tiles are named by what they show. Use the rulebook's own examples where it has them.

```json
"pickerTotals": [
  {
    "name": "Rulebook example: ×2 doubles the number cards, then +4",
    "picker": "cards",
    "taps": ["8", "6", "3", "×2", "+4"],
    "expected": 38
  }
]
```

| Key | Required | Rules |
|---|---|---|
| `name` | yes | Describes what the check proves. |
| `picker` | yes | The `id` of a value picker in the template. |
| `taps` | yes | Tiles in the order they are tapped, by their text or value. |
| `expected` | yes | The score. |

### Coverage Rules

The test run fails unless a template's scenarios:

* include at least one tie for first place
* answer every prompt that has an `effect` with a non-default value at least once
* include at least one `pickerTotals` check for every value picker with a `total`
* expect every score label, score sub label, and player badge at least once, in a scenario's `roundScoreLabels`, `roundScoreSubLabels`, or `roundPlayerBadges`

---

## Error Messages

Problems are reported with the path to the bad value, for example:

```text
assets/templates/skyjo.json: prompts[0].effect: unsupported value "doubleScores"; expected one of: lowScoreWins
assets/templates/skyjo.json: scoreField.entry.tapTo: unknown key
```
