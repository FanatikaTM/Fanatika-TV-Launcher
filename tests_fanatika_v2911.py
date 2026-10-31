"""v2.9.11 focus and low-distraction artwork halo regression checks.
Source checks supplement, but do not substitute for, compiling on Flutter.
"""
from pathlib import Path
import unittest
R=Path(__file__).parent
def src(name): return (R/name).read_text(encoding='utf8')

class FocusAndSubtleGlow2911(unittest.TestCase):
    def test_version_is_prerelease_below_three(self):
        self.assertIn('version: 2.9.14+4157', src('pubspec.yaml'))
    def test_action_rows_use_direct_focus_not_nested_button_focus(self):
        s=src('lib/widgets/fanatika_tv_action_row.dart')
        for term in ('focusNode: widget.focusNode', 'GestureDetector(',
                     'LogicalKeyboardKey.arrowUp', 'LogicalKeyboardKey.arrowDown',
                     'LogicalKeyboardKey.select', 'widget.onPressed()',
                     'const Color(0xFF1975CC)', 'onFocusChange:'):
            self.assertIn(term, s)
    def test_app_action_panel_initial_focus_and_explicit_navigation(self):
        s=src('lib/widgets/application_info_panel.dart')
        for term in ('_visibleActions = [', '_moveAction(id, -1)',
                     '_moveAction(id, 1)', "FocusScope.of(context).requestFocus(_node('open_$pkg'))",
                     'autofocus: true', 'FanatikaTvActionRow('):
            self.assertIn(term, s)
        self.assertNotIn('FocusableSettingsTile(',s)
    def test_destination_list_remote_focus_and_arc_backend(self):
        s=src('lib/widgets/fanatika_add_to_category_dialog.dart')
        for term in ('FanatikaTvActionRow(', 'autofocus: index == 0',
                     'addToCategory(widget.selectedApplication, category)',
                     '.requestFocus()', 'FocusNode('):
            self.assertIn(term, s)
    def test_watch_next_white_ring_breathes_not_color_ring(self):
        s=src('lib/widgets/fanatika_watch_next_panel.dart')
        for term in ('Colors.white.withValues(alpha: 0.42 + (t * 0.58))',
                     'blurRadius: 11 + (t * 9)',
                     'getPosterAccent(', 'alpha: 0.055 + (t * 0.035)',
                     '_pulse.repeat(reverse: true)'):
            self.assertIn(term, s)
    def test_poster_colors_are_decoded_before_cache_notification(self):
        s=src('lib/providers/watch_next_service.dart')
        decode=s.index('await FanatikaArtworkColor.sample(imageBytes)')
        cache=s.index('_posterCache[uri] = imageBytes;',decode)
        notify=s.index('_schedulePosterCacheNotification();',cache)
        self.assertLess(decode,cache)
        self.assertLess(cache,notify)
    def test_app_focus_uses_white_border_and_faint_artwork_halo(self):
        s=src('lib/widgets/app_card.dart')
        for term in ('FanatikaArtworkColor.sample(bytes)',
                     '_contentGlowColor.withValues(alpha: 0.05)',
                     '_contentGlowColor.withValues(alpha: 0.085)',
                     'accentColor: Colors.white',
                     '_animation.repeat(reverse: true)'):
            self.assertIn(term, s)
    def test_sampling_is_small_and_disposed(self):
        s=src('lib/widgets/fanatika_artwork_color.dart')
        for term in ('targetWidth: 24, targetHeight: 24',
                     'image?.dispose()', 'codec?.dispose()', 'class FanatikaArtworkColor'):
            self.assertIn(term,s)
    def test_original_arc_editor_untouched(self):
        self.assertIn('class AddToCategoryDialog',src('lib/widgets/add_to_category_dialog.dart'))
        self.assertIn('toggleFavorite(widget.application)',src('lib/widgets/application_info_panel.dart'))

if __name__=='__main__':unittest.main()
