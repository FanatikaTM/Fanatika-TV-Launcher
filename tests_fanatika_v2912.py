"""v2.9.12: blue Watch Next and visible TV-menu focus regressions.
Static assertions; Android focus behavior requires device validation.
"""
from pathlib import Path
import unittest
ROOT=Path(__file__).parent
src=lambda p:(ROOT/p).read_text(encoding='utf-8')

class V2912(unittest.TestCase):
    def test_version(self):
        self.assertIn('version: 2.9.12+4155', src('pubspec.yaml'))
    def test_watch_next_blue_fill_white_pulse(self):
        s=src('lib/widgets/fanatika_watch_next_panel.dart')
        self.assertIn('const Color(0xFF63B6EC)',s)
        self.assertIn('const Color(0xD51F6DAC)',s)
        self.assertIn('0.52 + (t * 0.47)',s)
        self.assertIn('1.9 + (t * 1.4)',s)
        self.assertIn('_pulse.repeat(reverse: true)',s)
        self.assertIn('getPosterAccent(',s)
    def test_all_app_card_rings_pulse_white(self):
        s=src('lib/widgets/app_card.dart')
        self.assertIn('final alpha = 0.54 + (_animation.value * 0.46)',s)
        self.assertIn('strokeWidth: (borderThickness + 0.8 + _animation.value * 1.6)',s)
        self.assertIn('accentColor: Colors.white',s)
        self.assertIn('_contentGlowColor.withValues(alpha: 0.05)',s)
    def test_app_menu_has_unambiguous_initial_selection(self):
        page=src('lib/widgets/application_info_panel.dart')
        row=src('lib/widgets/fanatika_tv_action_row.dart')
        self.assertIn('Fanatika menu v2.9.12',page)
        self.assertIn("_selectedActionId = 'open_${widget.application.packageName}'",page)
        self.assertIn('selected: _selectedActionId == id',page)
        self.assertIn('FocusScope.of(context).requestFocus(',page)
        self.assertIn('final highlighted = _hasFocus || widget.selected',row)
        self.assertIn('GestureDetector(',row)
        self.assertNotIn('InkWell(',row)
        for key in ('arrowUp','arrowDown','select','gameButtonA'):
            self.assertIn('LogicalKeyboardKey.'+key,row)
    def test_original_arc_favorites_backend_preserved(self):
        self.assertIn('class AddToCategoryDialog',src('lib/widgets/add_to_category_dialog.dart'))
        self.assertIn('toggleFavorite(widget.application)',src('lib/widgets/application_info_panel.dart'))

if __name__=='__main__': unittest.main()
