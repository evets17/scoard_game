# Restart Slice 9 Plan: Templates As Data

## 1. Purpose

This document defines Slice A of the template system: moving scoring templates out of Dart code and into bundled, schema-validated data files.

Its job is to establish the foundation for the product vision goal that a game's scoring template can be written by an AI coding agent (or a developer) from the game's rules, checked automatically, and run without changing app code.

This slice changes the template's form, not the scoring experience. The quick score and round score screens should behave exactly as they do today.

This plan should be read alongside:

* `initial_overview.md` (sections 5.5, 8, 10, 16.3, 17, 18, 24.5)
* `scoring_thoughts_examples.md`
* `restart_slice_8_prompted_preset_options_plan.md`

---

## 2. Slice Goal

Implement bundled data templates so that:

* the existing Quick Score and Round Score modes become the first two templated "games"
* a new **Skyjo** template appears in Score a Game and plays through the existing round scoring screen
* every bundled template is validated against a versioned schema
* every bundled template ships with scoring scenarios that run as automated tests
* adding a new template that fits the existing scoring styles means adding data files only, with no Dart changes

This slice is successful when a third template (Skyjo) can be added as a data file plus a scenario file, passes validation and scenario tests, and appears and works in the app.

---

## 3. Why This Is Slice 9

This is the right next step because:

* the scoring experience (entry modes, sorting, rounds, resume) is now solid enough to build templates on
* templates are currently Dart constants, which means an agent must write code and the result cannot be schema-checked
* every later template capability (categories, formulas, validation rules, notifications) needs a data format, a validator, and a test runner to land in
* settling these foundations with today's small vocabulary is far cheaper than settling them alongside formulas and new screens

It also tests the agent workflow end to end at the smallest useful size:

* write a template file
* write its scenarios
* run validation and tests
* see the game in the app

---

## 4. Core Direction For This Slice

### 4.1 Built-In Modes Are Templates Too

Quick Score and Round Score are not special code paths with templates layered beside them. They are the first two templates, defined in the same format as any game template.

Their template IDs must stay `quick-final-score-basic` and `round-score-basic` so that saved games and active sessions keep resolving.

### 4.2 A Template Picks A Scoring Style, Not A Screen

Each template declares a scoring model. In this slice the vocabulary is:

* `finalScore` — one score per player, entered once (the quick score screen)
* `rounds` — one score per player per round, totals accumulate (the round score screen)

The app chooses the screen from the scoring model. Nothing outside the template layer should check template IDs.

### 4.3 The Schema Grows By Version, Not By Exception

Template files carry a `schemaVersion`. This slice defines version 1.

Later slices add vocabulary (fields, formulas, validation, notifications) by introducing new versions or additive keys, never by special-casing individual templates in code.

### 4.4 Strict Over Forgiving

The validator rejects unknown keys, wrong types, and unsupported values rather than ignoring them.

A misspelled key in an agent-written template should fail loudly at test time, not silently fall back to a default in the app.

### 4.5 Every Template Proves Itself

A template without scenarios does not pass. Scenarios are what catch a template that is valid but scores the game incorrectly (overview risk 24.5).

### 4.6 Formulas Are Decided, Not Built

Calculations will be expressed as formula strings such as `"{landmarks} * 3 + {bonus}"`, evaluated by a small, safe expression language. This decision is recorded here so the v1 format leaves room for it, but no formula evaluation is built in this slice.

---

## 5. In Scope

### 5.1 Template File Format

* JSON, one file per template, bundled as a Flutter asset
* location: `assets/templates/<template-id>.json`
* the file name must match the template `id`

JSON is chosen over YAML because Flutter reads it without new dependencies, it is unambiguous for agents to write, and formula strings fit naturally as values. YAML can be revisited if hand-authoring becomes common.

### 5.2 Schema Version 1 Vocabulary

Top level:

| Key | Required | Meaning |
|---|---|---|
| `schemaVersion` | yes | Must be `1` |
| `id` | yes | Lowercase kebab-case, unique across bundled templates, matches the file name |
| `version` | yes | Template version, `major.minor.patch` |
| `name` | yes | Shown in Score a Game and in game history |
| `description` | yes | One or two sentences shown in Score a Game |
| `source` | no | Where the scoring rules came from, for example the rulebook section or a URL |
| `players` | yes | `minimum` (required, at least 1) and `maximum` (optional, informational only) |
| `scoringModel` | yes | `finalScore` or `rounds` |
| `winner` | yes | `highestScore` or `lowestScore` |
| `prompts` | no | Questions asked at game start (see below) |
| `scoreField` | yes | The single entered score field (see below) |

`players.maximum` is informational. In keeping with the scribe-not-referee principle, the app does not block games with more players.

`prompts` entries:

