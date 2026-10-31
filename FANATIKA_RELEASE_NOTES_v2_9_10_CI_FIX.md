# Fanatika TV Launcher v2.9.10 — CI compatibility hotfix

- Keeps the v2.9.10 Google TV-style Watch Next cards, adaptive pulsing focus glow, and focusable app action menu.
- Fixes the v2.9.6 regression test to validate rounded, uncropped artwork without requiring the retired `280 × 206` layout.
- Fixes the v2.9.9 app-menu focus test to recognize the shared `FocusableSettingsTile` implementation.
- Updates `pubspec.yaml` to `2.9.10+4153` and aligns the source version tests.
- Adds tests for the v2.9.10 behavior.

No Flutter SDK is available in the packaging environment. The full Flutter/Android build and TV remote tests must run in GitHub Actions and on the device.
