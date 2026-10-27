# TV Launcher v2.8.3 · MiTV-M0EU0

- Dark slate gray Google TV-inspired Quick Settings with light selected tiles.
- Top Home / Apps / Tools navigation no longer gated on a 980 logical pixel width; scrollable if icons fill the bar.
- Visible product wording simplified to TV Launcher, Quick Settings, Tools, Updates, and Customization. **About** retains Fanatika TV Launcher. Package and release signing identifiers are unchanged.
- Native input picker: first request `com.android.tv.action.VIEW_INPUTS` (AOSP Live TV public activity on compatible devices), then standard Android input actions. If the OEM blocks all of them, the existing detected-source page is displayed. No privileged bypass, no guaranteed Xiaomi OEM selector.
- Original branded splash asset remains in source for archival reasons but is no longer shown; the startup uses an unbranded TV glyph instead.
- User backup directory remains Downloads/Fanatika for backward compatibility.

The ZIP includes Flutter source, not a signed APK. Rebuild with the existing keystore; avoid uninstalling the working launcher. Verify on MiTV-M0EU0.
