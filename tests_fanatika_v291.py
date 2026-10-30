"""v2.9.1 unified settings navigation checks; source-level, not Flutter compilation."""
from pathlib import Path
import hashlib
import unittest
ROOT = Path(__file__).resolve().parent
read = lambda n: (ROOT/n).read_text(encoding='utf-8')

class Unified291(unittest.TestCase):
    def test_single_four_section_settings_root(self):
        s=read('lib/widgets/settings/settings_panel_page.dart')
        self.assertEqual(s.count('item(Icons.'), 4)
        for route in ['UnifiedHomePage.routeName','UnifiedAppsPage.routeName',
                      'UnifiedMediaPage.routeName','UnifiedSystemPage.routeName']:
            self.assertIn(route,s)
        self.assertNotIn('UnifiedWallpaperPage.routeName',s)

    def test_wallpapers_in_home_and_advanced_one_deeper(self):
        s=read('lib/widgets/settings/unified_settings_pages.dart')
        self.assertIn('UnifiedWallpaperPage.routeName',s)
        self.assertIn('UnifiedAdvancedPage.routeName',s)
        self.assertIn("'App descriptions & backgrounds'",s)
        self.assertIn("'App customization'",s)
        self.assertIn("'Weather'",s)
        self.assertIn("FanatikaToolSection('Weather')",read('lib/widgets/settings/fanatika_v2_page.dart'))
        self.assertIn("'Backup and restore'",s)
        self.assertIn("'Input'",s)
        self.assertIn('openTvSourcePicker()',s)

    def test_one_place_for_app_descriptions_and_backgrounds(self):
        s=read('lib/widgets/settings/fanatika_v2_page.dart')
        self.assertEqual(s.count("'Custom app descriptions'"), 1)
        self.assertEqual(s.count("'Background per favorite app'"), 1)
        self.assertIn("FanatikaToolSection('App customization')",s)

    def test_home_tab_returns_home_not_more_settings(self):
        s=read('lib/widgets/fanatika_top_bar_tabs.dart')
        self.assertIn("case 'Home':",s)
        self.assertIn('onGoHome!()',s)
        self.assertNotIn("settings(UnifiedHomePage.routeName);",s)
        self.assertIn('AppBarFocusRing(',s)

    def test_pin_and_favorites_retained(self):
        s=read('lib/widgets/settings/settings_panel.dart')
        self.assertIn('Settings locked',s)
        self.assertIn('UnifiedAdvancedPage.routeName',s)
        self.assertIn('unlockedByParent: storedPin.isEmpty || _pinUnlocked',s)
        apps=read('lib/providers/apps_service.dart')
        for method in ['addToFavorites','removeFromFavorites','reorderApplication']:
            self.assertIn(method,apps)

if __name__=='__main__': unittest.main()
