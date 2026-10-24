# Fanatika TV Launcher v2.3 — source release

**Base:** Fanatika v2.2 from the working Java build fix. Arc Favorites add/remove/reorder logic preserved.
**Version:** 2.3.0+4127. **Build:** Flutter/Gradle APK compilation NOT run in this environment.

## Added and wired into Fanatika v2 Tools

1. **Remote Button Tester:** foreground-only key names, logical/physical IDs, repeats and hold durations. OEM HOME/POWER events may not reach it.
2. **Live Theme Preview:** previews appearance before Apply; Cancel makes no preference changes.
3. **Stable release signing:** opt-in GitHub workflow + instructions for YOUR keystore. No key supplied and workflow not executed.
4. **Manual visual recovery profile:** saves and temporarily disables optional heavy visual effects; restore at any time from the same Settings entry. **Not** automatic crash recovery and does not recover ADB/HOME failure.
5. **App-specific mountains:** optional per-Favorite image from bundled six wallpaper files. No change to original Arc Favorites selection.
6. **Remember last focused Favorite:** opt-in; returns focus to saved favorite if it remains in the dock.
7. **Quick app search:** text search across installed apps, launch selected result. No Favorites edits.
8. **Text effects:** `Glow` style joins Classic, Bold, Cinema and Glass.
9. **Offline weather cache:** stores latest successful weather reading locally per city/unit/forecast configuration and marks cached results offline with time.
10. **Read-only launcher health summary:** apps loaded, favorite management status, weather and performance settings; no invasive health checks.
11. **Update checker:** read-only check against the newest **public** GitHub Release of `FanatikaTM/Fanatika-TV-Launcher`. Private repos/no releases return an explanation. Never auto-installs.

## Not implemented as originally envisioned

- A **fully translated Bulgarian** interface; original Arc localization remains unchanged.
- **Automatic crash recovery** capable of restarting the TV: only opt-in manual appearance recovery is implemented.
- Device-side firmware-level HOME recovery (unsafe without reliable ADB) is not added.

## Updating the existing test APK

1. Back up preferences/Favorites from Fanatika Tools.
2. Merge `Fanatika_v2_3_Changed_Files.zip` into the same local Git repository.
3. Commit and Push to main; existing GitHub Actions will build a new **debug** APK.
4. Run `adb install -r <debug.apk>` only when signing signatures are compatible.
5. If signatures differ, **don't blindly uninstall**. Debug signing on ephemeral GitHub runners is not stable. See `SIGNING_AND_UPDATING.md` for future signed releases.
6. The signed release and debug APK have different package IDs, so they can coexist for migration. Keep Arc and existing HOME intact while testing.

### Validation
Python source-integration checks; ZIP extraction/integrity. **Not** Flutter analyzer, Java compilation, Android tests, or real Xiaomi validation. GitHub CI is the next build gate.
