# Fanatika TV Launcher v2.8.2 — Watch Next and Weather layout

Based on v2.8.1 for MiTV-M0EU0. The Watch Next section is now a compact
horizontal panel to the left of the weather card. The focused app title is
anchored below both, just above the Favorites dock. The previous separate
full-width Watch Next sliver is removed.

Watch Next depends on entries provided through Android's TV provider. If
permission is missing, the compact panel offers Allow / Recheck. If permission
exists but the provider has no entries (common when apps do not publish to the
standard Android TV Watch Next provider), it shows an honest empty-state
message and a Refresh icon. It does NOT fabricate Plex or YouTube history.

To test on TV: enable "Show Watch Next section" in Settings, open a supported
streaming app and watch part of a program, return to Fanatika, and Refresh.
If the TV provider remains empty, apps may not be sharing recommendations
through the public API. The panel will still remain visible.

Build status: Python source checks only. Flutter/Gradle compilation and physical
MiTV-M0EU0 testing are pending. Keep using your permanent signing certificate.
