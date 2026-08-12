# Restart Readme

## 1. Purpose

This document is the starting point for a fresh implementation of the Board Game Scoring Platform.

It explains which specs should be carried into the new solution, the order in which to read them, and the main lessons they capture from the first attempt.

---

## 2. Carry-Forward Spec Set

The restart pack consists of these documents:

1. `initial_overview.md`
2. `restart_technology_approach.md`
3. `restart_data_simplicity_principles.md`
4. `restart_iteration_and_mvp_principles.md`

These should be treated as the primary starting documents for the new solution.

---

## 3. Recommended Reading Order

## 3.1 Start With Product Intent

Read:

* `initial_overview.md`

Why:

* defines the product vision
* clarifies what kinds of scoring the platform should support
* distinguishes score tally workflows from full gameplay-sheet recreation
* establishes the long-term template direction

## 3.2 Then Read The Restart Technology Direction

Read:

* `restart_technology_approach.md`

Why:

* records the preferred restart footing
* explains why the new solution should be mobile-first but preview-friendly
* captures the Flutter/Dart leaning
* defines architectural boundaries such as repository-based persistence and async startup

## 3.3 Then Read The Data Simplicity Posture

Read:

* `restart_data_simplicity_principles.md`

Why:

* explains that this is a low-stakes scoring app
* keeps the product focused on direct editing and ease of use
* warns against heavy integrity, locking, and audit-history thinking
* sets the tone for correction, undo, and completion behavior

## 3.4 Then Read The Delivery And MVP Approach

Read:

* `restart_iteration_and_mvp_principles.md`

Why:

* explains how the new implementation should proceed in small visible slices
* prioritizes a runnable shell early
* encourages UI and interaction feedback before broad feature depth
* provides a practical sequence for early feature delivery

---

## 4. What Each Document Is Doing

### `initial_overview.md`

Defines what the product is.

### `restart_technology_approach.md`

Defines the technical footing and architecture posture for the restart.

### `restart_data_simplicity_principles.md`

Defines the product attitude toward editing, correction, and data complexity.

### `restart_iteration_and_mvp_principles.md`

Defines how the team should actually build and review the app in the new solution.

---

## 5. Main Restart Conclusions

The first implementation attempt clarified several important lessons:

1. The product itself still makes sense.
2. The first attempt became too coupled to platform-specific persistence too early.
3. The app should favor simple user-authoritative editing over strong integrity mechanics.
4. The new solution should become runnable and reviewable much earlier.
5. Fast preview and UI iteration are valuable even though the app is not web-first.

These conclusions should shape both architecture and delivery choices in the new project.

---

## 6. Recommended Starting Posture In The New Solution

When beginning the new solution, assume the following defaults:

* mobile-first product
* Flutter/Dart as the likely foundation
* desktop or browser preview used for fast design iteration
* repository-based persistence boundaries from day one
* async startup by default
* current-value-first editing model
* lightweight data-control semantics
* early runnable app shell before deeper feature breadth

If a later decision conflicts with these defaults, it should be a deliberate exception rather than an accidental drift.

---

## 7. Suggested First Implementation Sequence

Use the following rough sequence for the new solution:

1. create the project shell and basic preview/running path
2. establish the visual direction with a main menu or home shell
3. implement player management as an early real feature
4. implement one simple scoring flow
5. refine result display and lightweight correction behavior
6. expand into richer template-driven scoring only after these basics feel right

This sequence is intended to keep the new effort visible, reviewable, and easy to steer.

---

## 8. Historical Documents

Some older specs from the first attempt may still be useful as reference, but they should not drive the restart by default.

In particular:

* `technology_selection_criteria.md` reflects the earlier React Native and TypeScript direction
* iteration-specific implementation docs reflect assumptions from the first solution attempt

These can still provide useful product or data-model thinking, but they should be treated as reference material rather than the default restart guide.

---

## 9. Use Of This Document

If a new developer or coding agent joins the restarted effort, this document should be the first file they read.

Its job is to point them to the right specs before implementation begins.