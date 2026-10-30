from pathlib import Path
import unittest
R = Path(__file__).parent
read = lambda path: (R/path).read_text()
class Fanatika290(unittest.TestCase):
    def test_watch_next_up_returns_home_not_settings(self):
        self.assertIn('onNavigateUp: () => _appBarKey.currentState?.focusHome()', read('lib/flauncher.dart'))
        self.assertIn('void focusHome()', read('lib/widgets/focus_aware_app_bar.dart'))
        self.assertIn("name == 'Home' ? homeFocusNode", read('lib/widgets/fanatika_top_bar_tabs.dart'))
    def test_plex_pairing_replaces_keyboard_and_manual_save(self):
        page = read('lib/widgets/settings/plex_continue_watching_page.dart')
        for marker in ['Start Plex pairing', 'I approved Plex', 'setPlexContinueWatchingConfig(',
                       'Choose your Plex server', 'Disconnect Plex']:
            self.assertIn(marker,page)
        for removed in ['TextField(', 'bottomNavigationBar:', 'Manual server setup']:
            self.assertNotIn(removed,page)
    def test_sleep_countdown_on_home(self):
        code = read('lib/widgets/fanatika_sleep_countdown_badge.dart')
        self.assertIn('fanatikaSleepStatus()', code)
        self.assertIn('Timer.periodic',code)
        self.assertIn('FanatikaSleepCountdownBadge()',read('lib/flauncher.dart'))
    def test_sleep_theme_matches_arc_menu(self):
        theme = read('lib/widgets/side_panel_dialog.dart')
        sleep = read('lib/widgets/fanatika_sleep_timer_dialog.dart')
        self.assertIn('Color(0xFF1E1E1E)',theme)
        self.assertIn('Color(0xFF1E1E1E)',sleep)
