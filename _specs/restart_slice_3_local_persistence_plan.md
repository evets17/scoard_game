# Restart Slice 3 Plan: Local Persistence Foundation

## 1. Purpose

This document defines the next implementation slice after Player Management.

Its job is to add real local persistence beneath the repository seams that were established in Slice 1 and exercised in Slice 2.

This slice should make Scoard Game retain real data across app restarts without changing the app's user-facing scope dramatically.

This plan should be read alongside:

* `restart_readme.md`
* `restart_technology_approach.md`
* `restart_data_simplicity_principles.md`
* `restart_slice_1_flutter_shell_plan.md`
* `restart_slice_2_player_management_plan.md`

---

## 2. Slice Goal

Add a persistent local storage implementation that:

* stores Players across app restarts
* stores the selected theme preference across app restarts
* preserves the existing repository-based architecture
* allows the app to continue using in-memory adapters for tests and fast preview flows

This slice is successful when Scoard Game no longer loses its current player data and theme choice every time the app restarts.

---

## 3. Why This Is Slice 3

This is the right next step because the app now has:

* a real player model
* real mutation flows
* a settings-backed theme choice
* repository seams that are ready for a persistent adapter

Adding local persistence now will prove that the restart architecture can support real stored data without leaking storage concerns into UI and application logic.

It also turns Player Management from a review-only feature into something that begins to feel durable.

---

## 4. Success Criteria

Slice 3 should be considered complete when all of the following are true:

1. The app can load a persistent local storage implementation at startup.
2. Added, renamed, archived, and restored players remain intact after app restart.
3. The selected theme remains intact after app restart.
4. The existing application services continue to work without being rewritten around storage details.
5. The in-memory adapter path still exists for tests and fast preview flows.
6. Persistent storage setup remains asynchronous and does not break the app bootstrap design.
7. The chosen persistence approach has an explicit schema and clear upgrade path.

---

## 5. In Scope

The following work belongs in Slice 3.

### 5.1 Persistent Player Storage

* Add a real local storage implementation for Player data.
* Persist the current Player model fields from Slice 2.
* Preserve the archive flag and created timestamp.

### 5.2 Persistent Theme Preference

* Persist the selected app theme choice.
* Restore that theme during startup before the main shell renders.

### 5.3 Storage Adapter Layer

* Keep repository contracts above concrete storage details.
* Add a persistent adapter beneath the existing `PlayerRepository` contract.
* Add a small persistence path for app preference storage used by theme selection.

### 5.4 Bootstrap Integration

* Update async startup so the app can initialize its local persistence dependencies.
* Keep preview and tests able to use in-memory wiring when desired.

### 5.5 Schema And Migration Footing

* Define an explicit schema for the persisted player data.
* Establish a migration story from version 1, even if it is minimal.

---

## 6. Out Of Scope

The following work should not enter Slice 3.

* session persistence
* score persistence
* template persistence
* cloud sync
* account storage
* offline synchronization queue
* player groups
* guest-player persistence
* generalized settings infrastructure beyond the current theme preference
* broad data import or export

If these begin to enter the slice, the slice is drifting.

---

## 7. Product And UX Rules For This Slice

### 7.1 No New Major Product Surface Is Needed

This slice should mostly strengthen existing behavior rather than introducing a new large user-facing feature area.

The user-visible win is that data now persists.

### 7.2 Current Value Remains The Authority

Persistence should store current effective player state plainly.

Do not introduce action-history-first storage or audit-oriented structures for this slice.

### 7.3 Theme Persistence Should Feel Invisible

If a user selects a theme, it should simply stay selected the next time the app opens.

The app should not need extra ceremony to explain this.

### 7.4 Player Identity Must Stay Stable

The persisted storage model should preserve the durable player ID strategy established in Slice 2.

That is part of the app's emerging model philosophy, not just an implementation detail.

---

## 8. Technical Decisions For This Slice

### 8.1 Use A Relational Local Store

Use a relational local store for player persistence.

That best fits the restart guidance around:

* explicit schema evolution
* deterministic testability
* inspectable stored data
* straightforward current-state records

### 8.2 Recommended Concrete Choice

Recommended default for this slice:

* `drift`
* SQLite-backed native database

Rationale:

