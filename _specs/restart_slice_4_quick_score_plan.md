# Restart Slice 4 Plan: Quick Score As Built-In Template

## 1. Purpose

This document defines the next feature slice after local persistence.

Its job is to implement the first real scoring flow for Scoard Game while establishing a durable scoring direction:

* user-facing quick score remains simple
* internally, the flow is treated as a built-in template

This allows the restart to move into scoring without splitting the app into separate "quick mode" and "template mode" architectures.

This plan should be read alongside:

* `initial_overview.md`
* `restart_readme.md`
* `restart_iteration_and_mvp_principles.md`
* `restart_technology_approach.md`
* `restart_slice_2_player_management_plan.md`
* `restart_slice_3_local_persistence_plan.md`

---

## 2. Slice Goal

Implement a first scoring flow that allows a user to:

* choose Score a Game from the landing page
* choose a built-in scoring option from a scoring chooser screen
* choose saved players
* add a missing player from within the flow if needed
* enter one final score per player
* see the winner and ranking
* save the completed result

Internally, this flow should be backed by a built-in base template rather than by a one-off special-case scoring engine.

This slice is successful when Scoard Game can record and save a real finished game result using one thin, reviewable scoring flow.

---

## 3. Why This Is Slice 4

This is the right next step because:

* Players now exist and persist
* theme and startup footing are settled
* the app can finally move toward its actual product purpose

It also creates the best next architectural proof point:

* the app can support a real scoring interaction
* built-in quick modes can still be modeled as templates internally
* later custom templates can begin from the same base structure rather than from a separate subsystem

---

## 4. Scoring Direction For This Slice

### 4.1 User-Facing Product Language

The landing page should stay task-oriented with a concept such as:

* Score a Game

Inside that area, the user should then see built-in scoring choices such as:

* Quick Score

The app should not force template terminology into the main user flow for this slice.

### 4.2 Internal Architecture Direction

Internally, quick score should be modeled as a built-in template or preset.

That means the app should move toward this posture:

* every scoring mode is a template internally
* some templates are first-party built-in presets
* future custom templates can start from those built-in presets

### 4.3 Why This Matters

This avoids a brittle split such as:

* quick score uses one scoring architecture
* custom templates use another

Instead, it creates one scoring-definition direction with different levels of richness.

---

## 5. In Scope

The following work belongs in Slice 4.

### 5.1 Quick Score Entry Point

* Replace the current placeholder scoring entry with a real Score a Game path.
* Keep the landing-screen entry task-oriented and obvious.
* Add a simple scoring chooser screen that presents built-in scoring options.

### 5.2 Minimal Scoring Template Model

* Introduce the smallest internal template or preset representation needed to back quick final score.
* Model the built-in quick score flow as one base template.
* Represent the quick score input as a field list, even though the first built-in preset contains only one score field per player.
* Avoid generalized template authoring or loading systems in this slice.

### 5.3 Session Setup

* Let the user choose players for the session.
* Support selecting saved players.
* Support invoking the reusable add-player flow from within session setup.

### 5.4 Final Score Entry

* Let the user enter one final numeric score per player.
* Support positive and negative numbers.
* Keep the input flow fast and legible.

Even though the first preset has one entered score value, that value should still be treated as one score field object in the underlying template structure rather than as a special primitive-only shortcut.

### 5.5 Result Calculation

* Determine winner and ranking for highest-score-wins as the default first rule.
* Support ties at a basic level.
* Produce a resolved final result per player that can be used consistently by ranking, persistence, and later history/statistics.

### 5.6 Result Display

* Show the completed result clearly.
* Make it easy to see who won and what each player scored.

### 5.7 Persistence

* Persist the created quick score session locally.
* Persist entered field values separately from resolved player results.
* Keep the storage boundary consistent with the repository-based architecture.

---

## 6. Out Of Scope

The following work should not enter Slice 4.

* full template editor UI
* template copying UX
* custom template persistence beyond the built-in preset path
* round scoring
* running totals
* category-based end-game tallying
* game-specific formulas
* tie-break configuration UI
* low-score-wins variant unless it is nearly free to support internally
* session history browsing beyond what already exists or is minimally needed

If these begin to enter the slice, the slice is drifting.

---

## 7. Product And UX Rules For This Slice

### 7.1 Keep Quick Score Simple

The user experience should feel like a fast score-entry mode, not like a template-management feature.

### 7.2 Reuse Player Flows In Context

If the user realizes a player is missing during setup, they should be able to add that player from within the quick score flow.

The flow should reuse the existing add-player path rather than forcing a detour back to Player Management.

### 7.3 One Thin Scoring Flow Is Enough

This slice should prove one complete scoring experience, not a family of scoring systems.

### 7.4 Correction Should Stay Lightweight

Score entry should follow the restart simplicity posture:

* edit directly
* overwrite current value
* recompute result

Do not build heavy completion or correction machinery.

---

## 8. Technical Decisions For This Slice

### 8.1 Use A Built-In Template Preset

The first quick score flow should be backed by a built-in scoring preset such as:

* `quick-final-score-basic`

This preset may be represented in Dart objects at first rather than in a full external declarative file format.

Built-in presets should be surfaced through one registry or listing rather than being hardcoded separately in each UI surface.

### 8.2 Keep The Template Model Minimal

The first internal template model only needs enough vocabulary to support quick final score.

Possible early concepts:

* template ID
* display name
* scoring mode
* winner rule
* score fields

Do not build a broad generic schema in this slice.

Each score field should be represented as an object rather than as a primitive type token alone.

That object can start small, but it should be able to grow later.

