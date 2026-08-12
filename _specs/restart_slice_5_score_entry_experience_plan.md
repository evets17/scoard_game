# Restart Slice 5 Plan: Score Entry Experience

## 1. Purpose

This document defines the next feature slice after the first quick score flow.

Its job is to improve how score fields are displayed and edited, while keeping the work grounded in the existing Quick Score flow.

This slice should strengthen the template-driven scoring direction by making score-entry behavior part of the score field definition rather than part of one hardcoded UI screen.

This plan should be read alongside:

* `score_input_ideas.md`
* `initial_overview.md`
* `restart_slice_4_quick_score_plan.md`
* `scoring_thoughts_examples.md`

---

## 2. Slice Goal

Improve score entry so that Quick Score can serve as the first proving ground for a reusable, field-driven score input experience.

This slice should allow the app to:

* define score-entry behavior on the score field object
* improve the touch-first score entry experience for Quick Score
* establish reusable interaction patterns that later built-in and custom templates can use

This slice is successful when Quick Score no longer depends only on a generic text-field approach and instead uses score-field-driven input behavior that can grow into richer templates later.

---

## 3. Why This Is Slice 5

This is the right next step because:

* the app already has one real scoring flow
* the score field model already exists
* the current score entry works, but is still generic and primitive
* the input brainstorming points toward a reusable interaction layer that should be built before more scoring modes multiply UI complexity

Using Quick Score as the proving ground keeps the slice small while still testing ideas that will matter across future templates.

---

## 4. Core Direction For This Slice

### 4.1 Quick Score Is The Host, Not The Whole Point

Quick Score is where the new score-entry behavior will first appear.

The real purpose of the slice is to establish reusable score-field UI behavior, not just to polish one screen in isolation.

### 4.2 Entry Behavior Is Field Metadata

Score input behavior should increasingly be defined by score-field metadata.

The score-entry screen should render according to those behaviors rather than assuming every entered score is a plain text box.

### 4.3 Touch-First Interaction Matters

Primary entry behavior should assume a mobile touch-first context.

That means large tap targets, fast adjustments, and avoiding unnecessarily awkward keyboard-heavy flows where a better touch interaction is available.

---

## 5. In Scope

The following work belongs in Slice 5.

### 5.1 Score Field Entry Metadata

Extend the score field model with the minimum additional properties needed to influence score-entry behavior.

Likely early properties:

* quick adjust enabled
* tap-to-edit enabled
* allowed values or constrained input mode where useful
* default entry mode hints if needed

### 5.2 Quick Adjust Interaction

Allow a score field to support direct increment and decrement controls when enabled.

This should feel fast and comfortable on touch devices.

### 5.3 Tap-To-Edit Score Display

Allow a score field to be displayed as a large tappable value rather than only as a plain input field.

This is especially relevant for the current Quick Score preset.

### 5.4 Value Picker Or Custom Numeric Entry

Introduce one more guided numeric entry path for touch use.

This does not need to become a full calculator system yet.

It should simply establish a cleaner reusable mechanism than raw text entry alone.

### 5.5 Replace vs Adjust Semantics

Begin distinguishing between:

* replacing the current score value
* adjusting the current score value by a delta

This distinction may appear in the field behavior or input action design even if Quick Score uses only a narrow part of it at first.

### 5.6 Quick Score Integration

Apply the new field-driven score-entry behavior to the built-in Quick Score preset.

Keep the user-facing flow simple while proving the architecture.

---

## 6. Out Of Scope

The following work should not enter Slice 5.

* formula engine
* template triggers or notifications
* game-specific auto-setting rules
* team scoring
* round scoring
* full enum scoring UI for games like chess unless it is needed immediately by a built-in preset
* full custom keyboard designer
* broad scoring-mode expansion

If these begin to enter the slice, the slice is drifting.

---

## 7. Product And UX Rules For This Slice

### 7.1 Speed Matters More Than Flexibility Theater

Score entry should feel faster and more touch-friendly after this slice.

Do not add configuration or interaction complexity unless it improves actual scoring use.

### 7.2 Scribe, Not Referee

The score-entry system may guide and assist, but it should not try to police the user.

Usability aids are welcome. Hard rule enforcement is not the goal.

### 7.3 One Good Numeric Flow Is Enough For Now

This slice should primarily improve numeric score entry first.

That gives the app a better input foundation without forcing it to solve every future field type at once.

### 7.4 Quick Score Should Still Feel Simple

Even if the field model becomes richer underneath, the built-in Quick Score experience should remain easy to understand and quick to use.

