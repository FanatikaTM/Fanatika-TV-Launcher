"""Xiaomi installer regression checks; not a Flutter compile or TV hardware test."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parent
class FanatikaV271Tests(unittest.TestCase):
    def test_version_bump(self):
        self.assertIn('version: 2.7.1+4132', (ROOT/'pubspec.yaml').read_text())
    def test_verified_update_guards_remain(self):
        source = (ROOT/'android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java').read_text()
        for token in ['!expected.equals(actual)', 'newer <= current', 'getPackageName().equals(incoming.packageName)']:
            self.assertIn(token, source)
    def test_no_early_permission_loop(self):
        source = (ROOT/'android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java').read_text()
        block = source.split('private Map<String, Object> fanatikaInstallVerifiedReleaseApk',1)[1].split('private boolean installApk',1)[0]
        self.assertIn('openAndroidApkInstaller(apkPath)', block)
        self.assertNotIn('!getPackageManager().canRequestPackageInstalls()', block)
        self.assertIn('catch (SecurityException e)', block)
    def test_android_package_installer_and_fallback(self):
        source = (ROOT/'android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java').read_text()
        block = source.split('private void openAndroidApkInstaller',1)[1].split('private void requestInstallUnknownAppsPermission',1)[0]
        for token in ['Intent.ACTION_INSTALL_PACKAGE','Intent.ACTION_VIEW','FLAG_GRANT_READ_URI_PERMISSION','setClipData(uriGrant)','FileProvider.getUriForFile']:
            self.assertIn(token,block)
        self.assertNotIn('pm install',block)
    def test_set_clip_data_cannot_be_chained(self):
        source = (ROOT/'android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java').read_text()
        block = source.split('private void openAndroidApkInstaller',1)[1].split('private void requestInstallUnknownAppsPermission',1)[0]
        self.assertIn('installIntent.setClipData(uriGrant);', block)
        self.assertIn('legacyIntent.setClipData(uriGrant);', block)
        self.assertNotIn('.setClipData(uriGrant)\n                .addFlags(', block)
        self.assertNotIn('.setClipData(uriGrant)\n                    .addFlags(', block)
if __name__ == '__main__': unittest.main()
