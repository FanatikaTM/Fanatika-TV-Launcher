# Fanatika TV Launcher 2.8.6 — Unified Arc-style settings

Builds on 2.8.5 Plex Watch Next. Original Arc Favorites data/organizing, home bar, and Plex are preserved.

## One settings structure

The gear opens one Arc-colored settings index:
1. Home & appearance: large app title, font family, title style/size, Arc appearance
2. Apps & Favorites: original Arc Favorites/sections/app manager and Fanatika focus options
3. Watch Next & weather: Plex Continue Watching, weather and forecast
4. Wallpapers: Arc wallpaper editor plus Fanatika mountain backgrounds
5. TV & tools: the TV native Input menu, sleep, Arc system preferences, backup, USB and updates

The existing Home / Apps / Tools bar buttons remain visually unchanged but now open their corresponding section of the **same settings tree**, not a second independent menu. The top bar’s optional Tools shortcut goes to TV & tools. Quick Settings is retained as a compact action panel (no duplicate settings section links).

## Native TV Input picker

Removed the custom source list, input renaming, and experimental Xiaomi HDMI selection from the user interface. The toolbar source button and TV & tools ask Android to open its native source picker. If the TV firmware blocks that action, use the physical remote INPUT/SOURCE button. No undocumented vendor switching is used automatically.

## Font families

The large selected-app name now offers Automatic, Roboto/sans-serif, Condensed, Light, Medium, Heavy, Serif, Monospace, Cursive and Casual. The choices use Android's installed fonts; availability can vary by TV. The title-style effects are independent of the font; Automatic preserves v2.8.5 appearance. The live theme preview supports font selection with Apply/Cancel.

## Build / install

Open the full source in Flutter 3.41.9, run `flutter pub get`, then build the APK with the existing GitHub workflow or `flutter build apk --debug --flavor github --target-platform android-arm`. For updates to an installed signed app, keep your original signing key and application ID. This ZIP is source, not a compiled APK; it has not been tested on Xiaomi MiTV-M0EU0 hardware.
