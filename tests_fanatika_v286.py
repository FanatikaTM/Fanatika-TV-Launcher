"""v2.8.6 unified settings regressions (static source checks; not Flutter compilation)."""
from pathlib import Path
import hashlib
import unittest
R = Path(__file__).resolve().parent

def read(name):
    return (R / name).read_text(encoding='utf-8')

class Unified286Tests(unittest.TestCase):
    def test_version(self):
        self.assertIn('version: 2.9.2+4145', read('pubspec.yaml'))

    def test_arc_favorites_files_unchanged(self):
        hashes = {
            'lib/providers/apps_service.dart': 'ee1c70744418638165b61608df19578902d793194b7702eb0e38367639d3917b',
            'lib/database.dart': 'e561bdd070cab1b7ad48ea34e2c4677c5ef0b00ad67ecfd65e6fa526e80f19ea',
            'lib/widgets/settings/applications_panel_page.dart': 'afb8af7b7b85b581452838614b89c99f5bc6999cc28c102ae27d077891f57964',
        }
        for file, expected in hashes.items():
            self.assertEqual(hashlib.sha256((R/file).read_bytes()).hexdigest(), expected)

    def test_merged_root_only(self):
        root = read('lib/widgets/settings/settings_panel_page.dart')
        for name in ['UnifiedHomePage.routeName','UnifiedAppsPage.routeName',
                     'UnifiedMediaPage.routeName',
                     'UnifiedSystemPage.routeName']:
            self.assertIn(name,root)
        for old in ['FanatikaToolsHub.routeName', 'FanatikaQuickSettingsDialog()',
                    'TvInputsPanelPage.routeName']:
            self.assertNotIn(old,root)

    def test_top_tab_buttons_route_into_same_settings(self):
        nav=read('lib/widgets/tv_top_navigation_dialog.dart')
        self.assertIn('SettingsPanel(initialRoute: route)',nav)
        self.assertNotIn('return Dialog(',nav)
        self.assertNotIn('FocusableSettingsTile(',nav)
        self.assertIn('UnifiedHomePage.routeName',nav)
        self.assertIn('UnifiedAppsPage.routeName',nav)
        self.assertIn('UnifiedSystemPage.routeName',nav)

    def test_app_bar_visual_elements_still_present(self):
        bar=read('lib/widgets/focus_aware_app_bar.dart')
        for s in ['fanatikaStatusBarStyle', 'FanatikaTopBarTabs(', 'SingleChildScrollView(']:
            self.assertIn(s,bar)
        for s in ["case 'Home'", "case 'Apps'", "case 'Tools'", "case 'Input'"]:
            self.assertIn(s,read('lib/widgets/fanatika_top_bar_tabs.dart'))

    def test_native_inputs_only(self):
        unified=read('lib/widgets/settings/unified_settings_pages.dart')
        inp=read('lib/widgets/settings/tv_inputs_panel_page.dart')
        top=read('lib/widgets/focus_aware_app_bar.dart')
        self.assertIn('openTvSourcePicker()', unified)
        self.assertIn('openTvSourcePicker()', inp)
        self.assertIn('openTvSourcePicker()', read('lib/widgets/fanatika_top_bar_tabs.dart'))
        self.assertNotIn('tryXiaomiHdmi',inp)
        self.assertNotIn('getTvInputs()',inp)
        self.assertNotIn('editInputNames',read('lib/widgets/settings/fanatika_v2_page.dart'))

    def test_quick_controls_no_duplicate_menu(self):
        q=read('lib/widgets/fanatika_quick_settings_dialog.dart')
        self.assertIn('Widget _mainTiles()', q)
        self.assertNotIn('Widget _secondaryTiles()', q)
        self.assertNotIn('All settings', q)
        self.assertNotIn('FanatikaToolsHub.routeName', q)
        self.assertIn('Color(0xFF1E1E1E)',q)

    def test_arc_colors(self):
        focus=read('lib/widgets/settings/focusable_settings_tile.dart')
        self.assertIn('Theme.of(context).colorScheme.surfaceContainerHigh',focus)
        self.assertIn('Theme.of(context).colorScheme.primary',focus)
        self.assertNotIn('Color(0xFF7CB7FF)',focus)
        plex=read('lib/widgets/settings/plex_continue_watching_page.dart')
        self.assertIn('Theme.of(context).colorScheme.surface',plex)

    def test_big_title_font_choices_persist(self):
        font=read('lib/widgets/settings/fanatika_title_font_page.dart')
        settings=read('lib/providers/settings_service.dart')
        launcher=read('lib/flauncher.dart')
        for f in ['Automatic','sans-serif-condensed','sans-serif-light',
                  'sans-serif-black','serif','monospace','cursive']:
            self.assertIn(f,font)
        self.assertIn("'fanatika_v2_title_font'",font)
        self.assertIn('fanatikaTitleFont',settings)
        self.assertIn('fanatikaSettings.fanatikaTitleFont',launcher)
        self.assertIn('Automatic',launcher)

    def test_font_live_preview_cancel_and_apply(self):
        preview=read('lib/widgets/settings/fanatika_theme_preview.dart')
        self.assertIn("late String _font",preview)
        self.assertIn('Future<void> _chooseFont()',preview)
        self.assertIn("setFanatikaOption('fanatika_v2_title_font', _font)",preview)
        self.assertIn("title: 'Cancel'",preview)
        self.assertIn("title: 'Apply changes'",preview)

    def test_plex_watch_next_retained(self):
        merged=read('lib/widgets/settings/unified_settings_pages.dart')
        self.assertIn('PlexContinueWatchingPage.routeName',merged)
        backend=read('lib/providers/plex_continue_watching_client.dart')
        self.assertIn('/hubs/continueWatching/items',backend)
        self.assertIn('X-Plex-Token',backend)

    def test_fanatika_advanced_options_still_reachable(self):
        merged=read('lib/widgets/settings/unified_settings_pages.dart')
        self.assertIn('FanatikaV2Page.routeName',merged)
        for name in ['Large selected-app title','Weather','Backup and restore']:
            self.assertIn(name,merged)
        self.assertIn('settings.arguments as List<String>?',read('lib/widgets/settings/settings_panel.dart'))

    def test_pin_guard_not_bypassed(self):
        p=read('lib/widgets/settings/settings_panel.dart')
        self.assertIn('Settings locked',p)
        self.assertIn('sha256.convert',p)
        self.assertIn('unlockedByParent: storedPin.isEmpty || _pinUnlocked',p)
        a=read('lib/widgets/settings/fanatika_v2_page.dart')
        self.assertIn('!widget.unlockedByParent',a)

    def test_no_new_permissions(self):
        android=read('android/app/src/main/AndroidManifest.xml')
        for s in ['android.permission.INTERNET','android.permission.ACCESS_NETWORK_STATE']:
            self.assertIn(s,android)
        self.assertNotIn('android.permission.WRITE_SECURE_SETTINGS',android)

if __name__ == '__main__': unittest.main()
