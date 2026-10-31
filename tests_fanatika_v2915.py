"""v2.9.15: white focus ring fades in place, per-artwork glow stays steady.

Source-level guardrails. Actual Flutter rendering must be checked on the TV.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).parent

def read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')

class FocusFadeRegression2915(unittest.TestCase):
    def test_version_below_three(self):
        self.assertIn('version: 2.9.15+4158', read('pubspec.yaml'))

    def test_white_app_ring_alpha_only(self):
        s = read('lib/widgets/app_card.dart')
        section = s[s.index('// Fixed-size white ring:'):s.index('// Original Arc moving/reorder outline')]
        self.assertIn('final ringOpacity = 1.0 - _curvedAnimation.value;', section)
        self.assertIn('Colors.white.withValues(alpha: ringOpacity)', section)
        self.assertIn('width: 2.0', section)
        self.assertNotIn('boxShadow:', section)
        self.assertNotIn('spreadRadius:', section)
        self.assertNotIn('width: 2.0 +', section)

    def test_watch_next_white_ring_alpha_only(self):
        s = read('lib/widgets/fanatika_watch_next_panel.dart')
        section = s[s.index('// Fixed 2 px white outline'):s.index('              ],\n            ),', s.index('// Fixed 2 px white outline'))]
        self.assertIn('Colors.white.withValues(alpha: 1.0 - t)', section)
        self.assertIn('width: 2.0', section)
        self.assertNotIn('boxShadow:', section)
        self.assertNotIn('blurRadius:', section)
        self.assertNotIn('width: 2.0 +', section)

    def test_app_color_glow_is_static(self):
        s = read('lib/widgets/app_card.dart')
        section = s[s.index('// The artwork-color halo is STATIC'):s.index('                          Material(', s.index('// The artwork-color halo is STATIC'))]
        self.assertIn('_contentGlowColor.withValues(alpha: 0.35)', section)
        self.assertIn('blurRadius: 27', section)
        self.assertIn('spreadRadius: 2.1', section)
        self.assertNotIn('AnimatedBuilder(', section)
        self.assertNotIn('pulse', section.split('if (shouldHighlight')[1])

    def test_poster_color_glow_is_static(self):
        s = read('lib/widgets/fanatika_watch_next_panel.dart')
        self.assertIn('final glow = artworkAccent.withValues(alpha: 0.35);', s)
        box = s[s.index('BoxShadow(\n                        color: glow'):s.index('                  child: child,', s.index('BoxShadow(\n                        color: glow'))]
        self.assertIn('blurRadius: 29', box)
        self.assertIn('spreadRadius: 2.0', box)
        self.assertNotIn('+ (t *', box)
        self.assertNotIn('Color.lerp(', box)

    def test_animation_runs_only_when_focused(self):
        app = read('lib/widgets/app_card.dart')
        poster = read('lib/widgets/fanatika_watch_next_panel.dart')
        self.assertIn('_setHighlightAnimation(_shouldHighlight() && _animationEnabled)', app)
        self.assertIn('_animation.repeat(reverse: true)', app)
        self.assertIn('_animation.stop()', app)
        self.assertIn('if (focused) {', poster)
        self.assertIn('_pulse.repeat(reverse: true)', poster)
        self.assertIn('_pulse.stop()', poster)

    def test_existing_layout_and_favorites_unchanged(self):
        poster = read('lib/widgets/fanatika_watch_next_panel.dart')
        app = read('lib/widgets/app_card.dart')
        self.assertIn('clipBehavior: Clip.hardEdge', poster)
        self.assertIn('height: 226', poster)
        self.assertIn('fit: BoxFit.contain', poster)
        self.assertIn('ApplicationInfoPanel(category: widget.category', app)
        self.assertIn('widget.onMove(AxisDirection.left)', app)

if __name__ == '__main__':
    unittest.main()
