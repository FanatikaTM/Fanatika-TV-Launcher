"""v2.9.10 CI regression checks: content focus effects and TV action dialog.
These static checks supplement, but cannot replace, a Flutter build/device test.
"""
from pathlib import Path
import unittest
ROOT=Path(__file__).parent
read=lambda p:(ROOT/p).read_text(encoding='utf8')

class V2910(unittest.TestCase):
    def test_version_matches_archive(self):
        self.assertIn('version: 2.9.15+4158',read('pubspec.yaml'))
    def test_rounded_full_watch_next_artwork(self):
        code=read('lib/widgets/fanatika_watch_next_panel.dart')
        for required in ('BorderRadius.circular(28)', 'BorderRadius.circular(20)',
                         'fit: BoxFit.contain', 'textAlign: TextAlign.center',
                         'SingleChildScrollView(', 'Scrollable.ensureVisible('):
            self.assertIn(required, code)
        self.assertNotIn('width: 280, height: 206',code)
        self.assertNotIn('fit: BoxFit.cover',code)
    def test_watch_next_has_static_content_glow_and_pulsing_ring(self):
        code=read('lib/widgets/fanatika_watch_next_panel.dart')
        for required in ('AnimationController(', '_pulse.repeat(reverse: true)',
                         'getPosterAccent(', 'color: glow,',
                         'Colors.white.withValues(alpha: 1.0 - t)'):
            self.assertIn(required,code)
    def test_apps_have_static_artwork_glow_and_pulsing_ring(self):
        code=read('lib/widgets/app_card.dart')
        for required in ('_contentGlowColor', 'FanatikaArtworkColor.sample(bytes)',
                         'AnimatedBuilder(', '_contentGlowColor.withValues(alpha: 0.35)',
                         'final ringOpacity = 1.0 - _curvedAnimation.value',
                         '_animation.repeat(reverse: true)'):
            self.assertIn(required,code)
    def test_action_menu_is_focusable(self):
        code=read('lib/widgets/application_info_panel.dart')
        for required in ('FanatikaTvActionRow(', 'autofocus: true',
                         'FanatikaAddToCategoryDialog(', 'toggleFavorite(',
                         'ApplicationInfoPanelResult.reorderApp'):
            self.assertIn(required,code)
    def test_arc_favorites_still_uses_original_backend(self):
        self.assertIn('addToCategory(widget.selectedApplication, category)',
                      read('lib/widgets/fanatika_add_to_category_dialog.dart'))
        self.assertIn('class AddToCategoryDialog',
                      read('lib/widgets/add_to_category_dialog.dart'))

if __name__ == '__main__':
    unittest.main()
