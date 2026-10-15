# Restart Slice 13 Plan: Back Up And Restore

## 1. Purpose

This document defines how the app saves its database (players, groups, finished games, and games in progress) to a file the player keeps, and how it puts that file back.

Android deletes an app's private data when the app is uninstalled. That is where the app keeps its data, and it is the right place: it needs no permissions and no other app can read it. But it means an uninstall, a phone reset, or a new phone loses every player and game. A backup file kept outside the app is the dependable way to carry the data across.

The backup is a copy of the database file itself. The database already upgrades itself from every earlier version when it opens, so a backup from an older app version restores into a newer one with no extra work, and new features need no changes to back up and restore. A designed backup format (readable, mergeable) was considered and left for later (6, 14).

This plan should be read alongside:

* `restart_slice_3_local_persistence_plan.md` (the database)
* `restart_slice_7_active_sessions_plan.md` (games in progress)

---

## 2. Slice Goal

Implement back up and restore so that:

* Settings has **Back up** and **Restore** in a new Your Data section
* Back up saves a copy of the database wherever the player chooses (Downloads, Drive, and so on)
* Restore checks a picked file, shows what is in it, and after a confirmation puts it in place of the app's database
* a file that is not a Scoard backup, is damaged, or is from a newer app is refused with a clear message, and nothing changes
* the app carries on with the restored players, history, and games in progress, without being closed and reopened

This slice is successful when a phone that is backed up, uninstalled, reinstalled, and restored shows the same players, history, and games in progress as before, and a game in progress can be resumed and finished.

---

## 3. What Was Checked Before Planning

| Question | Finding | Consequence |
|---|---|---|
| Where is the data? | One SQLite database, `scoard_game.sqlite`, in the app documents folder, opened through drift at schema 8. A few settings are in `shared_preferences`. Online templates are cached in the app support folder. | The backup is the database. Settings and the template cache are not backed up (6). |
| Does the database upgrade old versions? | Yes. `onUpgrade` steps through every version from 1 to 8. | A backup from any earlier version opens in the current app. Each new schema version is already handled by the migration every slice writes. |
| How is the schema version stored? | SQLite's `user_version`, which drift sets to `schemaVersion`. | A file with a `user_version` newer than the app's `schemaVersion` is from a newer app, and is refused (5.3). |
| Can a copy be taken while the database is open? | Yes. SQLite's `VACUUM INTO` writes a consistent, compacted copy of an open database to a new file. | Back up does not close the database or stop the app. |
| What opens the database? | `AppBootstrap.initialize` creates one `AppDatabase` and every persistent repository from it; `main` passes the environment to the app. | Restore closes the database, replaces the file, and runs startup again to rebuild the environment (8.2). |
| Does Android back the app up already? | Auto Backup is on (the manifest does not turn it off), but it runs about daily, only when idle, charging, and on Wi-Fi, and restoring a sideloaded build is unreliable. | Auto Backup stays on as a bonus. This slice does not depend on it. |
| Can the app save and open files without permissions? | Yes. Android's system file screens let the player pick where to save or what to open, with no storage permission. | One new dependency, `file_picker`, for both screens (8.4). |
| Do games in progress need their template? | Yes. A game in progress is resumed by template id. | A game restored onto a phone without its template (an online-only template not yet downloaded) waits for the template (13.3). |

---

## 4. Core Direction For This Slice

### 4.1 The Backup Is The Database File

The backup is an exact, compacted copy of the database. The app's existing migrations are what read an older backup, so back up and restore never need updating when a feature adds a table or column.

### 4.2 Restore Replaces, It Does Not Merge

Restore makes the app's data match the file. It is the reinstall and new-phone case. Merging is out of scope (6).

### 4.3 Check The File Before Touching Anything

The picked file is copied to a temporary place and checked there (5.3). The app's database is only touched after the file passes and the player confirms.

### 4.4 The Player Always Knows What Will Be Replaced

Before restoring, the app shows what the file holds and what the app holds now, and asks for a confirmation that names the loss: "Replace this phone's data".

---

## 5. In Scope

### 5.1 Your Data In Settings

A new Settings section, **Your Data**, below the existing sections:

* **Back up**: "Save your players and games to a file." Opens the system save screen with a suggested name, `scoard-backup-2026-10-15.db`. Afterwards a message confirms it was saved.
* **Restore**: "Replace this phone's players and games with a backup file." Opens the system open screen, then the confirmation (5.4).
* Under the buttons: "Last backed up 15 Oct 2026", or "Not backed up yet". The date is kept in `shared_preferences`. This is a nudge, not a reminder system.

### 5.2 Backing Up

1. `VACUUM INTO` a temporary file in the app's cache folder.
2. Hand its bytes to the system save screen.
3. Delete the temporary file, whether or not the player saved it.
4. Record the date when the save succeeds.

### 5.3 Checking A Picked File

The picked file is copied to the cache folder and opened there, read only. It is refused, with nothing changed, when:

| Problem | Message |
|---|---|
| It is not an SQLite database, or its `application_id` is not Scoard's (8.1) | "This file isn't a Scoard backup." |
| Its `user_version` is newer than this app's `schemaVersion` | "This backup was made by a newer version of the app. Update the app, then restore." |
| `PRAGMA integrity_check` does not report `ok` | "This backup is damaged and can't be restored." |

A file that passes is counted for the confirmation: players, finished games, games in progress, and the date of the latest game in it.

### 5.4 Confirming A Restore

```text
Restore this backup?

                 Backup   This phone
Players              12            0
Finished games       48            0
Games in progress     1            0
Latest game     12 Oct 2026        –

This phone's players and games will be replaced.
This can't be undone.

                  [Cancel]  [Replace this phone's data]
```

### 5.5 Restoring

1. Close the app's database.
2. Move the current database file to a safety copy, `scoard_game.before_restore.sqlite`, in the same folder (one copy, replaced each time). It is not offered in the app; it is there so an accidental restore can be undone by hand while the app is installed.
3. Move the checked file into place as `scoard_game.sqlite`, and remove any `-wal` or `-shm` files left beside it.
4. Run startup again, which opens the database (upgrading it if it is older) and rebuilds every repository, then return to the home screen.

If step 3 or 4 fails, the safety copy is moved back, startup runs again on it, and the player is told the restore did not happen.

### 5.6 Platform

* Android is the target. The system save and open screens need no permissions.
* Windows and the other desktop builds use the same package and get native save and open dialogs.

---

## 6. Out Of Scope

* Settings (theme, stay awake, online template source, last player group). They take moments to set again.
* The online template cache, which downloads again.
* Merging a backup into existing data.
* A readable backup format, or sharing a single game.
* Scheduled or automatic backups.
* Encrypting the backup. It holds first names and scores, nothing sensitive.
* Changing Android Auto Backup. It stays on, as it is now.

---

## 7. Product And UX Rules For This Slice

### 7.1 Nothing Changes Until The Player Confirms

Picking a file only reads a copy of it. Cancel at any point leaves the app as it was.

### 7.2 A Restore Is All Or Nothing

A file that fails a check changes nothing. A restore that fails part way puts the safety copy back.

### 7.3 Messages Say What To Do

Every failure message says what happened and, where there is one, what to do next. The details are logged, not shown.

### 7.4 The App Does Not Need The Template To Restore A Game

Finished games and games in progress are restored whether or not their template is on this phone. A game in progress whose template is missing behaves as it does today when resumed.

---

## 8. Technical Decisions For This Slice

### 8.1 The Database Says It Is Scoard's

Set SQLite's `application_id` to a fixed Scoard value in drift's `beforeOpen`, so every database, and so every backup, carries it. Existing databases get it the next time they open, before any backup can be made. The check in 5.3 uses it to tell a Scoard backup from any other SQLite file.

### 8.2 Restore Restarts The App From The Inside

The app's root holds the environment and can build a new one. After the file is replaced, it closes everything the old environment opened, runs `AppBootstrap.initialize` again, and swaps the app over to the new environment. The player is never asked to close and reopen the app.

### 8.3 Checking Uses SQLite Directly

The picked file is opened with the `sqlite3` package (already used through drift; it becomes a direct dependency) to read `application_id`, `user_version`, the integrity check, and the counts, without going through drift or the app's migrations.

### 8.4 New Dependency

Add `file_picker` for the system save and open screens. Saving uses its save file screen with the backup's bytes; opening uses its pick files screen. Any file can be picked: Android does not filter unknown file types reliably, and the check in 5.3 decides.

The file screens sit behind a small `BackupFiles` interface, so tests use a fake that hands back bytes instead of opening a screen.

