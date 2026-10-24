# Fanatika TV Launcher v2.6 — on-TV updates

## How it works

1. Publish a **public** GitHub Releases repository containing signed universal APKs, e.g. `FanatikaTM/Fanatika-TV-Launcher-Releases`. The private development repo may remain private.
2. Publish a stable release tag like `v2.7.0` and attach `fanatika-tv-launcher-universal-release.apk` produced by the **signed** build workflow. Do not attach an APK built with the ephemeral debug key.
3. Build and install Fanatika **v2.6+ signed release**. First installation is manual; the updater will work for subsequent signed releases **using the exact same keystore and package ID**.
4. In **Settings > Fanatika tools > Public release source**, enter the public `owner/repository` (default `FanatikaTM/Fanatika-TV-Launcher-Releases`).
5. Enable checks Off / 15 / 30 days, or use **Check, download and install Fanatika update**.
6. Approve download, wait for verification, approve installation in Fanatika, and then approve Android's package installer confirmation. If Android requires **Allow from this source**, approve in system settings and retry.

## Security

- Only HTTPS GitHub Releases and universal `.apk` assets are used.
- If GitHub provides an asset `sha256:` digest it is verified incrementally without loading the entire APK into RAM.
- In all cases Android checks the APK package ID, strictly higher version code and exact current signing certificate against the **installed Fanatika** before showing the installer.
- The same checks run again when opening the installer. Unknown signing identities and other applications are rejected.
- Download size is capped at 250 MB. Updates are stored in private application storage; the existing FileProvider grants read access to Android's installer only.
- No silent installation, no Android system app disabling, no HOME changes, and no GitHub token inside the TV app.
- No updates from private GitHub Actions artifacts: a private source repository requires a separate public release distribution.
- Android TV OEM firmware may have no compatible package installer, or may refuse unknown-app permissions. In that case use USB or ADB for a manually reviewed signed APK.
- First-time release installers need a manually installed matching app. The v2.5 app cannot perform this v2.6 update flow because the feature wasn't in that APK.

## Build verification

The source tests do not prove an APK compiles. Run signed GitHub Actions build and install on an Android TV before considering a release tested.
