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
| `scoreNotes` | no | array | A short line under a player's score, such as "Rack-o" or "from 4". See below. |

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

#### `rowLabels`

Optional, and only with `groups`. Shows a word on the player's row in place of their score when the tapped tiles match, so the table can see at a glance what happened. For Flip 7, a bust shows **Bust** in red instead of 0:

```json
"rowLabels": [
  { "when": "{bust} > 0", "text": "Bust", "color": "#C62828", "size": "small" }
]
```

| Key | Required | Rules |
|---|---|---|
| `when` | yes | A formula over the groups, like `total`. The label shows when it is not 0. |
| `text` | yes | At most 8 characters. |
| `show` | no | `replace` (default): shown instead of the score. `badge`: a small chip beside the player's name, keeping the score visible. |
| `color` | no | Text colour for `replace`, chip colour for `badge`, as `#RRGGBB`. |
| `size` | no | `replace` labels only: `small`, `medium`, or `large` (default). Use `small` to keep a word like "Bust" quieter than a score. The score number always keeps its normal size. Sizes follow the phone's text-size setting. |

Use `replace` only when the outcome always has the same score (a Flip 7 bust is always 0), and `badge` when the score still matters (a Flip 7 bonus round scores differently each time):

```json
{ "when": "{bust} == 0 and distinctIn(numbers) >= 7", "text": "7!", "show": "badge", "color": "#2E7D32" }
```

For `replace`, the first matching label is used. Every matching `badge` is shown. The score itself still counts as normal.

#### Remembered tiles

When a score is entered with a value picker and **Replace**, the tapped tiles are kept with that entry while the game is in progress (through resume, and when going back to an earlier round). Reopening the entry sheet for that player goes straight to the picker with those tiles, ready to adjust. Row labels come from the kept tiles. Changing the score any other way (− / +, the calculator, quick pick, or **Adjust**) drops the tiles, and with them any label.

### `scoreNotes`

A small line of text under a player's score, which stays the main number. The app shows whatever the template says; the template decides what a note means. For Rack-O, a Rack-O tile shows **Rack-o** under the 75:

```json
"scoreNotes": [
  { "when": "{racko} > 0", "text": "Rack-o", "color": "#00D126" }
]
```

| Key | Required | Rules |
|---|---|---|
| `when` | yes | A formula. The note shows when it is not 0. |
| `text` | yes | At most 24 characters as written. `{name}` shows a value, for example `"from {round-score}"`. |
| `color` | no | Text colour as `#RRGGBB`. Default: the usual quiet colour. |

The first note whose `when` is true is shown, so put the most specific first. A note can read:

* the score field, and in version 2 every field, including calculated fields and markers
* the other players, with `highestOther`, `lowestOther`, `sumOthers`, and `countOthers`
* prompts by `id`, `{playerCount}`, and `{roundNumber}`
* the tile groups of the score's value pickers, with `{group}`, `countIn(group)`, and `distinctIn(group)`

Tile groups are 0 unless the score was entered with the picker and **Replace** (see Remembered tiles), so a typed 75 is not a Rack-O. A tile group may not have the same `id` as a field or prompt, so `{name}` always means one thing.

The same note shows in the entry sheet, as "Current score: 75 (Rack-o)".

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
| `rounds` | `rounds` only | One object per round, with an integer per player. |
| `expected` | yes | At least one of `totals`, `winners`, `placements`, `roundNotes`. |

`expected`:

| Key | Meaning |
|---|---|
| `totals` | Each player's final total. |
| `winners` | The players in first place. More than one means a tie. Order does not matter. |
| `placements` | Each player's place. Tied players share a place. |
| `roundNotes` | `rounds` only. Each round's score notes by player, in round order, for example `[{ "avery": "from 10" }, {}]`. Players left out expect no note. |

### `pickerTotals`

Each check taps tiles in a value picker and states the score they should give. Tiles are named by what they show. Use the rulebook's own examples where it has them.

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
| `label` | no | The row label the taps should give, for example `"Bust"`, or `null` for no label. |
| `badges` | no | The badge texts the taps should give, in order, for example `["7!"]`, or `[]` for none. |
| `note` | no | The score note the taps should give, for example `"Rack-o"`, or `null` for none. |

### Coverage Rules

The test run fails unless a template's scenarios:

* include at least one tie for first place
* answer every prompt that has an `effect` with a non-default value at least once
* include at least one `pickerTotals` check for every value picker with a `total`
* include a `pickerTotals` check expecting each row label's `text`, in `label` or `badges`
* expect every score note at least once, in a scenario's `roundNotes` or a `pickerTotals` `note`

---

## Error Messages

Problems are reported with the path to the bad value, for example:

```text
assets/templates/skyjo.json: prompts[0].effect: unsupported value "doubleScores"; expected one of: lowScoreWins
assets/templates/skyjo.json: scoreField.entry.tapTo: unknown key
```