| Key | Required | Meaning |
|---|---|---|
| `id` | yes | Unique within the template |
| `type` | yes | `boolean` or `integer` |
| `label` | yes | Prompt label |
| `help` | no | Prompt helper text |
| `default` | no | Must match `type` |
| `effect` | no | What the answer changes. v1 supports `lowScoreWins` (boolean only) |

`scoreField`:

| Key | Required | Meaning |
|---|---|---|
| `id` | yes | Stored with every saved score; must not change between template versions |
| `label` | yes | Field label |
| `initialValue` | no | Starting integer value |
| `minimumDisplayDigits` | no | Score display width, default 1 |
| `entry` | no | `tapToEdit`, `quickAdjust`, `replace`, `adjust` booleans |

Version 1 deliberately supports exactly one integer score field, because that is what both existing screens support. Multiple fields arrive with category scoring in Slice B.

Illustrative Skyjo template:

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

The "game ends at 100" rule is not modeled in this slice. Notifications arrive in Slice C.

### 5.3 Template Loading

* templates are discovered from the asset manifest under `assets/templates/`
* they are loaded, parsed, and validated once during app startup
* the resulting catalog is held in memory and looked up synchronously, replacing `getBuiltInScoringPresetById` and `builtInScoreGamePresets`
* parsed templates produce the existing `ScoringPreset` model, so the scoring screens and calculations are unchanged

### 5.4 Template Validator

A pure Dart validator, usable from the app and from tests, that reports every problem found with a path, for example `prompts[0].effect: unsupported value "doubleScores"`.

Version 1 checks:

* supported `schemaVersion`
* required keys present, with correct types
* no unknown keys at any level
* `id` format and file-name match
* `version` format
* `players.minimum` at least 1, and `maximum` not below `minimum`
* `scoringModel`, `winner`, prompt `type`, and prompt `effect` are known values
* prompt IDs unique, and `default` matches `type`
* `lowScoreWins` effect only on boolean prompts
* entry flags are booleans and `minimumDisplayDigits` is at least 1
* template IDs unique across the bundled catalog

### 5.5 Invalid Templates At Runtime

* in debug builds, an invalid bundled template fails startup with the validator's messages
* in release builds, an invalid template is left out of the catalog and the rest of the app works

Bundled templates are validated by tests, so the release fallback should never be needed; it exists so one bad file cannot take the whole app down.

### 5.6 Scenario Files And Test Runner

* every template has a scenario file at `test/templates/scenarios/<template-id>.json`
* scenario files are test data only and are not bundled into the app
* a single test file loads every bundled template, validates it, and runs its scenarios through the real calculation code

Scenario format:

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

* `finalScore` templates use `"scores": { ... }` instead of `rounds`
* `prompts` may be given per scenario, for example `{ "low-score-wins": true }`
* `expected` may include `totals`, `winners`, and `placements`
* the runner fails if a template has no scenario file, if a scenario file names an unknown template, or if any scenario has no expectations

### 5.7 Score A Game Lists The Catalog

* Score a Game lists every template in the catalog: Quick Score, Round Score, and Skyjo
* selecting one opens the screen for its scoring model, with its prompts if it has any
* history and active games show the template `name`, so a Skyjo game is recorded as "Skyjo"

### 5.8 Schema Reference Document

A short reference, `_specs/template_schema_v1.md`, listing every key, allowed value, and validator rule, with the Skyjo example. This is the contract an agent writes against. Fuller agent instructions are Slice D.

---

## 6. Out Of Scope

* multiple score fields, sections, or categories (Slice B)
* formula evaluation and calculated fields (Slice B)
* field validation rules such as minimum, maximum, or allowed values (Slice C)
* prompts used as formula variables, and notifications such as "100 reached" (Slice C)
* round labels such as "Inning" (later)
* templates loaded or imported at runtime, or a template catalog service (Phase 4)
* recording the template version with each saved game (revisit when a template change would alter how old games read)
* a JSON Schema file for editors (the Dart validator is the single source of truth)
* teams

---

## 7. Product And UX Rules For This Slice

### 7.1 Nothing Changes For Existing Games

Quick Score and Round Score look, behave, and save exactly as before. Saved and in-progress games keep resuming.

### 7.2 Templates Are Games In The UI

The person choosing what to score sees game names ("Skyjo") and short descriptions, not schema terms like "scoring model".

### 7.3 Keep Score A Game Scannable

With three entries a plain list is fine. Search, favorites, and grouping wait until the catalog is large enough to need them.

---

## 8. Technical Decisions For This Slice

### 8.1 Parse Into The Existing Model

The parser produces `ScoringPreset`, `ScoreFieldDefinition`, and `PresetPromptDefinition`. Screens and calculations keep depending on those models, which keeps this slice's blast radius small.

### 8.2 Map Effects In One Place

Prompt `effect` values map to the existing `PresetPromptBehavior`, in the parser only. `resolvePresetOptions` is unchanged.

### 8.3 Catalog Is Loaded Before The App Shell

