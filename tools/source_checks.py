"""Structural tests only: do not imply that Dart/Gradle compiled."""
from pathlib import Path
import re
import zipfile
import unittest
ROOT=Path(__file__).resolve().parents[1]

def read(relative): return (ROOT/relative).read_text(encoding='utf8')
class SourceChecks(unittest.TestCase):
    def test_arc_favorites_core(self):
        s=read('lib/providers/apps_service.dart')
        for name in ('addToFavorites','removeFromFavorites','toggleFavorite','reorderApplication','saveApplicationOrderInCategory'):
            with self.subTest(name=name): self.assertIn(name,s)
    def test_settings_file(self):
        self.assertTrue((ROOT/'lib/providers/settings_service.dart').is_file())
    def test_favorites_database(self):
        s=read('lib/database.dart'); self.assertIn('class AppsCategories',s); self.assertIn('class Categories',s)
    def test_original_settings_pages(self):
        self.assertGreaterEqual(len(list((ROOT/'lib/widgets/settings').glob('*.dart'))), 30)
    def test_features(self):
        s=read('lib/widgets/settings/fanatika_v2_page.dart')
        for item in ['Export settings & Favorites','Import settings & Favorites','Title size','Custom app descriptions',
                     'Forecast days','Smart bundled mountain','Rename TV / HDMI', 'Minimal','Cinema','Classic',
                     'App focus animations','Performance mode','settings PIN','Install manually selected',
                     'Wi-Fi settings','Bluetooth settings']:
            with self.subTest(item=item): self.assertIn(item,s)
    def test_settings_provider_api(self):
        s=read('lib/providers/settings_service.dart')
        for name in ['fanatikaImportPreferences','fanatikaExportPreferences','fanatikaHeroSize','fanatikaSmartMountains',
                     'setFanatikaLayout','fanatikaInputNames','fanatikaDescriptions']:
            with self.subTest(name=name):self.assertIn(name,s)
    def test_backup_format(self):
        s=read('lib/providers/fanatika_backup_service.dart')
        for term in ['fanatika-launcher-backup','favorites','preferences','fanatikaReadBackup']:
            with self.subTest(term=term):self.assertIn(term,s)
    def test_picker_validation(self):
        s=read('android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java')
        for term in ['fanatikaPickUpdateApk','fanatikaSaveBackup','fanatikaReadBackup','getPackageName().equals(apkInfo.packageName)','ACTION_CREATE_DOCUMENT']:
            with self.subTest(term=term):self.assertIn(term,s)
    def test_weather_days(self):
        s=read('lib/widgets/fanatika_weather_card.dart'); self.assertIn('forecast_days',s);self.assertIn('widget.days',s)
    def test_wallpaper_assets(self):
        assert len(list((ROOT/'assets/mountains').glob('*.jpg'))) == 6
    def test_wallpaper_switch(self):
        self.assertIn('fanatikaSmartMountains',read('lib/providers/wallpaper_service.dart'))
    def test_separate_package(self):
        self.assertIn('com.fanatika.tvlauncher',read('android/app/build.gradle'))
    def test_home_unbranded(self):
        self.assertNotIn('Fanatika TV Launcher',read('lib/flauncher.dart'))
    def test_no_upstream_auto_updater(self):
        self.assertIn('defaultValue: false',read('lib/build_flags.dart'))
    def test_workflow_and_build_script(self):
        self.assertIn('flutter build apk',read('.github/workflows/build-fanatika-apk.yml'))
        self.assertIn('flutter',read('BUILD_FANATIKA_WINDOWS.bat'))
    def test_license(self):
        self.assertTrue((ROOT/'LICENSE').is_file())
if __name__=='__main__': unittest.main(verbosity=2)
