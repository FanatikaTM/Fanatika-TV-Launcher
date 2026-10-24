"""v2.4 source/asset checks; Flutter and device tests are separate."""
from pathlib import Path
import struct
import unittest
import re
ROOT=Path(__file__).resolve().parent
class V24Checks(unittest.TestCase):
 def read(self,path): return (ROOT/path).read_text(encoding='utf-8')
 def test_update_default_off_and_choices(self):
  src=self.read('lib/providers/settings_service.dart')
  self.assertIn('fanatikaUpdateCadenceChoices = [0, 15, 30]',src)
  self.assertRegex(src,r'fanatikaUpdateCheckDays[\s\S]{0,220}\n\s*: 0;')
  self.assertIn('markFanatikaUpdateAttempt',src)
 def test_update_guarded_and_no_silent_install(self):
  service=self.read('lib/providers/fanatika_release_checker.dart')
  obs=self.read('lib/widgets/fanatika_auto_update_observer.dart')
  self.assertIn('/releases/latest',service)
  self.assertIn('newerThan',service)
  self.assertIn("RegExp(r'^v?",service)
  self.assertIn('FanatikaUpdateDialogs.offer(context, result)',obs)
  self.assertIn('result.updateAvailable',obs)
  for unsafe in ['installApk(', 'pm disable-user','adb install','uninstall(']:
   self.assertNotIn(unsafe,service+obs)
  self.assertIn('Timer.periodic',obs)
  self.assertIn('lastAttempt',obs)
 def test_settings_remote_entry_and_observer(self):
  ui=self.read('lib/widgets/settings/fanatika_v2_page.dart')
  self.assertIn('Every $days days',ui)
  self.assertIn('FanatikaTvControls.choose<int>',ui)
  self.assertIn('FanatikaReleaseChecker.check(releaseRepo: repo)',ui)
  self.assertIn('FanatikaAutoUpdateObserver(child: FLauncher())',self.read('lib/flauncher_app.dart'))
 def test_logos_separate_and_unbranded_home(self):
  icon=(ROOT/'assets/icon.png').read_bytes()
  splash=(ROOT/'assets/splash_fanatika_tv.png').read_bytes()
  self.assertTrue(icon.startswith(b'\x89PNG\r\n\x1a\n'))
  self.assertTrue(splash.startswith(b'\x89PNG\r\n\x1a\n'))
  self.assertEqual(struct.unpack('>II',icon[16:24]),(512,512))
  self.assertEqual(struct.unpack('>II',splash[16:24]),(1920,1080))
  self.assertNotIn('Fanatika TV Launcher',self.read('lib/flauncher.dart'))
  self.assertIn('fanatika_splash_logo',self.read('android/app/src/main/res/drawable/launch_background.xml'))
 def test_signed_workflow(self):
  wf=self.read('.github/workflows/build-fanatika-signed.yml')
  for key in ['FANATIKA_KEYSTORE_B64','FANATIKA_STORE_PASSWORD','FANATIKA_KEY_ALIAS','FANATIKA_KEY_PASSWORD']:
   self.assertIn(key,wf)
  self.assertIn('workflow_dispatch',wf)
  self.assertFalse((ROOT/'android/app/upload-keystore.jks').exists())
 def test_version_and_favorites(self):
  self.assertRegex(self.read('pubspec.yaml'), r'version: 2\.[4-9]\.\d+\+41\d+')
  self.assertIn('addToFavorites',self.read('lib/providers/apps_service.dart'))
  self.assertIn('removeFromFavorites',self.read('lib/providers/apps_service.dart'))
if __name__=='__main__':unittest.main()
