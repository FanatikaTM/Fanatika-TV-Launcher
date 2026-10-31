"""v2.9.9: TV focus, clean artwork and settings regression checks.
These are static source checks; they do not replace a real Flutter/TV build.
"""
from pathlib import Path
import hashlib
import unittest
ROOT=Path(__file__).resolve().parent

def source(path): return (ROOT/path).read_text()

class FocusAndAppearance299(unittest.TestCase):
    def test_version_stays_below_three(self):
        self.assertIn('version: 2.9.9+4152',source('pubspec.yaml'))
    def test_arc_original_favorites_dialog_preserved(self):
        orig=source('lib/widgets/add_to_category_dialog.dart')
        self.assertIn('class AddToCategoryDialog',orig)
        self.assertNotIn('FanatikaAddToCategoryDialog',orig)
    def test_new_destination_has_focus_and_original_backend(self):
        s=source('lib/widgets/fanatika_add_to_category_dialog.dart')
        for term in ('FocusableSettingsTile','autofocus: index == 0',
                     'addToCategory(selectedApplication, category)',
                     'destination_${category.id}_${category.name}'):
            self.assertIn(term,s)
    def test_app_actions_use_tv_highlight(self):
        s=source('lib/widgets/application_info_panel.dart')
        self.assertIn('WidgetState.focused',s)
        self.assertIn('FanatikaAddToCategoryDialog',s)
        s=source('lib/widgets/settings/app_details_page.dart')
        self.assertIn('focusColor:',s)
    def test_select_current_option(self):
        s=source('lib/widgets/settings/fanatika_tv_controls.dart')
        for term in ('focusIndex', 'index == focusIndex','initialScrollOffset',
                     'value == current','Icons.check_circle'):
            self.assertIn(term,s)
    def test_date_identity_and_focus(self):
        s=source('lib/widgets/settings/date_time_format_page.dart')
        self.assertIn("focusId: 'date_${entry.value.$1}'",s)
        self.assertIn("focusId: 'time_${preset.$1}'",s)
        self.assertIn('service.dateFormat == entry.value.$1',s)
    def test_topbar_one_control_per_row(self):
        s=source('lib/widgets/settings/fanatika_top_bar_editor_page.dart')
        self.assertIn('onKeyEvent:',s)
        self.assertIn('LogicalKeyboardKey.arrowLeft',s)
        self.assertIn('LogicalKeyboardKey.arrowRight',s)
        self.assertIn('VISIBLE TABS',s)
        self.assertIn('AVAILABLE TABS',s)
        self.assertNotIn('IconButton(',s)
    def test_fixed_title_without_toggle(self):
        self.assertIn('bool get fanatikaFixedTitle => true;',source('lib/providers/settings_service.dart'))
        self.assertNotIn("switcher('Lock title to fixed position'",source('lib/widgets/settings/fanatika_v2_page.dart'))
    def test_original_text_styles_untouched(self):
        s=source('lib/widgets/settings/fanatika_v2_page.dart')
        for preset in ('Classic','Bold','Cinema','Glass','Glow','Neon','Minimal','Wide','Shadow','Outline','Elegant','Mono','Soft','Steel','Sunset'):
            self.assertIn(preset,s)
    def test_more_system_fonts(self):
        s=source('lib/widgets/settings/fanatika_title_font_page.dart')
        for f in ('sans-serif-thin','sans-serif-condensed-light','sans-serif-rounded','serif-monospace'):
            self.assertIn(f,s)
    def test_wallpaper_gradient_picker_gone(self):
        self.assertNotIn('GradientPanelPage.routeName',source('lib/widgets/settings/wallpaper_panel_page.dart'))
    def test_poster_floating_and_title_centered(self):
        s=source('lib/widgets/fanatika_watch_next_panel.dart')
        self.assertIn('color: Colors.transparent,',s)
        self.assertIn('textAlign: TextAlign.center',s)
        self.assertIn('fit: BoxFit.contain',s)
        self.assertNotIn('const Color(0xFF0B1729)',s)
    def test_favorites_label_short(self):
        s=source('lib/widgets/settings/unified_settings_pages.dart')
        self.assertIn("'Favorites and Sections'",s)
        self.assertNotIn('Original Arc add, remove and reorder',s)

if __name__=='__main__':unittest.main()
