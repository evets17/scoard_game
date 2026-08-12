# Restart Slice 7 Plan: Active Sessions And Resume

## 1. Purpose

This document defines the next feature slice after round scoring.

Its job is to make in-progress scoring sessions resumable.

This slice should turn the current placeholder concept of active games into a real user-facing capability without expanding into a full history, sync, or audit system.

This plan should be read alongside:

* `restart_technology_approach.md`
* `restart_slice_4_quick_score_plan.md`
* `restart_slice_6_round_scoring_plan.md`
* `initial_overview.md`

---

## 2. Slice Goal

Implement autosaved in-progress game sessions so a user can:

* start a new Quick Score or Round Score game
* leave that game before Game Over
* come back later and resume it from where they left off
* see in-progress sessions surfaced appropriately from the home screen
* open a durable Active Games list when more than one in-progress session exists
* discard abandoned in-progress sessions when they no longer matter

This slice is successful when Scoard Game can preserve unfinished work for both current scoring modes while keeping the user-facing behavior simple:

* Score a Game always starts a new game
* in-progress sessions save automatically
* resume actions appear only when they are relevant

---

## 3. Why This Is Slice 7

This is the right next step because:

* the app now supports real scoring flows, including repeated rounds
* leaving a game mid-session currently loses work
* the home-screen action model and session repository already hint at active-session support
* resumable sessions make the app feel dependable for real game-night use

It also forces the next important architecture step:

* separate in-progress session state from completed session results
* resume the correct scoring flow from saved draft data
* promote Active Games from placeholder to working feature

---

## 4. Core Direction For This Slice

### 4.1 Product Rule: New Game Always Means New Game

Choosing Score a Game should always start a new game.

The app should not redirect that action into an older draft or ask the user to resolve draft conflicts before starting.

### 4.2 Product Rule: Autosave, Do Not Ask

In-progress sessions should save automatically.

The user should not need to think about draft-saving as a separate action.

### 4.3 Product Rule: Home Screen Adapts To Active Session Count

The home screen should only show active-session actions when they are relevant.

Rules:

* if there are `0` in-progress sessions, show no resume or active-games action
* if there is `1` in-progress session, show `Resume <game>` as the first home action
* if there are `2+` in-progress sessions, show `Active Games` as the first home action

This keeps the home screen focused while still surfacing unfinished work as a reminder.

### 4.4 Product Rule: Active Games Is The Durable Resume Surface

Even when the home screen shows `Resume <game>`, the durable model is still the Active Games list.

That means:

* Active Games remains the real place to manage unfinished sessions
* Resume on home is a shortcut, not a separate concept

### 4.5 Allow Any Number Of In-Progress Sessions

The app should allow multiple unfinished games.

This avoids special-case singleton draft logic and keeps behavior easy to understand:

* starting a new game never mutates older drafts
* resuming is explicit
* abandoned drafts stay until the user completes or deletes them

---

## 5. In Scope

The following work belongs in Slice 7.

### 5.1 Draft Session Persistence

Persist in-progress sessions separately from completed sessions.

This should cover at least:

* Quick Score drafts
* Round Score drafts

### 5.2 Resume-Ready Draft Data

Persist enough data to reopen the correct flow and restore its current state.

Likely required data includes:

* session id
* preset id
* participants
* entered values for the current session state
* progress metadata suitable for labeling active sessions
* updated timestamp
* session status such as in-progress vs completed

### 5.3 Automatic Draft Saving

Save draft progress automatically while the user is in the scoring flow and when they leave it.

The first version does not need to be overly clever about micro-events.

It only needs to be reliable enough that normal navigation or app closure does not throw away work.

### 5.4 Home Screen Active Session Action

Use the active session count to determine whether the first home action is:

* nothing
* `Resume <game>`
* `Active Games`

### 5.5 Active Games Screen

Replace the placeholder screen with a real list of in-progress sessions.

Each item should clearly show:

* game/preset name
* players
* progress label

### 5.6 Resume From Active Games

Selecting an active session should resume the correct scoring flow at the correct point.

### 5.7 Discard / Delete Draft

Allow the user to remove an abandoned in-progress session from Active Games.

### 5.8 Move Completed Sessions Out Of Active Games

When a user reaches Game Over and saves the completed result, that session should no longer appear as active.

---

## 6. Out Of Scope

The following work should not enter Slice 7.

* cloud sync
* multi-device draft conflict resolution
* collaborative live sessions
* audit snapshots of every draft change
* editing completed sessions
* advanced sorting, filtering, folders, or tags for active sessions
* warning systems for too many drafts
* review-heavy round history tables beyond the current scoring flow

If these begin to enter the slice, the slice is drifting.

---

## 7. Product And UX Rules For This Slice

### 7.1 Unfinished Work Should Feel Safe

The app should feel like it remembers unfinished games without the user having to manage draft state manually.

### 7.2 Do Not Surface Dead Navigation

If there are no active sessions, the home screen should not show resume-related actions.

### 7.3 Resume Shortcut Comes First

When active-session actions do exist, they should appear first in the home action list.

This reflects the most likely next task for the user.

### 7.4 Active Games Is Simple Management, Not A Dashboard

The first Active Games screen should be a straightforward list.

