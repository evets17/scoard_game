# Restart Slice 10 Plan: Formulas And Calculated Fields (Cornhole)

## 1. Purpose

This document defines Slice B of the template system: letting a template calculate a player's score with a formula instead of always using the number that was entered.

The proof case is **Cornhole**, which needs three things today's templates cannot express:

* a raw value worked out from what happened (bags on the board are worth 1, bags in the hole 3)
* a score that depends on the other side's result (cancellation scoring: only the higher side scores, and only the difference)
* a score that differs from the number typed in (a side can enter 7 points and score 0)

This plan should be read alongside:

* `restart_slice_9_templates_as_data_plan.md` (Slice A)
* `template_schema_v1.md`
* `scoring_thoughts_examples.md` ("Everything is a formula", Bean Bags)

---

## 2. Slice Goal

Implement formulas and calculated fields so that:

* a template can declare calculated fields whose values come from formula strings
* a template can say which field is the score that adds up to the total
* formulas can refer to the player's own fields and, through a small set of functions, to the other players' fields
* the round screen, results, sorting, and saved history all use the calculated score
* a **Cornhole** template plays correctly using cancellation scoring

This slice is successful when Cornhole is added as data (template plus scenarios) and plays a full game in the app with correct cancellation totals.

---

## 3. Why This Slice, And What Moved

The Slice A plan named Slice B as category scoring: several entered fields per player on a tally sheet, proven with an end-game category game.

Cornhole does not need several entered fields. A side's inning points can be entered with the existing value picker (Board = 1, Hole = 3), which already sums taps. What Cornhole needs is the formula engine, which category scoring also needs. Building formulas first, with a game that needs nothing else, keeps this slice small and gives the category slice a finished engine to build on.

Revised order:

| Slice | Focus | Proof |
|---|---|---|
| A (done) | Templates as data, validator, scenarios | Skyjo |
| **B (this)** | Formulas, calculated fields, score field | Cornhole |
| C | Several entered fields per player, tally sheet, sections | An end-game category game |
| D | Prompts as formula variables, validation rules, notifications | Cornhole "exact 21", "21 reached", Skyjo "100 reached" |

---

## 4. Core Direction For This Slice

### 4.1 Formulas Are Small, Safe, And Integer

Formulas are strings evaluated by a purpose-built evaluator. There is no code execution, no loops, and no access to anything beyond the values the formula may name. All arithmetic is whole-number, matching scores everywhere else in the app; division rounds down, matching the calculator.

### 4.2 Entered Values Stay The Stored Truth

Only entered values are saved. Calculated values are recomputed from them whenever they are needed. This keeps saved games simple, means a corrected entry fixes every calculation, and requires no database change.

### 4.3 The Score Is A Field

A template names which field is the score. For existing templates that is the one entered field, so nothing changes for them. For Cornhole it is a calculated field.

### 4.4 Other Players Are Reached Through Functions, Not Names

A formula never names another player. It asks questions of the other players as a group, such as the highest value of a field among them. This keeps templates independent of who is playing and how many.

### 4.5 Errors Are Caught Before The Game

Unknown fields, unknown functions, wrong argument counts, syntax errors, and circular references are validator errors with the formula and position, not runtime surprises.

---

## 5. In Scope

### 5.1 Formula Language

