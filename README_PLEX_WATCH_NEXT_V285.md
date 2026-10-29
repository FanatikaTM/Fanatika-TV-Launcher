# Fanatika TV Launcher 2.8.5 — Plex Continue Watching

This patch adds Plex Media Server Continue Watching to the compact Watch Next panel next to Weather, while retaining all Arc Favorites and all existing Fanatika 2.8.4 options. The standard Android TV recommendations feed remains enabled when TV listings permission is granted. Plex rows are shown first and duplicated native Plex rows are suppressed only while the direct Plex feed contains entries.

## Setup on Xiaomi / Android TV

1. Build the v2.8.5 source using your existing GitHub signed-build workflow, with your **same signing certificate**. Do not uninstall the existing signed launcher or its Favorites data.
2. Install the resulting correctly signed release APK using Windows Android TV Cleaner **Fanatika Setup → Install / Update signed APK**. The Windows app will not accept an unsigned or `.debug` package.
3. On the TV, open Fanatika → **Home → Plex Continue Watching**. Enable the source. Enter your Plex Media Server URL and Plex access token. Prefer HTTPS with a valid server certificate, e.g. a server's real `.plex.direct:32400` URL. To use `http://192.168.x.x:32400`, explicitly enable **Allow HTTP on my trusted LAN**; this exposes the token unencrypted to anyone able to capture that LAN traffic. Public HTTP hosts are rejected.
4. Select **Test Plex**. If connected, it reports how many Continue Watching entries it retrieved. Select **Save**. The Watch Next panel is enabled automatically. Refresh Watch Next or reopen Fanatika.
5. Plex items appear with their artwork (when available), title and source label. Selection uses the best-available Plex Android deep link to open a movie or series detail page. Plex 2026.x does not reliably support automatic playback from third-party deep links; use Plex's own Resume action on the detail screen when required.

## Authentication / privacy

Plex's official support page explains how to find a temporary X-Plex-Token in Plex Web: https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/ .

Use a token with access to the intended Plex profile's Continue Watching list. Do not send the token in this chat. Tokens are sent as `X-Plex-Token` request headers **only to the configured Plex host**. HTTP redirects are not followed. The token is stored locally in the TV app's private preferences, *not encrypted at rest*, and excluded from Fanatika's JSON export/import. Android's own app-data backup and access on rooted devices may still expose it; use a revocable token. The settings page has a **Clear** option.

Plex data is pulled independently of the Android TV Watch Next database using Plex's documented `/hubs/continueWatching/items` endpoint (fallback `/hubs/continueWatching`). A refresh happens on return to launcher, when settings change, manually, and every five minutes. A current Plex Media Server is needed and the TV must reach its IP/host.

## Limitations

- No server URL or token is hardcoded.
- No automatic Plex account sign-in/OAuth was added; this version uses a user-provided Plex token.
- The direct Plex feed is independent of the Android TV listings permission, but the standard Android row still needs `READ_TV_LISTINGS` and apps must publish searchable entries.
- New Plex Android builds may open a title's details instead of resuming playback automatically; deep-link behavior is controlled by Plex.
- **Build and on-device validation are pending.** This environment does not include Flutter/Android SDK or the private release-signing certificate. Python source checks are not a substitute for compiling and testing the APK.
