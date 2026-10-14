# Restart Slice 12 Plan: Score Sheets And The Sheet View

## 1. Purpose

This document defines how the app moves from "one score per player" to a **score sheet**: several values per player, some entered and some calculated, shown as a grid when that suits the game better than player cards.

The proof case is **Cascadia** (see `cascadia_basegame_scoring.md`), whose paper score sheet asks for a separate score for each wildlife species, each habitat and its majority bonus, and unused nature tokens, with subtotals and a total.

Most of the foundation already exists. The schema's fields are already the lines of a sheet, saved games already store every entered value by field, and the score engine already adds lines into others with formulas. What is missing is the vocabulary, a grid view, and templates with more than one entered line.

This plan should be read alongside:

* `restart_slice_10_formulas_and_calculated_fields_plan.md` (formulas, calculated fields)
* `template_schema_v1.md` (Player Card, card text) and `template_schema_v2.md`, which step 1 merges into `template_schema.md`
* `cascadia_basegame_scoring.md`

---

## 2. Slice Goal

Implement score sheets so that:

* templates describe a score sheet in terms of **lines**
* any game can be shown as a **sheet view** (a grid) as well as the **player card view**
* the sheet view can be edited: tap a cell to enter or correct that player's value for that line and round
* a template can have several entered lines, grouped into sections with subtotals
* **Cascadia** is scored on a sheet that looks and works like its paper one

This slice is successful when a four-player Cascadia game is scored on the phone from start to finish on the sheet view, and when Flip 7 can switch to a scorepad of every round so far and fix a past round's score from it.

---

## 3. Concepts And Vocabulary

These were settled in discussion and are used throughout the app, templates, and docs.

| Term | Meaning |
|---|---|
| **Score sheet** | Everything a template records for each player. Every template has one; today's templates just have one entered line. |
| **Line** | One value per player on the sheet: **entered** (players type it), **calculated** (a formula), or **marker** (a flag set by hand). Replaces "field". |
| **Section** | A group of lines on the sheet, usually ending in a subtotal line (Cascadia: Wildlife, Habitats). |
| **Score line** | The line that decides the winner (`score`). |
| **Player card view** | Today's scoring screen: one card per player for the selected round. Suits sheets with one entered line. |
| **Sheet view** | A grid of the score sheet. Suits sheets with several entered lines, and gives any game a scorepad. |
| **Selected round** | The round both views are showing. Today's round number on the scoring screen already is one; the sheet view adds selecting a round by tapping its row. |

The score sheet has three dimensions: **lines**, **players**, and **rounds**. Games so far use part of it:

| Shape | Example |
|---|---|
| One entered line, no rounds | Quick Score |
| One entered line, rounds | Flip 7, Skyjo, Cornhole, Rack-O |
| Several entered lines, no rounds | Cascadia |
| Several entered lines, rounds | No game yet; supported by the design (5.5) |

Quick Score is not a separate construct: it is the simplest score sheet.

### 3.1 Where Card Text Lives

Each kind of card text has one home and one meaning in both views:

| Card text | Player card view | Sheet view | Means |
|---|---|---|---|
| Score | The big number | The cell's number | The score line's value |
| Score label (`scoreLabels`) | Instead of the score | Instead of the cell's number | What happened in that round, as written on the sheet |
| Score sub label (`scoreSubLabels`) | Under the score | Small, under the cell's number | A note on that round's score, as written on the sheet |
| Player badges (`playerBadges`) | By the name | In the player's column header | The player's state in the **selected round** |
| Markers | By the name | In the column header | Same as player badges |

Rule for template authors: **score labels and sub labels go on the score sheet; player badges describe the player in the selected round.** Something that should be visible in every past round (on the sheet) is a score sub label, not a badge.

Flip 7's "7!" stays a player badge for now. Moving it to a score sub label after the sheet view exists is a good test of this rule, and needs no code.

---

## 4. Core Direction For This Slice

