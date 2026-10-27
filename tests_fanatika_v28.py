"""v2.8 quick settings source checks (not compilation or TV hardware validation)."""
import unittest
from pathlib import Path
R = Path(__file__).resolve().parent

def read(p): return (R/p).read_text(encoding='utf-8')

class QuickSettingsChecks(unittest.TestCase):
    def test_menu_accessible_from_bar_and_settings(self):
        self.assertIn('FanatikaQuickSettingsDialog()', read('lib/widgets/focus_aware_app_bar.dart'))
        self.assertIn('FanatikaQuickSettingsDialog()', read('lib/widgets/settings/settings_panel_page.dart'))
    def test_all_tiles_present(self):
        source = read('lib/widgets/fanatika_quick_settings_dialog.dart')
        for name in ['Screensaver', 'Input source', 'Picture', 'Sound', 'Wi-Fi', 'Home settings', 'Bluetooth', 'Sleep timer']:
            self.assertIn("text: '%s'" % name, source)
    def test_safe_intents_and_no_home_modification(self):
        source = read('lib/widgets/fanatika_quick_settings_dialog.dart')
        for intent in ['android.settings.DISPLAY_SETTINGS', 'android.settings.SOUND_SETTINGS', 'android.settings.HOME_SETTINGS', 'android.settings.BLUETOOTH_SETTINGS']:
            self.assertIn(intent, source)
        for unsafe in ['pm disable', 'pm uninstall', 'Runtime.getRuntime', 'adb shell', 'WRITE_SECURE_SETTINGS']:
            self.assertNotIn(unsafe, source)
    def test_sleep_timer_is_real_and_permitted(self):
        source = read('lib/widgets/fanatika_quick_settings_dialog.dart')
        native = read('android/app/src/main/java/com/leanbitlab/ltvL/FanatikaSleepController.java')
        self.assertIn('fanatikaSleepTimer(minutes)',source)
        self.assertIn('Device Administrator', source)
        for duration in [15,30,45,60,90,120,180]:
            self.assertIn('minutes != %d' % duration, native)
    def test_favorites_unmodified(self):
        source = read('lib/providers/apps_service.dart')
        for method in ['getOrCreateFavoritesCategory','addToFavorites','removeFromFavorites','reorderApplication']:
            self.assertIn(method,source)
    def test_new_version(self): self.assertIn('version: 2.8.0+4133', read('pubspec.yaml'))
    def test_workflow(self): self.assertIn('tests_fanatika_v28',read('.github/workflows/build-fanatika-signed.yml'))

if __name__ == '__main__': unittest.main()
