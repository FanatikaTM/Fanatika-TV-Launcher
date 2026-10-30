from pathlib import Path
import unittest
ROOT = Path(__file__).parent

def read(name): return (ROOT/name).read_text()

class FanatikaV287(unittest.TestCase):
    def test_version(self): self.assertIn('version: 2.9.2+4145',read('pubspec.yaml'))
    def test_authority_and_own_uid_checks(self):
        manifest=read('android/app/src/main/AndroidManifest.xml')
        provider=read('android/app/src/main/java/com/leanbitlab/ltvL/FanatikaRemoteControlProvider.java')
        self.assertIn('android.permission.DUMP', manifest)
        self.assertIn('Process.SHELL_UID', provider)
        self.assertIn('Process.myUid()', provider)
        self.assertIn('Unsupported option',provider)
        self.assertNotIn('plex_token',provider)
    def test_settings_applied_through_dart_not_raw_prefs(self):
        settings=read('lib/providers/settings_service.dart')
        self.assertIn("invokeMethod<String>('consume')",settings)
        self.assertIn("setShowFanatikaHero(enabled)",settings)
        self.assertIn("setPlexRefreshMinutes(int.parse(value))",settings)
    def test_plex_recovery(self):
        service=read('lib/providers/watch_next_service.dart')
        self.assertIn('_plexOfflineRetention',service)
        self.assertIn('_lastPlexItems',service)
        self.assertIn('Duration(minutes: _settings.plexRefreshMinutes)',service)
    def test_backup_in_both_update_paths(self):
        self.assertIn('backupBeforeInstall(context)', read('lib/widgets/fanatika_update_dialog.dart'))
        self.assertIn('backupBeforeInstall(context)', read('lib/widgets/settings/fanatika_updates_page.dart'))
        self.assertIn('FanatikaBackupService.export',read('lib/widgets/fanatika_remote_backup_observer.dart'))
    def test_title_and_favorites(self):
        f=read('lib/flauncher.dart')
        self.assertIn('fanatikaTitleSpacing',f)
        self.assertIn('fanatikaTitleShadow',f)
        self.assertTrue((ROOT/'lib/providers/apps_service.dart').is_file())
        self.assertIn('_routeFocus',read('lib/widgets/settings/focusable_settings_tile.dart'))

if __name__ == '__main__': unittest.main()
