# Fanatika TV Launcher — Arc Launcher 1.1.0 source fork

This project is based on the **actual Arc Launcher 1.1.0 source ZIP** supplied by the user, commit `1bbe66b642930e3a12a22989c6bf60e10d1e4971`.
It keeps Arc's original application categories, **Favorites UI and ordering, apps grid, wallpaper system, watch-next support, settings, clock, and navigation logic**. Favorites are deliberately **not hard-coded**. Add, remove and reorder apps using Arc's existing interface.

## Modifications

- Android app name: **Fanatika TV Launcher**, package `com.fanatika.tvlauncher` (`.debug` for debug builds). This installs **beside** original Arc `com.omeda.arc`.
- **No Fanatika name or robot logo on the HOME screen.** A unique generic robotic/mechanical emblem is used for app icons, TV banner and startup splash only; not an official Transformers trademark logo.
- **Appearance → Large selected-app title** toggle (default ON), showing the focused Favorite's display name in large text. Original Favorites storage and reordering were not replaced.
- **Appearance → Weather card** toggle (default ON), **Weather city** and **Use Fahrenheit** settings. Uses Open-Meteo via HTTPS every 30 minutes, with no GPS/location permissions or API key. If offline, a status message or last known reading is shown. Weather location defaults to Sofia until changed.
- **Wallpaper → Mountain wallpaper gallery**: six embedded photographs/artworks from the previous Cleaner package, directly applied to the wallpaper using Arc's existing WallpaperService. No file picker required; original picture, video, Unsplash, Reddit, and gradient options remain.
- Clock, Watch Next, accent colors, focus border, background blur, etc. remain from Arc.

## Build on Windows

Prerequisites: **Flutter 3.41.9 / Dart 3.11+**, Java 17, Android SDK Platform 36, Android build tools, network for Flutter packages (see `.fvmrc` / `pubspec.yaml`).

1. Extract this ZIP to a short directory such as `C:\\FanatikaLauncher`.
2. Open an Android/Flutter-enabled Windows terminal in the folder, run `flutter doctor` and `flutter pub get`.
3. Run `BUILD_FANATIKA_WINDOWS.bat` or manually `flutter build apk --debug --flavor github --target-platform android-arm`.
4. Check `build\\app\\outputs\\flutter-apk\\` for a signed debug APK (usually `app-github-debug.apk`). The **debug** app ID is `com.fanatika.tvlauncher.debug` and the APK may require Android's normal install confirmation.
5. Install using `adb -s <TV_IP>:5555 install -r <apk_path>`; first launch Fanatika as a *normal app* to test all navigation before attempting to change HOME.
6. Keep Arc, Xiaomi launcher and Xiaomi recovery packages installed and enabled. **Do not repeat the high-risk Xiaomi HOME replacement procedure without a verified recovery path.**

**Note**: Existing Arc preferences and Favorites **cannot automatically transfer across package IDs** due to Android app sandboxing. Fanatika has all the same tools to configure them, but they start empty on first launch. You can continue using Arc while setting up Fanatika.

## Status and limitations

- This is a **modified source project**, not a compiled/tested APK. The current build environment does not provide Flutter or Android SDK; the Java/Dart code has been statically checked, but no on-device test has been made.
- Weather relies on internet access to `geocoding-api.open-meteo.com` and `api.open-meteo.com`. Open-Meteo conditions and city selection may be unavailable if the TV network blocks the API.
- No currency card is added.
- The startup icon and splash are original geometric robot-inspired art, **not a branded asset from Transformers**.

## Licensing

This fork retains upstream `LICENSE` (GPL-3.0-or-later), authorship headers, and source, complying with share-alike conditions. Modified source must accompany any redistributed APK. Original Arc project: https://github.com/meddouribadis/arclauncher
