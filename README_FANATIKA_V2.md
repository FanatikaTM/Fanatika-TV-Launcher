# Fanatika TV Launcher v2 — modified Arc Launcher 1.1.0 source

## Release status

**Source-only / uncompiled / not TV tested.** Dart source bracket checks and integration/source-preservation tests were run. Flutter 3.41.9, Android SDK, and Dart are not installed in the build environment, and network download is blocked. Do not claim an APK is included or a successful build.

This is a GPL-3.0-or-later fork preserving the original Arc Favorites implementation (add, remove, rearrange; no default app list). The installed app's Android ID is `com.fanatika.tvlauncher`, separate from Arc. It does not change HOME, enable/disable Google TV services, or overwrite Arc. The home screen is not branded with a logo; the existing icon and splash remain separate.

## Fanatika v2 Settings (Arc Settings → Fanatika v2 tools)

- **Backup & restore** — exports Arc SharedPreferences and the Favorites package IDs/order as JSON via Android's document picker; restores them only after explicit approval and a second, local pre-restore backup. Other launcher category contents and wallpaper *image bytes* are not included. Inaccessible or uninstalled favorite apps are skipped. Keep external copies of the backup.
- **Visual editor** — adjust large selected-app title size and placement. This is not a free-position drag-and-drop editor.
- **App descriptions** — set short descriptions by package name, shown under the large selected-app title.
- **Weather** — enable/disable, choose city/units, 3 or 5 day forecast, adjustable refresh interval. Uses Open-Meteo; requires Internet. In performance mode refresh is limited to 180 minutes.
- **Smart mountain wallpaper** — opt-in scheduled time-of-day choice from six locally bundled images. Disabling returns to existing Arc wallpaper selection. The schedule uses the device clock, not astronomical sunrise/sunset.
- **HDMI names** — label detected inputs, displayed in the existing input selection page; switching remains firmware-dependent.
- **Layout presets** — Minimal, Cinema, and Classic adjust selected preferences; original Arc layout/categories are not deleted.
- **Focus animations** — toggle focus animations and transitions on app cards.
- **Settings PIN** — salted SHA-256 stored locally; protects the *new Fanatika v2 settings page* only, not original Arc/system settings. It is a convenience guard, not strong parental security.
- **Updater** — choose a local APK through Android file picker; precheck that the package ID matches the *currently installed* Fanatika variant (debug builds use `.debug`); Android's normal package installer enforces signing-key continuity and requests approval. No online update feed is configured, so there is no automatic check/download.
- **Performance mode** — reduces animation and throttles weather refresh; original wallpaper or Arc plugins may still consume resources.
- **Quick settings** — Android Wi-Fi, Bluetooth, Display, and system Settings shortcuts (some may not be supported on every firmware).

Original Favorites, original Arc categories, all existing settings screens, and the previously included mountain wallpaper gallery are retained. No installed apps are hard-coded as favorites.

## Sleep / Standby update (v2.1 source)

**New page:** Arc Settings → Fanatika v2 tools → Remote sleep shortcut & timer.

- Long-press remote shortcuts: user-selectable MENU / INFO / GUIDE / RED / GREEN / YELLOW / BLUE; default OFF; HOME / POWER / BACK / direction arrows / volume buttons deliberately cannot be assigned.
- Sleep timers: 15, 30, 60, 90 or 120 minutes, with cancellation and status refresh. Inexact Android alarms may be delayed and are cancelled on restart.
- Sleep Now: manual confirmation required.
- Optional user-approved Device Administrator force-lock permission required, and optional manually enabled Accessibility service to receive suitable keys outside Fanatika.
- Android may lock rather than enter standby; do not assume Xiaomi will switch off the TV. Feature does not disable Xiaomi/Google components, run privileged shell commands or replace HOME.
- Remote shortcut selection participates in Fanatika settings backup. Device administrator and accessibility permissions are never backed up, installed, or silently enabled.

See **README_SLEEP_STANDBY.md** for detailed setup, permissions, and limitations. The source integration tests run with `python tests_sleep_source.py` (Python 3.9+). Tests validate source integration, not an APK build or physical TV standby behavior.

## Build APK on Windows

1. Install [Flutter 3.41.9](https://docs.flutter.dev/install), Android Studio/Android SDK, and Java 17.
2. Use `SETUP_CHECK_WINDOWS.bat`, then `BUILD_FANATIKA_WINDOWS.bat`.
3. Or open the project in a Flutter-capable IDE and run:

```
flutter pub get
flutter analyze
flutter build apk --debug --flavor github --target-platform android-arm
```

The APK will be under `build/app/outputs/flutter-apk/` if the build completes.

## Build APK on GitHub Actions (no local Flutter install)

1. Create a **private** or public GitHub repository containing the **contents** of this project folder, including `.github/workflows/build-fanatika-apk.yml`.
2. Open the repository's **Actions → Build Fanatika TV Launcher APK → Run workflow**.
3. After the workflow successfully finishes, open its artifact named **Fanatika-TV-Launcher-debug-APK** and download the generated APK.
4. This is a *debug* APK intended for testing. The first debug signing certificate must stay the same for later updates or you will need a separate signed release APK. Do not replace the currently working Arc HOME configuration until the new APK is installed and tested independently.

**The cloud workflow is provided but has not been executed in this environment.** If it reports a Flutter analyzer or Gradle error, the actual build logs are necessary to repair it.

## Safety

- No changes to the Xiaomi HOME replacement or factory packages.
- Data import is user-approved and prompts for a safety backup.
- The updater is not connected to Arc's upstream releases.
- No user-installed APK is in this ZIP.
- GPL license and original attributions are preserved.