* strong typing fits the restart's explicitness goals
* schema and migration support are first-class
* it works well with repository boundaries
* it supports deterministic local testing better than more opaque persistence layers

If a different SQLite wrapper is later preferred, the repository seam should make replacement possible.

### 8.3 Keep Browser Preview On The In-Memory Path

Do not force browser preview to define the production storage solution.

The app should be able to keep using an in-memory composition path for fast preview surfaces if the persistent local adapter is not available or not desirable there.

### 8.4 Keep Preferences Storage Lightweight

Theme preference persistence does not need the full repository shape used for players.

It may use a lighter preference-storage mechanism if that keeps startup and code structure clearer.

### 8.5 Preserve Service Contracts

Do not rewrite the Player feature around storage details.

The current `createPlayer`, `renamePlayer`, `archivePlayer`, `unarchivePlayer`, and list-loading flows should continue to work through repository contracts.

---

## 9. Recommended Project Shape For Slice 3

The following additions are likely appropriate:

```text
lib/
  infrastructure/
    persistence/
      db/
        app_database.dart
        tables/
          players_table.dart
      repositories/
        persistent_player_repository.dart
      preferences/
        theme_preference_store.dart
```

The exact names may vary, but the separation should remain clear:

* schema and database setup
* concrete persistent repository implementation
* lightweight preference persistence
* bootstrap composition

---

## 10. Concrete Deliverables

Slice 3 should ideally produce these concrete artifacts:

1. A persistent player storage adapter.
2. A durable startup path that initializes local persistence asynchronously.
3. Explicit schema definitions for player storage.
4. Theme preference persistence and restore behavior.
5. Tests proving that players persist and reload correctly.
6. Tests proving that theme preference persists and reloads correctly.
7. Continued in-memory support for fast preview and existing tests where appropriate.

---

## 11. Suggested Build Sequence Inside The Slice

Implement Slice 3 in this order:

1. Add the local persistence packages and configuration.
2. Define the player storage schema.
3. Build the persistent player repository adapter.
4. Add theme preference persistence.
5. Update bootstrap to choose the persistent path for real app runs.
6. Keep or preserve the in-memory path for tests and preview composition.
7. Validate persistence across app restarts.

This order keeps the slice focused on storage footing rather than on unrelated feature growth.

---

## 12. Validation Rules

At the end of Slice 3, validate the following:

### 12.1 Runtime Validation

* Add a player, restart the app, and confirm the player remains.
* Rename a player, restart the app, and confirm the name remains.
* Archive a player, restart the app, and confirm the archive state remains.
* Change the theme, restart the app, and confirm the theme remains.

### 12.2 Architecture Validation

* UI code still does not import storage implementation details directly.
* Application services do not change their storage abstraction posture.
* In-memory adapters still support tests and preview flows.

### 12.3 Storage Validation

* Schema creation is explicit.
* Data writes are deterministic and inspectable.
* Storage initialization is compatible with async bootstrap.

---

## 13. Risks To Watch During Slice 3

### 13.1 Persistence Leaks Upward

Risk:

Storage details begin shaping UI or application services directly.

Response:

Keep all concrete persistence decisions inside infrastructure and bootstrap composition.

### 13.2 Browser Preview Starts Driving Storage Design

Risk:

The app bends its storage design around browser parity too early.

Response:

Keep browser preview free to use the in-memory path when that is simpler.

### 13.3 Theme Persistence Becomes Over-Engineered

Risk:

Preference storage is forced into heavy repository machinery that adds more ceremony than value.

Response:

Use the lightest persistence path that still fits the architecture cleanly.

### 13.4 Slice Scope Expands Into Full Data Modeling

Risk:

The slice starts trying to persist every future entity before those entities exist meaningfully.

Response:

Persist Players and theme preference first. Use that as the proof point.

---

## 14. Exit Decision After Slice 3

Once Slice 3 is complete, the next likely decisions are:

1. begin the first simple scoring flow using persisted saved players
2. add the next layer of player capability such as groups or guest flows only if a scoring slice proves it necessary

Default recommendation:

* if persistence lands cleanly, move next to one real scoring flow
* only revisit player feature expansion immediately if that scoring flow reveals a concrete need

The decision should be made after persisted player and theme behavior have been reviewed in the running app.