### 4.1 One Model, Two Views

There is one score sheet model. The player card view and the sheet view are two ways of showing it, and both read the same lines, values, and card text from the score engine.

### 4.2 The Sheet Decides The Default View

A sheet with one entered line opens in the player card view; one with several opens in the sheet view. Either way, a toggle on the scoring screen switches views, keeping the selected round.

### 4.3 Score Entry Is Universal

Calculator, quick pick, Adjust, and template value pickers are ways to enter one number. They belong to an entered line (`entry`, `entryModes`) and open the same entry sheet from a player card or a sheet cell.

### 4.4 Build In Usable Steps

Each step in section 5 ships something usable on its own, and none needs reworking for the next.

---

## 5. In Scope

### 5.1 Step 1: Rename Fields To Lines, One Schema Version

* **One schema, no legacy.** Version 1 (`scoreField`) and version 2 (`fields`) are replaced by a single schema that uses `lines` and `score`. There are no outside templates or game history to keep, so nothing reads the old shapes: every bundled template and scenario file is converted, the validator and parser drop the old versions, and `schemaVersion` starts again at `1` for the new shape. An app with the old schema rejects new templates as invalid and keeps its last good copies, which is acceptable with only the two devices in use.
* The two schema docs merge into one, `template_schema.md`.
* Schema: `fields` becomes `lines`. `score` stays. A template with one entered line whose value is the score can leave out `score`, so Quick Score-style templates stay short.
* Code: the field definitions, engine, parser, validator, scenario runner, and screens use "line" (for example `EnteredLineDefinition`, `CalculatedLineDefinition`, `MarkerLineDefinition`, `enteredLines`).
* Storage: saved values are stored by line id. There is no game history to keep, so the database can be migrated or reset rather than carried forward with old names.
* Docs: the schema docs say "line" throughout and introduce the score sheet (section 3).
* No behaviour changes. All tests and scenarios pass with templates rewritten to `lines`.

### 5.2 Step 2: Read-Only Sheet View (Scorepad)

A **view toggle** in the scoring screen's title bar, left of the sort button, switches between the player card view and the sheet view. It is a title-bar action like sort because, like sort, it changes how the same round is shown rather than what is being scored. The icon shows the view it switches to (a grid icon on player cards, a cards icon on the sheet), with a tooltip ("Show sheet" / "Show player cards"). The app remembers the last view per game in progress, so a resumed game opens the way it was left.

For today's one-entered-line round games the sheet view is a scorepad:

* rows are rounds, columns are players, a totals row at the bottom
* cells show the score line's value, with its score label or score sub label (3.1)
* the selected round's row is highlighted; tapping a row selects that round
* column headers show the player's name, colour, and badges for the selected round
* switching back to player cards keeps the selected round

Layout decisions (from rendered mockups at phone width; section 7):

* **Columns** share the width, never narrower than a minimum. Past the minimum the player columns scroll sideways, with the round column, header row, and totals row fixed, and a faded edge showing more columns. Landscape fits roughly twice as many.
* **Column order** follows the existing sort modes: play order, score (by total, using a snapshot taken when the sort is chosen or the round changes, as today), and name.
* **No − / + buttons** in the grid. The entry sheet behind a cell has Adjust and quick pick; the player card view keeps its buttons (`entry.quickAdjust`).

### 5.3 Step 3: Editable Sheet View

* Tapping a cell selects its round and opens the entry sheet for that player, line, and round.
* Value picker tiles are remembered per cell, as they are per card today.
* Correcting a past round updates that round's saved values, totals, sorting, and card text, the same way going back with Previous Round does today.
* **Next cell.** The entry sheet gets a **Next** action that saves the value and opens the next cell, so a sheet can be filled without closing and tapping each time. Which cell is next depends on how the sheet is usually filled:

  | Sheet | Next cell | Why |
  |---|---|---|
  | One entered line (scorepad, and the player card view) | The next player in the same round, in play order | A round is scored player by player |
  | Several entered lines (Cascadia) | The next entered line for the same player | Paper sheets are filled one player at a time, down their column |

  These are defaults. A template can override them with a sheet-level setting, for example `"entryOrder": "byPlayer"` or `"byLine"`, if a game is usually scored the other way. Next skips calculated lines, stops at the last cell rather than wrapping, and never creates rounds.

