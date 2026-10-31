# Fanatika v2.9.6 — Full Plex covers and clean Watch Next

- Removed the visible Watch Next refresh button and removed it from TV remote focus traversal.
- Preserved timed and on-resume background updates; manual refresh is still available in Plex settings.
- Changed Watch Next artwork from cropping (`BoxFit.cover`) to full-image display (`BoxFit.contain`) against a dark letterbox background.
- Changed card dimensions to 280 × 206 to give widescreen covers more room while retaining title below.
- Kept horizontal left/right D-pad traversal and scrolling each selected title fully into view.
- When no shows are loaded, Home/Up navigation falls back to the first Favorite or Home tab; no phantom refresh control.
- Home top-bar button remains a scroll-to-top shortcut, not the physical Android HOME override.
- Original Arc Favorites, Plex pairing, weather, sleep, menu colors, and HOME work pause preserved.

Source checks only; Flutter compilation and real TV navigation need on-device testing.
