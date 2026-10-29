# Fanatika TV Launcher v2.8.7 — desktop sync and quality improvements

Based on v2.8.6. Build the APK with the same signing key as the installed launcher. This archive contains source only, not a compiled APK.

- ONE Arc-style unified settings layout remains. Home/Apps/Tools top bar and original Arc Favorites database/control flow are untouched.
- Windows desktop via **authorized ADB shell** can queue a fixed allowlist: Watch Next, Weather, large title, centered Favorites, focus glow, large-title font/style, Plex refresh 5/15/30/60 minutes. No local HTTP server or extra app permission is opened.
- Android `FanatikaRemoteControlProvider` requires `android.permission.DUMP` **and** checks shell/root/app UID. Other Android apps cannot make changes. The provider queues changes; Flutter applies them via the existing SettingsService, so the launcher MUST be started to accept them. The Windows tool can read acknowledgment. Access requires physical TV-approved USB/wireless debugging (turn off ADB when not needed).
- Plex Continue Watching keeps its last *in-memory* successful items for at most six hours if Plex is temporarily unreachable. Tokens are never sent to Windows by the bridge. Refresh can be changed under Plex settings or from desktop.
- Large title now supports font, font weight, character spacing, outline thickness, shadow strength, preset styles and existing size/alignment controls. The status bar is unchanged.
- Remote focus remembers the last focused settings tile on named routes; no keyboard shortcuts or app menus modified.
- Install/update routes now ask to export a backup first, saving non-sensitive preferences and Arc Favorite order to TV Downloads/Fanatika. Downloading APK and approving Android installer are still required. Debugging privileges are not enabled automatically.

## Important verification

Python source-check tests pass in the provided environment, but **Flutter/Android APK compilation and Xiaomi MiTV-M0EU0 device tests were not available**. Confirm the provider `content call` is allowed by your particular firmware, and that a backup actually exists in the TV Downloads/Fanatika directory before updates. No claim of verified live-TV operation is made.
