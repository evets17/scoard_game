# Restart Data Simplicity Principles

## 1. Purpose

This document records a product and architecture lesson from the first implementation attempt:

the app should favor simplicity, ease of use, and direct editing over heavy data-control mechanisms.

This document should travel with:

* `initial_overview.md`
* `restart_technology_approach.md`

---

## 2. Core Product Attitude

This is a low-stakes scoring app.

The user is normally trying to record or fix values they already know.

The app should therefore behave as though:

* the user is the authority on the intended value
* changing a value is normal, not suspicious
* re-entering a value is preferable to workflow-heavy correction mechanics
* simplicity matters more than strong internal control semantics

The app is not a financial ledger, compliance system, or high-risk record of truth.

---

## 3. What Went Wrong In The First Attempt

The first implementation direction placed too much weight on:

* result integrity mechanics
* protective state transitions
* lock-like completion behavior
* internal audit-style thinking

Those ideas added conceptual weight that is not justified by the product.

They risk making score entry feel more formal and constrained than players actually need.

---

## 4. Primary Principle

## 4.1 Current Value Matters Most

For this product, the most important stored fact is the current intended value.

If the user wants a score to be different, the normal behavior should be:

* change the value
* show the new result
* keep moving

The app should optimize for reaching the correct current score quickly.

## 4.2 Correction Should Usually Mean Overwrite

Correction should generally be modeled as replacing the current value.

That applies to:

* scores
* notes
* category values
* other user-entered scoring fields

The product should not force users through formal correction workflows unless a later feature proves they are truly needed.

---

## 5. Undo And Editing Guidance

## 5.1 Undo Does Not Need Heavy History Semantics

For this app, undo does not need to imply event sourcing, action logs, or reversible command stacks.

A practical user-facing undo can often be treated as:

* clear the current value
* restore a prior visible value
* let the user type the intended value again

The key idea is simplicity of interaction, not perfect historical replay.

## 5.2 Erase And Rewrite Is Acceptable

If a user enters the wrong score, the app should lean toward letting them erase it and type the correct one.

That is often enough.

The restart should avoid turning ordinary score correction into a specialized subsystem.

---

## 6. Completion And Locking Guidance

## 6.1 Completion Should Not Behave Like A Hard Lock

Completion should primarily communicate that a result was reached.

It should not automatically imply that the user has crossed an administrative boundary that makes later edits awkward.

## 6.2 Avoid Locking Mindset

The architecture and UX should avoid assuming:

* completed data must be locked by default
* reopening must be a heavy workflow
* users need protection from changing their own scores

If users want to change a value after completion, the default posture should be to allow it.

## 6.3 Reopen Should Be Lightweight If It Exists At All

If the product keeps a “reopen” concept, it should be a lightweight UI state, not a complex integrity mechanism.

The app should not require deep lifecycle machinery just to permit ordinary correction.

---

## 7. Audit History Guidance

## 7.1 No Audit-Trail Requirement

A scoring change audit history is not a core requirement for this product.

It adds storage complexity, conceptual overhead, and UI burden without enough user value for the current app direction.

## 7.2 History Should Be About Results, Not Edits

If the app keeps history, it should focus on useful player-facing history such as:

* prior sessions
* prior winners
* past final results
* comparative statistics

It should not default to retaining or exposing every intermediate score correction.

## 7.3 Internal Metadata Must Stay Lightweight

If any internal change metadata is later introduced, it should remain:

* optional
* implementation-light
* non-authoritative
* invisible unless it proves real user value

It must not reshape the app around audit concerns.

---

## 8. Validation Guidance

## 8.1 Validate For Basic Sanity, Not Control Theater

Validation should protect against clearly invalid or unusable data, for example:

* missing required participants
* malformed numeric values
* impossible template inputs

Validation should not be used to create unnecessary friction around ordinary correction.

## 8.2 Favor Correction Over Rejection

When the user intent is obvious and recoverable, the better design is usually to let them correct the value directly rather than forcing a narrow workflow.

---

## 9. Architecture Implications

The restart should reflect these principles in concrete design choices:

1. Store current effective values plainly.
2. Keep edit flows direct.
3. Avoid action-history-first data models.
4. Avoid treating completion as a lock boundary.
5. Add audit concepts only if a later product need clearly justifies them.

This should reduce both implementation complexity and user-facing friction.

---

## 10. Recommended Default Posture For The Restart

When a design choice is unclear, prefer the simpler interpretation:

* let the user edit
* let the latest value win
* recompute results
* avoid heavy integrity machinery
* avoid audit-style storage unless later evidence demands it

That posture is more appropriate for this product than the stricter model explored in the first attempt.