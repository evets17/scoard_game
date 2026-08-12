# Restart Slice 1 Plan: Flutter Shell

## 1. Purpose

This document defines the first implementation slice for the restarted Board Game Scoring Platform.

It is intentionally narrow.

Its job is to establish a runnable Flutter application shell and prove the most important restart architecture decisions without pulling in broader feature scope.

This plan should be read alongside:

* `restart_readme.md`
* `restart_technology_approach.md`
* `restart_iteration_and_mvp_principles.md`
* `restart_data_simplicity_principles.md`

---

## 2. Slice Goal

Create a runnable Flutter app shell that:

* starts through an asynchronous bootstrap path
* renders a branded home screen and basic navigation shell
* depends on repository interfaces rather than storage details
* runs against an in-memory adapter
* is reviewable quickly on a development preview surface

This slice is successful when the restart has a living product shell rather than only specifications.

---

## 3. Why This Is Slice 1

This slice directly supports the restart lessons:

* get to a runnable product shell early
* keep architecture boundaries visible from day one
* avoid immediate coupling to a production persistence stack
* enable fast UI review before deeper feature work

It is intentionally more about footing than feature breadth.

---

## 4. Success Criteria

Slice 1 should be considered complete when all of the following are true:

1. A Flutter project exists and runs successfully.
2. App startup flows through an asynchronous bootstrap step.
3. The app opens to a home screen with intentional visual direction rather than a default scaffold look.
4. The home screen exposes placeholder navigation targets for the next feature areas.
5. Repository interfaces exist for the first application-facing data needs.
6. An in-memory implementation is wired into the app through composition rather than direct imports from UI code.
7. UI code consumes application-facing models, not persistence shapes.
8. The shell can be previewed quickly on at least one non-emulator development surface.

---

## 5. In Scope

The following work belongs in Slice 1.

### 5.1 Project Scaffold

* Create the Flutter project.
* Set up the initial package structure.
* Confirm the app runs on the primary local development path.

### 5.2 Async Bootstrap

* Add an application bootstrap path that can initialize dependencies asynchronously.
* Avoid any assumption that repositories or storage are synchronously available.
* Keep startup simple, but make the async boundary explicit.

### 5.3 Initial Architecture Seams

* Create the first high-level module boundaries.
* Define repository interfaces in the application layer.
* Add an in-memory infrastructure implementation.
* Compose dependencies at app startup.

### 5.4 App Shell UI

* Create a branded home screen.
* Create a simple main menu or shell layout.
* Add placeholder routes or screens for likely next areas such as players, quick score, history, and settings.
* Establish the first visual language for spacing, typography, and buttons.

### 5.5 Minimal Application Models

* Define only the application-facing models needed to render the shell.
* Keep them independent from future database-row or serialization concerns.

### 5.6 Previewability

* Ensure the shell can be reviewed quickly outside the slowest emulator-only loop.
* Choose one primary fast preview surface for development, such as Windows desktop or browser.
* Treat that preview surface as a development aid, not as a change in product target.

---

## 6. Out Of Scope

The following work should not enter Slice 1.

* real player management behavior
* real scoring flows
* local database implementation
* cloud sync
* account handling
* statistics
* template engine or generalized dynamic template rendering
* rich session lifecycle rules
* full persistence schema design
* production-grade navigation depth

If any of these begin to enter the slice, the slice is drifting.

---

## 7. Technical Decisions For This Slice

### 7.1 Use Flutter And Dart Immediately

Do not spend Slice 1 re-evaluating the foundation.

Use Flutter and Dart as the working restart default.

### 7.2 Establish The Architecture Boundary Now

Do not postpone repository interfaces until after feature work begins.

The first shell should already demonstrate:

* application-layer contracts
* infrastructure-layer implementation swapping
* UI isolation from infrastructure details

### 7.3 Use In-Memory Repositories First

The first concrete adapter in this slice should be in-memory.

That keeps the shell easy to run, easy to test, and easy to preview.

### 7.4 Defer Real Local Persistence One Slice

This slice should establish the seam for persistent storage without implementing the actual local database adapter yet.

