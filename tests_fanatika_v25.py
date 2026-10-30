"""Fanatika v2.5 static integration checks (not a substitute for Flutter/TV tests)."""
import re
import struct
import unittest
from pathlib import Path
from xml.etree import ElementTree
ROOT=Path(__file__).resolve().parent

def src(p):return (ROOT/p).read_text(encoding='utf-8')
class V25Checks(unittest.TestCase):
 def test_new_version(self): self.assertRegex(src('pubspec.yaml'), r'version: 2\.[5-9]\.\d+\+41\d+')
 def test_tools_renamed(self):
  self.assertIn("'TV & tools'",src('lib/widgets/settings/settings_panel_page.dart'))
  self.assertNotIn("'Fanatika v2 tools'",src('lib/widgets/settings/settings_panel_page.dart'))
 def test_hidden_accent_ui_only(self):
  self.assertNotIn('AccentColorPage.routeName',src('lib/widgets/settings/interface_settings_page.dart'))
  self.assertIn('accentColorHex',src('lib/providers/settings_service.dart'))
 def test_centered_rows_and_favorites_unchanged(self):
  self.assertIn('fanatikaCenterSections',src('lib/widgets/category_clean_row.dart'))
  self.assertIn('fanatikaCenterSections',src('lib/flauncher.dart'))
  for key in ['addToFavorites','removeFromFavorites','reorderApplication']:
   self.assertIn(key,src('lib/providers/apps_service.dart'))
 def test_focus_glow_scale_options(self):
  s=src('lib/widgets/app_card.dart')
  self.assertIn('fanatikaFocusGrow',s)
  self.assertIn('fanatikaFocusGlow',s)
  self.assertIn('fanatika_v2_focus_glow',src('lib/widgets/settings/fanatika_v2_page.dart'))
 def test_weather_with_watchnext(self):
  s=src('lib/flauncher.dart')
  self.assertIn('showWatchNextSection',s)
  self.assertIn('FanatikaWeatherCard(',s)
  self.assertRegex(s,r'clamp\(365\.0, 1200\.0\)')
 def test_backup_redacts_secrets_and_asks_permission(self):
  settings=src('lib/providers/settings_service.dart')
  screen=src('lib/widgets/settings/fanatika_v2_page.dart')
  self.assertIn("'apikey'",settings)
  self.assertIn("'password'",settings)
  self.assertIn('Export settings and Favorites?',screen)
 def test_backup_no_external_file_picker(self):
  java=src('android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java')
  self.assertIn('fanatikaSaveLocalBackup',java)
  self.assertIn('fanatikaReadLocalBackup',java)
  self.assertIn('MediaStore.Downloads.EXTERNAL_CONTENT_URI',java)
  self.assertIn('MAX_FANATIKA_BACKUP',java)
  self.assertNotIn('case "fanatikaSaveBackup" -> fanatikaChooseDocument',java)
 def test_safety_sleep(self):
  t=src('android/app/src/main/java/com/leanbitlab/ltvL/FanatikaSleepController.java')
  self.assertIn('DevicePolicyManager',t)
  self.assertNotIn('Runtime.getRuntime()',t)
  self.assertIn('fanatikaOpenDisplaySleepSettings',src('lib/widgets/settings/fanatika_sleep_page.dart'))
 def test_preview_remote_actions(self):
  t=src('lib/widgets/settings/fanatika_theme_preview.dart')
  self.assertIn("title: 'Cancel'",t)
  self.assertIn("title: 'Apply changes'",t)
  self.assertIn('FanatikaTvControls.action',t)
  self.assertIn('Future<void> _apply()',t)
 def test_title_fixed_slot(self):
  t=src('lib/flauncher.dart')
  self.assertIn('fanatikaFixedTitle',t)
  self.assertIn('SizedBox(width: double.infinity',t)
  self.assertIn('maxLines: 1, softWrap: false',t)
 def test_status_options(self):
  b=src('lib/widgets/focus_aware_app_bar.dart'); s=src('lib/providers/settings_service.dart')
  self.assertIn('fanatikaStatusBarStyle',b)
  self.assertIn('fanatikaTopBarTabs',s)
  self.assertIn('FanatikaTopBarTabs(',b)
 def test_wallpapers(self):
  dialog=src('lib/widgets/settings/fanatika_mountains_dialog.dart')
  names=['07_Alpine_Lake_Photoreal.jpg','08_Winter_Twilight_Photoreal.jpg']
  for name in names:
   self.assertIn(name,dialog)
   self.assertTrue((ROOT/'assets/mountains'/name).read_bytes().startswith(b'\xff\xd8\xff'))
  self.assertIn('digitally generated', dialog)
 def test_manifest_valid(self): ElementTree.parse(ROOT/'android/app/src/main/AndroidManifest.xml')
 def test_signed_ci_order(self):
  wf=src('.github/workflows/build-fanatika-signed.yml')
  self.assertLess(wf.find('- name: Fanatika source checks'),wf.find('- name: Verify signing secrets'))
  self.assertIn('tests_fanatika_v25',wf)
  self.assertIn('rm -f android/app/upload-keystore.jks',wf)
  self.assertFalse((ROOT/'android/app/upload-keystore.jks').exists())
if __name__=='__main__':unittest.main()
