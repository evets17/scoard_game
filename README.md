# Scoard Game

Scoard Game is a board game scoring app focused on end-of-round and end-of-game score entry rather than full gameplay simulation.

This repository currently contains the restart implementation shell for Slice 1:

* Flutter application scaffold
* async bootstrap path
* repository composition with in-memory adapters
* branded home screen and placeholder routes

## Run

```bash
flutter run -d windows
```

or

```bash
flutter run -d chrome
```

## Validate

```bash
flutter analyze
flutter test
```

## Android release APK download

The project publishes Android release APKs as GitHub Release assets:

- Stable latest link (same URL every release):  
  `https://github.com/evets17/scoard_game/releases/latest/download/scoard-game-latest.apk`
- Versioned link:  
  `https://github.com/evets17/scoard_game/releases/latest` (download the
  `scoard-game-vX.Y.Z+N.apk` asset)

### How publishing works

GitHub Actions workflow [android-release-apk.yml](./.github/workflows/android-release-apk.yml)
builds and uploads two APK assets for each release:

- `scoard-game-latest.apk` (stable filename for the static `/latest` URL)
- `scoard-game-vX.Y.Z+N.apk` (version/build specific filename)

### Trigger a release

Use either method:

1. Push a `v*` tag (for example `v0.1.0`) and the workflow runs automatically.
2. Run the workflow manually from Actions and provide a tag (for example
   `v0.1.0`).

After the workflow succeeds, install from the stable latest link above on your
phone.