---

## 8. Technical Decisions For This Slice

### 8.1 Keep Input Behavior On The Field Definition

Do not define score-entry behavior purely inside the Quick Score screen.

The score field definition should increasingly describe how a field wants to be edited.

### 8.2 Prefer Reusable Score Input Components

Build reusable score-input widgets or interaction helpers rather than burying all behavior in one screen.

Examples may include:

* quick-adjust score row
* tappable score display
* numeric entry sheet or dialog

### 8.3 Preserve Entered Values And Result Separation

The new entry behavior should continue to feed field values, not bypass them.

Resolved results should still be derived from those values rather than becoming the primary input surface.

### 8.4 Allow Different Behaviors Per Field Later

The first implementation may only exercise one score field type, but the architecture should avoid assuming every field will always use the same entry interaction.

### 8.5 Start With Integer Behavior

The first target should remain integer numeric input.

Future support for enum, boolean, or richer field types should be informed by this slice, not solved fully inside it.

---

## 9. Recommended Project Shape For Slice 5

The following additions are likely appropriate:

```text
lib/
  application/
    models/
      scoring/
  ui/
    score_input/
      score_value_display.dart
      quick_adjust_controls.dart
      numeric_value_picker.dart
      score_entry_actions.dart
  ui/
    quick_score/
      quick_score_entry_screen.dart
```

The exact names may vary, but the separation should remain clear:

* score-field behavior metadata
* reusable score-input widgets
* one first application inside Quick Score

---

## 10. Concrete Deliverables

Slice 5 should ideally produce these concrete artifacts:

1. Expanded score-field behavior metadata.
2. At least one reusable score-input widget or interaction path.
3. Quick adjust support for the Quick Score preset if enabled.
4. A better tap-to-edit or guided numeric-entry path for Quick Score.
5. Tests covering the score-entry behavior where practical.

---

## 11. Suggested Build Sequence Inside The Slice

Implement Slice 5 in this order:

1. Extend the score-field model with minimal input-behavior metadata.
2. Define one reusable numeric score input/display component.
3. Add quick-adjust capability where enabled.
4. Add the guided tap-to-edit/value-picker path.
5. Integrate those behaviors into Quick Score.
6. Validate the runtime feel on touch-oriented targets.

This keeps the slice focused on score-entry behavior instead of broadening into additional scoring modes.

---

## 12. Validation Rules

At the end of Slice 5, validate the following:

### 12.1 Runtime Validation

* Quick Score score entry is faster and more touch-friendly than a plain text-field-only approach.
* A user can still enter, adjust, correct, and complete a score session without confusion.
* Existing persistence and result calculation still work unchanged from the user's perspective.

### 12.2 Architecture Validation

* Score-entry behavior is driven by score-field metadata rather than only by screen-specific assumptions.
* Reusable score-input components exist outside the one Quick Score screen.
* Entered values remain distinct from resolved results.

### 12.3 UX Validation

* Numeric entry feels natural on mobile.
* Quick adjust is helpful where enabled.
* The score display is readable and touchable.
* The flow still feels like Quick Score, not a complicated editor.

---

## 13. Risks To Watch During Slice 5

### 13.1 Input System Becomes Over-Abstract Too Early

Risk:

The team tries to fully solve every future field type and scoring interaction in one slice.

Response:

Start with integer numeric input and keep the behavior focused.

### 13.2 Quick Adjust Creates Hidden Complexity

Risk:

The user may not understand whether a score tap replaces a value or adjusts it.

Response:

Make the interaction model explicit and keep the first version narrow.

### 13.3 Screen-Specific Logic Creeps Back In

Risk:

Quick Score becomes the only place where the new input behavior works.

Response:

Keep the behavior attached to score-field metadata and reusable widgets.

### 13.4 Input Polish Delays Broader Product Progress

Risk:

The score-entry experience keeps absorbing refinements without a clear stopping point.

Response:

Define a clear “good enough” bar for Quick Score and stop once the field-driven pattern is proven.

---

## 14. Exit Decision After Slice 5

Once Slice 5 is complete, the next likely decisions are:

1. add another built-in scoring preset that benefits from the improved score-entry system
2. broaden score field types such as enum or boolean entry where a real scoring mode needs them
3. revisit player or setup behaviors only if the scoring experience exposes concrete friction

Default recommendation:

* if the score-entry system feels solid, add another scoring mode next
* only widen the generic template/input system further when a real use case demands it

The decision should be made after the improved Quick Score entry experience has been reviewed in real use.