That adapter should arrive in the next slice or very soon after, before the app gains substantial feature depth.

### 7.5 Keep The Home Screen Intentional

Avoid shipping the default counter-app feel.

The shell should already begin expressing:

* product tone
* navigation rhythm
* spacing rules
* primary actions
* placeholder information hierarchy

### 7.6 Keep State Simple

Use only the minimum state management needed for the shell.

Do not introduce broad state machinery unless the shell actually requires it.

---

## 8. Recommended Project Shape For Slice 1

The slice should begin with a structure like this:

```text
lib/
  main.dart
  bootstrap/
    app_bootstrap.dart
    app_environment.dart
  core/
    shared/
  application/
    models/
    repositories/
    services/
  infrastructure/
    memory/
  ui/
    app/
    home/
    navigation/
    theme/
```

Purpose of each area:

* `bootstrap/`: app composition and async startup
* `core/`: shared pure code that does not depend on Flutter UI or storage
* `application/`: repository interfaces, simple services, and app-facing models
* `infrastructure/`: concrete adapter implementations, starting with in-memory
* `ui/`: screens, widgets, theme, and navigation

This structure is only deep enough to support Slice 1.

---

## 9. Concrete Deliverables

Slice 1 should ideally produce these concrete artifacts:

1. A Flutter project committed to the repository.
2. A startup path that awaits dependency setup before rendering the main app.
3. A dependency-composition point that registers repository implementations.
4. An in-memory repository package or module for the first shell data.
5. A home screen with branded layout and placeholder destination cards or actions.
6. Placeholder screens for likely next slices.
7. A lightweight theme foundation with colors, typography, spacing, and button treatment.
8. At least one basic automated test covering bootstrap or dependency composition.

---

## 10. Suggested Build Sequence Inside The Slice

Implement Slice 1 in this order:

1. Create the Flutter project.
2. Replace the default starter app with a minimal custom app root.
3. Add async bootstrap and dependency composition.
4. Define initial repository interfaces and in-memory implementations.
5. Build the home shell UI and placeholder routes.
6. Add the first theme tokens and core shell components.
7. Add a small automated validation for bootstrap or composition behavior.
8. Run the shell on the chosen preview surface and adjust the UI until it is reviewable.

This order keeps the slice visible early while still establishing the correct seams.

---

## 11. Validation Rules

At the end of Slice 1, validate the following:

### 11.1 Runtime Validation

* The app launches successfully.
* The bootstrap path is asynchronous and stable.
* The shell renders without requiring a production database package.
* Navigation between placeholder destinations works.

### 11.2 Architecture Validation

* UI screens do not import infrastructure implementation types directly.
* Repository usage flows through application-layer contracts.
* In-memory adapters can be swapped at the composition boundary.

### 11.3 Review Validation

* The shell is visually coherent enough to discuss.
* The home layout communicates likely product direction.
* The next slice can build on the shell without reworking startup.

---

## 12. Risks To Watch During Slice 1

### 12.1 Scaffold Drift

Risk:

The slice quietly expands into player management, scoring, or persistence design.

Response:

Keep the shell thin and stop when the architecture seam and home flow are proven.

### 12.2 Accidental Persistence Coupling

Risk:

UI or application services begin depending on a storage library because it feels convenient.

Response:

Require repository interfaces before any concrete data dependency enters UI flows.

### 12.3 Default-Looking UI

Risk:

The shell technically runs but does not provide useful design feedback because it still feels like scaffold output.

Response:

Give the home screen enough visual intent to evaluate product tone and navigation shape.

### 12.4 Over-Engineering The Shell

Risk:

The slice builds elaborate domain or template abstractions before any real screen exists.

Response:

Add only the abstractions needed to support the shell and the immediate next slice.

---

## 13. Exit Decision For Slice 2

Once Slice 1 is complete, choose Slice 2 based on what the shell reveals.

The most likely next choices are:

1. add local persistence beneath the established repository interfaces
2. build player management as the first real vertical feature

Default recommendation:

* if the architecture seam still feels uncertain, do local persistence next
* if the shell is stable and the seam feels clean, do player management next

The decision should be made after reviewing the running shell, not before.