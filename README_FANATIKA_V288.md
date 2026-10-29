# Fanatika TV Launcher v2.8.8 — Clean sleep timer, Input and configurable text bar

This is a source-only update from v2.8.7. Build and sign with the **same signing certificate** as the installed app; do not wipe the app data or recreate Arc Favorites.

## Changes

- The prior Quick Settings timer warning/confirmation popup is replaced with one blue, centered timer dialog. It offers 15/30/45/60/90/120/180 minutes, a remaining-time circle, estimated sleep request time, pause/resume, and cancel. Its state comes from Android, not a fake UI timer. The Quick Settings panel closes first. Android Device Administrator permission is still optional and explicitly approved by the user; on this Xiaomi model it may **lock the screen** rather than power off the TV. This is NOT the firmware's OEM sleep-timer API.
- Empty/permission-failed Watch Next rows do not overlay warning text over the home screen. Plex and Android TV permissions remain in Watch Next settings. No simulated Plex recommendations are inserted.
- The launcher's Android application label now reads **Fanatika TV Launcher** rather than the confusing **TV Launcher**. The existing HOME category and applicationId remain; Xiaomi firmware can still override HOME. No system applications are disabled by this update.
- The manufacturer's input action is labeled **Input** everywhere it is offered. Custom HDMI input picker remains disabled.
- The single existing top bar uses its original pill background and focus decoration, but its actionable controls are text tabs. Default: Quick, Home, Apps, Tools, Settings, Input. Settings > Home & appearance > Top bar lets you add/remove and reorder tabs: Sleep, Weather, Network, Updates, Bar. Home and Settings remain always available to prevent locking the user out. D-pad focus scrolls long rows into view.
- Date/time and passive Wi-Fi usage indicator retain their existing appearance; the original Arc Favorites service/data handling, Plex settings, and the app bar visual style switches are unchanged.

## Troubleshooting HOME selection on Xiaomi

Run `CHECK_FANATIKA_HOME_WINDOWS.bat` from Windows with ADB available. It reads the installed Fanatika package, HOME candidates, selected/resolved HOME activity, and HOME role. It **does not change or disable** any packages. If role selection says Fanatika but HOME still opens an OEM app, Xiaomi's firmware may be intercepting the remote HOME key or using a persistent preferred activity.

First try the TV's Settings > Apps > Default apps > Home app menu. For advanced debugging only, you can run `adb shell cmd package set-home-activity --user 0 com.fanatika.tvlauncher/com.omeda.arc.MainActivity`, then check again. If you do not know how to recover the OEM launcher, do not disable or uninstall system launchers. A firmware-specific workaround cannot be guaranteed without diagnosing the real TV.

## Verification

`python -m unittest discover -p 'tests_*.py' -q`: 139 source checks passed. The current environment has no Flutter/Android SDK available; **no APK build or Xiaomi hardware test was performed**. In particular test native lock/sleep behavior, default HOME handling and D-pad interactions on the device.
