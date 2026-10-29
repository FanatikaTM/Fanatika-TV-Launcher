"""Fanatika v2.8.2 compact Watch Next beside Weather checks (source only)."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def read(p): return (ROOT/p).read_text(encoding='utf-8')

class FanatikaV282Tests(unittest.TestCase):
    def test_version(self):
        self.assertIn('version: 2.8.9+4142', read('pubspec.yaml'))
    def test_watch_next_left_of_weather(self):
        source=read('lib/flauncher.dart')
        self.assertIn('FanatikaWatchNextPanel(',source)
        self.assertLess(source.index('FanatikaWatchNextPanel('),source.index('FanatikaWeatherCard('))
        self.assertNotIn('child: WatchNextRow(',source)
    def test_hero_is_below_both_panels(self):
        source=read('lib/flauncher.dart')
        self.assertLess(source.index('FanatikaWeatherCard('),source.index('if (heroEnabled) Expanded('))
        self.assertIn('key: ValueKey(_focusedFavoritePackage',source)
    def test_empty_state_and_permission_recovery(self):
        source=read('lib/widgets/fanatika_watch_next_panel.dart')
        for feature in ['SizedBox.shrink()', 'refreshPermissionAndItems','service.items.length']:
            self.assertIn(feature,source)
        self.assertNotIn('No Watch Next titles available',source)
    def test_real_provider_not_fake_content(self):
        source=read('lib/widgets/fanatika_watch_next_panel.dart')
        self.assertIn('getCachedPoster',source)
        self.assertIn('service.launchItem(widget.item)',source)
        self.assertNotIn('demoItems',source)
    def test_favorites_integrity(self):
        source=read('lib/providers/apps_service.dart')
        for marker in ['addToFavorites','removeFromFavorites','reorderApplication']:
            self.assertIn(marker,source)
    def test_workflow(self):
        self.assertIn('tests_fanatika_v282',read('.github/workflows/build-fanatika-signed.yml'))

if __name__=='__main__': unittest.main()
