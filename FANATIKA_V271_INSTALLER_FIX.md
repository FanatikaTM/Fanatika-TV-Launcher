# Fanatika v2.7.1 — Xiaomi installer handoff correction

The v2.7.0 app could repeatedly display its own permission instructions even if Xiaomi's Unknown Apps screen showed Fanatika as allowed, because it returned early when canRequestPackageInstalls() was false.

v2.7.1 verifies the downloaded APK package, increasing version code, and signing certificate as before; then asks Android's installer to handle permission and the final user approval. It tries ACTION_INSTALL_PACKAGE and falls back to ACTION_VIEW only when no handler is available. It cannot silently install or bypass Android restrictions.

Publish a signed universal APK built with the original signing key in a stable public GitHub Release tagged **v2.7.1**. You may need one ADB install -r to upgrade the existing v2.7.0 installation. This is a source-level change; full Android build and device tests remain pending.
