# Fanatika TV Launcher 2.7 — Changes and build status

Based on existing v2.6 source. Original Arc Favorites methods and database preserved.

## Changes
- Separate **Fanatika updates** menu in main Settings (with Off / 15 / 30 day check, public release source, signed APK verification, and user-approved install).
- **Fanatika tools** is a submenu hub: Favorites/Layout; Title/Status; Weather; Wallpapers/Inputs; Backup/Privacy; Diagnostics/Preview; Sleep.
- **Remote Button Tester** and **Quick app search** removed from menus. Original installed apps and Favorites management stay intact.
- Six additional title styles: Outline, Elegant, Mono, Soft, Steel, Sunset.
- Approximate weather location: OFF by default; ask Android for coarse-location permission; query Open-Meteo at deliberately rounded coordinates. On unsupported TVs or denied permission, fall back to the user's manual weather city. Location not persistently saved.
- **USB storage**: list removable volumes, use Android's system document picker to import a JPG/PNG/WEBP wallpaper into Pictures/Fanatika; import a Fanatika JSON backup after preview and required safety backup. USB APKs can be selected with the local update action under Fanatika Updates, where Android verifies the target app identity/signing.

## Known limitations
- Some Xiaomi firmware does **not** include a compatible Android document picker. USB browsing/import then requires an installed compatible file manager; the app does not bypass Android storage security.
- Android TV boxes may not expose a location provider. No location permission is requested until chosen; manual city always remains possible.
- USB imports of wallpapers require Android 10+ for MediaStore Pictures. Imported files are visible in Arc's wallpaper gallery only if its media permissions allow them.
- **No APK included:** source-level Python tests are not the same as compiling Flutter, signing an APK, or on-device QA.
- The signed build must use your **existing release keystore** and the same package ID to support in-place updates. Never commit a signing key.

## Build
Merge patch files over your v2.6 GitHub project, commit and push; run the existing **Build signed Fanatika release APK** workflow. Read the build log and install the signed APK only if it succeeds. Keep the working launcher intact until v2.7 is tested.
