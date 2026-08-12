# Restart Slice 6 Plan: Round Scoring Preset

## Status

Slice 6 is complete.

Implemented outcome:

* built-in Round Score preset added to Score a Game
* repeated round entry with cumulative totals
* lightweight round correction via previous/next round navigation
* manual Game Over completion
* local persistence for round values and resolved final results

Follow-up decision:

* a dedicated round-history review surface was intentionally moved out of Slice 6
* if added later, it should be treated as a follow-up UX enhancement rather than part of the core round-entry flow

## 1. Purpose

This document defines the next feature slice after the first Quick Score flow and score-entry behavior work.

Its job is to introduce the next built-in scoring preset:

* round-based scoring with cumulative totals

This slice should extend the current scoring architecture rather than creating a separate round-scoring subsystem.

This plan should be read alongside:

* `initial_overview.md`
* `scoring_thoughts_examples.md`
* `restart_slice_4_quick_score_plan.md`
* `restart_slice_5_score_entry_experience_plan.md`

---

## 2. Slice Goal

Implement a built-in round scoring flow that allows a user to:

* choose Score a Game from the landing page
* choose a built-in round-scoring option from the scoring chooser screen
* select players
* enter one score per player for each round
* see round totals and cumulative totals
* continue adding rounds until the players decide the game is over
* see the winner and final ranking
* save the completed result

Internally, this flow should be backed by a built-in round-scoring preset rather than a one-off special-case implementation.

This slice is successful when Scoard Game can support repeated score entry across rounds while preserving the same template-driven and result-driven architecture established by the earlier scoring slices.

---

## 3. Why This Is Slice 6

This is the right next step because:

* Quick Score already proves the base scoring path
* score field metadata and reusable score-input behavior now exist
* the next natural built-in preset is one where repeated rounds produce cumulative totals

It also tests the next important architectural step:

* repeatable scoring events inside one session
* cumulative result projection over time
* user-driven completion of a game that does not end after one score entry pass

---

## 4. Core Direction For This Slice

### 4.1 User-Facing Product Language

The user should see this as another simple way to score a game, not as an advanced template editor.

Possible user-facing language:

* Round Score
* Round Scoring

### 4.2 Internal Architecture Direction

Internally, this mode should be modeled as another built-in preset in the same template family as Quick Score.

That means:

* one preset registry
* another built-in scoring preset
* same score-field / session-value / resolved-result separation

### 4.3 Why This Matters

This keeps the scoring system cohesive:

* quick final score is one preset
* round scoring is another preset
* later running total or round tally can be added the same way

---

## 5. In Scope

The following work belongs in Slice 6.

### 5.1 Round Scoring Entry Point

* Add a built-in round-scoring choice to the Score a Game chooser.
* Give it a short explanatory blurb like other built-in presets.

### 5.2 Built-In Round Scoring Preset

* Define a built-in preset for one score field per player per round.
* Use highest-score-wins as the first default winner rule unless adding lowest-score-wins is nearly free.

### 5.3 Session Setup

* Reuse the existing player-selection flow.
* Reuse in-flow add-player where appropriate.

### 5.4 Round Entry

* Let the user enter one score per player for the current round.
* Reuse the improved score-entry behavior from Slice 5.
* Make it easy to complete one round and move to the next.

### 5.5 Round History In Session

* Keep correction lightweight within the active session.
* Allow users to move backward and forward across rounds without turning the main round-entry screen into a review dashboard.
* Defer any dedicated round-history grid or table view to a later slice if it proves useful.

### 5.6 Current Leader / Cumulative Result

* Compute cumulative totals after each round.
* Show the current leader clearly.

### 5.7 User-Driven Completion

* Let the user decide when the game is over.
* Do not force completion because of a built-in rule threshold in this slice.

### 5.8 Persistence

* Persist the round-scoring session locally.
* Persist per-round entered field values and a resolved current/final result model consistent with the existing architecture.

---

## 6. Out Of Scope

The following work should not enter Slice 6.

* round-tally scoring with multiple score elements per round
* game-specific formulas
* target-score triggered notifications
* fixed-round enforcement
* team scoring
* round label overrides such as “inning”
* variant-rule prompt variables
* advanced score aids such as entering cards or board state
* full running-total mode as a separate preset
* a dedicated round-history grid or table review surface

If these begin to enter the slice, the slice is drifting.

---

## 7. Product And UX Rules For This Slice

### 7.1 Keep Round Entry Fast

The core experience should be:

* enter a round
* review totals
* continue

It should not feel like bookkeeping overhead.

For this slice, correction should stay inside the round-entry flow rather than adding a separate review-heavy history panel.

### 7.2 User Still Determines Game Over

Following the restart philosophy, the user decides when to stop adding rounds.

The app records and calculates. It does not referee the end condition.

### 7.3 Corrections Stay Lightweight

If a round was entered incorrectly, the user should be able to go back and correct it without heavy lifecycle machinery.

