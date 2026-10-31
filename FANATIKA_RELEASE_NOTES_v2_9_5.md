# Fanatika v2.9.5 — Compact navigation

Based on the complete v2.9.4 source. Changes are limited to navigation and settings organization:

- Remove **Tools** from the top-bar choices, including previously saved tab layouts. Functions remain available under **Settings → TV & tools**; no existing user preference needs to be cleared.
- Default bar remains **grid icon (Quick) · Home · Apps · Settings · Input**, with the original pill styling and configurable order.
- Simplify Quick controls: remove the redundant Input shortcut (already in the top bar and TV & tools) and the old HOME-settings shortcut. Keep Screensaver, Picture, Sound, Wi-Fi, Bluetooth and Sleep timer.
- Clarify the top-bar editor's explanation of where TV controls live.
- Preserve Arc Favorites, Plex pairing-only Watch Next, weather, sleep timer, wallpapers, date/time format and the existing HOME limitation.

## Build/test

- Python source checks: `python3 -m unittest discover -p 'tests_*.py'`
- Flutter: `flutter pub get && flutter analyze --no-fatal-infos --no-fatal-warnings`
- Build using the existing private signing workflow so package data and Favorites are kept.

This package is **source**, not a compiled APK; live TV testing is still required.
