# Restart Slice 2 Plan: Player Management

## 1. Purpose

This document defines the first substantive product feature slice for the restarted Board Game Scoring Platform.

It follows the Flutter shell work from Slice 1 and uses that shell to introduce a real user-facing feature with meaningful interaction, state changes, and reusable product patterns.

This plan should be read alongside:

* `restart_readme.md`
* `restart_technology_approach.md`
* `restart_iteration_and_mvp_principles.md`
* `restart_data_simplicity_principles.md`
* `restart_slice_1_flutter_shell_plan.md`

---

## 2. Slice Goal

Create a real Player Management feature that allows users to:

* open the Players area from the landing screen
* view saved players
* add a new player through a reusable creation flow
* edit an existing player name
* archive a player
* view archived players
* unarchive a player

This slice is successful when Scoard Game has its first practical data-management feature rather than only shell navigation and placeholders.

---

## 3. Why This Is Slice 2

Player management is the right next step because it establishes reusable product behavior without dragging the app into scoring complexity too early.

It is specifically useful for proving:

* list styling
* empty-state design
* form treatment
* lightweight confirmation patterns
* edit flow conventions
* repository-backed state updates

It also creates real user data that later scoring setup screens can depend on.

---

## 4. Success Criteria

Slice 2 should be considered complete when all of the following are true:

1. The `Players` option on the landing screen opens a real screen rather than a placeholder.
2. The Players screen shows either a saved-player list or a useful empty state.
3. A user can add a player with a simple name-entry flow.
4. A user can edit an existing player's display name.
5. A user can archive a player without deleting them permanently.
6. Archived players stop appearing in the default active-player list.
7. A user can view archived players in a lightweight secondary view.
8. A user can unarchive a player and return them to the active list.
9. Player changes update the UI through application-layer contracts rather than direct infrastructure access.
10. The feature works end to end against the in-memory repository.
11. The add-player path is designed so it can later be launched from scoring setup and other contexts without being rewritten.
12. Exact duplicate saved-player names are prevented through lightweight validation.

---

## 5. In Scope

The following work belongs in Slice 2.

### 5.1 Players Screen

* Replace the Players placeholder with a real screen.
* Use the shared title-bar and screen-scaffold pattern established in Slice 1.
* Show an empty state when there are no active players.
* Show a scrollable list when players exist.

### 5.2 Basic Player Model

Support a minimal player record for this slice:

* player ID
* display name
* archived flag
* created timestamp if useful for ordering

Optional nickname, avatar, color, and account linkage should stay out of this slice.

This player model should also be treated as the first concrete example of the app's broader modeling posture.

In particular:

* `player ID` should help establish the app's approach to stable entity IDs and keys
* the slice should prefer the minimum durable fields needed for real behavior
* the model should support future extension without speculative over-design now

This does not mean every later entity must look exactly like Player.

It means the Player model is the first place where the app starts proving its approach to identity, current-state data, and lightweight lifecycle flags.

### 5.3 Add Player Flow

* Add a primary action for creating a player.
* Use a simple entry form or modal flow.
* Validate for basic sanity only, such as non-empty name text.
* Prevent exact duplicate saved-player names using a simple normalized comparison.
* Surface likely existing matches while the user is entering a name so accidental duplicates are easier to catch.
* Structure the flow so it can later be launched from places other than the Players screen, especially new-game setup.
* Treat the Players screen as the first caller of the flow, not as the only owner of the behavior.

### 5.4 Edit Player Flow

* Allow the player name to be changed directly.
* Treat editing as ordinary overwrite behavior rather than as a protected workflow.
* Keep the UI quick and lightweight.
* Prevent renaming a player to an exact duplicate of another saved player.

### 5.5 Archive Flow

* Allow a player to be archived from the active list.
* Use a lightweight confirmation if needed.
* Do not permanently delete the player in this slice.

### 5.6 Archived Players View

* Provide a lightweight way to view archived players.
* Keep archived players out of the default active list.
* Allow an archived player to be restored to the active list.

### 5.7 Repository And Application Layer Support

* Add player-management repository methods needed by the screen.
* Add application-layer services or use cases for:
  * load players
  * create player
  * rename player
  * archive player
  * load archived players or load players by status
  * unarchive player
* Keep UI state separate from infrastructure details.

### 5.8 In-Memory Adapter Expansion

* Extend the in-memory player repository to support mutation, not only seeded reads.
* Keep implementation simple and explicit.

---

## 6. Out Of Scope

The following work should not enter Slice 2.

* player groups
* guest-player flows
* converting guests into saved players
* drag-to-reorder players
* avatar upload
* preferred player colors
* a generalized notes system
* search and filtering beyond trivial list size
* cloud sync
* local persistence adapter
* session-participant attachment
* multi-step onboarding

If these begin to enter the slice, the slice is drifting.

---

