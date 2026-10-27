"""Source consistency checks, not Dart analysis or TV runtime tests."""
from pathlib import Path
import unittest, hashlib,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parent

class RemoteUpdateTests(unittest.TestCase):
 def read(self,name): return (ROOT/name).read_text(encoding='utf-8')
 def test_remote_controls(self):
  v=self.read('lib/widgets/settings/fanatika_v2_page.dart')
  self.assertIn('FocusTraversalGroup(',v)
  self.assertIn('FanatikaTvControls.toggle(',v)
  self.assertIn('FanatikaTvControls.action(',v)
  self.assertIn('chooseSetting<double>',v)
  self.assertIn('chooseSetting<String>',v)
  self.assertNotIn('SwitchListTile(',v)
  self.assertNotIn('Slider(',v)
  self.assertNotIn('SimpleDialogOption(',v)
 def test_remote_dialog(self):
  d=self.read('lib/widgets/settings/fanatika_tv_controls.dart')
  self.assertIn('FocusableSettingsTile(',d)
  self.assertIn('autofocus: index == 0',d)
  self.assertIn('ListView.builder(',d)
  self.assertIn('value == current',d)
 def test_sleep_nav(self):
  main=self.read('lib/widgets/settings/settings_panel_page.dart')
  sleep=self.read('lib/widgets/settings/fanatika_sleep_page.dart')
  self.assertIn('FanatikaSleepPage.routeName',main)
  self.assertIn('FanatikaTvControls.choose<int>',sleep)
  self.assertIn('autofocus: true',sleep)
  self.assertNotIn('SimpleDialogOption(',sleep)
  for minutes in [15,30,60,90,120]: self.assertIn(str(minutes),sleep)
 def test_title_styles(self):
  source=self.read('lib/flauncher.dart')
  self.assertIn('AnimatedSwitcher(',source)
  self.assertIn('fanatikaSettings.fanatikaTitleStyle',source)
  self.assertIn('FontWeight.w800',source)
  self.assertIn('fontSize: 19',source)
  s=self.read('lib/providers/settings_service.dart')
  self.assertIn('fanatika_v2_title_style',s)
  v=self.read('lib/widgets/settings/fanatika_v2_page.dart')
  for x in ['Classic','Bold','Cinema','Glass']:self.assertIn(x,v)
 def test_splash_is_not_firmware_boot(self):
  v=self.read('lib/widgets/fanatika_startup_splash.dart')
  self.assertIn("Icons.tv_rounded",v)
  self.assertIn('TweenAnimationBuilder',v)
  self.assertIn('FanatikaStartupSplash',self.read('lib/flauncher_app.dart'))
  xml=self.read('android/app/src/main/res/drawable/launch_background.xml')
  self.assertNotIn('@drawable/fanatika_splash_logo',xml)
 def test_brand_assets(self):
  for name in ['assets/icon.png','android/app/src/main/res/drawable-nodpi/fanatika_splash_logo.png',
    'android/app/src/main/res/drawable/banner.png']:
   data=(ROOT/name).read_bytes()
   self.assertTrue(data.startswith(b'\x89PNG\r\n\x1a\n'))
   self.assertGreater(len(data),1000)
  ET.parse(ROOT/'android/app/src/main/res/drawable/launch_background.xml')
 def test_original_arc_favorites_preserved(self):
  baseline={'lib/providers/apps_service.dart':'ee1c70744418638165b61608df19578902d793194b7702eb0e38367639d3917b',
            'lib/database.dart':'e561bdd070cab1b7ad48ea34e2c4677c5ef0b00ad67ecfd65e6fa526e80f19ea',
            'lib/widgets/settings/applications_panel_page.dart':'afb8af7b7b85b581452838614b89c99f5bc6999cc28c102ae27d077891f57964'}
  for file,sha in baseline.items():
   self.assertEqual(hashlib.sha256((ROOT/file).read_bytes()).hexdigest(),sha)
 def test_sleep_safety_unchanged(self):
  a=self.read('android/app/src/main/java/com/leanbitlab/ltvL/FanatikaSleepController.java')
  self.assertIn('lockNow()',a)
  self.assertNotIn('pm disable-user',a)
  self.assertNotIn('Runtime.getRuntime()',a)
 def test_fanatika_not_home_branded(self):
  source=self.read('lib/flauncher.dart')
  self.assertNotIn('Transformers',source)
  self.assertNotIn('Fanatika TV Launcher',source)

if __name__=='__main__':unittest.main()
