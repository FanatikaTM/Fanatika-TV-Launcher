"""v2.9.10 CI regression checks: content focus effects and TV action dialog.
These static checks supplement, but cannot replace, a Flutter build/device test.
"""
from pathlib import Path
import unittest
ROOT=Path(__file__).parent
read=lambda p:(ROOT/p).read_text(encoding='utf8')

class V2910(unittest.TestCase):
    def test_version_matches_archive(self):
        self.assertIn('version: 2.9.10+4153',read('pubspec.yaml'))
    def test_rounded_full_watch_next_artwork(self):
        code=read('lib/widgets/fanatika_watch_next_panel.dart')
        for required in ('BorderRadius.circular(28)', 'BorderRadius.circular(20)',
                         'fit: BoxFit.contain', 'textAlign: TextAlign.center',
                         'SingleChildScrollView(', 'Scrollable.ensureVisible('):
            self.assertIn(required, code)
        self.assertNotIn('width: 280, height: 206',code)
        self.assertNotIn('fit: BoxFit.cover',code)
    def test_watch_next_has_pulsating_content_glow(self):
        code=read('lib/widgets/fanatika_watch_next_panel.dart')
        for required in ('AnimationController(', '_pulse.repeat(reverse: true)',
                         '_extractDominantColor(', 'BoxShadow(color: glow',
                         'targetWidth: 36'):
            self.assertIn(required,code)
    def test_apps_have_pulsating_artwork_glow(self):
        code=read('lib/widgets/app_card.dart')
        for required in ('_contentGlowColor', '_extractDominantColor(bytes)',
                         'AnimatedBuilder(', 'BoxShadow(color: mainGlow',
                         '_animation.repeat(reverse: true)'):
            self.assertIn(required,code)
    def test_action_menu_is_focusable(self):
        code=read('lib/widgets/application_info_panel.dart')
        for required in ('FocusableSettingsTile(', 'autofocus: true',
                         'FanatikaAddToCategoryDialog(', 'toggleFavorite(',
                         'ApplicationInfoPanelResult.reorderApp'):
            self.assertIn(required,code)
    def test_arc_favorites_still_uses_original_backend(self):
        self.assertIn('addToCategory(selectedApplication, category)',
                      read('lib/widgets/fanatika_add_to_category_dialog.dart'))
        self.assertIn('class AddToCategoryDialog',
                      read('lib/widgets/add_to_category_dialog.dart'))

if __name__ == '__main__':
    unittest.main()