### 7.4 Reuse Score Entry Behavior

Round scoring should prove that the Slice 5 input system is reusable beyond Quick Score.

---

## 8. Technical Decisions For This Slice

### 8.1 Use Another Built-In Preset, Not Another Engine

Round scoring should be introduced as another scoring preset in the built-in registry.

### 8.2 Keep Round Values And Resolved Totals Separate

Each round should store entered values by player.

Resolved cumulative totals and rankings should be derived from that series rather than treated as the only stored truth.

### 8.3 Introduce Repeatable Session Stages Lightly

The session model should gain enough structure to represent repeated rounds without becoming a full generalized workflow engine.

### 8.4 Prefer Simple Cumulative Calculation

For the first version, cumulative total should simply be the sum of round scores per player.

### 8.5 Keep Completion Manual

Do not implement threshold- or fixed-round-based automatic completion in this slice.

That can come later through richer preset behavior.

### 8.6 Design For Future Round Variants

Even though this slice is simple, it should set up the right footing for future extensions such as:

* fixed round counts
* threshold notifications
* low-score-wins
* round-level multiple fields

---

## 9. Recommended Project Shape For Slice 6

The following additions are likely appropriate:

```text
lib/
  application/
    models/
      scoring/
      sessions/
      results/
    services/
      scoring/
      sessions/
    repositories/
      session_repository.dart
  core/
    scoring/
      built_in_templates/
      calculations/
  ui/
    round_score/
      round_score_setup_screen.dart
      round_entry_screen.dart
      cumulative_result_view.dart
```

The exact names may vary, but the separation should remain clear:

* built-in preset definition
* round session state and values
* resolved cumulative results
* user-facing round entry and review UI

---

## 10. Concrete Deliverables

Slice 6 should ideally produce these concrete artifacts:

1. A built-in round-scoring preset visible in Score a Game.
2. A real round-scoring flow using saved players.
3. Round-by-round score entry.
4. Cumulative total calculation.
5. Current leader display.
6. Manual game-over completion.
7. Persistence for the full round session.
8. Tests covering cumulative calculation and/or persisted round data.
9. Lightweight round correction without a dedicated history screen.

---

## 11. Suggested Build Sequence Inside The Slice

Implement Slice 6 in this order:

1. Define the built-in round-scoring preset.
2. Define round session value models and resolved cumulative result models.
3. Extend session persistence for repeatable rounds.
4. Add the round-scoring option to the chooser registry.
5. Build setup/player selection reuse.
6. Build round entry for the current round.
7. Add cumulative totals and lightweight previous/next round correction.
8. Add manual game-over completion and final result view.
9. Validate the full round-scoring flow visually and with tests.

---

## 12. Validation Rules

At the end of Slice 6, validate the following:

### 12.1 Runtime Validation

* The Score a Game chooser shows the round-scoring option.
* Users can select players and begin a round-scoring session.
* Users can enter multiple rounds.
* Cumulative totals update correctly after each round.
* Users can move back to a previous round and adjust it.
* Users can manually end the game and see final ranking.
* The session persists across app restart.

### 12.2 Architecture Validation

* Round scoring is implemented as another built-in preset, not a special-case engine.
* Round values remain distinct from resolved cumulative/final results.
* Slice 5 score-entry behaviors are reused rather than duplicated.

### 12.3 UX Validation

* Entering a round is fast enough to repeat multiple times.
* The current leader and cumulative totals are easy to understand.
* Correction remains lightweight.

---

## 13. Risks To Watch During Slice 6

### 13.1 Round Scoring Starts Absorbing Round-Tally Scope

Risk:

The slice starts trying to solve per-round multi-field scoring and formulas too early.

Response:

Keep each round to one entered score field per player in this slice.

### 13.2 Completion Logic Becomes Rule-Heavy

Risk:

The implementation starts enforcing target thresholds or game-over rules.

Response:

Keep completion manual in the first version.

### 13.3 History And Review Become Too Heavy

Risk:

The session review UI grows into a full analytics/history subsystem.

Response:

Keep the active flow focused on entering and correcting rounds.

Treat any dedicated round-history table or review screen as a later enhancement only if it proves useful in practice.

### 13.4 Persistence Model Over-Grows

Risk:

The team tries to future-proof every possible round-scoring variant in one step.

Response:

Persist only what is required for simple repeated rounds and cumulative totals.

---

## 14. Exit Decision After Slice 6

Once Slice 6 is complete, the next likely decisions are:

1. add running total as another built-in preset
2. deepen round scoring with fixed rounds or low-score-wins if a real use case needs it
3. move toward round-tally scoring with multiple per-round score elements

Default recommendation:

* if round scoring feels solid, add another thin built-in preset next
* only move into richer round-tally/template logic when that need is clearly justified by real game use

The decision should be made after the round-scoring flow has been run and reviewed in context.