### 5.4 Step 4: Several Entered Lines, Sections, And Subtotals (Cascadia)

* The validator drops the "exactly one entered line" rule.
* Lines can be grouped into **sections**, each usually ending in a subtotal line (a calculated line). Section shape (decided):
  * `lines` stays one ordered list, top to bottom as on the sheet. A **heading entry**, `{ "heading": "Wildlife" }`, starts a section; the lines after it, up to the next heading, belong to it. Lines before the first heading have no section. This reads like the paper sheet, needs no repeated section names or nesting, and keeps sheets without sections exactly as they are.
  * A calculated line marked `"subtotal": true` is drawn as its section's subtotal (bold, with a rule above). The score line is always drawn as the grand total at the bottom.
  * The validator rejects a heading with no lines after it, and a subtotal that isn't a calculated line.

  ```json
  "lines": [
    { "heading": "Wildlife" },
    { "id": "bear", "label": "Bear", "entry": { "tapToEdit": true } },
    { "id": "elk", "label": "Elk", "entry": { "tapToEdit": true } },
    { "id": "wildlife", "label": "Wildlife", "formula": "{bear} + {elk}", "subtotal": true },
    { "heading": "Nature tokens" },
    { "id": "tokens", "label": "Tokens", "entry": { "tapToEdit": true } },
    { "id": "total", "label": "Total", "formula": "{wildlife} + {tokens}" }
  ],
  "score": "total"
  ```
* Each line has a short label for the grid, such as "Bear", "Elk", or "Nature tokens".
* A sheet with several entered lines and no rounds is shown as **lines × players**: lines down the side, sections with their subtotals, and the score line (Total) at the bottom.
* Every entered line gets the entry sheet, with its own settings. For example, a habitat line could offer a 0–15 quick pick.
* The **Cascadia** template and its scenarios:
  * Wildlife: Bear, Elk, Salmon, Hawk, Fox (entered), Wildlife subtotal (calculated)
  * Habitats: Mountain, Forest, Prairie, Wetland, River, each a largest-corridor line and a majority-bonus line (entered), Habitats subtotal (calculated)
  * Nature tokens (entered)
  * Total (calculated, the score line)
* Card text keeps working: a template can still give lines score labels, sub labels, and badges.

### 5.5 Step 5 (Direction Only): Several Entered Lines With Rounds

Not built in this slice, but the design must not prevent it. Such a sheet is a lines × players grid for the selected round, plus a scorepad of each round's score line and the totals. Steps 2–4 should build the grid from lines, rounds, and players rather than assuming one of them is fixed, so step 5 only adds combining the two.

---

## 6. Out Of Scope

* step 5 itself (5.5)
* working out Cascadia's habitat majority bonuses from the corridor sizes (needs ranking functions with tie-splitting rules); they are entered by hand
* Cascadia's different wildlife scoring cards (A–D) and per-card scoring aids
* tie-breakers such as "most unused nature tokens"; a later small addition (for example a `tiebreak` line reference)
* icons or images for line labels; text labels only
* turning a marker's `badge` into a formula; revisited later
* moving Flip 7's "7!" to a score sub label (a post-slice test of 3.1)

---

## 7. Product And UX Rules For This Slice

### 7.1 Grid Shapes

| Sheet | Grid |
|---|---|
| No rounds | Lines down, players across, total at the bottom |
| Rounds, one entered line | Rounds down, players across, totals at the bottom (scorepad) |
| Rounds, several entered lines (later) | Lines × players for the selected round, plus a scorepad summary |

