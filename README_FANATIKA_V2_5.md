# Fanatika TV Launcher v2.5 — mountain, status bar, layout and reliability update

Based on Arc Launcher (GPL-3.0-or-later). All original Arc Favorites selection, ordering and management are retained. This update does not disable or change the system HOME application.

## What's new

- **Additional offline wallpaper choices:** five *original illustrations* inspired by Bansko, Pirin, snowy peaks, rivers and alpine lakes. Not documentary photos of Bansko. Existing six wallpapers remain installed. Open Interface → Wallpaper → Mountain wallpaper gallery.
- **Status bar variants:** Transparent, Glass, Solid and Compact; optional Apps, Fanatika tools, Sleep and Weather shortcuts. Existing status controls (network, time/date, Wi-Fi usage) remain available.
- **Accent color:** original Arc accent-color menu is hidden; its stored preference remains unchanged for compatibility and backup recovery.
- **Favorites:** separate On/Off switches for focus enlargement and cyan/gold glow. Short rows are centered only when Center short app rows is On, including row/grid sections with fewer apps than columns; other rows remain scrollable/reorderable. Defaults preserve previous layout.
- **Watch Next + Weather:** keeps the weather/title area allocated even while Watch Next is visible, with a minimum height so the weather card is not squeezed away.
- **Title:** stable width/height and one-line ellipsis to prevent focus title jumping. Additional styles Minimal, Neon, Wide and Shadow join Classic, Bold, Cinema, Glass and Glow. The fixed-title option defaults On.
- **Fanatika tools:** shortened menu title.
- **Backup/export/import:** no document-picker app required. Android 10+ writes timestamped backups to `Download/Fanatika/` through MediaStore; Import restores the latest *readable, app-owned* backup. Android 9 and below use app-scoped external Downloads, when available. Export/Import require explicit confirmation; signing keys, PINs and credential-like preference keys are excluded from exported/imported settings.
- **Live theme preview:** revised responsive D-pad dialog, with real focusable Cancel and Apply choices. Cancel does not save changes.
- **Sleep:** Xiaomi's device-policy feature report may not reflect available controls, so the permission request is tested through the Android Device Policy service; a new shortcut opens display/power settings. Timers and Sleep Now are only offered when Device Administrator has actually been approved. If OEM firmware refuses the permission, a third-party launcher **cannot force standby**; no protected packages are disabled or privileged ADB commands attempted.

## Upgrade

1. Download the `Fanatika_TV_Launcher_v2_5_Patch_From_v2_4.zip` archive.
2. Unzip it. Copy the **contents of `Fanatika_TV_Launcher/`** into the corresponding local GitHub project root, merging directories and replacing matching files.
3. In GitHub Desktop, commit `Fanatika v2.5 — status bar, wallpapers and TV controls` and push to `main`.
4. Open Actions → **Build signed Fanatika release APK** → Run workflow.
5. After a successful build, download `Fanatika-TV-Launcher-signed-release`, extract the ZIP and install the suitable `.apk` (universal is safest for unknown TV ABI) with:
   `adb -s 192.168.3.163:5555 install -r "C:\\path\\to\\fanatika-tv-launcher-universal-release.apk"`
6. Use **the same release signing keystore** as v2.4. Do not uninstall the working launcher before verifying backups and the new build.

Debug APKs use `.debug` package ID and a different signing certificate, so they are NOT in-place updates to release APKs.

## Backup limitations

The internal Xiaomi file-provider error is avoided by saving/reading through the Android MediaStore (or app-scoped Downloads on older devices). MediaStore access is scoped by Android app ownership. A backup created by a debug package is **not guaranteed to be readable** by a separately installed release package. For cross-variant migrations, retain both apps and copy the export safely with ADB; if the new release cannot read the file through MediaStore, restore the relevant Favorites manually. The app does not request all-files access and cannot bypass Android's scoped-storage rules.

## Sleep limitations

`DevicePolicyManager.lockNow()` is not the same as system-level power/standby. Xiaomi Google TV firmware may deny Device Administrator entirely. In that case timers cannot safely send a real sleep command; use built-in power settings. There is no root/ADB workaround and no attempt to disable Xiaomi or Google launchers.

## Verification

- 54 source-level integration tests pass (including inherited security/Favorites tests).
- Image assets verified present, Android manifest parsed, and original Arc Favorites files unchanged.
- **Not compiled with Flutter/Gradle in this environment.** This source must pass GitHub Actions and actual TV navigation tests before being considered a release.
