# Restart Technology Approach

## 1. Purpose

This document records the technology approach that should guide a fresh restart of the Board Game Scoring Platform.

It exists because the first implementation attempt clarified an important boundary:

* the product is not web-first
* fast design iteration outside emulators is still highly desirable
* cross-platform success depends more on architecture boundaries than on UI framework choice alone

This document should travel with `initial_overview.md` into any new solution.

---

## 2. What We Learned From The First Attempt

## 2.1 The Core App Logic Was Not The Problem

The product shape remains sound:

* mobile-first score entry
* local-first behavior
* deterministic calculations
* current-state-first editing
* simple user-driven correction flows

Those ideas should be kept.

## 2.2 The Main Risk Was Early Platform Coupling

The first attempt became constrained at the infrastructure boundary, not at the UI boundary.

The main issue was allowing an early platform-specific persistence assumption to become part of application startup and everyday flow.

That reduced flexibility for:

* browser-based preview or iteration
* desktop preview or iteration
* future alternate platform targets

## 2.3 The Next Foundation Must Preserve Optionality Longer

The next solution should be designed so that:

* domain logic does not know about the storage engine
* application services do not assume one platform runtime
* app startup tolerates asynchronous infrastructure
* preview surfaces can run without the production storage stack

---

## 3. Product Positioning For The Restart

The restart should treat the product as:

* mobile-first
* local-first
* app-first rather than web-first

However, the implementation should still support rapid iteration in non-emulated environments for:

* UI exploration
* layout tuning
* flow testing
* template-preview work

This means browser or desktop preview is a development capability, not necessarily a first-class product target.

---

## 4. Primary Technology Direction

## 4.1 Recommended Default

Primary recommendation for the restart:

* Flutter
* Dart
* local relational persistence behind interfaces
* desktop and/or browser preview support for development iteration

## 4.2 Why Flutter Is A Strong Fit Here

Flutter is a strong fit because it aligns with the actual goals more closely than the previous foundation:

1. It is excellent for mobile-first UI.
2. It supports polished, intentional layout work.
3. It works well for rapid design iteration on desktop and web preview surfaces.
4. It has proven workable for AI-assisted development in prior experience.
5. It does not require the product to become web-first in order to gain faster iteration loops.

## 4.3 What This Recommendation Does Not Mean

This recommendation does not imply:

* browser is the main product target
* the app should be architected around web constraints first
* the storage solution should be chosen for browser parity at the expense of the mobile app

The primary product still remains a mobile application.

---

## 5. Architecture Rules For The New Solution

## 5.1 Pure Core Domain

All scoring rules and result integrity logic should live in a pure Dart core with no UI or storage dependencies.

That includes:

* scoring calculations
* winner and ranking rules
* session status transitions
* completion readiness
* correction rules
* participant-removal rules
* result projections

## 5.2 Application Layer Above Repositories

Use cases should depend on repository interfaces, not concrete storage libraries.

Examples:

* create session
* attach participant
* enter or correct score
* remove participant
* complete session
* reopen session
* load latest resumable session

## 5.3 Replaceable Storage Adapters

The solution should start with at least two repository implementations:

* in-memory adapter for tests and preview flows
* persistent local adapter for real app behavior

This prevents preview and development tooling from depending on the production database stack.

## 5.4 Asynchronous Startup By Default

The app must assume initialization is asynchronous.

Do not allow the first app shell to depend on synchronous database boot.

That rule preserves flexibility for:

* different storage engines
* desktop preview
* browser preview
* future remote or synced initialization

## 5.5 UI Must Consume View Models, Not Storage Shapes

Screens should render application-facing view models, not raw database rows.

That keeps UI portable and makes template-driven rendering easier.

---

## 6. Storage And Backend Guidance

## 6.1 Flutter Does Not Meaningfully Limit Backend Choice

Flutter should not be rejected out of concern that it limits backend options.

For this product, Flutter is compatible with:

* local-only operation
* later REST APIs
* later GraphQL APIs
* later sync services
* later cloud-backed history or account features

The technology choice only becomes limiting if backend and persistence assumptions leak into the application core.

## 6.2 Local Persistence Recommendation

Use a local persistence approach that supports:

* explicit schema evolution
* transactional writes
* deterministic testability
* clear inspection during development

A relational model remains a strong fit for straightforward current-state storage with optional lightweight saved-result persistence.

## 6.3 Storage Selection Principle

Choose the storage library after the architecture rules above are accepted.

The storage package should be replaceable beneath repository interfaces.

This matters more than whether the first concrete implementation is Drift, SQLite wrappers, or another local engine.

## 6.4 Preview Environments Must Not Drive Production Storage Shape

Desktop or browser preview should be achieved through alternate adapters or preview composition, not by forcing the main mobile architecture to behave like a web app.

---

## 7. Dynamic Scoring Template Guidance

## 7.1 Dynamic UI Is A First-Class Requirement

The future scoring-template direction should remain central to architecture decisions.

The solution should assume the app will eventually support:

* direct final-score entry
* round-based score entry
* category-based end-game tally sheets
* per-game template variations
* calculated and derived fields
* optional notes, warnings, and validation messages

## 7.2 Use A Typed Template Model

Do not begin with arbitrary JSON-driven widget generation.

Instead, define a typed template model that can describe:

* sections
* field groups
* participant-scoped fields
* calculated values
* visibility rules
* validation rules
* result-calculation bindings

## 7.3 Constrained Dynamic Rendering Is Preferred

The UI should render templates from a controlled vocabulary of field and layout types.

This gives flexibility without turning the app into an unbounded low-code runtime.

## 7.4 Flutter Is Compatible With This Direction

Flutter does not materially limit this template-driven UI approach.

It is well suited to:

* composable widgets
* adaptive layout
* conditional sections
* repeatable participant blocks
* polished scoring-entry flows

The main design risk is template-model sprawl, not Flutter itself.

---

## 8. Recommended Project Shape

Suggested high-level structure:

* `core/`
* `application/`
* `infrastructure/`
* `ui/`
* `templates/`
* `preview/` or equivalent development-only composition surface

### `core/`

Contains pure domain objects, rules, calculations, and result projections.

### `application/`

Contains use cases, repository interfaces, view-model assembly, and orchestration.

### `infrastructure/`

Contains concrete storage implementations, migrations, serialization, and any later API clients.

### `ui/`

Contains widgets, screens, navigation, and interaction state.

### `templates/`

Contains template definitions, template schema types, and template-to-view-model mapping.

### `preview/`

Contains development-only entry points and preview composition using in-memory data.

---

## 9. Early Validation Rules For The Restart

The new solution should prove the following very early:

1. The same core scoring logic runs under tests without UI or storage.
2. The same application flow can run on top of an in-memory repository.
3. The real mobile app can swap to a persistent repository without changing use cases.
4. A design-preview surface can render representative screens without depending on production persistence.

If any of these fail early, the architecture is drifting toward the same coupling problem.

---

## 10. Recommended Near-Term Decision

For the restart, the working default should be:

* Flutter as the UI foundation
* mobile-first product assumptions
* desktop or browser preview for faster iteration
* repository-based storage abstraction from day one
* typed scoring-template model from early design stages

This is the footing that best reflects what was learned from the first solution attempt.