### 7.2 Column Headers Adapt To Column Width

Chosen from rendered mockups at phone width with 4 and 7 players:

* **Wide columns (about 64px or more): horizontal names**, up to two lines with an ellipsis, badges side by side underneath, wrapping to a second line when they don't fit.
* **Narrow columns: names angled at 45°**, rising to the right from the middle of the column, with badges **stacked vertically** under the name, one per line, so each stays in its own column.
* Fully rotated (90°) names were rejected as slow to read. Badges inline on the angled line were rejected because they drift over the next player's column. Dots were rejected because they need a tap to read.
* The header's height follows the most badges any player has in the selected round; it does not reserve room for badges that aren't there, which would usually be wasted space. If the grid moving when a badge appears turns out to be jarring on the phone, revisit.
* The player's colour underlines their header.
* Tapping a header can show the full name.

At a 360px-wide phone, horizontal headers fit about 4 players without scrolling, and angled headers about 6.

### 7.3 Cells

* A number, or a score label instead of it (sized to fit, so "Bust" fits a 46px cell), or a dash when nothing is entered yet.
* A score sub label in small text under the number.
* No badges in cells: badges are about the selected round and live in the header (3.1).

### 7.4 The Selected Round

* Highlighted in the grid; the round column shows its number in the accent colour.
* Tapping a row or cell selects it; headers then show that round's badges.
* The scoring screen's Previous Round / Next Round and the grid select the same round.

### 7.5 Nothing Changes For Existing Games Unless The Player Chooses The Sheet

Flip 7, Skyjo, Cornhole, Rack-O, Quick Score, and Round Score open in the player card view and play exactly as before.

---

## 8. Technical Decisions For This Slice

### 8.1 The Engine Already Covers Lines

`ScoreEngine.fieldValues` (to be renamed for lines) already returns every line's value for every player in a round, and `cardTexts` already returns each player's card text. The sheet view reads the same results; it adds no scoring logic.

### 8.2 One Grid Widget, Data-Driven

The sheet view is one widget built from three lists: row keys (rounds, or lines, or both), player columns, and a cell builder. The grid shapes in 7.1 differ only in which rows they list. This keeps step 5 an addition rather than a rewrite.

### 8.3 Fixed Row And Column Sizes

Rows and cells have fixed heights and column widths are computed once per layout, so card text never changes the grid's geometry. This follows the fix that keeps player cards the same height whatever their score shows.

### 8.4 Rendered Mockups Before Building UI

Layout choices are made from rendered mockups at phone width (real fonts and theme, through a throwaway widget test harness that writes a PNG), as was done for badges and headers. The harness is never committed.

---

## 9. Recommended Project Shape For Slice 12

```text
lib/
  application/models/scoring/
    entered_line_definition.dart     (was score_field_definition.dart)
    calculated_line_definition.dart  (was calculated_field_definition.dart)
    marker_line_definition.dart      (was marker_field_definition.dart)
    sheet_section.dart               (step 4)
  ui/
    score_sheet/
      score_sheet_grid.dart          (the grid: fixed column, scrolling players, fixed header and totals)
      sheet_column_header.dart       (horizontal or angled name, badges, colour)
      sheet_cell.dart                (number, score label, sub label, dash)
    round_score/round_score_flow_screen.dart   (view toggle, selected round)
    quick_score/quick_score_flow_screen.dart   (view toggle)

assets/templates/cascadia.json

test/
  ui/score_sheet/
  templates/scenarios/cascadia.json
```

---

## 10. Concrete Deliverables

1. Fields renamed to lines in one schema version, in the code, storage, templates, and docs, with no behaviour change.
2. A read-only sheet view: a scorepad for round games, a toggle between views, a selected round shared between them, and adaptive column headers.
3. An editable sheet view: tap a cell to enter or correct a value for any player, line, and round.
4. Several entered lines with sections and subtotals, shown as a lines × players grid.
5. The Cascadia template and scenarios.
6. One schema doc, `template_schema.md`: score sheet vocabulary, lines, headings and subtotals, `entryOrder`, the sheet view, and the card text rule in 3.1.

