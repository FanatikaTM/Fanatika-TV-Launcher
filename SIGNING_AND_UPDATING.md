# Stable Fanatika APK signing and updates

## Why another debug APK may not update the previous debug APK
GitHub-hosted runners are ephemeral. Their debug signing keystore can change, so
`adb install -r` may fail with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
The normal debug workflow remains a **test build only**.

## Make a long-lived signing key ON YOUR WINDOWS PC
Install Java 17+ (`keytool`). In PowerShell, from a private folder **outside the Git repository**:

```powershell
keytool -genkeypair -v -keystore fanatika-release.jks -alias fanatika -keyalg RSA -keysize 3072 -validity 10000
[Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path .\fanatika-release.jks))) | Set-Clipboard
```

Copy the base64 string from the clipboard into a GitHub Actions repository secret.
In GitHub: **Settings → Secrets and variables → Actions → New repository secret**.
Create four secrets:
- `FANATIKA_KEYSTORE_B64` — Base64 of fanatika-release.jks
- `FANATIKA_STORE_PASSWORD` — keystore password
- `FANATIKA_KEY_ALIAS` — `fanatika`
- `FANATIKA_KEY_PASSWORD` — alias/key password

**Never commit the `.jks` key or passwords to GitHub.** Store a private offline backup of your keystore
and credentials. Losing them means you cannot update apps signed with that key.

Then run **Actions → Build signed Fanatika release APK → Run workflow**.
The signed release has Android ID `com.fanatika.tvlauncher` and can be updated
in-place by subsequent signed releases from the **same key**, provided versionCode increases.
The debug build uses `com.fanatika.tvlauncher.debug`: it is a **different package** and
cannot be upgraded in-place to this release APK. To migrate, keep the working Arc launcher,
export Fanatika Settings & Favorites to your own storage, install the new signed release
alongside the debug version, and import the backup only after testing. Never uninstall Arc
or disable Xiaomi setup/recovery components to force a HOME change.

## If installation fails
`INSTALL_FAILED_UPDATE_INCOMPATIBLE`: key mismatch or differently signed APK. Do NOT blindly uninstall.
`INSTALL_FAILED_VERSION_DOWNGRADE`: new versionCode must exceed the installed versionCode.

## Limits
This signed workflow is provided but **not executed or verified on real Android hardware** here.
It runs only by manual opt-in and does not post APKs to public Releases.
