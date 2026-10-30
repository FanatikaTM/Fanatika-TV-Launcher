# Fanatika v2.9.0 — UI and navigation fixes

- Sleep timer dialog now shares the dark Arc unified settings-panel surface, without confirmation popups.
- A small sleep countdown appears on Fanatika HOME (not above other apps) only while an actual Android sleep alarm is active. You must grant Device Administrator permission and start a timer. Countdown polling is best-effort.
- D-pad Up from Watch Next/refresh now focuses the Home tab, not Settings. Down from tabs still goes to first Watch Next item or first Favorite if the feed is empty.
- Plex setup has a permanently visible Save/Test/Clear strip and TV keyboard Next/Done handling; press Done after entering the token to save. Three Plex sources from v2.8.9 remain unchanged.
- Arc Favorites, Plex authentication, wallpapers, weather and Input handling are retained.

Build with Flutter 3.41.9 and the existing private signing key. Do not include the keystore in Git. This ZIP is source, not an APK. The 149 Python source checks passed here; Flutter build and Xiaomi D-pad/IME behavior require real-device validation.
