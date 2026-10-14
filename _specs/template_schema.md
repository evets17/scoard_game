# Scoring Template Schema

This is the reference for writing a Scoard Game scoring template. A template describes how one game is scored. The app reads it, validates it, and scores the game with it, with no code changes.

A template describes the game's **score sheet**: the **lines** recorded for each player, such as the score entered each round, or values worked out from it with formulas. Today a sheet has exactly one entered line, entered either once at the end (`finalScore`) or once per round (`rounds`). Several entered lines per player (for example Cascadia's categories) are planned; see `restart_slice_12_score_sheets_plan.md`.

---

## Files

Each template needs two files. Both use the template's `id` as the file name.

| File | Purpose |
|---|---|
| `assets/templates/<id>.json` | The template. Bundled into the app, and listed in `assets/templates/index.json`. |
| `test/templates/scenarios/<id>.json` | Scoring scenarios that prove the template scores the game correctly. Test data only. |

After adding or changing either file, run:

```bash
flutter test test/templates
```

That validates every bundled template and runs every scenario. A template is done when this passes.

---

## Template File

### Example: One Entered Line

When the number entered is the score, the sheet has one line and needs nothing else:

```json
{
  "schemaVersion": 1,
  "id": "round-score-basic",
  "version": "1.0.0",
  "name": "Round Score",
  "description": "Scores add up each round. Highest total wins.",
  "players": { "minimum": 2 },
  "scoringModel": "rounds",
  "winner": "highestScore",
  "lines": [
    {
      "id": "round-score",
      "label": "Round Score",
      "initialValue": 0,
      "minimumDisplayDigits": 2,
      "entry": { "tapToEdit": true, "quickAdjust": true, "replace": true, "adjust": true }
    }
  ]
}
```

### Example: A Calculated Score (Cornhole)

When the score is worked out from what was entered, add a calculated line and name it as the `score`:

```json
{
  "schemaVersion": 1,
  "id": "cornhole",
  "version": "1.3.0",
  "name": "Cornhole",
  "subtitle": "Cancellation scoring",
  "description": "Each inning, the side with more points scores the difference. First to 21 wins.",
  "players": { "minimum": 2, "maximum": 2 },
  "scoringModel": "rounds",
  "winner": "highestScore",
  "lines": [
    {
      "id": "inning-points",
      "label": "Inning Points",
      "initialValue": 0,
      "entry": { "tapToEdit": true, "quickAdjust": true, "replace": true, "adjust": true },
      "entryModes": [
        {
          "type": "valuePicker",
          "id": "bags",
          "label": "Bags",
          "values": [
            { "value": 1, "label": "Board", "color": "#C8A165" },
            { "value": 3, "label": "Hole", "color": "#37474F" }
          ]
        }
      ]
    },
    {
      "id": "points-scored",
      "label": "Points Scored",
      "formula": "max(0, {inning-points} - highestOther(inning-points))"
    }
  ],
  "score": "points-scored",
  "scoreSubLabels": [
    { "when": "{points-scored} != {inning-points}", "text": "from {inning-points}" }
  ]
}
```