Possible early score-field concepts:

* field ID
* label
* input kind
* whether the field is entered or derived
* whether the field contributes to the final result

### 8.3 Separate Session Data From Template Definition

The built-in template defines the scoring structure.

The session stores the players and the per-field entered values.

The resolved result stores the final comparable outcome used by winner/ranking/history logic.

Keep those concerns separate from the start.

For the first quick-score preset, this means:

* template: one score field object
* session values: one entered value for that field per player
* resolved result: one final numeric result per player

### 8.4 Preserve Repository Boundaries

Add repository contracts and persistent adapters for session/result storage without leaking storage details into UI.

Persisted session field values and persisted resolved results should remain distinct storage concerns even when the first preset only has one score field.

### 8.5 Let This Inform Future Template Copying

Even though template copying is out of scope now, the built-in preset should be modeled so that future custom templates could plausibly start from the same base definition.

### 8.6 Distinguish Entered Fields From Resolved Results

Do not assume that every future scoring mode is best represented only as one stored final score value.

Many future templates may include:

* multiple entered fields
* derived totals
* bonuses or penalties
* tie-break values
* non-numeric inputs that still contribute to a final outcome

This slice should therefore establish a clear distinction between:

* score field definitions in the template
* field values entered or derived during the session
* resolved player result used for ranking and persistence consumers

### 8.7 Keep The First Preset Simple Without Making It Special

The first quick-score preset only has one entered score field per player.

That is simple by quantity, not different by architecture.

The implementation should avoid creating a completely separate data model just because the first preset has only one score field.

---

## 9. Recommended Project Shape For Slice 4

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
  infrastructure/
    persistence/
      repositories/
        persistent_session_repository.dart
  ui/
    quick_score/
      quick_score_setup_screen.dart
      quick_score_entry_screen.dart
      quick_score_result_screen.dart
      quick_score_player_picker.dart
  core/
    scoring/
      built_in_templates/
```

The exact names may vary, but the separation should remain clear:

* built-in scoring preset definition
* score field and session value models
* resolved result models
* session/result application logic
* persistent storage adapter
* user-facing quick score screens

---

## 10. Concrete Deliverables

Slice 4 should ideally produce these concrete artifacts:

1. A real Quick Score flow reachable from the landing screen.
2. A Score a Game chooser screen that presents built-in scoring options.
3. One built-in quick-score preset modeled as an internal template.
4. A built-in preset registry or equivalent shared listing.
5. Player selection for a new score session.
6. In-flow add-player reuse.
7. Final score entry per player.
8. Result calculation and display.
9. Local persistence for the created session, including entered field values and resolved results.
10. Automated tests covering at least part of the scoring logic and/or persistence.

---

## 11. Suggested Build Sequence Inside The Slice

Implement Slice 4 in this order:

1. Define the minimal built-in quick-score preset model.
2. Create a shared registry or listing for built-in scoring presets.
3. Define score field, session value, and resolved result models.
4. Add session repository contracts and persistent storage footing.
5. Build the Score a Game chooser screen.
6. Build quick score session setup with player selection.
7. Reuse add-player in that setup flow.
8. Build the final score entry screen.
9. Add result calculation and result screen.
10. Persist and reload both entered field values and the created result.
11. Validate the full flow visually and with tests.

This keeps the slice grounded in one real vertical path instead of spreading into template infrastructure too broadly.

---

## 12. Validation Rules

At the end of Slice 4, validate the following:

### 12.1 Runtime Validation

* The Score a Game entry point opens from the landing screen.
* The scoring chooser screen presents the built-in Quick Score option.
* Saved players can be selected for a session.
* A missing player can be added from within the flow.
* Final scores can be entered for all selected players.
* A result screen shows the winner and ranking.
* The result remains after app restart.

### 12.2 Architecture Validation

* Quick score is backed by a built-in preset/template model rather than by a one-off special-case engine.
* Built-in scoring options come from a shared registry or equivalent listing.
* Session/result persistence stays behind repository boundaries.
* Entered field values are persisted separately from resolved results.
* Player creation remains reusable rather than being duplicated inside scoring code.

### 12.3 UX Validation

* The flow is understandable without template terminology.
* Score entry is quick enough to feel distinct from a more complex future scoring mode.
* Correction is lightweight and direct.

---

## 13. Risks To Watch During Slice 4

### 13.1 Quick Score Becomes A Dead-End Special Case

Risk:

The first scoring flow is implemented in a way that cannot evolve into the future template direction.

Response:

Back it with a built-in preset model from the start.

### 13.2 Template Ambition Bloats The Slice

Risk:

The team tries to solve custom templates, full schema design, and template editing before one scoring flow is working.

Response:

Keep the template model minimal and internal for this slice.

### 13.3 Player Setup Becomes Friction Heavy

Risk:

The scoring flow becomes cumbersome because player selection and creation are awkward.

Response:

Reuse the add-player path and keep setup fast.

### 13.4 Session Persistence Scope Expands Too Broadly

Risk:

The slice starts trying to persist every future scoring concept.

Response:

Persist only what is required for one quick final score session and result.

---

## 14. Exit Decision After Slice 4

Once Slice 4 is complete, the next likely decisions are:

1. expand scoring by adding another built-in preset such as running total or result-only
2. deepen player capability only if the scoring flow exposes a concrete need
3. begin formalizing the next layer of internal template representation

Default recommendation:

* if the quick-score preset feels sound, continue outward by adding another thin scoring mode
* only broaden player-management or template infrastructure when the scoring flows prove that need

The decision should be made after the quick score flow has been run and reviewed in context.