# Fanatika v2.9.3 — Xiaomi HOME override

Xiaomi MiTV-M0EU0 (Android 14) registers Fanatika as HOME role holder but launches Google TV HOME.
This release adds a standalone opt-in Accessibility service for the two Google TV HOME activities.

## One-time setup without ADB commands
1. Update **signed Fanatika v2.9.3** with the original signing key.
2. On the TV, open **Fanatika → Settings → TV & tools → Make Fanatika HOME**.
3. Select **Enable on this TV**. In Android Accessibility select **Fanatika HOME Override** and enable it, approving the system warning.
4. Return and press the **physical HOME** button. The TV should redirect to Fanatika if Android allows the background activity launch.
5. If Android says **Restricted setting**, open the **Restricted settings help** button on that screen; in Fanatika's App Info use **Allow restricted settings** if offered, then repeat step 3.

## Rollback
Turn the override off inside Fanatika (Pause HOME override), or disable the service in Android Accessibility. The stock Google TV launcher remains installed and enabled. No root, ADB commands, boot scripts or auto-disabling stock packages are used. The separate Sleep shortcut Accessibility service is unchanged.

## Caveats
This method can briefly show Google TV before redirecting, and some Android 14/OEM builds block background activity launches or disable the Accessibility service after updates. If so this feature cannot force HOME without a different, more invasive workaround. The source is not a signed APK; build it using existing GitHub signing secrets. Physical-device validation is required.
