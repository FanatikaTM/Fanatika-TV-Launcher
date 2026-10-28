# TV Launcher v2.8.4 — MiTV-M0EU0 navigation and layout

- D-pad Up from Watch Next Refresh/Allow/Recheck/item returns to the top bar Settings button, even where spatial focus search fails.
- Disabling **Show large app title** lets the Watch Next and Weather panels stretch vertically into its previous space. Favorites remain below.
- The top Home, Apps and Tools pills now open TV-remote-friendly grouped option menus. They reuse current settings routes and Arc Favorites management; they do not change the Android HOME handler.
- Same application ID, signing settings, and Favorites database. Version **2.8.4+4137**.
- Source-level regression checks: `python3 -m unittest tests_sleep_source tests_fanatika_remote_ui tests_fanatika_v23 tests_fanatika_v24 tests_fanatika_v25 tests_fanatika_v26 tests_fanatika_v27 tests_fanatika_v271 tests_fanatika_v28 tests_fanatika_v281 tests_fanatika_v282 tests_fanatika_v283 tests_fanatika_v284`.
- A real Flutter/Gradle signed build and D-pad testing on MiTV-M0EU0 are still required.
