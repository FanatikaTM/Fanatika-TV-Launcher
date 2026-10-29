# Fanatika TV Launcher v2.8.9 — Plex setup, focus, weather, wallpapers

This is a full source release (no APK). Built on the **corrected v2.8.8** source. Keep the same private signing key and application ID `com.fanatika.tvlauncher` for an in-place upgrade without wiping the original Arc Favorites.

## Plex: all three setup routes (Settings → Watch Next & weather → Plex Continue Watching)

1. **Android TV Watch Next** — Test the feed that other apps (including installed Plex, if supported) publish through the Android TV provider. No Plex credentials needed. If the number is zero, Plex is not currently publishing content on this TV.
2. **Discover Plex servers** — User-initiated Plex GDM LAN broadcast (UDP 32414); no tokens sent over LAN discovery. Select a result. If the discovery is blocked by the router/Wi-Fi AP, proceed to pairing or manual server selection.
3. **Plex account pairing** — Start pairing, open `https://plex.tv/link` on a phone/computer, enter the displayed code, approve login, then press **I approved Plex — Check sign-in** on the TV. Select a server returned by Plex account resources. Press **Test Plex** and **Save** to enable Continue Watching.

A manual server/token setup is still available as an advanced fallback. Fanatika cannot read the installed Plex app's private authentication data; pairing grants Fanatika its own token. Tokens are excluded from exported backups, and only sent to Plex and the selected server via request headers. A Plex Media Server URL is never silently auto-authorized. Plex API methods and available endpoints can vary by Plex version. Newer Plex deployments may require the JWT-based client-auth flow if the legacy PIN flow is disabled; this release uses the documented traditional PIN route and reports pairing failures.

## Other changes

- D-pad **Down from any top-bar tab** directly focuses the first Watch Next card, if available, or the first Favorite app. This overrides the previously remembered focus for navigation from the bar; Arc's Favorites selection/order remains unchanged.
- The Quick control is the original-style **grid icon**. Remaining bar tabs stay text-based and are still configurable.
- Weather auto location (opt in) now tries Android's approximate location, then HTTPS approximate public-IP geolocation via ipwho.is, then your saved city. This optional IP lookup sends the TV's public IP to the provider. Approximate IP location can be inaccurate; set the city manually if needed. The detected/fallback source is displayed.
- Removed the five flat Bansko/Pirin illustrations and added **two distinct photorealistic digitally generated mountain landscapes** to the six existing photographic-style assets; no claim these are real geotagged photographs.
- Restored a darker Arc-like slate-blue sleep dialog color while keeping the clean selector, countdown, pause, resume, and cancel design. No repeated confirmation popups in the timer dialog.
- **Global sleep countdown over other apps is not included**. It would require additional Android special overlay permissions and TV firmware validation; the native timer state and countdown in the launcher continue to work as before, subject to Android sleep permissions.
- No changes to the user's Favorites, HOME component, native Input handling, Plex refresh settings, or Windows live scrcpy integration.

## Source verification

Run `python3 -m unittest discover -p 'tests_*.py' -q` and `flutter analyze --no-fatal-infos --no-fatal-warnings`. Then build and sign using the existing CI workflow. The source checks are not a Flutter/Android build substitute. Test on the real Xiaomi MiTV-M0EU0 before relying on sleep or remote behavior.

## v2.8.9 wallpaper migration / GitHub Actions fix

The v2.8.9 patch ZIP adds new images but cannot itself delete five old tracked images
when copied over an existing v2.8.8 Git checkout. Old `07_Bansko_Pirin.jpg`,
`08_Pirin_River.jpg`, `09_Mountain_River.jpg`, `10_Bansko_Winter.jpg`, and
`11_Pirin_Alpine_Lake.jpg` must be retired. Otherwise the v2.8.9 wallpaper
source test fails, and old illustration files can remain bundled in the APK.

The corrected source includes `tools/cleanup_v289_wallpapers.py`. Both GitHub
Actions workflows run this cleanup **before tests and builds**; no system or user
app data is changed. This fixes the CI build even if a previous patch left the old
JPGs tracked in the repository. For a permanent repository cleanup, run:

```bash
python3 tools/cleanup_v289_wallpapers.py
git add -u assets/mountains
git add tools/cleanup_v289_wallpapers.py .github/workflows/
git commit -m "Migrate Fanatika v2.8.9 wallpapers"
git push
```

The per-app background picker now lists only images present in v2.8.9, and
previously saved legacy image choices are mapped to one of the new photo assets
without modifying Favorites or overwriting saved settings.
