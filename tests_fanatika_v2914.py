"""v2.9.14: restore content-driven accent colors and make the white focus ring pulse outward."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent

def src(rel: str) -> str:
    return (ROOT / rel).read_text()

class T(unittest.TestCase):
    def test_version(self):
        self.assertIn('version: 2.9.15+4158', src('pubspec.yaml'))
        self.assertIn('Fanatika menu v2.9.15', src('lib/widgets/application_info_panel.dart'))

    def test_watch_next_restores_v2910_accent_glow(self):
        s = src('lib/widgets/fanatika_watch_next_panel.dart')
        for needle in (
            'artworkAccent.withValues(alpha: 0.35)',
            'color: glow,',
            'blurRadius: 29',
            'spreadRadius: 2.0',
        ):
            self.assertIn(needle, s)

    def test_watch_next_white_pulse_fades_without_expansion(self):
        s = src('lib/widgets/fanatika_watch_next_panel.dart')
        for needle in (
            'width: 2.0',
            'color: Colors.white.withValues(alpha: 1.0 - t)',
            '_pulse.repeat(reverse: true)',
            'blurRadius: 29',
        ):
            self.assertIn(needle, s)

    def test_apps_restore_content_color_glow(self):
        s = src('lib/widgets/app_card.dart')
        for needle in (
            '_contentGlowColor.withValues(alpha: 0.35)',
            '_contentGlowColor.withValues(alpha: 0.13)',
            'final ringOpacity = 1.0 - _curvedAnimation.value',
            'shadowColor: shouldHighlight && fanatikaGlowEnabled\n                              ? _contentGlowColor : Colors.black',
            'accentColor: _accentColor',
        ):
            self.assertIn(needle, s)

    def test_app_white_pulse_fades_without_expansion(self):
        s = src('lib/widgets/app_card.dart')
        for needle in (
            'color: Colors.white.withValues(alpha: ringOpacity)',
            'width: 2.0',
            'final ringOpacity = 1.0 - _curvedAnimation.value',
        ):
            self.assertIn(needle, s)

if __name__ == '__main__':
    unittest.main()
