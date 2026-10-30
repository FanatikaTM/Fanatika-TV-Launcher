# Fanatika v2.9.2 — Xiaomi navigation, Plex setup and weather repair

- Weather automatic-location preference uses `fanatika_v27_auto_weather_location`; it is now an explicitly allowed key in the settings service. All other unknown non-v2 keys remain blocked.
- D-pad UP from a Favorite routes to **Watch Next Refresh**, then UP routes to **Home** in the top bar. UP from other Arc application rows retains original behavior. DOWN from the top bar visits first Watch Next card or Refresh if the feed is empty; otherwise first Favorite.
- Plex normal setup no longer forces the user into manual URL/token fields. Android TV recommendations, discovery and Plex account pairing remain. Successful account pairing saves the chosen Plex server automatically. Manual setup remains under the Advanced button.
- New-install top bar defaults to grid icon, Home, Apps, Settings, Input. Existing customized top bars **are not changed**. Tools and all optional tabs can still be enabled in Settings > Home & appearance > Top bar.
- Original Arc Favorites implementation, native Input menu, Watch Next data sources and launcher settings PIN remain unchanged.
- GitHub source tests updated and a new v292 regression suite added. Flutter compilation and hardware D-pad validation remain required.

## HOME key

The physical HOME key on Xiaomi MiTV-M0EU0 is not necessarily governed by the standard Android HOME role. The Windows Cleaner update shows a clear diagnostic when Android's role holder differs from resolved HOME; it does not disable Google TV or Xiaomi recovery components. Use **Save HOME report** and share the JSON for firmware-specific investigation. Do not run `pm disable-user` against stock Home or Setup Wizard without a verified recovery plan.
