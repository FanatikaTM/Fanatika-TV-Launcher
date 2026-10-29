# Fanatika TV Launcher v2.8.8 — Flutter analyzer syntax fix

This build-fix release uses the same v2.8.8 feature set.

Changed file:
- lib/widgets/fanatika_sleep_timer_dialog.dart

Fix: close the Padding widget containing the Enable sleep permission button. The missing ")" caused three Dart parse errors reported at line 148.

All 139 existing Python source checks pass. Dart/Flutter tooling is not available in this packaging environment; the Flutter analyzer and APK build still need to be rerun in your Flutter / GitHub Actions environment.

Validation commands:
    flutter pub get
    flutter analyze --no-fatal-infos --no-fatal-warnings
    flutter build apk --debug --flavor github --target-platform android-arm

The unrelated analyzer warnings and infos in the original log are left unchanged; with the flags above they are non-fatal.
