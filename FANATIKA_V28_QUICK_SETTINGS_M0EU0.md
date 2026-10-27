# Fanatika TV Launcher v2.8.0 — Quick Settings (MiTV-M0EU0)

Adds an optional Google TV-inspired Quick Settings dialog without changing the original HOME-button or Arc Favorites implementation. The new control appears at the start of Fanatika's status bar, and also under Settings > Quick Settings.

**First page:** Screensaver, Input source, Picture (generic Android display settings), Sound (generic Android sound settings), Wi-Fi, Home settings, Bluetooth, and Sleep timer.

**Second page:** Fanatika tools, Updates, USB, Sleep & Standby, TV Inputs, and System settings.

The Sleep Timer offers 15, 30, 45, 60, 90, 120, and 180 minutes. These are **Fanatika's own scheduled Device Administrator lock/sleep requests**, not the Xiaomi OS's proprietary Quick Settings timer. If the TV has not granted optional Device Administrator permission, no timer is scheduled; open Fanatika's Sleep & Standby settings or use Xiaomi's native timer. On some TV firmware, lockNow() may lock the screen or be rejected rather than enter standby. The native Xiaomi Quick Settings activity and OEM-specific Picture/Sound panels do not have a stable public API, so the equivalent Android settings intents are used and may not open on all devices. These limitations are intentionally visible to the user.

Target test device: Xiaomi **MiTV-M0EU0**. Do not use any special firmware-specific HOME/power shell commands from other Xiaomi models. The original HOME configuration, package list, and Favorites editing are untouched.

The complete project incorporates the v2.7.1 Java `setClipData` compilation hotfix. Source checks passed; a full Flutter/Gradle build and Xiaomi MiTV-M0EU0 on-device test are required.

To build: replace existing files from the patch in the root of the project, commit and push to GitHub, then run the signed release workflow. Use the same release-signing key and install with `adb install -r` if the updater is not yet working. Avoid removing the installed launcher. For a newer public release, use a matching `v2.8.0` GitHub Release tag and attach the signed universal APK after a successful build.
