# Restart Slice 11 Plan: Online Templates

## 1. Purpose

This document defines how the app loads scoring templates from a URL, so a template can be fixed or changed without rebuilding and reinstalling the app.

The templates are hosted in this repository, which is public on GitHub. The app reads them over plain HTTPS from:

```text
https://raw.githubusercontent.com/evets17/scoard_game/main/assets/templates/
```

Publishing a template change is then the normal workflow: edit the JSON, run the tests, commit, push.

This plan should be read alongside:

* `restart_slice_9_templates_as_data_plan.md` (templates as data, validator, catalog)
* `template_schema_v1.md` and `template_schema_v2.md`

---

## 2. Slice Goal

Implement online templates so that:

* the app downloads templates from a configurable base URL, defaulting to this repository
* every downloaded template goes through the same validator as bundled templates, and a bad file is skipped and reported, never fatal
* downloaded templates are saved on the device, so the app starts and plays offline with the last good copies
* the bundled templates remain the fallback when there is no network, no URL, or no valid copy
* Settings shows where templates come from, when they were last updated, and any problems, with a Check Now button

This slice is successful when a wording change to `skyjo.json`, pushed to `main`, appears on a phone running a release build after Check Now, with no reinstall.

---

## 3. What Was Checked Before Planning

| Question | Finding | Consequence |
|---|---|---|
| Does the raw URL serve the templates? | Yes: `200`, `text/plain`, `Cache-Control: max-age=300`. | No GitHub API or token is needed. A push can take up to 5 minutes to show. |
| Can GitHub raw list a folder? | No. Raw URLs serve single files only. | An index file listing the templates is needed (5.1). |
| Do finished games depend on the template? | No. Finished games save each player's total, placement, and tie at completion, and history reads those. | Changing a template never changes a finished game's result. |
| Do in-progress games depend on the template? | Yes. Active sessions save entered values and look the template up by id when resumed. | A resumed game is scored with the current template. Field, marker, and picker ids must never be renamed or removed once published (7.3). |
| How does the catalog load today? | `loadTemplateCatalog(Map<String, String> filesByPath)` validates and parses a map of file name to JSON text. Bundled files are read from the asset bundle at startup. | Online files feed the same function. Only the source of the map is new. |
| Can a release build reach the network? | Not yet. `INTERNET` is only in the debug and profile Android manifests. | Add it to `android/app/src/main/AndroidManifest.xml` (5.8). |

---

## 4. Core Direction For This Slice

### 4.1 Templates Are Data, So Online Templates Are Safe

A template cannot run code. Formulas are evaluated by the app's own evaluator over whole numbers, and the validator rejects any key or name it does not know. Pointing the app at a URL therefore only ever changes what the existing app can already express.

### 4.2 Bundled Templates Are The Floor

The app always has its bundled templates. Online templates override or add to them, never replace the floor. With no network on first launch, the app behaves exactly as it does today.

### 4.3 The Last Good Copy Wins Over A Bad New One

A downloaded file that fails validation is not saved over the last good copy of that template. A failed download changes nothing.

### 4.4 The Installed App Decides What A Template May Use

A template using a schema version or feature this build does not know fails validation and is skipped with a visible problem. New formula functions, effects, or schema versions still need an app update; wording, tiles, colors, formulas, and options using existing features do not.

### 4.5 A Template Changes Only Between Games

A game already open keeps the template it started with. Refreshed templates apply to games started or resumed afterwards.

---

## 5. In Scope

### 5.1 Template Index

Add `assets/templates/index.json`, listing the template files:

```json
{
  "indexVersion": 1,
  "templates": [
    "cornhole.json",
    "flip-7.json",
    "quick-final-score-basic.json",
    "round-score-basic.json",
    "skyjo.json"
  ]
}
```