Players enter each side's inning points (with the Bags picker or the usual score entry). The app works out points scored, and that is what adds up, sorts, and decides the winner. The score sub label shows the inning points under the points scored when they differ, for example 3 over "from 7". Without it, only the points scored would show: the app has no built-in text.

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
| `lines` | yes | array | The score sheet. See [Lines](#lines). |
| `score` | no | string | The line that is each player's score. See [`score`](#score). |
| `scoreLabels` | no | array | Text shown instead of the score. See [Player Card](#player-card). |
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

A prompt without an `effect` is asked and saved with the game. Formulas can read its answer by its `id` (see [Formula Language](#formula-language)), so a house rule can be an option.

---

## Lines

`lines` is the score sheet: one value per player, in order. A line with a `formula` is **calculated**, a line with a `marker` is a **marker**, and any other line is **entered**.

Rules:

* exactly one entered line (several entered lines per player are planned)
* any number of calculated lines and markers
* every `id` unique across all lines, in the same format as the template `id`, and not the same as a prompt `id`
* a calculated line may read entered and other calculated lines, but not itself, directly or through other lines
* once a template is published, never rename or remove a line, marker, value picker, or prompt `id`; add new ones instead. Games in progress are scored again with the current template when resumed, and their saved entries are found by these ids

### Entered Line

| Key | Required | Type | Rules |
|---|---|---|---|
| `id` | yes | string | Same format as the template `id`. Stored with every saved score: never change it once games have been saved. |
| `label` | yes | string | Non-empty. |
| `initialValue` | no | integer | The score a player starts at. |
| `minimumDisplayDigits` | no | integer | At least 1. Default 1. Reserves width so scores don't shift as they grow. |
| `entry` | no | object | See below. |
| `entryModes` | no | array | Extra ways to enter a value in the entry sheet. See below. |

#### `entry`

All keys are optional booleans.

| Key | Default | Meaning |
|---|---|---|
| `tapToEdit` | `false` | Tapping the score opens the score entry sheet (calculator and quick pick). |
| `quickAdjust` | `false` | Shows - and + buttons beside the score. |
| `replace` | `true` | The entry sheet offers Replace. |
| `adjust` | `false` | The entry sheet offers Add to Existing. |

#### `entryModes`

Each entry adds a mode to the score entry sheet, offered before the built-in calculator and quick pick. Needs `entry.tapToEdit`. The sheet opens in the first of these until the players switch modes, and then remembers their choice for the rest of the game.

One type is supported, `valuePicker`: tiles for the values that can be in front of a player, such as cards. Each tap adds a value; the value is the total of everything tapped.

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
| `id` | yes | string | Same format as the template `id`. Unique within the line. |
| `label` | yes | string | Non-empty. Names the mode, for example `"Cards"`. |
| `values` | one of `values` or `groups` | array | The tiles. The value is their sum. |
| `groups` | one of `values` or `groups` | array | Tiles in named groups, for when the value is not a plain sum. See below. |
| `total` | no, and only with `groups` | string | Formula for the value from the group totals. See below. Without it, every tapped tile is added up. |

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

`total` uses the [formula language](#formula-language) (numbers, operators, `min`, `max`, `abs`, `if`), with these values instead of lines:

| Write | Means |
|---|---|
| `{group}` | The sum of the values of the tapped tiles in that group (0 if none). |
| `countIn(group)` | How many tiles were tapped in that group. |
| `distinctIn(group)` | How many different tiles were tapped in that group. |

The players see the total update as they tap, and Replace or Adjust uses it.

#### Remembered tiles

When a value is entered with a value picker and **Replace**, the tapped tiles are kept with that entry while the game is in progress (through resume, and when going back to an earlier round). Reopening the entry sheet for that player goes straight to the picker with those tiles, ready to adjust. Card text that reads tile groups comes from the kept tiles. Changing the value any other way (− / +, the calculator, quick pick, or **Adjust**) drops the tiles, and with them any text that depended on them.

### Calculated Line

| Key | Required | Type | Rules |
|---|---|---|---|
| `id` | yes | string | Unique across all lines. |
| `label` | yes | string | Non-empty. |
| `formula` | yes | string | See the [formula language](#formula-language). |

No other keys are allowed.

### Marker Line

A per-player, per-round flag that players switch on by hand, for something that is not part of the score itself but changes how it counts. Skyjo uses one for the player who went out first:

```json
{
  "id": "first-out",
  "label": "Went out first",
  "marker": { "badge": "Out", "color": "#1565C0", "onePerRound": true }
},
{
  "id": "points",
  "label": "Points",
  "formula": "if({first-out} > 0 and {round-score} > 0 and lowestOther(round-score) <= {round-score}, {round-score} * 2, {round-score})"
}
```

| Key | Required | Type | Rules |
|---|---|---|---|
| `id` | yes | string | Unique across all lines. |
| `label` | yes | string | Non-empty. The toggle's text in the entry sheet. |
| `marker.badge` | yes | string | At most 8 characters. Shown as a player badge while the marker is on. |
| `marker.color` | no | string | Badge colour as `#RRGGBB`. |
| `marker.onePerRound` | no | boolean | Default `false`. `true`: switching it on for one player switches it off for everyone else that round. |

Players switch markers on and off in the entry sheet, whatever entry mode they use, and the change takes effect at once. Changing a player's score does not affect their markers. Formulas read a marker as `{id}`: 1 when on, 0 when off, and other-player functions work on markers too. Markers are saved like entered values, with the game and its results.

### `score`

The `id` of the line that is each player's score for the round (or the game, for `finalScore`). It can be the entered line or a calculated one. Leave it out when the entered line is the score.

---

## Player Card

Each player has a card on the scoring screen:

| Part | What it is | Set by |
|---|---|---|
| Player Name | The player | the players |
| Score | This round's score (Round Score), or the game's score in Quick Score | the `score` line |
| Total Score | Running total, round games only | the app |
| Score Label | A word shown **instead of** the score, such as "Bust" | `scoreLabels` |
| Score Sub Label | Small text **under** the score, such as "from 10" | `scoreSubLabels` |
| Player Badge | A chip **after** the name, such as "1st" or "7!" | `playerBadges`, and marker lines |
| Player Color | A halo around the card | the players |

The app shows whatever text the template gives; the template decides what it means. There is no built-in text.

**Score labels and sub labels describe the score, as it would be written on the score sheet. Player badges describe the player in the selected round.** Something that should stay visible on the score sheet in every past round is a score sub label, not a badge.

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

* every line, including calculated lines and markers
* the other players, with `highestOther`, `lowestOther`, `sumOthers`, and `countOthers`
* prompts by `id`, `{playerCount}`, `{roundNumber}`, and `{playerPosition}`
* the tile groups of the score's value pickers, with `{group}`, `countIn(group)`, and `distinctIn(group)`

Tile groups are 0 unless the value was entered with the picker and **Replace** (see Remembered tiles), so a typed 75 is not a Rack-O. A tile group may not have the same `id` as a line or prompt, so `{name}` always means one thing.

The score sub label also shows in the entry sheet, as "Current score: 75 (Rack-o)".

---

## Formula Language

Formulas use whole numbers only. They are evaluated separately for each player, every round.

### Values

| Write | Means |
|---|---|
| `12`, `0` | A whole number. Use `-2` or `0 - 2` for negatives. |
| `{inning-points}` | This player's value for that line this round. |
| `{playerCount}` | How many players are in the game. |
| `{roundNumber}` | The current round, starting at 1 (always 1 for `finalScore`). |
| `{playerPosition}` | The player's seat in play order, starting at 1. Changes if players are reordered. |
| `{double-points}` | A prompt's answer, by prompt `id`: 1 for true and 0 for false, or the number entered. Unanswered prompts use their `default` (0 if none). |

### Operators

Listed from first to last applied. Use parentheses to change the order.

| Operators | Meaning |
|---|---|
| `-` (before a value) | Negative. |
| `*` `/` `%` | Multiply, divide, remainder. Division rounds down to a whole number (`7 / 2` is 3, `-7 / 2` is -4). The remainder matches it (`7 % 2` is 1, `-1 % 4` is 3), so it is never negative for a positive divisor. Dividing by zero gives 0 for both. |
| `+` `-` | Add, subtract. |
| `>` `>=` `<` `<=` `==` `!=` | Compare. True is 1, false is 0. Comparisons cannot be chained: write `a < b and b < c`. |
| `not` | 1 if the value is 0, otherwise 0. |
| `and` | 1 if both sides are non-zero. |
| `or` | 1 if either side is non-zero. |

### Functions

| Function | Result |
|---|---|
| `min(a, b, ...)` | The smallest value. At least one argument. |
| `max(a, b, ...)` | The largest value. At least one argument. |
| `abs(a)` | `a` without its sign. |
| `if(condition, then, else)` | `then` when `condition` is non-zero, otherwise `else`. |

### Looking At The Other Players

A formula never names another player. These functions look at all the other players at once. Their argument is a line name **without** braces.

| Function | Result |
|---|---|
| `highestOther(line)` | The highest value of `line` among the other players. |
| `lowestOther(line)` | The lowest value of `line` among the other players. |
| `sumOthers(line)` | The total of `line` across the other players. |
| `countOthers()` | How many other players there are. |

With no other players, `highestOther`, `lowestOther`, and `sumOthers` give 0.

### Examples

| Rule | Formula |
|---|---|
| Score the difference over the best other player, never below 0 | `max(0, {points} - highestOther(points))` |
| Half the points, rounded down | `{points} / 2` |
| Double the score in round 3 | `if({roundNumber} == 3, {points} * 2, {points})` |
| The first player moves one seat each round | `({roundNumber} - 1) % {playerCount} + 1 == {playerPosition}` |
| A bonus of 5 for having the most | `{points} + if({points} > highestOther(points), 5, 0)` |
| At most 10 per round | `min({points}, 10)` |
| A house-rule option doubles the score | `if({double-points} > 0, {points} * 2, {points})` |

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
| `players` | yes | At least `players.minimum` unique player names, in play order (which sets `{playerPosition}`). |
| `prompts` | no | Prompt answers by prompt `id`, for example `{ "low-score-wins": true }`. Unanswered prompts use their `default`. |
| `scores` | `finalScore` only | One entry per player. |
| `rounds` | `rounds` only | One object per round, with an entry per player. |
| `expected` | yes | At least one of `totals`, `winners`, `placements`, or a `round...` key below. |

A player's entry (in `scores` or a round) is the entered line's value as a whole number, or an object:

| Key | Meaning |
|---|---|
| the entered line's `id` | The value, for example `{ "round-score": 10 }`. |
| a marker line's `id` | `1` to set the marker, for example `{ "round-score": 10, "first-out": 1 }`. |
| `tiles` | Tiles tapped in a value picker, by their text or value, for example `{ "tiles": ["9", "Bust"] }`. Without a value, the value is the picker's total. Card text reads these tiles. |
| `picker` | The value picker's `id`, needed only when the line has more than one. |

`expected`:

| Key | Meaning |
|---|---|
| `totals` | Each player's final total. |
| `winners` | The players in first place. More than one means a tie. Order does not matter. |
| `placements` | Each player's place. Tied players share a place. |
| `roundScores` | Each round's score per player, in round order. Every player in every round. Use it to check a calculated score round by round. |
| `roundScoreLabels` | Each round's score labels by player, for example `[{ "avery": "Bust" }, {}]`. Players left out expect none. |
| `roundScoreSubLabels` | The same for score sub labels, for example `[{ "avery": "from 10" }]`. |
| `roundPlayerBadges` | Each round's player badges by player, in template order, for example `[{ "avery": ["1st"], "jules": ["7!"] }]`. Players left out expect none. |

The `round...` keys apply to `rounds` templates only and need one entry per round.

### `pickerTotals`

Each check taps tiles in a value picker and states the value they should give. What tiles show on the player card is checked in scenarios, with `tiles` entries. Tiles are named by what they show. Use the rulebook's own examples where it has them.

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
| `expected` | yes | The value. |

### Coverage Rules

The test run fails unless a template's scenarios:

* include at least one tie for first place
* answer every prompt that has an `effect`, or is read by a formula, with a non-default value at least once
* include at least one `pickerTotals` check for every value picker with a `total`
* expect every score label, score sub label, and player badge at least once, in a scenario's `roundScoreLabels`, `roundScoreSubLabels`, or `roundPlayerBadges`

Templates whose formulas can divide should also include a scenario where the divisor is zero.

---

## Error Messages

Problems are reported with the path to the bad value, and formula problems with the 1-based position in the formula:

```text
assets/templates/skyjo.json: prompts[0].effect: unsupported value "doubleScores"; expected one of: lowScoreWins
assets/templates/skyjo.json: lines[0].entry.tapTo: unknown key
assets/templates/cornhole.json: lines[1].formula: expected ")" but found the end at position 16
assets/templates/cornhole.json: lines[1].formula: unknown name "bonus"; expected one of: inning-points, points-scored, playerCount, roundNumber, playerPosition at position 1
assets/templates/cornhole.json: lines[1].formula: circular reference: scored -> subtotal -> scored
```

---

## Publishing A Template Change

The app can load templates from a URL instead of only those built in (Settings > Templates). By default it reads this repository's `assets/templates/` folder from GitHub, so pushing to `main` publishes.

`assets/templates/index.json` lists the template files, because a raw GitHub URL can't list a folder:

```json
{ "indexVersion": 1, "templates": ["cornhole.json", "skyjo.json"] }
```

To publish a change:

1. Edit the template and its scenario file. A new template also goes in `index.json`.
2. Bump `version`: patch for wording, minor for scoring changes. An online copy with the same version as the built-in one is used, so a local edit without a bump is hidden by the older online copy; the version shows on the game page ("Template v2.1.0 · online"), which confirms which copy a phone has.
3. Run `flutter test`. The validator, scenarios, and a check that `index.json` matches the folder must pass.
4. Commit and push to `main`.
5. On the phone, open Settings and tap Check now. GitHub caches files for up to 5 minutes, so a change pushed just before may not show yet.

How the app chooses:

* An online template replaces the built-in one with the same id, unless the built-in `version` is higher.
* An online file that fails validation is skipped and listed under problems in Settings. Its last good copy, if any, is kept.
* A template using a feature this app version doesn't know fails validation, so release the app before pushing templates that need it.
* Online templates are off by default in debug builds, so an older online copy never hides a template being edited locally.
