"""v2.9.2 regression checks for the Xiaomi TV issues reported on v2.9.1."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parent
read = lambda p: (ROOT/p).read_text(encoding='utf-8')
class V292(unittest.TestCase):
    def test_weather_option_accepted_without_permitting_arbitrary_settings(self):
        s = read('lib/providers/settings_service.dart')
        self.assertIn("key != 'fanatika_v27_auto_weather_location'",s)
        self.assertIn("throw ArgumentError('Invalid setting key')",s)
    def test_favorites_up_uses_watch_next_not_settings(self):
        s=read('lib/widgets/app_card.dart')
        self.assertIn('widget.onNavigateUp!()',s)
        self.assertLess(s.index('widget.onNavigateUp!()'),s.index('MoveFocusToSettingsIntent()'))
        self.assertIn('onNavigateUp: onNavigateUp',read('lib/widgets/category_clean_row.dart'))
        home=read('lib/flauncher.dart')
        self.assertIn('onNavigateUp: _focusFromFavoritesUp',home)
        self.assertIn('feed.hasItems',home)
        self.assertNotIn('refreshFocusNode:',home)
    def test_empty_watch_next_refresh_still_focusable(self):
        s=read('lib/widgets/fanatika_watch_next_panel.dart')
        self.assertNotIn('refreshFocusNode',s)
        self.assertIn('widget.onNavigateUp?.call()',s)
    def test_plex_does_not_force_manual_entry(self):
        s=read('lib/widgets/settings/plex_continue_watching_page.dart')
        self.assertNotIn('Manual server setup',s)
        self.assertIn('Plex connected. Continue Watching updated.',s)
        self.assertIn('setPlexContinueWatchingConfig(',s)
        self.assertIn('Start Plex pairing',s)
    def test_top_bar_original_controls_and_arc_favorites_preserved(self):
        bar=read('lib/widgets/fanatika_top_bar_tabs.dart')
        self.assertIn('Icons.grid_view_rounded',bar)
        self.assertIn("case 'Input':",bar)
        settings=read('lib/providers/settings_service.dart')
        self.assertIn('fanatikaTopBarTabs',settings)
        self.assertIn("const ['Quick','Home','Apps','Settings','Input']",settings)
        self.assertIn('addToFavorites',read('lib/providers/apps_service.dart'))
        self.assertIn('removeFromFavorites',read('lib/providers/apps_service.dart'))
if __name__ == '__main__': unittest.main()
