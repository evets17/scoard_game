# Restart Iteration And MVP Principles

## 1. Purpose

This document records a delivery lesson from the first implementation attempt:

the next solution should establish a running product shell early and then grow through small, visible, user-facing slices.

This document should travel with:

* `initial_overview.md`
* `restart_technology_approach.md`
* `restart_data_simplicity_principles.md`

---

## 2. Core Lesson

The first attempt accumulated meaningful feature and architecture work before the app was easy to load and review as a living product.

That reduced the feedback loop for:

* UI direction
* visual language
* navigation feel
* interaction patterns
* scope discipline

The restart should correct that by making “running and reviewable” an early priority.

---

## 3. Primary Principle

## 3.1 Get To A Runnable Product Shell Early

The new solution should produce a working app shell very early, even if it contains only placeholder behavior.

That shell should be treated as a legitimate milestone, not as throwaway scaffolding.

Examples of acceptable early scope:

* app bootstrap
* main menu
* navigation shell
* placeholder buttons
* initial visual theme
* basic layout system

The goal is to start seeing and feeling the product quickly.

## 3.2 Visible Iteration Matters More Than Early Feature Breadth

It is better to have:

* a running app with one thin, reviewable slice

than:

* several partially designed feature concepts that cannot yet be experienced together

The restart should optimize for feedback in context, not abstract completeness.

---

## 4. MVP Guidance

## 4.1 MVP Should Mean Smallest Useful, Visible Product

For this app, MVP should not be defined primarily by internal capability count.

It should be defined by the smallest product state that:

* runs
* can be viewed easily
* expresses the intended design direction
* supports feedback on flow and interaction

## 4.2 Placeholder UI Is Valid Early MVP Material

Placeholder buttons, incomplete menu options, and non-final feature stubs are acceptable if they help establish:

* app structure
* navigation rhythm
* typography
* spacing
* component style
* visual tone

They are useful when they support real review and iteration.

## 4.3 Do Not Wait For Rich Domain Depth Before Rendering Product Shape

The restart should avoid a long period where architecture and data modeling advance while the app experience remains invisible.

Once the technological footing is chosen, the product should become visible quickly.

---

## 5. Recommended Feature Delivery Order

The restart should prefer a sequence like this:

1. app shell and main menu
2. visual system and navigation feel
3. player management as an early real feature
4. one simple game-scoring flow
5. result display and simple editing/correction behavior
6. later richer template capabilities

This order is useful because it lets the product identity emerge through small digestible steps.

## 5.1 App Shell First

The first user-facing milestone may be nothing more than:

* a branded home screen
* main menu options
* placeholder routes
* basic layout responsiveness

That is acceptable and desirable.

## 5.2 Player Management As An Early Real Slice

Player management is a good early feature because it helps establish:

* list styling
* form styling
* button treatment
* empty states
* confirmation patterns
* editing interaction norms

It also creates reusable product language before scoring complexity is introduced.

## 5.3 One Simple Game Before Generalized Template Power

A single simple scoring flow should come before broader template architecture or advanced scoring abstractions.

That keeps the design grounded in a real interaction rather than in a speculative system.

---

## 6. Slice Design Principles

## 6.1 Deliver Vertical Slices, Not Layer-Complete Phases

Each iteration should preferably cut through:

* UI
* interaction
* application logic
* minimal persistence

in one small scenario.

Avoid long phases that complete only one layer in isolation.

## 6.2 Keep Each Slice Small Enough To Review Visually

Each slice should be small enough that it can be:

* run quickly
* understood quickly
* discussed in context
* adjusted without broad rework

## 6.3 Prefer Digestible Bites

If a feature feels too large to visualize and evaluate quickly, split it into a smaller slice.

That is especially important for:

* template work
* scoring workflows
* navigation structure
* result presentation

---

## 7. Architecture Implications

## 7.1 Foundational Decisions Still Matter

The restart should still establish the essential technical footing early, including:

* platform direction
* project structure
* storage boundaries
* preview strategy
* state ownership

But that foundation should be only deep enough to support fast visible iteration.

## 7.2 Avoid Back-Loading The First Runnable Product

Do not defer the first meaningful app shell until multiple real features are already modeled.

That slows product learning and makes design decisions too abstract.

## 7.3 Preview Surfaces Should Support This Workflow

Desktop or browser preview should be used as a fast review surface for:

* shell design
* menu concepts
* component styling
* partial feature flows

That is one of the reasons preview support is valuable even though the app itself is not web-first.

---

## 8. Feedback Loop Rules

The restart should favor a loop like this:

1. choose a very small visible slice
2. make it runnable
3. review the UI and interaction in context
4. adjust style and flow
5. only then deepen the feature

This creates a better product rhythm than waiting for deeper feature completeness before seeing the result.

## 8.1 UI Direction Should Emerge Through Real Screens

Design should be established through actual screens and flows, not only through abstract component planning.

## 8.2 Product Learning Should Happen Early

The sooner a screen can be seen and discussed, the sooner weak assumptions can be corrected.

This reduces waste in both architecture and design.

---

## 9. Default Posture For The Restart

When deciding between:

* adding more internal capability before the UI is reviewable

and:

* getting a thinner but runnable slice in front of review

prefer the second option.

For this product, early visual and interaction feedback is strategically valuable and should be treated as part of the MVP approach, not as something postponed until after substantial implementation.