# Fanatika TV Launcher v2.9.15 (developer build)

This release changes focus visualization only. Physical HOME replacement remains paused.

- Selected app cards and Watch Next posters keep a **static** colored glow derived from the displayed app artwork or poster. Their shadow color, opacity, blur and spread are not driven by the pulse animation.
- The **white outer ring** stays in the same location at 2.0 logical pixels and smoothly fades from visible to transparent and back. No animated width, scale, or expanding white shadow.
- The white ring animation repeats only while the card has focus. The artwork and background do not pulse.
- No changes to the Watch Next card dimensions, layout, weather clipping, Settings menus, or original Arc Favorites interactions.

## Testing

244 Python source regression tests passed. Flutter compile/Android TV runtime not verified in this environment. Build a signed APK using the existing GitHub workflow and test both the app row and Watch Next focus on the Xiaomi TV.