---

## 11. Suggested Build Sequence Inside The Slice

1. Rename fields to lines and collapse to one schema version (5.1); confirm every test and scenario passes unchanged in meaning.
2. Render mockups of the scorepad with the real theme, then build the grid widget with fixed and scrolling parts.
3. Column headers: horizontal and angled, with stacked badges and the width-based switch.
4. Wire the view toggle and the selected round into the round and quick score screens (read-only).
5. Make cells editable through the existing entry sheet, including past rounds.
6. Add headings and subtotals to the schema (5.4), then lift the one-entered-line rule.
7. Render mockups of the Cascadia sheet, then build the lines × players grid with sections and subtotals.
8. Write the Cascadia template and scenarios, and play a four-player game end to end in a widget test.

Step 1 is the safety check: the rename must leave every game scoring exactly as before.

---

## 12. Validation Rules

### 12.1 Runtime Validation

* Flip 7: toggle to the scorepad, see every round with "Bust" labels, select round 3 and see its badges in the headers, correct round 3's score and see totals and sorting update, toggle back to player cards on the same round
* 7 players: the scorepad scrolls sideways with the round column, headers, and totals fixed; headers switch to angled names
* Cascadia: score four players on the sheet view, with subtotals and the total updating as values are entered
* Existing games play exactly as before in the player card view

### 12.2 Architecture Validation

* no scoring logic in the grid; it reads the engine's line values and card text
* one grid widget serves every grid shape

### 12.3 Agent Workflow Validation

* a Cascadia-like template is written as data only (template and scenarios), and the validator explains any mistakes in its lines and sections

---

## 13. Risks To Watch During Slice 12

### 13.1 The Grid Is Cramped On A Phone

Risk:

Seven or more players, or Cascadia's many lines, make the grid hard to read or tap.

Response:

Minimum column widths, sideways scrolling with fixed headers and totals, angled names for narrow columns, landscape support, and mockups rendered at real phone width before building each layout.

### 13.2 Two Views Drift Apart

Risk:

A score, label, or badge differs between the player card view and the sheet view.

Response:

Both views read the same engine results (8.1), and widget tests check the same round in both views.

### 13.3 Editing Past Rounds Has Side Effects

Risk:

Correcting an earlier round leaves totals, sorting, or remembered tiles out of step.

Response:

Reuse the existing save path for a round's values; test totals, sorting, and card text after editing a past round.

### 13.4 Sections Over-Designed Before Cascadia Needs Them

Risk:

The section schema grows features (nested sections, collapsible groups, icons) that no game needs.

Response:

Keep to the decided shape (headings and subtotals, 5.4), taken from Cascadia's paper sheet, and add only what a game needs.

---

## 14. Decisions Made While Planning

| Question | Decision | Where |
|---|---|---|
| Section schema shape | Heading entries in the one ordered `lines` list; `"subtotal": true` on calculated lines | 5.4 |
| Keep schema versions 1 and 2? | No. One schema with `lines`, every template converted, no legacy support | 5.1 |
| Where the view toggle sits | Title bar, left of the sort button; last view remembered per game | 5.2 |
| Which cell Next moves to | Next player for one-entered-line sheets, next line for several; a template can override with `entryOrder` | 5.3 |
| Reserve header room for badges? | No; the header follows the badges in the selected round. Revisit if it's jarring | 7.2 |

---

## 15. Exit Decision After Slice 12

Once score sheets work, the next steps are likely:

* step 5, several entered lines with rounds, when a game needs it
* Cascadia's habitat majority bonuses worked out automatically (ranking functions with tie-splitting)
* tie-breakers
* revisiting marker badges as formulas, and Flip 7's "7!" as a score sub label
