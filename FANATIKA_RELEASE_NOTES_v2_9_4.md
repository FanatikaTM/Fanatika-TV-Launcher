# Fanatika TV Launcher v2.9.4 — Plex & navigation cleanup

- Removes **Make Fanatika HOME** from the TV & tools menu and unregisters the HOME-override Accessibility service. Google TV HOME replacement work remains paused.
- Removes **Arc system preferences** entry, while preserving **Date & time format** directly in Settings → Home & appearance.
- Plex Continue Watching settings now offer **Plex pairing only** (plex.tv/link), account server picker, automatic saving, refresh interval, refresh and disconnect. Existing paired credentials are retained when updating; no manual URL/token entry.
- Removes the Watch Next heading and large container background, leaving artwork cards and an accessible 60×60 refresh button. Removes redundant `Plex •` prefix from cards.
- On the TV remote, Left/Right across titles moves focus and scrolls the card into view; Up returns to Home tab, Down moves to first Favorite. Pressing Home inside Fanatika returns focus to the first home item.
- Original Arc Favorites add/remove/order logic and the rest of the top bar are retained.

## Testing and installation
- Source checks: 169 tests pass, including new v2.9.4 checks. AndroidManifest.xml parses.
- Flutter SDK is unavailable in this environment. GitHub signed APK build and on-device D-pad testing are still required.
- Build with the existing signing key and update the installed `com.fanatika.tvlauncher` APK without clearing app data.
- The physical remote HOME key remains controlled by Google TV until the separately paused HOME project resumes. The top bar Home control now returns to Fanatika home content.
