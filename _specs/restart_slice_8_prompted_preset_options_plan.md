# Restart Slice 8 Plan: Prompted Preset Options

## 1. Purpose

This document defines the next feature slice after active-session resume support.

Its job is to introduce prompted preset options: template-defined values that are collected from the user at session start and stored with the session.

This slice should establish a reusable prompt-definition and prompt-rendering system without trying to build a full template formula engine.

This plan should be read alongside:

* `scoring_thoughts_examples.md`
* `restart_slice_4_quick_score_plan.md`
* `restart_slice_6_round_scoring_plan.md`
* `restart_slice_7_active_sessions_plan.md`

---

## 2. Slice Goal

Implement preset-defined prompted options so a user can:

* choose a scoring preset such as Quick Score or Round Score
* answer one or more prompted options defined by that preset
* continue into the scoring flow with those chosen options applied
* have those chosen option values saved with the active or completed session

This slice is successful when Scoard Game can dynamically render a prompt UI from preset definitions and use those stored answers to drive at least one real scoring behavior.

The first proof case should be:

* `Low Score Wins` as a prompted boolean option

---

## 3. Why This Is Slice 8

This is the right next step because:

* the app now has multiple real scoring presets
* active sessions already persist session-specific state
* the scoring brainstorm direction points toward user-prompted template values
* multiplying built-in presets for every small variation would create avoidable duplication

It also tests the next important architectural step:

* presets can define session-start options
* the app can render those options dynamically
* session behavior can be resolved from stored option values rather than only static preset constants

---

## 4. Core Direction For This Slice

### 4.1 Prompt Definitions Are Universal

Prompted options should be modeled as a generic capability on scoring presets.

That means the system should support:

* prompt definitions on presets
* dynamic prompt UI built from those definitions
* storage of the user’s answers with the session

This generic capability should exist even if the first behavioral use of those answers is intentionally narrow.

### 4.2 Prompt Uses Stay Narrow In This Slice

Slice 8 should not attempt to implement a full variable or formula engine.

The first version should limit what prompt answers can affect.

Recommended first use:

* winner rule selection such as high-score-wins vs low-score-wins

Possible secondary use only if nearly free:

* storing an integer option such as `Play Until` even if it is not yet connected to trigger logic

### 4.3 Dynamic Prompt UI Should Not Be Hardcoded For One Case

Even if the first real prompt is only `Low Score Wins`, the UI should be constructed from preset prompt definitions rather than from a hardcoded screen for that one question.

That means:

* one boolean prompt renders correctly
* two boolean prompts render correctly
* a mixed set of boolean and integer prompts can be rendered by the same system if integer support is included in this slice

### 4.4 Resolved Session Config Is The Boundary

The user-facing preset definition is static.

The prompt answers create a resolved session configuration for that particular game session.

That resolved configuration should then drive the scoring flow and result calculation.

---

## 5. In Scope

The following work belongs in Slice 8.

### 5.1 Prompt Definition Model

Extend the preset model with the minimum structure needed to define prompted options.

Likely early prompt properties:

* option id
* display label
* help text or prompt text
* value kind
* default value
* required flag if needed

### 5.2 Prompt Value Types

Recommended initial types:

* boolean
* integer

If integer support makes the slice materially harder, boolean-only is acceptable for the first pass, but the preferred direction is to include both now because the rendering and storage shape should support more than one value type.

### 5.3 Dynamic Prompt UI

When a preset includes prompted options, selecting that preset should present a generated prompt step before player selection or score entry.

The UI should be built dynamically from the prompt definitions.

### 5.4 Stored Prompt Answers

Prompt answers should be stored with:

* active sessions
* completed sessions when relevant to interpreting the result

### 5.5 Resolved Winner Rule From Prompt Answers

Use prompt answers to drive at least one real behavior.

Primary proof case:

* a boolean prompt such as `Low Score Wins` can resolve the winner rule for Quick Score and Round Score

### 5.6 Quick Score Integration

Apply prompted options to the built-in Quick Score preset.

### 5.7 Round Score Integration

Apply prompted options to the built-in Round Score preset.

### 5.8 Active Session Compatibility

Active-session resume should preserve prompt answers and restore them as part of the session state.

---

## 6. Out Of Scope

The following work should not enter Slice 8.

* formula expressions
* user-authored variables
* conditional visibility rules driven by formulas
* trigger or notification engines
* arbitrary text interpolation systems
* full template authoring UI
* advanced option dependencies such as one prompt changing the presence of another

If these begin to enter the slice, the slice is drifting.

---

## 7. Product And UX Rules For This Slice

### 7.1 Prompting Should Feel Like Setup, Not Configuration Theater

Prompted options should be presented as simple session-start choices, not as a heavy settings workflow.

### 7.2 Keep Presets Understandable

The user should still feel like they are choosing a simple scoring mode such as Quick Score or Round Score.

Prompts are a lightweight extension of that choice, not a separate template-management activity.

### 7.3 Only Ask What Matters

Do not add prompts unless they clearly influence the scoring experience or session interpretation.

### 7.4 Prompt UI Must Scale To More Than One Question

Even if the first shipping preset uses only one meaningful option, the prompt screen should clearly support multiple prompts in a readable way.

