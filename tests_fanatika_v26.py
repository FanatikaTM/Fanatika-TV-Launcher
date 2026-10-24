"""Source-level checks only: a signed APK still requires a real Gradle build."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parent

def read(path): return (ROOT / path).read_text(encoding='utf8')

class UpdateV26Tests(unittest.TestCase):
    def test_version_and_settings_options(self):
        self.assertIn('version: 2.6.0+4130', read('pubspec.yaml'))
        settings = read('lib/providers/settings_service.dart')
        self.assertIn('fanatikaUpdateCadenceChoices = [0, 15, 30]', settings)
        self.assertIn('setFanatikaReleaseRepo', settings)
        self.assertIn('fanatika_v26_release_repo', settings)
    def test_public_repo_checked_without_secrets(self):
        service = read('lib/providers/fanatika_release_checker.dart')
        self.assertIn('normalizedRepo', service)
        self.assertIn('defaultReleaseRepo', service)
        self.assertIn('/releases/latest', service)
        self.assertIn('assets', service)
        self.assertIn('assetSha256', service)
        self.assertNotIn('Authorization', service)
        self.assertNotIn('GITHUB_TOKEN', service)
        self.assertIn('https', service)
    def test_download_integrity(self):
        service=read('lib/providers/fanatika_apk_downloader.dart')
        self.assertIn('maxBytes = 250 * 1024 * 1024',service)
        self.assertIn('sha256.startChunkedConversion', service)
        self.assertIn('release.assetSha256', service)
        self.assertIn('getApplicationSupportDirectory', service)
        self.assertIn('await output.delete()', service)
        self.assertNotIn('Process.run', service)
    def test_android_verification_and_user_installer(self):
        java=read('android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java')
        self.assertIn('fanatikaVerifyReleaseApk', java)
        self.assertIn('fanatikaInstallVerifiedReleaseApk', java)
        self.assertIn('getPackageArchiveInfo', java)
        self.assertIn('getPackageName().equals(incoming.packageName)',java)
        self.assertIn('newer <= current', java)
        self.assertIn('!expected.equals(actual)', java)
        self.assertIn('getPackageManager().canRequestPackageInstalls()',java)
        self.assertIn('Intent.ACTION_VIEW',java)
        self.assertIn('FileProvider.getUriForFile',java)
        self.assertNotIn('pm install',java)
    def test_manifest_existing_provider_and_permissions(self):
        manifest=ET.parse(ROOT/'android/app/src/main/AndroidManifest.xml').getroot()
        self.assertIn('android.permission.REQUEST_INSTALL_PACKAGES',read('android/app/src/main/AndroidManifest.xml'))
        self.assertIn('android.support.FILE_PROVIDER_PATHS',read('android/app/src/main/AndroidManifest.xml'))
        self.assertIn('files-path',read('android/app/src/main/res/xml/provider_paths.xml'))
    def test_prompt_before_download_and_install(self):
        ui=read('lib/widgets/fanatika_update_dialog.dart')
        self.assertIn('Download and verify', ui)
        self.assertIn('Install verified Fanatika update?', ui)
        self.assertIn('Open Android installer', ui)
        self.assertIn('fanatikaVerifyReleaseApk',ui)
        self.assertIn('fanatikaInstallVerifiedReleaseApk',ui)
        self.assertIn('needsPermission',ui)
    def test_workflow_and_favorites_preserved(self):
        wf=read('.github/workflows/build-fanatika-signed.yml')
        self.assertIn('tests_fanatika_v26',wf)
        self.assertLess(wf.index('Fanatika source checks'),wf.index('Verify signing secrets'))
        self.assertIn('rm -f android/app/upload-keystore.jks',wf)
        apps=read('lib/providers/apps_service.dart')
        for func in ['getOrCreateFavoritesCategory','addToFavorites','removeFromFavorites','reorderApplication']:
            self.assertIn(func,apps)
if __name__=='__main__': unittest.main()
