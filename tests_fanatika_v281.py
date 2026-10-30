"""Fanatika 2.8.1 Google TV-style quick controls and native timer safety checks."""
import unittest
from pathlib import Path
R = Path(__file__).resolve().parent

def read(p): return (R/p).read_text(encoding='utf-8')

class QuickSettings281(unittest.TestCase):
    def test_version_and_workflow(self):
        self.assertIn('version: 2.9.2+4145', read('pubspec.yaml'))
        self.assertIn('tests_fanatika_v281', read('.github/workflows/build-fanatika-signed.yml'))
    def test_visible_short_names(self):
        self.assertIn("'TV & tools'", read('lib/widgets/settings/settings_panel_page.dart'))
        self.assertIn("'Updates'", read('lib/widgets/settings/unified_settings_pages.dart'))
        self.assertIn("Text('Tools'", read('lib/widgets/settings/fanatika_tools_hub.dart'))
        self.assertIn("Text('Updates'", read('lib/widgets/settings/fanatika_updates_page.dart'))
    def test_top_pill_nav_does_not_override_home(self):
        s=read('lib/widgets/fanatika_top_bar_tabs.dart')
        for name in ["case 'Home'", "case 'Apps'", "case 'Tools'", 'onGoHome']:
            self.assertIn(name,s)
        self.assertIn('_scrollController.animateTo(0.0', read('lib/flauncher.dart'))
    def test_native_timer_does_not_claim_direct_oem_control(self):
        s=read('lib/widgets/fanatika_quick_settings_dialog.dart')
        self.assertIn('FanatikaSleepTimerDialog()',s)
        self.assertIn('fanatikaSleepTimer(minutes)',read('lib/widgets/fanatika_sleep_timer_dialog.dart'))
        self.assertIn('Device Administrator',read('android/app/src/main/java/com/leanbitlab/ltvL/FanatikaSleepController.java'))
        for dangerous in ['pm disable', 'WRITE_SECURE_SETTINGS', 'Runtime.getRuntime', 'KEYCODE_HOME']:
            self.assertNotIn(dangerous,s)
    def test_previous_favorites_present(self):
        s=read('lib/providers/apps_service.dart')
        for m in ['addToFavorites','removeFromFavorites','reorderApplication']:
            self.assertIn(m,s)
if __name__=='__main__':unittest.main()
