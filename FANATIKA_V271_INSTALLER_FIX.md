# Fanatika TV Launcher v2.7.1 — Xiaomi update installer fix

- Previously Fanatika aborted before launching Android installer when Xiaomi returned false from PackageManager.canRequestPackageInstalls(), even if the TV showed installation permission enabled.
- Verified APKs are now handed off to Android via ACTION_INSTALL_PACKAGE, with ACTION_VIEW fallback. Android itself enforces permission and always requires user approval.
- APK checks still require identical package name and signing certificate plus higher Android versionCode. No silent installs.
- Version is 2.7.1+4132. Signed release must use the same permanent key.
- Publish a **stable** public GitHub Release tagged `v2.7.1` with a **signed universal release APK**.
- The first update to v2.7.1 may still require Windows ADB install -r. Later updates can use the corrected on-TV installer if Android firmware supports it.
- No real device test was performed; run GitHub Actions Flutter build before installation.