## 7. Product And UX Rules For This Slice

### 7.1 Keep The Language Plain

Use direct labels such as:

* Players
* Add Player
* Edit Player
* Archive Player

Avoid implementation language or internal data-model terminology.

If a duplicate name is detected, the UI should help the user resolve it in plain language rather than only rejecting the save with technical wording.

### 7.2 Editing Should Feel Ordinary

Changing a player name is not a dangerous or unusual action.

The flow should support quick correction rather than elaborate state protection.

### 7.3 Archive, Do Not Delete

This slice should keep players recoverable by archiving them rather than deleting them.

That preserves future session-history compatibility without introducing heavy lifecycle logic.

Archive should be treated primarily as hiding a player from normal active-player flows.

Archived players should still appear anywhere they are historically referenced, such as past sessions or later statistics.

### 7.4 Recovery Should Be Lightweight

Because archive is not delete, this slice should include a simple restore path.

Users should not need a future admin-only workflow just to make a previously archived player active again.

### 7.5 Empty States Matter

The first run experience for Players is likely to be an empty active-player list.

That state should feel intentional and should clearly point to adding the first player.

The archived-player view may also need its own empty state if no archived players exist.

### 7.6 Settings Stays Secondary

The shared screen title bar should continue to allow access to Settings as a secondary cross-app action.

The Players screen should not become responsible for broader settings concerns.

### 7.7 Add Player Should Be Reusable Across Contexts

Scoard Game will likely need quick player creation in more than one place.

In particular, new-game setup should eventually be able to create a player without forcing the user to leave that flow and navigate to Players first.

This slice should therefore establish a reusable add-player path that can be invoked from multiple screens later.

The Players area is the first place where that path is exposed, not the exclusive place where it may exist forever.

### 7.8 Saved Player Names Should Be Unique

For reusable saved players, duplicate display names create ambiguity later in:

* player pickers
* score entry flows
* history views
* statistics

The default posture for saved players should therefore be:

* allow the user to type any name they intend
* detect exact duplicates using a normalized comparison
* ask the user to differentiate the player if the name already exists

Examples of valid differentiation may include:

* `Josh B.`
* `Josh (Brother)`
* `Josh Friend`

This rule is about keeping reusable identities clear, not about creating unnecessary friction.

### 7.9 Duplicate Awareness Should Be Helpful, Not Punitive

The add-player flow should not wait until the final save attempt to hint that the player may already exist.

If the typed text overlaps with existing saved players, the UI should help the user notice that early.

For the first implementation, that can remain lightweight, such as:

* showing exact or close matches below the field
* flagging an exact duplicate clearly

The goal is to prevent accidental duplicate identities without forcing a heavy search workflow.

### 7.10 Notes Are A Future Cross-Cutting Concern

Scoard Game will likely need optional notes on more than one entity type.

Examples may eventually include:

* player notes
* game notes
* session notes
* score notes

That means note-taking should be treated as a cross-cutting product concern rather than as something invented separately inside each feature.

However, this slice should not build a generalized notes subsystem unless the team deliberately decides to use Players as the first note-bearing feature.

For Slice 2, the important point is architectural awareness:

* do not design the player model as though notes could never exist
* do not add a premature shared notes framework just because the idea is likely

---

## 8. Technical Decisions For This Slice

### 8.1 Keep Persistence In Memory For Now

This slice should still use the in-memory repository implementation.

The purpose here is to settle interaction patterns and application-layer seams before adding a local database adapter.

### 8.2 Add Narrow Use Cases, Not A Heavy Store

Introduce only the application services needed to support the Players feature.

Do not respond to one feature by introducing broad generalized state machinery unless the feature proves it is necessary.

### 8.3 Use App-Facing View Models

The Players screen should render application-facing models rather than raw repository storage shapes.

This keeps the screen portable and easier to test.

### 8.4 Prefer Simple Mutation Paths

Repository mutation methods should be explicit and boring.

Examples:

* `createPlayer`
* `renamePlayer`
* `archivePlayer`
* `unarchivePlayer`

Do not introduce command history, events, or audit-oriented data structures.

### 8.5 Use A Stable Normalization Rule For Duplicate Checks

Duplicate-name validation should use one simple normalization rule consistently.

For example, compare names after:

* trimming outer whitespace
* collapsing case differences

The important thing is consistency, not clever matching.

For this slice, exact normalized duplicates should be blocked, while near matches can remain advisory.

### 8.6 Build For Future Session Setup Without Over-Building It Now

The player model and screen structure should make later session selection easy, but this slice should not start implementing participant-picking flows yet.

### 8.7 Separate The Creation Path From The Players Screen

The add-player interaction should preferably be implemented as a reusable editor flow or shared UI component rather than as logic trapped inside one screen widget.

That does not mean building a generalized modal system.

It means the first implementation should avoid assuming that only the Players screen can create players.

