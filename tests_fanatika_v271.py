"""v2.7.1 Xiaomi installer regression checks, not a device or APK test."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parent
class FanatikaV271Tests(unittest.TestCase):
    def test_version_bump(self):
        self.assertIn('version: 2.8.9+4142', (ROOT/'pubspec.yaml').read_text())
    def test_verified_update_still_requires_same_package_newer_code_same_certificate(self):
        src=(ROOT/'android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java').read_text()
        self.assertIn('!expected.equals(actual)',src)
        self.assertIn('newer <= current',src)
        self.assertIn('getPackageName().equals(incoming.packageName)',src)
    def test_android_installer_called_without_premature_permission_loop(self):
        src=(ROOT/'android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java').read_text()
        body=src.split('private Map<String, Object> fanatikaInstallVerifiedReleaseApk',1)[1].split('private boolean installApk',1)[0]
        self.assertIn('openAndroidApkInstaller(apkPath)',body)
        self.assertIn('getPackageManager().canRequestPackageInstalls()',body)
        self.assertNotIn('!getPackageManager().canRequestPackageInstalls()',body)
        self.assertIn('catch (SecurityException e)',body)
    def test_grants_and_action_fallback(self):
        src=(ROOT/'android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java').read_text()
        body=src.split('private void openAndroidApkInstaller',1)[1].split('private void requestInstallUnknownAppsPermission',1)[0]
        for token in ['Intent.ACTION_INSTALL_PACKAGE','Intent.ACTION_VIEW','FileProvider.getUriForFile','FLAG_GRANT_READ_URI_PERMISSION','setClipData(uriGrant)','startActivity(installIntent)','startActivity(legacyIntent)']:
            self.assertIn(token,body)
        self.assertNotIn('pm install',body)
    def test_apk_only_and_signing_secrets_still_private(self):
        src=(ROOT/'android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java').read_text()
        self.assertIn('fanatika-reviewed-release.apk',src)
        wf=(ROOT/'.github/workflows/build-fanatika-signed.yml').read_text()
        self.assertIn('rm -f android/app/upload-keystore.jks',wf)
    def test_set_clip_data_cannot_be_chained(self):
        source = (ROOT/'android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java').read_text()
        self.assertIn('installIntent.setClipData(uriGrant);', source)
        self.assertIn('legacyIntent.setClipData(uriGrant);', source)
        self.assertNotIn('.setClipData(uriGrant)\n                .addFlags(', source)
        self.assertNotIn('.setClipData(uriGrant)\n                    .addFlags(', source)
if __name__ == '__main__': unittest.main()
