# Fanatika TV Launcher v2.1 — Sleep / Standby

## What was added

Arc's Favorites UI, underlying database, existing settings, appearance, wallpapers, widgets, HOME configuration, and all original features remain in the project. The added feature is in **Arc Settings → Fanatika v2 tools → Remote sleep shortcut & timer**.

- **Configurable long-press remote key**: Off (default), MENU, INFO, GUIDE, RED, GREEN, YELLOW or BLUE. Holding a chosen key for about 1 second attempts the sleep action. Only keys forwarded by the device can work. HOME, POWER, BACK, direction arrows and volume keys cannot be assigned. Short presses are not intentionally intercepted; depending on your remote/firmware its original action might still trigger while holding.
- **Sleep timer**: 15, 30, 60, 90 or 120 minutes. Cancel existing timer, or replace it by setting a new one. The timer uses Android AlarmManager and can run later than the requested time due to Android power management. It is cancelled on device reboot.
- **Try Sleep Now**: confirmation dialog and a permission check.
- **Permission status**: clearly indicates optional Device Administrator and optional Accessibility status.

## First-time setup on Xiaomi TV

1. Install Fanatika **alongside** Arc; do not change or disable the current HOME launcher until Fanatika has been tested.
2. Open Fanatika → Settings → **Fanatika v2 tools → Remote sleep shortcut & timer**.
3. Select **Enable sleep permission on TV** and approve the optional **Device Administrator** force-lock permission on the TV (if the firmware allows it). Fanatika cannot grant it itself. Some TVs do not support Device Admin at all.
4. Test **Try sleep now** before assigning a key. If Android accepts the request, verify whether the screen actually enters standby, presents a lock screen, or does nothing. If it asks for an unlock PIN, use your normal TV unlock method.
5. Choose a **long-press key** that your remote actually has. By default the shortcut works only while Fanatika is on screen.
6. *Optional:* Enable the **Fanatika Sleep Shortcut** accessibility service through the TV's Accessibility settings to receive supported keys when other apps are open. This is a special permission and should only be enabled if you want global behavior. It does not retrieve screen contents, contacts, or private app text.
7. Pick a **15/30/60/90/120 minute timer**, or cancel it. It does not shut down the TV, and cannot guarantee a minute-exact deadline.

## Permissions and safety

Android restricts `PowerManager.goToSleep()` to privileged/system apps. **Fanatika does not use it, execute shell commands, spoof ADB, root the TV, or disable Xiaomi/Google components.** The optional and documented `DevicePolicyManager.lockNow()` API can request lock/sleep after the TV owner activates `DeviceAdminReceiver` with `force-lock` policy. This call may **lock** the device instead of entering TV standby; it is not equivalent to pressing the physical Power button on all Xiaomi firmware.

The remote shortcut is **OFF by default**. HOME, POWER, BACK, arrows, volume keys and other reserved Android buttons cannot be assigned. Only a long key hold (>1 second, requiring Android key repeat events) can fire. Unsupported/unreported keys cannot be captured. Accessibility can receive the selected key globally only when the user explicitly enables the service; do not assume it is available on your TV.

No settings import can auto-approve Device Admin or Accessibility. A backup may restore the selected shortcut setting, but the TV owner must still manually authorize the services. Running timers are never restored from backups. Revoking Device Admin prevents future sleep requests.

## Build and validation

The archive includes the original GitHub Actions build workflow at `.github/workflows/build-fanatika-apk.yml`. Flutter SDK **3.41.9**, Android SDK and Java 17 are required to build an APK locally or via GitHub Actions. From the source root:

```bash
flutter pub get
flutter analyze
flutter build apk --debug --flavor github --target-platform android-arm
```

**Release status: SOURCE ONLY.** This update has not been compiled into an APK or tested on a physical Xiaomi TV in this environment. The supplied tests inspect source integration, manifest/XML correctness, privilege restrictions and preservation of the original Arc Favorites source, but cannot prove actual firmware standby behavior.

The original Arc GPL-3.0-or-later license and notices remain included.