### 8.8 Let Player Identity Inform Future Entity Identity

The approach used for `player ID` in this slice should be deliberate.

It will likely influence how other durable entities receive stable IDs later, such as:

* games
* sessions
* groups
* templates

This slice should therefore choose an ID/key approach that is simple, stable, and comfortable to reuse elsewhere.

### 8.9 Keep Notes Conceptually Open, But Practically Deferred

If notes are not included in Slice 2, that should be because the slice is staying focused, not because notes are considered unimportant.

If notes are later added to Players first, the interaction should be designed with the expectation that similar note behavior may later appear on other entities.

---

## 9. Recommended Project Shape For Slice 2

The following additions are likely appropriate:

```text
lib/
  application/
    models/
      players/
    services/
      players/
    repositories/
      player_repository.dart
  infrastructure/
    memory/
      memory_player_repository.dart
  ui/
    players/
      players_screen.dart
      player_editor_sheet.dart
      player_list_item.dart
      players_empty_state.dart
```

The exact file names may vary, but the separation should remain clear:

* application-layer contracts and services
* infrastructure mutation support
* UI-specific presentation components
* a player-editor path that can be reused by future setup flows

---

## 10. Concrete Deliverables

Slice 2 should ideally produce these concrete artifacts:

1. A real Players screen reachable from the landing screen.
2. A shared-screen pattern reused successfully for a non-settings feature.
3. A basic empty state for no saved players.
4. A player list with edit and archive affordances.
5. A lightweight archived-player view with restore behavior.
6. A simple add-player entry flow.
7. Application-layer services for player creation, rename, archive, unarchive, and list loading.
8. Expanded in-memory repository support for player mutation.
9. Automated tests covering at least part of the player-management behavior.
10. A player-creation UI path that can later be called from new-game setup without redesigning the behavior.

---

## 11. Suggested Build Sequence Inside The Slice

Implement Slice 2 in this order:

1. Define the application-facing player list and editor models.
2. Expand the player repository contract for list and mutation operations.
3. Implement those operations in the in-memory player repository.
4. Add application services for loading, creating, renaming, and archiving players.
5. Add archived-player loading and restore behavior.
7. Implement the reusable add-player editor flow.
8. Replace the Players placeholder with a real screen and empty state.
9. Connect the Players screen to the add-player flow.
10. Add edit, archive, and unarchive interactions.
11. Validate the feature visually and with tests.

This order keeps the slice vertical while preserving the architecture boundary.

---

## 12. Validation Rules

At the end of Slice 2, validate the following:

### 12.1 Runtime Validation

* The Players screen opens successfully from the landing screen.
* Adding a player updates the list immediately.
* Renaming a player updates the list immediately.
* Archiving a player removes them from the active list immediately.
* Archived players can be viewed without mixing them into the default active list.
* Unarchiving a player returns them to the active list immediately.
* The add-player flow is not tightly coupled to the Players screen widget structure.
* Exact duplicate saved-player names are blocked consistently.
* The add-player flow surfaces likely duplicate players clearly enough to prevent accidental double-entry.

### 12.2 Architecture Validation

* UI code does not depend on infrastructure implementation types.
* Player mutations flow through repository contracts and application services.
* The screen can be understood without knowledge of how the in-memory repository stores data.

### 12.3 UX Validation

* The empty state is understandable.
* The add flow is quick.
* The edit flow feels like ordinary correction, not a protected admin workflow.
* The archive interaction is clear and not overly heavy.
* The restore path is easy to discover and use.

---

## 13. Risks To Watch During Slice 2

### 13.1 Players Becomes A Mini CRM

Risk:

The slice expands into profile management, grouping, searching, avatars, and other secondary concerns.

Response:

Keep the first slice focused on saved names and lightweight lifecycle state.

### 13.2 Too Much Form Machinery Too Early

Risk:

The app introduces generalized form infrastructure before the actual interaction patterns are understood.

Response:

Build the smallest clean editor flow that works for players first.

### 13.3 Archive Behavior Becomes Confusing

Risk:

Users may not understand whether archiving removes the player permanently.

Response:

Use plain copy and keep archive behavior lightweight and reversible in future slices.

### 13.4 Persistence Pressure Returns Too Early

Risk:

The team starts introducing database concerns before the interaction and service seams are settled.

Response:

Keep this slice on the in-memory adapter unless the feature proves a concrete need to add local persistence immediately afterward.

---

## 14. Exit Decision After Slice 2

Once Slice 2 is complete, the next likely decisions are:

1. add a local persistence adapter beneath the now-tested player and theme flows
2. begin one simple scoring flow that uses saved players

Default recommendation:

* if the in-memory-only limitation starts to interfere with meaningful review, add local persistence next
* if the interaction seams feel stable and the review loop is still fast, move to one simple scoring flow next

The decision should be made after the Players feature has been run and reviewed in context.