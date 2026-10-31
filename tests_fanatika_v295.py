"""v2.9.5: reduce duplicate top navigation and quick controls."""
import unittest
from pathlib import Path
R=Path(__file__).parent
read=lambda file: (R/file).read_text(encoding='utf8')

class CompactMenus295(unittest.TestCase):
    def test_tools_does_not_reappear_for_saved_users(self):
        s=read('lib/providers/settings_service.dart')
        self.assertNotIn("'Home','Apps','Tools'", s)
        self.assertIn("'Home','Apps','Settings','Input','Quick'",s)
        self.assertIn('where(fanatikaAvailableTopBarTabs.contains)',s)
        self.assertIn('toSet().toList()',s)
    def test_tools_is_not_top_bar_button_but_system_menu_remains(self):
        bar=read('lib/widgets/fanatika_top_bar_tabs.dart')
        root=read('lib/widgets/settings/settings_panel_page.dart')
        system=read('lib/widgets/settings/unified_settings_pages.dart')
        self.assertNotIn("case 'Tools'",bar)
        for text in ["case 'Quick'", "case 'Home'", "case 'Apps'", "case 'Settings'", "case 'Input'"]:
            self.assertIn(text,bar)
        self.assertIn("'TV & tools'",root)
        for text in ["'Sleep timer'", "'Input'", "'Backup & restore'", "'Advanced tools'"]:
            self.assertIn(text,system)
    def test_quick_only_device_actions_no_duplicate_home_or_input(self):
        quick=read('lib/widgets/fanatika_quick_settings_dialog.dart')
        for label in ['Screensaver','Picture','Sound','Wi-Fi','Bluetooth','Sleep timer']:
            self.assertIn("text: '"+label+"'", quick)
        for label in ["text: 'Input'", "text: 'Home settings'",'android.settings.HOME_SETTINGS']:
            self.assertNotIn(label,quick)
    def test_editor_and_version(self):
        self.assertIn('top bar',read('lib/widgets/settings/fanatika_top_bar_editor_page.dart'))
        self.assertIn('version: 2.9.9+4152',read('pubspec.yaml'))
    def test_arc_favorites_still_work(self):
        apps=read('lib/providers/apps_service.dart')
        for method in ['addToFavorites','removeFromFavorites','reorderApplication']:
            self.assertIn(method,apps)