---

## 8. Technical Decisions For This Slice

### 8.1 Add Prompt Definitions To Presets

The `ScoringPreset` model should grow to include prompt definitions.

These definitions should remain declarative and lightweight.

### 8.2 Keep Prompt Answers As Stored Session Data

Prompt answers are session-specific, not preset-specific.

They belong on active and completed session data, not as mutable global preset state.

### 8.3 Use A Resolver Layer For Behavior

Prompt answers should not directly mutate UI or calculations in ad hoc ways.

Instead, a resolver step should turn preset plus prompt answers into resolved session behavior such as:

* winner rule
* future optional config values

### 8.4 Avoid Full Variable Engine Vocabulary

Do not introduce formula parsing, evaluation, or generalized substitution in this slice.

That can come later if the app proves it needs it.

### 8.5 Active Session Schema Must Grow Carefully

Active session persistence should include prompted option answers without breaking resume behavior.

### 8.6 Completed Results Should Remain Interpretable

If a completed result depends on a prompted option such as low-score-wins, the session/result storage should preserve enough information to interpret that result correctly later.

---

## 9. Recommended Project Shape For Slice 8

The following additions are likely appropriate:

```text
lib/
  application/
    models/
      scoring/
        preset_prompt_definition.dart
        preset_prompt_kind.dart
        preset_prompt_answer.dart
        resolved_preset_options.dart
    services/
      scoring/
        resolve_preset_options.dart
  ui/
    preset_options/
      preset_options_screen.dart
      preset_prompt_renderer.dart
      boolean_prompt_field.dart
      integer_prompt_field.dart
```

The exact names may vary, but the separation should remain clear:

* prompt definitions on presets
* stored prompt answers
* resolved session behavior
* dynamic UI renderer for prompt definitions

---

## 10. Concrete Deliverables

Slice 8 should ideally produce these concrete artifacts:

1. Prompt definition support on scoring presets.
2. Dynamic prompt UI built from prompt definitions.
3. Prompt answer storage on active and completed sessions.
4. Resolved winner-rule support from prompt answers.
5. Quick Score proof of `Low Score Wins`.
6. Round Score proof of `Low Score Wins`.
7. Tests covering prompt rendering, storage, and resolved behavior.

---

## 11. Suggested Build Sequence Inside The Slice

Implement Slice 8 in this order:

1. Define prompt definition and prompt answer models.
2. Extend `ScoringPreset` to declare prompted options.
3. Define a small resolver that turns prompt answers into resolved session behavior.
4. Build the dynamic prompt UI for boolean and optionally integer prompts.
5. Insert the prompt step into preset selection flow.
6. Persist prompt answers with active sessions.
7. Persist prompt answers with completed sessions where needed.
8. Use `Low Score Wins` to drive winner rule resolution in Quick Score.
9. Reuse the same mechanism in Round Score.
10. Validate prompt collection, resume, and scoring behavior.

---

## 12. Validation Rules

At the end of Slice 8, validate the following:

### 12.1 Runtime Validation

* selecting a preset with prompted options shows a generated prompt step
* one boolean prompt renders correctly
* multiple prompts render correctly if defined on a preset
* prompt answers are preserved when resuming an active session
* Quick Score can use a prompt answer to switch between high-score-wins and low-score-wins
* Round Score can use a prompt answer to switch between high-score-wins and low-score-wins

### 12.2 Architecture Validation

* prompts are defined on presets, not hardcoded into one scoring screen
* prompt answers are stored as session data
* behavior is resolved from stored answers through a clear mapping layer
* no formula engine was introduced prematurely

### 12.3 UX Validation

* the prompt step feels lightweight
* the UI remains understandable when a preset has multiple prompts
* users do not need template terminology to use the feature

---

## 13. Risks To Watch During Slice 8

### 13.1 Generic Prompting Turns Into Formula Design Too Early

Risk:

The slice starts building a broad variable expression system because prompts feel related to variables.

Response:

Keep prompted options generic, but keep their meaning narrow in this slice.

### 13.2 UI Is Built For One Question Only

Risk:

The prompt screen is hardcoded around `Low Score Wins` and cannot scale to a second prompt without rework.

Response:

Render the prompt UI from definition lists from the start.

### 13.3 Prompt Answers Are Not Persisted Cleanly

Risk:

Active-session resume loses or misinterprets prompt answers.

Response:

Treat prompt answers as first-class session data.

### 13.4 Too Many Prompted Variants Hurt Simplicity

Risk:

Presets begin accumulating too many options and become confusing.

Response:

Only add prompts that clearly improve the session being scored.

---

## 14. Exit Decision After Slice 8

Once Slice 8 is complete, the next likely decisions are:

1. add another scoring variation using prompted options
2. connect integer prompt values to lightweight informational or notification behavior
3. decide whether formula-driven variables are justified by real use cases

Default recommendation:

* if prompted options feel solid, continue using them to avoid preset duplication
* only move into formulas, triggers, or conditional rules when those needs are repeatedly justified by real game templates

The decision should be made after using prompted options in real scoring sessions and reviewing whether the generic prompt system feels durable without being overbuilt.