### 8.5 Migrations Carry Old Backups

There is no backup format version. The schema version inside the file is the version, and the migrations that every slice already writes are what read old backups. A test keeps this honest (12.3).

---

## 9. Recommended Project Shape For Slice 13

```text
lib/
  application/
    models/backup/
      backup_summary.dart          // counts and latest game date, for the confirmation
      backup_check_result.dart     // ok with summary, or the refusal reason
    services/backup/
      back_up_data.dart            // copy, save, record the date
      restore_data.dart            // check, confirm, swap, restart
  infrastructure/
    backup/
      database_backup.dart         // VACUUM INTO, check a file, swap files with a safety copy
      file_backup_files.dart       // file_picker save and open
    persistence/db/
      app_database.dart            // application_id in beforeOpen
  bootstrap/
    app_restarter.dart             // holds the environment, rebuilds it after a restore
  ui/settings/
    your_data_section.dart         // Back up, Restore, last backed up, confirmation
test/
  infrastructure/backup/
    database_backup_test.dart      // back up and restore on a real database file
  application/backup/
    restore_data_test.dart         // refusals, safety copy, failure puts the old file back
  ui/settings/
    your_data_section_test.dart
  support/
    fake_backup_files.dart
    backups/schema_8.db            // a backup made by this slice, restored by every later version
```

---

## 10. Concrete Deliverables

* `application_id` on the database
* Back up through `VACUUM INTO`
* The file check, with its three refusals and the counts
* Restore with the safety copy, and putting it back on failure
* Rebuilding the app's environment after a restore
* The Your Data section, confirmation dialog, and messages
* `file_picker` added, and `sqlite3` made a direct dependency
* A schema 8 backup kept under `test/support/backups`, and a test that it restores
* Tests for each item above

---

## 11. Suggested Build Sequence Inside The Slice

1. `application_id` in `beforeOpen`, with a test that a new and an existing database both get it.
2. Back up: `VACUUM INTO`, then open the copy and see the same players and games.
3. The check: a Scoard backup passes with the right counts; another SQLite file, a text file, a damaged file, and a newer `user_version` are each refused.
4. The swap: safety copy, replace, and putting the safety copy back when the swap fails.
5. Rebuilding the environment after a restore.
6. `file_picker` and the `BackupFiles` interface with its fake.
7. The Your Data section and confirmation dialog, rendered before finishing.
8. Save a schema 8 backup under `test/support/backups` with a test that restores it.
9. On a phone: back up, uninstall, reinstall, restore, then resume and finish a game in progress.

---

## 12. Validation Rules

### 12.1 Runtime Validation

* Back up, uninstall, reinstall, restore: players, groups, history, and games in progress come back.
* A restored game in progress resumes and finishes.
* A non-Scoard file, a damaged backup, and a backup from a newer app are each refused with their message, and nothing changes.
* Cancel on either system screen or on the confirmation changes nothing.

### 12.2 Architecture Validation

* The UI never touches files or the database directly. It goes through the services.
* Only `database_backup.dart` knows file names and SQLite pragmas.

### 12.3 Agent Workflow Validation

* Every later schema change must restore the saved backups under `test/support/backups`. That test runs the real migrations on old files, so a migration that only works on a fresh install fails it.
* When a slice raises `schemaVersion`, it may add a backup from the new version beside the old ones.

---

## 13. Risks To Watch During Slice 13

### 13.1 A Migration That Only Works On A Fresh Database

An old backup is opened by the migrations, so a migration that assumes something not true of older data breaks restore. The saved-backup test (12.3) catches it.

### 13.2 Restoring Over Data The Player Wanted

The confirmation shows both sides, and the safety copy (5.5) keeps the replaced data until the next restore.

### 13.3 A Game In Progress Without Its Template

A game restored onto a phone without its online template waits for the template to download. Check Now in Settings fetches it.

### 13.4 Something Still Holds The Old Database

A screen or service that kept a reference to the old environment would write to a closed database. Rebuilding from the root (8.2) and returning to the home screen leaves nothing from before the restore on screen.

---

## 14. Exit Decision After Slice 13

The slice is done when the phone round trip in 12.1 passes on a release build, and every test passes.

Follow-ups to weigh once the feature set settles:

* a designed, readable backup format, if merging or sharing games is wanted
* backing up settings
* a reminder when the last backup is old
