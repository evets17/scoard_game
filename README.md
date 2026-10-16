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

### Required: stable signing key (for install updates)

Android updates only install when the APK is signed with the same key as the
currently installed app.

This repository's release process uses `android/key.properties` and a keystore
at `android/app/upload-keystore.jks`. The CI workflow creates both from GitHub
Secrets.

1. Generate one release keystore once (keep it forever):

   ```bash
   keytool -genkeypair -v \
     -keystore upload-keystore.jks \
     -alias upload \
     -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Save the keystore in the repo locally as:
   - `android/app/upload-keystore.jks`

3. Copy [key.properties.example](./android/key.properties.example) to
   `android/key.properties`, then fill in your values:

   ```properties
   storeFile=app/upload-keystore.jks
   storePassword=YOUR_STORE_PASSWORD
   keyAlias=upload
   keyPassword=YOUR_KEY_PASSWORD
   ```

4. Add these GitHub repository secrets:
   - `ANDROID_UPLOAD_KEYSTORE_BASE64` (base64 of `upload-keystore.jks`)
   - `ANDROID_UPLOAD_KEY_ALIAS`
   - `ANDROID_UPLOAD_KEY_PASSWORD`
   - `ANDROID_UPLOAD_STORE_PASSWORD`

   Example to produce the base64 value:

   ```bash
   base64 -w 0 upload-keystore.jks
   ```

   On Windows PowerShell:

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
   ```

### Publish a new updatable release

1. Ensure `main` is up to date and clean.
2. Create and push a new tag `vX.Y.Z`:

   ```bash
   git tag -a v0.1.2 -m "Release v0.1.2"
   git push origin v0.1.2
   ```

3. Wait for workflow [android-release-apk.yml](./.github/workflows/android-release-apk.yml)
   to finish successfully.
4. Install from:
   - `https://github.com/evets17/scoard_game/releases/latest/download/scoard-game-latest.apk`

Release build number (`versionCode`) is set automatically from the GitHub
Actions run number, so each release is newer than the previous one for Android
update checks.

### Important troubleshooting note

If install fails with "App not installed", the usual causes are:

- APK signed with a different key than installed app
- trying to install an APK with same or lower build number

If a different key was used previously, uninstall once, then install from the
new release track. Future updates from that same track should install normally.
