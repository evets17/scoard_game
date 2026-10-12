# Scoring Template Schema, Version 2

Version 2 lets a template **calculate** a player's score with a formula instead of always using the number that was entered. Use it when the score is worked out from what was entered, or depends on the other players (for example Cornhole's cancellation scoring).

Everything in [version 1](template_schema_v1.md) still applies except where this document says otherwise. Version 1 templates keep working and do not need to change; use version 1 when the entered number is the score.

---

## What Changes From Version 1

| Version 1 | Version 2 |
|---|---|
| `"schemaVersion": 1` | `"schemaVersion": 2` |
| `scoreField` (one entered field, which is the score) | `fields` (entered and calculated fields) and `score` (which field is the score) |

All other top-level keys (`id`, `version`, `name`, `subtitle`, `description`, `source`, `players`, `scoringModel`, `winner`, `prompts`) are unchanged. `scoreField` is not allowed in version 2.

---

## Example: Cornhole

```json
{
  "schemaVersion": 2,
  "id": "cornhole",
  "version": "1.0.0",
  "name": "Cornhole",
  "subtitle": "Cancellation scoring",
  "description": "Each inning, the side with more points scores the difference. First to 21 wins.",
  "players": { "minimum": 2, "maximum": 2 },
  "scoringModel": "rounds",
  "winner": "highestScore",
  "fields": [
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
  "score": "points-scored"
}
```

Players enter each side's inning points (with the Bags picker or the usual score entry). The app works out points scored, and that is what adds up, sorts, and decides the winner.

---

## `fields`

A list of fields. A field with a `formula` is **calculated**; any other field is **entered**.

Rules:

* exactly one entered field (several entered fields per player come in a later version)
* any number of calculated fields
* every `id` unique across all fields, in the same format as the template `id`
* a calculated field may read entered and other calculated fields, but not itself, directly or through other fields

### Entered Field

The same keys as version 1's `scoreField`: `id`, `label`, `initialValue`, `minimumDisplayDigits`, `entry`, `entryModes`.

### Calculated Field

| Key | Required | Type | Rules |
|---|---|---|---|
| `id` | yes | string | Unique across all fields. |
| `label` | yes | string | Non-empty. |
| `formula` | yes | string | See the formula language below. |

No other keys are allowed.

## `score`

Required. The `id` of the field that is each player's score for the round (or the game, for `finalScore`). It can be the entered field or a calculated one.

---

## Formula Language

Formulas use whole numbers only. They are evaluated separately for each player, every round.

### Values

| Write | Means |
|---|---|
| `12`, `0` | A whole number. Use `-2` or `0 - 2` for negatives. |
| `{inning-points}` | This player's value for that field this round. |
| `{playerCount}` | How many players are in the game. |
| `{roundNumber}` | The current round, starting at 1 (always 1 for `finalScore`). |

### Operators

Listed from first to last applied. Use parentheses to change the order.

| Operators | Meaning |
|---|---|
| `-` (before a value) | Negative. |
| `*` `/` | Multiply, divide. Division rounds down to a whole number (`7 / 2` is 3, `-7 / 2` is -4). Dividing by zero gives 0. |
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

A formula never names another player. These functions look at all the other players at once. Their argument is a field name **without** braces.

| Function | Result |
|---|---|
| `highestOther(field)` | The highest value of `field` among the other players. |
| `lowestOther(field)` | The lowest value of `field` among the other players. |
| `sumOthers(field)` | The total of `field` across the other players. |
| `countOthers()` | How many other players there are. |

With no other players, `highestOther`, `lowestOther`, and `sumOthers` give 0.

### Examples

| Rule | Formula |
|---|---|
| Score the difference over the best other player, never below 0 | `max(0, {points} - highestOther(points))` |
| Half the points, rounded down | `{points} / 2` |
| Double the score in round 3 | `if({roundNumber} == 3, {points} * 2, {points})` |
| A bonus of 5 for having the most | `{points} + if({points} > highestOther(points), 5, 0)` |
| At most 10 per round | `min({points}, 10)` |

---

## Scenario Files

Scenario files work as in version 1. Each round gives the entered value per player:

```json
{ "blue": 7, "red": 4 }
```

`expected` can also include **`roundScores`** (for `rounds` templates): each round's score per player, in round order. Use it to check a calculated score round by round, not only through the totals.

```json
"expected": {
  "roundScores": [
    { "blue": 3, "red": 0 },
    { "blue": 0, "red": 6 }
  ],
  "totals": { "blue": 3, "red": 6 }
}
```

Version 2 templates follow the same coverage rules as version 1 (a tie for first, and every prompt effect used). Templates whose formulas can divide should also include a scenario where the divisor is zero.

---

## Error Messages

Formula problems name the field, the problem, and the 1-based position in the formula:

```text
assets/templates/cornhole.json: fields[1].formula: expected ")" but found the end at position 16
assets/templates/cornhole.json: fields[1].formula: unknown name "bonus"; expected one of: inning-points, points-scored, playerCount, roundNumber at position 1
assets/templates/cornhole.json: fields[1].formula: circular reference: scored -> subtotal -> scored
```