| Element | Examples |
|---|---|
| Whole numbers | `0`, `21`, `-2` |
| Field references | `{inning-points}` (this player's value this round) |
| Arithmetic | `+ - * /` with normal precedence and parentheses |
| Comparison | `> >= < <= == !=` (true is 1, false is 0) |
| Logic | `and`, `or`, `not` |
| Functions | `min(a, b, ...)`, `max(a, b, ...)`, `abs(a)`, `if(condition, then, else)` |
| Other players | `highestOther(field)`, `lowestOther(field)`, `sumOthers(field)`, `countOthers()` |

Built-in values, referenced like fields:

| Name | Meaning |
|---|---|
| `{playerCount}` | Players in the game |
| `{roundNumber}` | Current round (1 for `finalScore`) |

`highestOther`, `lowestOther`, and `sumOthers` take a field name without braces, for example `highestOther(inning-points)`. With no other players they return 0.

Cornhole's score:

```text
max(0, {inning-points} - highestOther(inning-points))
```

### 5.2 Schema Version 2

Version 2 replaces the single `scoreField` with a `fields` list and a `score` key. Everything else is unchanged from version 1.

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

Field rules:

* a field with `formula` is calculated; any other field is entered
* entered fields keep the version 1 `scoreField` keys (`initialValue`, `minimumDisplayDigits`, `entry`, `entryModes`)
* calculated fields have only `id`, `label`, and `formula`
* in this slice a template has exactly one entered field (several entered fields arrive in Slice C)
* `score` must name a field in `fields`

Version 1 templates remain valid and are read as if their `scoreField` were the only entry in `fields` and also the `score`. The three existing templates stay on version 1.

### 5.3 Formula Validation

The validator parses every formula and reports, with the field path and position:

* syntax errors, for example `fields[1].formula: expected ")" at position 31`
* unknown field or built-in names
* unknown functions and wrong argument counts
* other-player functions given something that is not a field name
* circular references between calculated fields, naming the cycle

### 5.4 Score Engine

A single pure function computes, for one round (or the one final entry), every participant's calculated values and score:

1. take each participant's entered values
2. evaluate calculated fields in dependency order, one field at a time across all participants, so other-player functions always see finished values
3. read each participant's score from the `score` field

Every place that today reads the entered value as the score uses this engine instead:

* `calculateQuickScoreResult` and `calculateRoundScoreResult`
* the round screen's running totals and score-sort snapshot
* the quick score screen's score-sort snapshot
* scenario tests

### 5.5 Round Screen Display

For a template whose score is calculated:

* the row's number and its -/+ and entry sheet edit the entered field, as today (Cornhole: inning points)
* the shaded total box shows the running total of the calculated score, so a side that out-throws the other sees its total rise and the other side's stay put

No new controls are added to the row.

### 5.6 Scenarios For Version 2

Scenario rounds give entered values by player. With one entered field a plain number is still allowed:

```json
{ "avery": 7, "jules": 4 }
```

`expected` gains an optional `roundScores`: each round's score per player, so calculated values are checked round by round, not only through totals.

### 5.7 Cornhole Template And Scenarios

Scenarios must cover at least:

* the higher side scoring the difference and the lower side scoring 0
* equal inning points scoring 0 for both
* a game reaching 21 over several innings
* a tie for first

### 5.8 Schema Reference

`_specs/template_schema_v2.md`, covering the version 2 changes and the full formula language with examples. Version 1 stays documented as is.

---

## 6. Out Of Scope

* several entered fields per player, tally sheets, and sections (Slice C)
* prompts as formula variables, so "exact 21" and target scores can be options (Slice D)
* notifications such as "21 reached" (Slice D)
* the previous running total as a formula value, needed for "bust back to 15" (Slice D)
* teams (see 7.2)
* round labels such as "Inning" (later; Cornhole shows "Round" for now)
* decimal numbers in formulas

---

## 7. Product And UX Rules For This Slice

### 7.1 The Score Players See Is The Score That Counts

Totals, sorting, results, and history all show the calculated score. The entered value is only ever shown where it is being edited.

### 7.2 Teams Are Not In This Slice

Cornhole is often played two against two, but scored by side. Proper teams (picking players onto sides, history per person) are a separate feature with its own setup and history design. Until then a side can be recorded as a player named for the team, which loses per-person history for that game. Singles Cornhole works fully.

### 7.3 Nothing Changes For Existing Games

Quick Score, Round Score, and Skyjo play, save, resume, and show history exactly as before.

---

## 8. Technical Decisions For This Slice

### 8.1 Hand-Written Parser, Pure Dart

The formula tokenizer, parser, checker, and evaluator live in `lib/core/formulas/`, with no Flutter or package dependencies, so they can be tested exhaustively and reused by the future template builder.

### 8.2 Parse Once, Evaluate Many Times

Templates are parsed and checked when the catalog loads. The scoring engine evaluates the parsed form, never the string.

### 8.3 Evaluation Errors Do Not Crash Scoring

Division by zero is the only runtime problem the language allows. It evaluates to 0, so scoring always completes, and the schema reference says so. Templates that divide should cover the zero case in a scenario.

### 8.4 Version 1 Is Read Through The Same Model

The parser turns both versions into the same in-memory template, so the scoring engine and screens see one shape.

---

## 9. Recommended Project Shape For Slice 10

```text
lib/
  core/
    formulas/
      formula_tokenizer.dart
      formula_parser.dart          (string -> expression tree, with positions)
      formula_checker.dart         (names, functions, arity)
      formula_evaluator.dart
    scoring/
      score_engine.dart            (entered values -> calculated values and scores)
  application/models/scoring/
    calculated_field_definition.dart

assets/templates/
  cornhole.json

test/
  core/formulas/
  core/scoring/score_engine_test.dart
  templates/scenarios/cornhole.json

_specs/
  template_schema_v2.md
```

---

## 10. Concrete Deliverables

1. Formula language with parser, checker, and evaluator, fully unit tested.
2. Schema version 2 in the validator and parser, with version 1 still accepted.
3. Circular-reference detection across calculated fields.
4. Score engine used by results, the round and quick score screens, sorting, and scenarios.
5. Scenario `roundScores` expectations.
6. Cornhole template and scenarios.
7. `template_schema_v2.md`.

---

## 11. Suggested Build Sequence Inside The Slice

1. Formula tokenizer, parser, and evaluator, test-first.
2. Formula checker (names, functions, arity) and cycle detection.
3. Score engine, with unit tests including other-player functions.
4. Route results, screens, sorting, and scenario tests through the engine; confirm all existing tests and scenarios still pass with no template changes.
5. Schema version 2 validation and parsing.
6. `template_schema_v2.md`.
7. Cornhole as data only (template and scenarios).
8. Play a Cornhole game end to end in a widget test.

Step 4 is the safety check: once the engine is in place, every existing game must score exactly as before.

---

## 12. Validation Rules

### 12.1 Runtime Validation

* Cornhole appears in Score a Game and plays with correct cancellation totals
* the Bags picker enters inning points
* the total box, sorting, results, and history show points scored, not inning points
* Quick Score, Round Score, and Skyjo are unchanged

### 12.2 Architecture Validation

* no Dart outside `core/formulas` and `core/scoring` knows how a score is calculated
* adding Cornhole touched only `assets/templates/cornhole.json` and `test/templates/scenarios/cornhole.json`

### 12.3 Agent Workflow Validation

* formula errors name the field, the problem, and the position, so a template can be fixed from the message alone

---

## 13. Risks To Watch During Slice 10

### 13.1 The Formula Language Grows Without A Game Asking For It

Risk:

Functions are added because they might be useful.

Response:

Every function in 5.1 is needed by Cornhole or by the games already described in `scoring_thoughts_examples.md`. New functions need a game that uses them.

### 13.2 Calculated And Entered Values Get Confused

Risk:

Some screen keeps reading the entered value as the score, and Cornhole totals come out wrong in one place.

Response:

Route every score read through the engine (5.4), and have the Cornhole widget test check the total box, sorting, and results.

### 13.3 Other-Player Functions Create Hidden Ordering Bugs

Risk:

A calculated field reads another player's calculated field before it is computed.

Response:

Evaluate one field at a time across all players, in dependency order (5.4), and test a field that depends on another player's calculated field.

---

## 14. Exit Decision After Slice 10

Once Slice 10 is complete, the likely next step is Slice C, several entered fields per player with a tally sheet, using the finished formula engine for subtotals and totals.

If real games point first at prompts as variables and notifications (Cornhole's 21, Skyjo's 100), Slice D can come first instead; both build on this slice.
