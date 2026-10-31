# Fanatika TV Launcher 2.9.8 — Quick Menu visual parity

All launcher settings windows now use the same dark gradient, rounded 30px
corners, light outline, shadow and right-side placement as Quick Settings.
The blue HOME top bar and Arc Favorites implementation are preserved.

## Changes
- Shared `FanatikaPanelStyle` for Quick Settings, side panels and wallpaper picker.
- Shared titled headers with Back across unified, Plex, large-font and customization pages.
- Menu page routing now preserves `RouteSettings` and section-specific focus.
- One remote focus target per standard setting row, including focus-driven scroll.
- Responsive width, height and wallpaper columns for smaller screens and keyboard.
- Plex setup no longer embeds a second Scaffold/AppBar inside Settings.
- Tab reorder arrows now point left and right.
- Existing quick actions, Plex pairing, wallpapers and Favorites unchanged.

## Validation
Run `python3 -m unittest discover -p 'tests*.py'` and
`flutter analyze --no-fatal-infos --no-fatal-warnings` on your build runner.
Flutter compilation and physical TV behavior still require device verification.