* The bundled loader skips `index.json`.
* A test fails unless the index lists exactly the `.json` template files in `assets/templates/`, so a new template cannot be pushed without being listed.
* `indexVersion` lets a later index format be told apart. The app ignores an index with a version it does not know and keeps its saved copies.

### 5.2 Fetching

`HttpTemplateDownloader` (infrastructure, behind the `TemplateDownloader` interface), using the `http` package:

1. GET `<base URL>index.json`.
2. GET each listed file from the base URL.
3. Return the file map, plus a problem for each file that could not be downloaded.

Rules:

* HTTPS only. The base URL must end with `/`; Settings adds it if missing.
* A 10-second timeout per request.
* Files are fetched with a small amount of parallelism (for example 4 at a time).
* The fetcher takes an `http.Client`, so tests use `MockClient` and never touch the network.

### 5.3 Validation And Merging

A pure function in `lib/core/templates/` builds the catalog from two sources: bundled files and online files.

1. Validate and parse each source with the existing `loadTemplateCatalog`.
2. For each template id, choose:

| Bundled | Online | Use |
|---|---|---|
| valid | none or invalid | bundled |
| none | valid | online (a template added online) |
| valid | valid | online, unless the bundled `version` is higher |

"Unless the bundled version is higher" lets an online fix land without bumping the version, while a newer app release still wins over an older online copy.

3. Each chosen template records its origin (`bundled` or `online`) for display (5.7).
4. Problems from online files are returned for Settings, never thrown, in any build mode. Bundled problems keep today's behaviour (fatal in debug, logged in release).

`version` comparison is numeric per part (`2.10.0` > `2.9.0`).

### 5.4 Saved Copies

`FileOnlineTemplateCache` (infrastructure, behind the `OnlineTemplateCache` interface) stores online templates in the app support directory:

```text
<app support>/online_templates/
  templates/<template>.json ...
  status.json      (source URL, last checked, last updated, problems)
```

Rules:

* Only files that pass validation are written.
* A file that fails validation keeps its last good copy, if there is one.
* A template removed from the online index is removed from the cache. The bundled one, if any, takes over.
* Writes go to a temporary folder that is renamed into place, so a crash mid-write never leaves a half-written set.
* Changing the base URL clears the cache, so templates from two sources are never mixed.

### 5.5 When Templates Are Checked

* **Startup:** the catalog is built from bundled files plus saved copies. This reads only local files, so startup stays fast and works offline.
* **Once per app start:** a single check runs after the first screen shows, so it never delays startup. If anything changed, the catalog updates in place (5.6). There is no timer or repeated polling: templates change rarely, and Check Now covers the rest.
* **Check Now** in Settings runs a check immediately and shows the result.

### 5.6 Catalog Updates

`TemplateCatalog` keeps its current API (`templates`, `byId`, `maybeById`, `firstFor`) and gains:

* `replaceTemplates(List<ScoringPreset>)`
* change notification (`ChangeNotifier`), so Score a Game rebuilds when the list changes

Services keep their existing reference to the one catalog, so no wiring changes are needed. Screens that already hold a `ScoringPreset` keep it until the game is closed (4.5). `ScoreEngine.of` is cached per preset object, so a replaced template gets a new engine automatically.

### 5.7 Settings And Game Page

Settings gains an **Online templates** section:

* **Load templates online** switch.
* **Template URL**, prefilled with the default, plus a Reset to Default action.
* **Check Now** button.
* A status line, for example:
  * "Updated 3 minutes ago · 5 templates"
  * "Couldn't reach the template URL · using saved copies from 12 Oct"
  * "1 template has problems" (tap to see each file and its problems)

The game page shows the template version and origin under the description, for example "Template v2.1.0 · online" or "Template v2.1.0 · built in", so it is clear which copy a game will use.

### 5.8 Platform

* Add `<uses-permission android:name="android.permission.INTERNET"/>` to the main Android manifest.
* iOS and desktop need no change for HTTPS.

### 5.9 Debug Builds

In debug builds, the switch defaults to **off**.

