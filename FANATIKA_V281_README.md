# Fanatika v2.8.1 — MiTV-M0EU0 UX

- Quick Settings uses a darker Google-TV-inspired slate-blue palette, with white D-pad focus.
- Top status bar has a Home / Apps / Tools pill (Home scrolls to the top), in addition to existing icons.
- Menus display Tools and Updates. Original routes, categories and Favorites remain intact.
- Sleep Timer includes a button to open the manufacturer's **TV settings**. From there navigate System > Power & Energy > Power > Sleep Timer. The OEM timer is not controllable through a public third-party API; no unverified deep links or false claims of direct timer control are used.
- Long-press HOME is system-reserved on some firmware, and is **not** redirected. Use the Quick Settings top icon or an Android-permitted alternative remote key.
- HOME reassignment is not forced and stock Google TV launcher remains enabled. Use the read-only ADB diagnostic script to investigate which HOME component wins.

Version 2.8.1+4134. Requires a signed APK build and actual MiTV-M0EU0 device testing.