`AppBootstrap.initialize` loads the catalog and places it in `AppEnvironment`. Code that currently calls `getBuiltInScoringPresetById` receives the catalog instead of reaching for a global.

### 8.4 Route From The Scoring Model

`ScoreGameScreen._routeForPreset` is replaced by a lookup on the template's scoring model. No code outside the template layer checks template IDs.

### 8.5 Test Code Reads Assets From Disk

The scenario test runner reads template files from `assets/templates/` directly, so it exercises the same files the app bundles.

---

## 9. Recommended Project Shape For Slice 9

```text
assets/
  templates/
    quick-final-score-basic.json
    round-score-basic.json
    skyjo.json

lib/
  application/
    models/scoring/
      scoring_model.dart              (finalScore | rounds)
    repositories/
      template_repository.dart
  core/
    templates/
      template_parser.dart            (JSON -> ScoringPreset)
      template_validator.dart         (JSON -> list of problems)
      template_catalog.dart           (in-memory, synchronous lookup)
  infrastructure/
    templates/
      bundled_template_repository.dart (asset manifest + rootBundle)

test/
  core/templates/
    template_validator_test.dart
    template_parser_test.dart
  templates/
    template_scenarios_test.dart
    scenarios/
      quick-final-score-basic.json
      round-score-basic.json
      skyjo.json

_specs/
  template_schema_v1.md
```

`lib/core/scoring/built_in_templates/` is removed once nothing references it.

---

## 10. Concrete Deliverables

1. Schema version 1 defined in `_specs/template_schema_v1.md`.
2. Template validator with path-based error messages and unit tests for each rule.
3. Template parser producing the existing preset models.
4. Template catalog loaded at startup from bundled assets.
5. Quick Score and Round Score converted to JSON with unchanged IDs.
6. Skyjo template.
7. Scenario files for all three templates and a runner that tests every bundled template.
8. Score a Game listing the catalog and routing by scoring model.
9. Old built-in Dart presets removed.

---

## 11. Suggested Build Sequence Inside The Slice

1. Write `template_schema_v1.md` so the format is settled before code.
2. Build the validator test-first against hand-written good and bad JSON.
3. Build the parser and check that parsing the converted Quick Score and Round Score JSON produces presets equal to today's Dart constants.
4. Build the scenario runner and scenario files for the two existing templates.
5. Add the bundled repository and catalog, wire them through bootstrap, and replace every `getBuiltInScoringPresetById` call.
6. Switch Score a Game to the catalog and scoring-model routing.
7. Delete the Dart presets.
8. Add Skyjo as data only (template and scenarios), as the proof that no code change is needed.
9. Resume a game saved before the change to confirm compatibility.

Step 8 is the slice's real test. If adding Skyjo requires touching Dart, the format or wiring is not done.

---

## 12. Validation Rules

### 12.1 Runtime Validation

* the app starts with all three templates in Score a Game
* Quick Score and Round Score play, save, and resume as before
* Skyjo plays through the round screen with lowest total winning
* an in-progress Round Score game saved before the change resumes after it

### 12.2 Architecture Validation

* no Dart code outside `core/templates` refers to specific template IDs
* adding Skyjo touched only `assets/templates/skyjo.json` and `test/templates/scenarios/skyjo.json`
* the validator rejects unknown keys, and a test proves it

### 12.3 Agent Workflow Validation

* using only `template_schema_v1.md` and the existing examples, an agent can write a new `rounds` or `finalScore` template plus scenarios that pass on the first or second attempt
* validator messages are specific enough to fix a broken template without reading Dart code

---

## 13. Risks To Watch During Slice 9

### 13.1 The Schema Is Designed For Slice B Too Early

Risk:

Version 1 grows sections, formulas, and validation keys "while we are here".

Response:

Version 1 describes what the app can actually do today. Anything else waits for the slice that builds it.

### 13.2 Saved Games Stop Resolving

Risk:

A changed template ID or score field ID breaks resume or history for existing games.

Response:

Keep the existing IDs, and include a compatibility check in the build sequence.

### 13.3 Async Loading Spreads Through The UI

Risk:

Loading templates from assets turns synchronous preset lookups into futures across many screens.

Response:

Load once at startup and hand a synchronous catalog to the rest of the app.

### 13.4 Scenarios Become A Formality

Risk:

Scenario files exist but only check trivial cases, so a mis-scored template still passes.

Response:

Each template's scenarios must cover its winner rule, any prompt effects, and at least one tie.

---

## 14. Exit Decision After Slice 9

Once Slice 9 is complete, the next likely decisions are:

1. start Slice B (category scoring with formula-calculated totals) using a real end-game category game as the proof case
2. add more `rounds` and `finalScore` games as data, to learn where the v1 vocabulary falls short
3. decide whether template versions should be recorded with saved games

Default recommendation:

* move to Slice B, since multiple fields and formulas are what most real games need, and use the games added along the way to shape its vocabulary
