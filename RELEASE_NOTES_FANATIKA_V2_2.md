# Fanatika TV Launcher 2.2 — Remote navigation & design fix

Based on original Arc Launcher code (GPL-3.0-or-later), preserving its existing Favorites and app/category management.

## Fixed
- The full **Fanatika v2 tools** page uses remote-focusable rows; switches toggle with OK and numeric settings open arrow-key-accessible choice dialogs.
- Title position, size, opacity, style, weather options, input labels, presets, and Sleep are navigable with a D-pad.
- Sleep & Standby is accessible directly from **Settings** and from **Fanatika v2 tools**. Sleep permission still requires user approval.
- Increased Settings side panel width to 440 px and added clearer visible focus highlight.
- Added **Classic, Bold, Cinema and Glass** text styles with animated app-title transitions and readable description typography.
- Replaced Transformers artwork with an original four-color television-style icon and app launch transition. No branding/logo added to home. This is not the official Google TV trademarked icon.
- Original mountain wallpapers, weather, HDMI controls and Favorites functionality preserved.

## Build on GitHub
1. Extract this source ZIP. Copy its contents into your **existing local Fanatika GitHub Desktop repository** (do not overwrite `.git`).
2. Commit and push. The workflow `.github/workflows/build-fanatika-apk.yml` runs the 21 source tests and builds a debug APK.
3. If green, open Actions > successful run > Artifacts to download the APK.

## Update warning (important)
GitHub-hosted *debug APKs* may be signed by a newly generated keystore on each run. Android can reject an update with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. **Do not uninstall Fanatika until you have backed up its Favorites and preferences.** For reliable upgrades, configure persistent signing credentials in GitHub Actions before distributing future builds.

## Test status
21 Python source and asset checks passed. **Flutter/Dart compilation and physical Xiaomi TV testing have NOT been run in the current environment.** Build and test the new APK before changing HOME.

## Startup animation vs TV boot
The new logo shows on Fanatika's Android launch window and fades when the app loads. This does not replace Xiaomi firmware's device boot animation and requires no root access.

## Licensing
Preserves all included original source and GPL-3.0 license and notices. Keep them intact if sharing the fork.
