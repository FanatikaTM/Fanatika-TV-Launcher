"""v2.9.14: restore content-driven accent colors and make the white focus ring pulse outward."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent

def src(rel: str) -> str:
    return (ROOT / rel).read_text()

class T(unittest.TestCase):
    def test_version(self):
        self.assertIn('version: 2.9.14+4157', src('pubspec.yaml'))
        self.assertIn('Fanatika menu v2.9.14', src('lib/widgets/application_info_panel.dart'))

    def test_watch_next_restores_v2910_accent_glow(self):
        s = src('lib/widgets/fanatika_watch_next_panel.dart')
        for needle in (
            'artworkAccent.withValues(alpha: 0.22)',
            'artworkAccent.withValues(alpha: 0.42)',
            'color: glow,',
            'blurRadius: 26 + (t * 9)',
            'spreadRadius: 1.2 + (t * 1.2)',
        ):
            self.assertIn(needle, s)

    def test_watch_next_white_pulse_expands_outward(self):
        s = src('lib/widgets/fanatika_watch_next_panel.dart')
        for needle in (
            'width: 2.0',
            'color: Colors.white.withValues(alpha: 0.14 + (t * 0.16))',
            'blurRadius: 8 + (t * 7)',
            'spreadRadius: 0.8 + (t * 1.8)',
        ):
            self.assertIn(needle, s)

    def test_apps_restore_content_color_glow(self):
        s = src('lib/widgets/app_card.dart')
        for needle in (
            '_contentGlowColor.withValues(alpha: 0.26)',
            '_contentGlowColor.withValues(alpha: 0.48)',
            '_contentGlowColor.withValues(alpha: 0.18)',
            'shadowColor: shouldHighlight && fanatikaGlowEnabled\n                              ? _contentGlowColor : Colors.black',
            'accentColor: _accentColor',
        ):
            self.assertIn(needle, s)

    def test_app_white_pulse_expands_outward(self):
        s = src('lib/widgets/app_card.dart')
        for needle in (
            'color: Colors.white.withValues(alpha: 0.14 + (pulse * 0.16))',
            'blurRadius: 8 + (pulse * 7)',
            'spreadRadius: 0.8 + (pulse * 1.8)',
        ):
            self.assertIn(needle, s)

if __name__ == '__main__':
    unittest.main()
