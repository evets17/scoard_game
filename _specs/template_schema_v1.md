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

A prompt without an `effect` is asked and saved with the game but does not change scoring yet.

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
| `values` | yes | array | 1 to 24 entries, so the tiles fit on a phone. |

Each of `values`:

| Key | Required | Type | Rules |
|---|---|---|---|
| `value` | yes | integer | Unique within the mode. Negative values are allowed. |
| `label` | no | string | Non-empty. Shown small under the number, for example `"Hole"`. |
| `color` | no | string | Tile colour as `#RRGGBB`. Match the physical item where it helps players find it. |

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

Each scenario:

| Key | Required | Rules |
|---|---|---|
| `name` | yes | Describes what the scenario proves. |
| `players` | yes | At least `players.minimum` unique player names. |
| `prompts` | no | Prompt answers by prompt `id`, for example `{ "low-score-wins": true }`. Unanswered prompts use their `default`. |
| `scores` | `finalScore` only | One integer per player. |
| `rounds` | `rounds` only | One object per round, with an integer per player. |
| `expected` | yes | At least one of `totals`, `winners`, `placements`. |

`expected`:

| Key | Meaning |
|---|---|
| `totals` | Each player's final total. |
| `winners` | The players in first place. More than one means a tie. Order does not matter. |
| `placements` | Each player's place. Tied players share a place. |

### Coverage Rules

The test run fails unless a template's scenarios:

* include at least one tie for first place
* answer every prompt that has an `effect` with a non-default value at least once

---

## Error Messages

Problems are reported with the path to the bad value, for example:

```text
assets/templates/skyjo.json: prompts[0].effect: unsupported value "doubleScores"; expected one of: lowScoreWins
assets/templates/skyjo.json: scoreField.entry.tapTo: unknown key
```