Without this, a local edit that has not been pushed would be overridden by the older online copy whenever both have the same version, which is confusing while editing a template. Turning the switch on in a debug build still works, for testing this slice.

### 5.10 Authoring Workflow

Add a short "Publishing a template change" section to `template_schema_v2.md`:

1. Edit the template JSON and its scenario file.
2. Bump `version` (patch for wording, minor for scoring changes). This is not required for the online copy to win, but it shows on the game page and confirms which copy a phone has.
3. Run `flutter test`. The validator, scenarios, and index test must pass.
4. Commit and push to `main`.
5. On the phone, open Settings and tap Check Now (allow up to 5 minutes for GitHub's cache).

---

## 6. Out Of Scope

* private repositories, access tokens, or Google Drive
* editing templates in the app
* more than one template URL at a time
* choosing an older version of a template
* signing or checksums for downloaded files (see 7.4)
* notifying the phone when a template is pushed
* a check that a published template has not renamed ids (see 7.3)

---

## 7. Product And UX Rules For This Slice

### 7.1 The App Never Gets Worse Offline

With no network, the app starts and plays with saved copies, or bundled templates if there are none. A failed check is shown in Settings only, never as an interruption while playing.

### 7.2 Finished Games Never Change

Finished games keep the totals and placements saved at completion (3).

### 7.3 Published Ids Are Permanent

A resumed game is re-scored with the current template using its saved entered values. Renaming or removing a field, marker, picker, or prompt id that a saved game used loses that game's entries.

Add this rule to `template_schema_v2.md`: "Once a template is published, never rename or remove a field, marker, value picker, or prompt id. Add new ones instead." The v1 doc already says this for `scoreField.id`.

### 7.4 Anyone Can Read The Templates, Only You Can Change Them

The repository is public, so the templates can be read by anyone, but only accounts with push access can change what the app downloads. Because templates are data (4.1), a bad or hostile template can at worst score a game wrongly. It cannot run code or read anything on the device. Signing is not needed at this stage.

### 7.5 Pushing To Main Publishes

With the default URL, anything pushed to `main` under `assets/templates/` reaches phones. If template work in progress should not reach the phone, point the app at a dedicated branch instead (for example `.../scoard_game/templates/assets/templates/`) and merge to it to publish. The URL setting supports this without code changes; the default stays `main`.

---

## 8. Technical Decisions For This Slice

### 8.1 Raw Files, Not The GitHub API

The GitHub contents API can list a folder, but it is rate-limited without a token (60 requests per hour per IP) and ties the app to GitHub. Raw files plus an index work from any static host.

### 8.2 One Validator For Every Source

Online files are validated by the same `validateTemplateJson` and parsed by the same `parseTemplateJson` as bundled files. There is no separate "remote" schema.

### 8.3 Merge Logic Is Pure

Choosing between bundled and online copies is a pure function in `core/templates`, tested without files or network. Fetching and caching live in `infrastructure/templates`.

### 8.4 New Dependency

Add `http` (and use `package:http/testing.dart` in tests). Nothing else new.

---

## 9. Recommended Project Shape For Slice 11

```text
lib/
  core/templates/
    template_index.dart              (parse and check index.json)
    template_sources.dart            (merge bundled + online, version compare, origin)
    template_catalog.dart            (replaceTemplates, change notification)
  application/
    models/scoring/template_origin.dart
    models/templates/online_template_status.dart
    repositories/online_template_repository.dart   (downloader, cache, settings interfaces)
    services/templates/online_templates.dart       (check, validate, save, merge, update catalog)
  infrastructure/
    templates/
      bundled_template_files.dart    (skip index.json)
      http_template_downloader.dart
      file_online_template_cache.dart
    memory/
      memory_online_template_cache.dart
      memory_template_source_preferences.dart
    persistence/preferences/
      template_source_preference_store.dart   (enabled, URL)
  ui/settings/
    online_templates_section.dart

assets/templates/index.json

test/
  core/templates/template_index_test.dart
  core/templates/template_sources_test.dart
  application/templates/online_templates_test.dart
  infrastructure/templates/http_template_downloader_test.dart
  infrastructure/templates/file_online_template_cache_test.dart
  templates/template_index_matches_folder_test.dart
  ui/settings/online_templates_test.dart
```

---

## 10. Concrete Deliverables

1. `assets/templates/index.json` and the test that keeps it in step with the folder.
2. Merge rules with origin and version comparison, fully unit tested.
3. Fetcher and cache, tested with a fake HTTP client and a temporary directory.
4. Startup from bundled plus saved copies, then one check per app start.
5. Catalog updates in place, with Score a Game following them.
6. Settings section with switch, URL, Check Now, status, and problem details.
7. Version and origin on the game page.
8. `INTERNET` permission in the main Android manifest.
9. Schema doc updates: index file, permanent ids, publishing workflow.

---

## 11. Suggested Build Sequence Inside The Slice

1. Add `index.json`, its folder test, and skip it in the bundled loader. Push, so the hosted index exists before the app needs it.
2. Index parsing and merge rules, test-first.
3. Template cache, test-first with a temporary directory.
4. Fetcher, test-first with `MockClient`: success, a 404 for one file, a timeout, an invalid file, an unknown index version.
5. `RefreshOnlineTemplates` service: fetch, validate, cache, merge, update catalog.
6. Startup wiring in `AppBootstrap`, plus catalog change notification. Confirm all existing tests pass with online templates switched off.
7. Settings section and game page label.
8. Android permission, then a release build on a phone: change Skyjo's description, push, tap Check Now, and see it change.

Step 6 is the safety check: with the switch off, the app must behave exactly as before.

---

## 12. Validation Rules

### 12.1 Runtime Validation

* a pushed wording change shows on the phone after Check Now, with no reinstall
* airplane mode on startup: the app opens with saved copies and Settings says the check failed
* a pushed template with a validation error: the phone keeps the last good copy and Settings names the file and problem
* a new template added online appears in Score a Game
* a template removed online falls back to the bundled copy, or disappears if it was online-only
* a game in progress keeps its template until closed; resuming it uses the new one
* finished game history is unchanged after any template update

### 12.2 Architecture Validation

* no code outside `infrastructure/templates` touches the network or the cache folder
* the merge rules have no Flutter, file, or network dependency
* online and bundled templates go through the same validator and parser

### 12.3 Agent Workflow Validation

* `flutter test` fails if a template is missing from `index.json`, so a template can't be published without being listed

---

## 13. Risks To Watch During Slice 11

### 13.1 A Push Breaks Games In Progress

Risk:

A template change renames an id, and resumed games lose entries.

Response:

The permanent-ids rule (7.3) in the schema docs. If it is broken in practice, add a test that compares each template's ids against the last released version.

### 13.2 Local Edits Look Ignored

Risk:

While editing a template, the older online copy overrides the local one, and the change seems not to work.

Response:

Online templates default to off in debug builds (5.9), and the game page shows version and origin (5.7).

### 13.3 A Template Needs A Newer App

Risk:

A template is pushed using a feature only in an unreleased build, and phones skip it.

Response:

This is the intended behaviour (4.4): the phone keeps its last good copy and Settings shows why. Release the app first, then push the template.

### 13.4 GitHub's Cache Delays Updates

Risk:

Check Now right after a push still gets the old file.

Response:

Document the 5-minute delay in the publishing workflow (5.10). Don't add cache-busting query strings; they don't reliably bypass GitHub's cache.

---

## 14. Exit Decision After Slice 11

Once online templates work, template changes no longer need an app release. The remaining reasons to release the app are new schema features, such as Slice C (several entered fields per player) and the rest of Slice D (validation rules and notifications), which can then be tried out by pushing templates that use them once the app supports them.
