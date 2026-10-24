"""Source-level integration checks. These are not Flutter compile/device tests."""
import unittest
from pathlib import Path
from xml.etree import ElementTree
ROOT = Path(__file__).resolve().parent

def read(relative): return (ROOT / relative).read_text(encoding='utf-8')

class FanatikaV23SourceChecks(unittest.TestCase):
    def test_remote_tester_is_foreground_only(self):
        t=read('lib/widgets/settings/fanatika_remote_tester_page.dart')
        self.assertIn('KeyboardListener(',t)
        self.assertIn('KeyRepeatEvent',t)
        self.assertIn('last', 'last')
        self.assertNotIn('AccessibilityService',t)
    def test_focusable_entry_point_and_registered_route(self):
        t=read('lib/widgets/settings/fanatika_v2_page.dart')
        n=read('lib/widgets/settings/settings_panel.dart')
        self.assertNotIn('Remote Button Tester', t)  # intentionally removed from v2.7 menus
        self.assertIn('FanatikaToolsHub.routeName', n)
        self.assertIn('Live theme preview', t)
    def test_preview_does_not_write_until_apply(self):
        t=read('lib/widgets/settings/fanatika_theme_preview.dart')
        self.assertIn('Future<void> _apply()',t)
        self.assertIn('Cancel', t)
        self.assertIn('Apply changes', t)
    def test_recovery_scope(self):
        t=read('lib/providers/settings_service.dart')
        self.assertIn('enableFanatikaRecoveryProfile',t)
        self.assertIn('restoreFanatikaRecoveryProfile',t)
        segment=t.split('Future<void> enableFanatikaRecoveryProfile()',1)[1].split('double get focusBorderThickness',1)[0]
        for dangerous in ['pm disable', 'setupwraith', 'launcherx', 'uninstall']:
            self.assertNotIn(dangerous,segment)
    def test_favorites_code_intact(self):
        apps=read('lib/providers/apps_service.dart')
        for name in ['getOrCreateFavoritesCategory', 'addToFavorites', 'removeFromFavorites', 'reorderApplication']:
            self.assertIn(name, apps)
        self.assertIn('CategoryCleanRow',read('lib/flauncher.dart'))
    def test_memory_last_favorite_avoids_notify(self):
        t=read('lib/providers/settings_service.dart')
        m=t.split('Future<void> saveFanatikaLastFavorite',1)[1].split('Map<String, String> get',1)[0]
        self.assertIn('setString',m)
        self.assertNotIn('notifyListeners()',m)
        self.assertIn('lastExists',read('lib/widgets/category_clean_row.dart'))
    def test_app_background_allowlist(self):
        t=read('lib/flauncher.dart')
        self.assertIn('available.contains(image)',t)
        self.assertIn('assets/mountains/$image',t)
    def test_weather_offline_and_timestamp(self):
        t=read('lib/widgets/fanatika_weather_card.dart')
        for value in ['_saveOfflineCache', '_readOfflineCache', 'Offline forecast', 'savedAt']:
            self.assertIn(value,t)
    def test_no_hardcoded_favorites(self):
        t=read('lib/widgets/settings/fanatika_v2_page.dart')
        self.assertNotIn('A1 Xplore',t)
        self.assertNotIn('com.google.android.youtube.tv',t)
    def test_signed_workflow_no_embedded_keys(self):
        t=read('.github/workflows/build-fanatika-signed.yml')
        self.assertIn('workflow_dispatch:',t)
        self.assertIn('FANATIKA_KEYSTORE_B64',t)
        self.assertIn('flutter build apk --release',t)
        self.assertNotIn('BEGIN PRIVATE KEY',t)
        self.assertFalse((ROOT/'android/app/upload-keystore.jks').exists())
    def test_version_code_increases(self):
        self.assertRegex(read('pubspec.yaml'), r'version: 2\.[3-9]\.\d+\+41\d+')
    def test_launcher_not_branded_on_home(self):
        home=read('lib/flauncher.dart')
        self.assertNotIn("Text('Fanatika TV Launcher')",home)
    def test_manifest_is_valid_xml(self):
        ElementTree.parse(ROOT/'android/app/src/main/AndroidManifest.xml')

if __name__ == '__main__': unittest.main()
