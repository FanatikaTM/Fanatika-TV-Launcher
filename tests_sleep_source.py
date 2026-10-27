"""Source integration tests; NOT an APK build or a physical TV validation."""
import pathlib
import unittest
import hashlib
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).parent
BASELINE_SHA256 = {'lib/providers/apps_service.dart': 'ee1c70744418638165b61608df19578902d793194b7702eb0e38367639d3917b', 'lib/database.dart': 'e561bdd070cab1b7ad48ea34e2c4677c5ef0b00ad67ecfd65e6fa526e80f19ea', 'lib/widgets/settings/applications_panel_page.dart': 'afb8af7b7b85b581452838614b89c99f5bc6999cc28c102ae27d077891f57964', 'lib/widgets/add_to_category_dialog.dart': '48d69845dfdee1a2803b8035b7305760ddad693665580d7787b8d7a63df1874d', 'lib/widgets/category_row.dart': '31715ebf7e44a0783385e057b750c76a03df5c6c34443105f4f94aab5a04ba09'}
JAVA = ROOT/'android/app/src/main/java/com/leanbitlab/ltvL'
XML = ROOT/'android/app/src/main/res/xml'
APPNS = '{http://schemas.android.com/apk/res/android}'

class SleepSourceTests(unittest.TestCase):
    def test_manifest_xml(self):
        ET.parse(ROOT/'android/app/src/main/AndroidManifest.xml')
        for name in ['fanatika_sleep_device_admin.xml', 'fanatika_sleep_accessibility.xml']:
            ET.parse(XML/name)
        ET.parse(ROOT/'android/app/src/main/res/values/fanatika_sleep_strings.xml')

    def test_device_admin_declared_and_not_automatic(self):
        xml = ET.parse(ROOT/'android/app/src/main/AndroidManifest.xml').getroot()
        receiver = next(r for r in xml.findall('.//receiver') if r.attrib.get(APPNS+'name')=='.FanatikaSleepAdminReceiver')
        self.assertEqual(receiver.attrib.get(APPNS+'permission'), 'android.permission.BIND_DEVICE_ADMIN')
        self.assertEqual(receiver.attrib.get(APPNS+'exported'), 'true')
        self.assertIn('android.app.device_admin', (ROOT/'android/app/src/main/AndroidManifest.xml').read_text())

    def test_accessibility_declared_and_no_content_reading(self):
        xml = ET.parse(ROOT/'android/app/src/main/AndroidManifest.xml').getroot()
        service = next(r for r in xml.findall('.//service') if r.attrib.get(APPNS+'name')=='.FanatikaSleepKeyService')
        self.assertEqual(service.attrib.get(APPNS+'permission'), 'android.permission.BIND_ACCESSIBILITY_SERVICE')
        data=(XML/'fanatika_sleep_accessibility.xml').read_text()
        self.assertIn('android:canRetrieveWindowContent="false"',data)
        self.assertIn('android:canRequestFilterKeyEvents="true"',data)
        self.assertIn('flagRequestFilterKeyEvents',data)

    def test_backend_commands_are_all_wired_to_channel(self):
        a=(JAVA/'MainActivity.java').read_text(); b=(ROOT/'lib/flauncher_channel.dart').read_text()
        for method in ['fanatikaSleepStatus','fanatikaRequestSleepAdmin','fanatikaOpenSleepAccessibility',
                       'fanatikaSleepNow','fanatikaSleepTimer','fanatikaCancelSleepTimer','fanatikaSetSleepShortcut']:
            with self.subTest(method=method):
                self.assertIn('case "'+method+'"',a)
                self.assertIn("'"+method+"'",b)

    def test_timer_duration_allowlist(self):
        s=(JAVA/'FanatikaSleepController.java').read_text()
        self.assertIn('minutes != 15 && minutes != 30 && minutes != 45 && minutes != 60 && minutes != 90 && minutes != 120 && minutes != 180',s)
        self.assertIn('ELAPSED_REALTIME, deadline',s)
        self.assertIn('AlarmManager',s)
        self.assertIn('alarm.cancel(',s)
        self.assertIn('adminActive(context)',s)

    def test_shortcut_has_no_system_reserved_keys(self):
        s=(JAVA/'FanatikaSleepController.java').read_text()
        selection = s.split('public static boolean isAllowedKey(int key)')[1].split('}',1)[0]
        for dangerous in ['KEYCODE_HOME','KEYCODE_POWER','KEYCODE_BACK','KEYCODE_VOLUME_UP','KEYCODE_DPAD_UP']:
            self.assertNotIn(dangerous,selection)
        self.assertIn('return key == 0',selection)
        self.assertIn('getRepeatCount() == 0',s)
        self.assertIn('HOLD_MS',s)
        self.assertIn('getDownTime()',s)
        self.assertIn('selected == 0',s)

    def test_permission_based_implementation(self):
        s=(JAVA/'FanatikaSleepController.java').read_text()
        for required in ['ACTION_ADD_DEVICE_ADMIN','EXTRA_DEVICE_ADMIN','USES_POLICY_FORCE_LOCK','lockNow()']:
            # USES_POLICY declared in XML as force-lock instead of Java
            if required=='USES_POLICY_FORCE_LOCK':
                self.assertIn('<force-lock/>', (XML/'fanatika_sleep_device_admin.xml').read_text())
            else:
                self.assertIn(required, s)
        for unsafe in ['Runtime.getRuntime()', 'ProcessBuilder(', 'goToSleep(', 'adb shell', 'pm disable-user']:
            self.assertNotIn(unsafe,s)

    def test_new_page_and_settings_route(self):
        page=(ROOT/'lib/widgets/settings/fanatika_sleep_page.dart').read_text()
        panel=(ROOT/'lib/widgets/settings/settings_panel.dart').read_text()
        v2=(ROOT/'lib/widgets/settings/fanatika_v2_page.dart').read_text()
        for minutes in [15,30,60,90,120]:
            self.assertIn(str(minutes),page)
        self.assertIn('FanatikaSleepPage.routeName',panel)
        self.assertIn('FanatikaSleepPage.routeName',v2)
        self.assertIn('Sleep timer',page)
        self.assertIn('Try sleep now',page)

    def test_original_arc_favorites_unchanged(self):
        # Original Arc Favorites source SHA-256s captured before these changes.
        for name, expected in BASELINE_SHA256.items():
            with self.subTest(name=name):
                actual = hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
                self.assertEqual(expected, actual)

    def test_no_new_favorites_ids_or_xiaomi_changes(self):
        modified='\n'.join((ROOT/name).read_text() for name in [
            'lib/widgets/settings/fanatika_sleep_page.dart','lib/flauncher_channel.dart',
            'android/app/src/main/AndroidManifest.xml'])
        self.assertNotIn('com.google.android.apps.tv.launcherx',modified)
        self.assertNotIn('com.amazon.amazonvideo', modified)
        self.assertNotIn('com.google.android.youtube.tv',modified)

    def test_backup_does_not_restore_admin_or_accessibility_permission(self):
        s=(ROOT/'lib/providers/fanatika_backup_service.dart').read_text()
        self.assertIn('fanatika_v2_sleep_shortcut_key',s)
        self.assertNotIn('fanatikaRequestSleepAdmin(',s)
        self.assertNotIn('fanatikaOpenSleepAccessibility(',s)

    def test_workflow_is_still_present(self):
        p=ROOT/'.github/workflows/build-fanatika-apk.yml'
        self.assertTrue(p.is_file())
        self.assertIn('flutter build apk',p.read_text())

if __name__=='__main__':
    unittest.main(verbosity=2)
