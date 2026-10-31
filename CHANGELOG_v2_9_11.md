# Fanatika TV Launcher v2.9.11 (pre-v3 development build)

- App long-press action menu now explicitly gives the first action focus and handles TV remote Up, Down and OK keys. A focused row has a clear blue highlight and white border. This fixes the invisible selection seen on the Xiaomi TV.
- 'Add to Category' destination selector uses the same focus implementation and the existing Arc AppsService method. The original Arc Favorites editor and backend were not changed.
- Watch Next has a softly pulsating WHITE outer focus outline, with an almost imperceptible artwork-colored halo.
- Every app card (Favorites, sections and app grids) receives matching white pulse and very faint artwork-based glow while focused; motion is disabled when the existing performance/animation controls disable it.
- Watch Next poster color is precomputed when artwork loads and stored with the poster cache so it cannot switch colors after selection.
- The artwork color sampler decodes a 24x24 image and disposes resources immediately; only the selected item animates.

Validation: 221 Python source tests pass. A Flutter compile and real Xiaomi TV interaction test are still needed; the source archive does not contain an APK.
The separate physical HOME replacement project remains paused until GO GO TV.
