"""Fanatika 2.9.8: shared Quick Menu visual style and remote navigation."""
import unittest
from pathlib import Path
ROOT = Path(__file__).parent
read = lambda name: (ROOT / name).read_text(encoding='utf-8')

class V298(unittest.TestCase):
    def test_shared_surface_matches_quick(self):
        shared = read('lib/widgets/settings/fanatika_panel_style.dart')
        quick = read('lib/widgets/fanatika_quick_settings_dialog.dart')
        panel = read('lib/widgets/side_panel_dialog.dart')
        self.assertIn('Color(0xFF242424)', shared)
        self.assertIn('Color(0xFF1E1E1E)', shared)
        self.assertIn('BorderRadius.circular(30)', shared)
        self.assertIn('FanatikaPanelStyle.decoration', quick)
        self.assertIn('FanatikaPanelStyle.decoration', panel)

    def test_settings_right_aligned_and_sized_like_quick(self):
        settings = read('lib/widgets/settings/settings_panel.dart')
        self.assertIn('isRightSide: true', settings)
        self.assertIn('FanatikaPanelStyle.panelWidth(', settings)
        self.assertIn('DialogThemeData(', settings)
        self.assertIn('MediaQuery.viewInsetsOf(context)', read('lib/widgets/side_panel_dialog.dart'))

    def test_submenu_focus_has_real_route_names(self):
        nav = read('lib/widgets/settings/settings_panel.dart')
        tile = read('lib/widgets/settings/focusable_settings_tile.dart')
        self.assertIn('_FastPageRoute(settings: settings, builder:', nav)
        self.assertIn('super.settings', nav)
        self.assertIn('arguments.join', tile)
        self.assertIn('Scrollable.ensureVisible', tile)
        self.assertIn('canRequestFocus: false', tile)

    def test_consistent_headers(self):
        for path in [
            'lib/widgets/settings/settings_panel_page.dart',
            'lib/widgets/settings/unified_settings_pages.dart',
            'lib/widgets/settings/fanatika_v2_page.dart',
            'lib/widgets/settings/plex_continue_watching_page.dart',
            'lib/widgets/settings/fanatika_top_bar_editor_page.dart',
        ]:
            self.assertIn('FanatikaPanelHeader', read(path), path)
        plex = read('lib/widgets/settings/plex_continue_watching_page.dart')
        self.assertNotIn('appBar: AppBar(', plex)
        self.assertNotIn('return Scaffold(', plex)

    def test_wallpaper_dialog_responsive(self):
        p = read('lib/widgets/settings/fanatika_mountains_dialog.dart')
        self.assertIn('MediaQuery.sizeOf(context)', p)
        self.assertIn('width < 680 ? 2 : 3', p)
        self.assertIn('FanatikaPanelStyle.decoration', p)

    def test_sleep_and_preview_share_quick_menu_surface(self):
        for path in [
            'lib/widgets/fanatika_sleep_timer_dialog.dart',
            'lib/widgets/settings/fanatika_theme_preview.dart',
        ]:
            self.assertIn('FanatikaPanelStyle.decoration', read(path), path)
        self.assertIn('FanatikaPanelStyle.focusedTile',
            read('lib/widgets/fanatika_sleep_timer_dialog.dart'))

    def test_compact_bar_stays_and_arc_favorites_intact(self):
        tab = read('lib/widgets/settings/fanatika_top_bar_editor_page.dart')
        self.assertIn('LogicalKeyboardKey.arrowLeft', tab)
        self.assertIn('LogicalKeyboardKey.arrowRight', tab)
        self.assertIn('version: 2.9.9+4152',read('pubspec.yaml'))
        self.assertIn('LauncherSectionsPanelPage.routeName', read('lib/widgets/settings/unified_settings_pages.dart'))
