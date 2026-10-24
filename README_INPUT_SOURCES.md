# Fanatika TV Launcher — source switching update

This is an update of the original Arc-based Fanatika fork. Arc Favorites, category management and sorting, weather, big-title controls, wallpaper gallery and app icon are preserved. The installed name remains **Fanatika TV Launcher**. No logo is added to the TV home screen.

## New inputs feature
- On the launcher home screen select the **HDMI icon** in the top-left status bar, or Settings → **TV Sources / HDMI Inputs**.
- Fanatika calls Android `TvInputManager.getTvInputList()` to display detected sources, including HDMI inputs and the tuner where exposed.
- A selected **passthrough** input uses Android's public `ACTION_VIEW` with a `TvContract.buildChannelUriForPassthroughInput()` URI. Many TVs do not provide a player for this; the app reports this clearly.
- **Open TV input menu** tries available system input menus. If none is available, use the physical INPUT button on the remote.
- On some Xiaomi TVs, an optional **experimental vendor request** for HDMI 1/2/3 is offered only after standard switching fails. The TV prompts before sending it; its port mapping has NOT been confirmed for MiTV-MOSR4. Confirm the correct source on the television. Never disable Xiaomi setup, launcher, or recovery components to use this tool.
- Inputs are managed separately from Arc Favorites: choose favorite apps using the original Arc UI, not prepopulated tiles.

## Build error: Flutter SDK missing
Your screenshot shows `Flutter SDK is not in PATH`. This is a toolchain problem, not an Android/launcher problem. For Windows:
1. Download the stable Flutter SDK: https://docs.flutter.dev/get-started/install/windows/mobile
2. Extract it (for example `C:\src\flutter`); avoid spaces and Program Files.
3. In Android Studio, install **Android SDK Platform 36** and Android build tools. Install Java 17.
4. Run `SETUP_CHECK_WINDOWS.bat` to see which dependencies are missing.
5. Run `BUILD_FANATIKA_WINDOWS.bat`; the new version searches common Flutter paths and also accepts a manually supplied Flutter folder.
6. You may run `flutter doctor --android-licenses` if Android SDK licenses are pending.

The debug build is signed with the development/debug key. Its package ID is **com.fanatika.tvlauncher.debug**, separate from both original Arc and any release Fanatika app. Test it like a normal app before replacing HOME.

**Honest limitation:** No Android TV or Flutter SDK runtime is installed in this build environment. The changed source was checked statically but not compiled as an APK or tested on the physical Xiaomi TV. Direct HDMI switching is manufacturer-specific and cannot be guaranteed.
