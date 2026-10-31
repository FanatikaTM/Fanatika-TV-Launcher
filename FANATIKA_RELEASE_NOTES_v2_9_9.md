# Fanatika TV Launcher v2.9.9 — UI focus and settings improvements

- Clear blue TV-remote focus for app information buttons and category destination picker.
- Original Arc `lib/widgets/add_to_category_dialog.dart` preserved. New Fanatika-focused picker is used by the two app info panels and calls the original AppsService category operation.
- Common Fanatika choice dialog focuses and scrolls to the currently saved option.
- Date/time options have distinct focus IDs so the date section no longer shares a generic `Column` identity with time rows.
- Top bar customization: one focusable row per tab; OK adds/removes a non-mandatory tab, Left/Right moves an enabled tab. Home and Settings cannot be removed.
- Large app title always uses the fixed-height placement; removed lock toggle from Settings. Original other title-style presets unchanged.
- Added more Android font-family choices; availability and rendering depend on device firmware. No font files bundled.
- Wallpaper settings: removed the Gradient menu choice, preserving backward compatibility for existing wallpaper settings and the fallback background.
- Watch Next: removed filled card and poster background, kept uncropped artwork and centered title underneath. Wallpaper shows around the poster.
- Renamed Favorites & sections to Favorites and Sections and removed its redundant secondary description.
- Version 2.9.9+4152 (pre-v3, by user request).

Tests: 206 Python source checks pass. Flutter SDK was not available in the editing environment, so the APK was not compiled and on-TV focus/navigation is unverified.

**Build:** Use existing GitHub Actions signed build workflow and the existing signing keystore; do not reset app data or Favorites. Patch ZIP is an overlay on exactly v2.9.8 source.
