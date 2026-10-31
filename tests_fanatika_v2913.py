"""v2.9.13: keep Watch Next inside its column, restore deep blue cards,
  make focus ring visible on top of content, and pulse every selected app.
"""
from pathlib import Path
import unittest
ROOT = Path(__file__).parent
src = lambda name: (ROOT/name).read_text(encoding='utf8')

class V2913(unittest.TestCase):
    def test_version(self):
        self.assertIn('version: 2.9.15+4158', src('pubspec.yaml'))

    def test_weather_cannot_be_overpainted_by_posters(self):
        s = src('lib/widgets/fanatika_watch_next_panel.dart')
        self.assertIn('clipBehavior: Clip.hardEdge', s)
        self.assertNotIn('clipBehavior: Clip.none', s)
        self.assertIn('padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)', s)

    def test_darker_translucent_blue_cards(self):
        s=src('lib/widgets/fanatika_watch_next_panel.dart')
        self.assertIn('const Color(0xB52A619B)',s)
        self.assertIn('const Color(0xA819477D)',s)
        self.assertNotIn('const Color(0xFF63B6EC)',s)

    def test_outer_white_pulse_drawn_above_content(self):
        s=src('lib/widgets/fanatika_watch_next_panel.dart')
        self.assertIn('child: Stack(', s)
        self.assertIn('if (_focused) IgnorePointer(',s)
        self.assertIn('Colors.white.withValues(alpha: 1.0 - t)',s)
        self.assertIn('width: 2.0',s)
        self.assertIn('_pulse.repeat(reverse: true)',s)
        self.assertLess(s.index('child: child,'),s.index('if (_focused) IgnorePointer('))

    def test_app_ring_ignores_optional_animation_toggle(self):
        s=src('lib/widgets/app_card.dart')
        self.assertIn('bool _animationEnabled = true;',s)
        self.assertIn('if (shouldHighlight && !_moving)',s)
        self.assertIn('return _isFocused;',s)
        self.assertIn('_animation.repeat(reverse: true)',s)
        self.assertIn('color: Colors.white.withValues(alpha: ringOpacity)',s)
        self.assertIn('width: 2.0',s)
        self.assertNotIn('showFocusBorders || fanatikaGlowEnabled',s)

    def test_favorites_backend_unchanged(self):
        s=src('lib/widgets/app_card.dart')
        self.assertIn('widget.onMove(AxisDirection.left)',s)
        self.assertIn('ApplicationInfoPanel(category: widget.category',s)

if __name__ == '__main__': unittest.main()
