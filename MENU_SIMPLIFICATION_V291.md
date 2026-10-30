# Fanatika v2.9.1 — one simplified settings menu

From the TV top bar choose **Settings**. The root now has just four sections:

1. **Home & appearance** — large title, wallpapers, Arc appearance, top-bar editor and extra layout options.
2. **Apps & Favorites** — the original Arc Favorites editor, installed apps, labels, focus effects and app-specific backgrounds/descriptions.
3. **Watch Next & weather** — Watch Next switch, all Plex integration methods and weather settings.
4. **TV & tools** — native Input, sleep timer, TV settings, backups, updates, plus an Advanced tools submenu for Arc system settings, USB, PIN and diagnostics.

The **Home** top-bar tab now scrolls to the actual home screen instead of opening yet another settings page. **Apps** and **Tools** are shortcuts into the same settings tree, not independent menu systems. **Quick** remains the grid-icon quick-control panel. No changes to Favorite ordering, Plex authentication, sleep logic, top-bar theme, system permissions or the default HOME launcher have been made.

## Updating an existing project

Extract the full source ZIP into a clean checkout **or** overlay the patch contents onto the root of the 2.9.0 project. Keep your existing Android signing key and secrets. Commit and run the signed release workflow. Do not uninstall the old APK or clear data.

## Verification

`python3 -m unittest discover -p "tests_*.py"`

`flutter analyze --no-fatal-infos --no-fatal-warnings` and `flutter build apk --release --flavor github --target-platform android-arm` must still run in your Flutter CI or development environment; Flutter is not available in this container.
