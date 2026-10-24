# Fanatika TV Launcher 2.4: approved logos and periodic release checks

## Artwork
- `assets/splash_fanatika_tv.png` / Android `drawable-nodpi/fanatika_splash_logo.png`: black startup artwork reading **Fanatika TV** from the approved visual.
- `assets/icon.png`, Android mipmap and adaptive resources: approved four-color TV frame with play symbol on white.
- Android TV banner uses the app icon and Fanatika TV label in the TV's app list.
- No app logo appears on the home-screen layout; this is **not** the television firmware boot animation.

## Update checking
Settings → Fanatika v2 tools → Automatic update checks: **Off (default)** / **Every 15 days** / **Every 30 days**.
Checks occur only when the launcher starts, resumes, or remains open (lightweight six-hour timer) and a check is due. No Android background service is used. Failures retry at most daily. Check results use the public GitHub Releases API; a private repository or no published Release results in no update notification. Published release tags should look like `v2.4.1`. A prompt never downloads or installs an APK. Existing manual check remains.

## Signed release workflow
`.github/workflows/build-fanatika-signed.yml` must be pushed to GitHub's **main** branch before the signed-release job appears in Actions. Requires all four repository secrets: `FANATIKA_KEYSTORE_B64`, `FANATIKA_STORE_PASSWORD`, `FANATIKA_KEY_ALIAS`, `FANATIKA_KEY_PASSWORD`. Keep the original JKS safe and do not change keys between signed releases. Debug and release package IDs differ.

## Testing
Static source checks and archive validation can be performed locally. Flutter compilation and real TV operation require GitHub Actions and Xiaomi hardware; do not assume those have succeeded. The logo is a custom design, not the official Google TV trademark.