It does not need analytics, grouping, or dense metadata.

### 7.5 Cleanup Is User-Controlled

The app may allow deletion of drafts, but it should not aggressively auto-clean unfinished sessions in this slice.

---

## 8. Technical Decisions For This Slice

### 8.1 Extend The Existing Session Repository

The current `SessionRepository` already exposes `loadActiveSessions`.

Slice 7 should turn that into a real feature seam rather than inventing a second draft-session repository.

### 8.2 Keep Draft State Distinct From Completed Results

Completed results and active draft sessions are different concepts.

Do not overload completed-session tables or models to pretend they are drafts.

### 8.3 Resume By Preset And Session Shape

Resume behavior should dispatch back into the proper scoring flow according to the saved preset or session type.

That keeps the built-in preset architecture intact.

### 8.4 Prefer Simple Draft Lifecycle States

The first version likely only needs a small status model such as:

* in progress
* completed

If discard is modeled separately, keep it as deletion rather than a heavy archived-draft lifecycle unless a real need appears.

### 8.5 Autosave Should Be Reliable, Not Clever

The system does not need to save after every conceivable micro-change if that adds complexity.

It does need to save often enough that the user can trust resume.

### 8.6 Memory And Persistent Adapters Must Both Work

The in-memory path should still support active sessions for tests and non-persistent environments.

The persistent adapter should support real local resume behavior.

---

## 9. Recommended Project Shape For Slice 7

The following additions are likely appropriate:

```text
lib/
  application/
    models/
      sessions/
        active_session_detail.dart
    services/
      sessions/
        save_active_session.dart
        load_active_session.dart
        delete_active_session.dart
  infrastructure/
    persistence/
      db/
      repositories/
  ui/
    active_games/
      active_games_screen.dart
      active_game_list_item.dart
```

The exact names may vary, but the separation should remain clear:

* draft session persistence
* active session summaries and details
* flow-specific resume logic
* user-facing Active Games list

---

## 10. Concrete Deliverables

Slice 7 should ideally produce these concrete artifacts:

1. Autosaved Quick Score drafts.
2. Autosaved Round Score drafts.
3. A working Active Games screen.
4. Conditional home-screen resume behavior based on active-session count.
5. Resume into the correct in-progress scoring flow.
6. Ability to discard an active draft.
7. Tests covering active-session persistence and resume behavior.

---

## 11. Suggested Build Sequence Inside The Slice

Implement Slice 7 in this order:

1. Define the in-progress session models needed for summaries and resume details.
2. Extend persistence and repository support for active draft sessions.
3. Implement active-session save/update/delete behavior.
4. Replace seeded/stub active-session repository behavior with real logic.
5. Wire autosave into Quick Score and Round Score flows.
6. Replace the Active Games placeholder with a real list screen.
7. Wire resume navigation back into the correct scoring flow.
8. Update the home action builder to use the `0 / 1 / many` active-session rules.
9. Validate the full save-leave-resume-complete lifecycle.

---

## 12. Validation Rules

At the end of Slice 7, validate the following:

### 12.1 Runtime Validation

* starting a scoring session creates or updates an in-progress session automatically
* leaving the app or flow does not lose draft progress
* if there are `0` active sessions, home shows no resume-related action
* if there is `1` active session, home shows `Resume <game>` first
* if there are `2+` active sessions, home shows `Active Games` first
* Active Games shows resumable sessions clearly
* resuming an active session restores the correct scoring state
* completing a game removes it from Active Games
* deleting a draft removes it from Active Games

### 12.2 Architecture Validation

* active sessions are persisted separately from completed sessions
* the existing session repository remains the main seam for session behavior
* resume dispatch remains aligned to preset/session type rather than hardcoded screen assumptions

### 12.3 UX Validation

* autosave feels invisible rather than ceremonial
* resume actions appear only when relevant
* Active Games is understandable without explanation
* the home screen keeps the next likely action at the top

---

## 13. Risks To Watch During Slice 7

### 13.1 Draft Lifecycle Becomes Over-Designed

Risk:

The implementation starts building a heavyweight draft-management subsystem.

Response:

Keep the first version limited to save, list, resume, complete, and delete.

### 13.2 Resume Logic Forks Per Flow In Ad Hoc Ways

Risk:

Quick Score and Round Score grow separate custom resume systems that are hard to extend.

Response:

Keep resume routed through shared session concepts plus preset/session-type dispatch.

### 13.3 Autosave Becomes Too Fragile

Risk:

Saving is attached to too few events and users still lose work.

Response:

Prefer reliability over premature elegance. Save often enough that normal navigation is safe.

### 13.4 Active Games Turns Into A Catch-All Dashboard

Risk:

The screen begins absorbing history, analytics, and review behavior.

Response:

Keep Active Games focused on unfinished sessions only.

---

## 14. Exit Decision After Slice 7

Once Slice 7 is complete, the next likely decisions are:

1. improve completed-session browsing and stats
2. deepen active-session review for round history if real use warrants it
3. add another thin built-in scoring preset on the stronger session foundation

Default recommendation:

* if active-session resume feels solid, keep building narrow user-facing scoring value on top of it
* only broaden draft/session management when real friction appears

The decision should be made after the full autosave-resume lifecycle has been exercised in real use.