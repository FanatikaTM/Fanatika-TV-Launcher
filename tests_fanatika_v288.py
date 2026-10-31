"""Targeted regression checks for v2.8.8. Source checks, not Flutter or device tests."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
R=Path(__file__).parent
read=lambda name:(R/name).read_text()
class Fanatika288(unittest.TestCase):
 def test_dedicated_home_label(self):
  manifest=read('android/app/src/main/AndroidManifest.xml')
  ET.fromstring(manifest)
  self.assertIn('android:label="Fanatika TV Launcher"', manifest)
  self.assertIn('android.intent.category.HOME', manifest)
  self.assertIn('com.fanatika.tvlauncher', read('android/app/build.gradle'))
  self.assertIn('resolve-activity',read('CHECK_FANATIKA_HOME_WINDOWS.bat'))
 def test_text_only_single_bar(self):
  bar=read('lib/widgets/focus_aware_app_bar.dart')
  text=read('lib/widgets/fanatika_top_bar_tabs.dart')
  self.assertIn('FanatikaTopBarTabs(',bar)
  for tab in ['Home','Apps','Settings','Input','Quick','Sleep','Weather','Network']:
   self.assertIn("'"+tab+"'",text)
  self.assertNotIn('Icons.settings_input_hdmi',bar)
  self.assertIn('AppBarFocusRing(',text)
 def test_editor_persist_and_order(self):
  editor=read('lib/widgets/settings/fanatika_top_bar_editor_page.dart')
  settings=read('lib/providers/settings_service.dart')
  self.assertIn('setFanatikaTopBarTabs',editor)
  self.assertIn('setStringList',settings)
  self.assertIn('updated[other]',editor)
  self.assertIn('updated[other]',editor)
  self.assertIn("!normalized.contains('Settings')",settings)
  self.assertIn("!normalized.contains('Home')",settings)
 def test_sleep_no_modal_confirmation_and_native_permissions(self):
  timer=read('lib/widgets/fanatika_sleep_timer_dialog.dart')
  native=read('android/app/src/main/java/com/leanbitlab/ltvL/FanatikaSleepController.java')
  quick=read('lib/widgets/fanatika_quick_settings_dialog.dart')
  for label in ['15 minutes','30 minutes','45 minutes','1 hour','1 hour 30 minutes','2 hours','3 hours',
                'Pause timer','Resume timer','Cancel timer']:
   self.assertIn(label,timer)
  self.assertNotIn("title: const Text('Set sleep timer?')",quick)
  self.assertIn('FanatikaSleepTimerDialog()',quick)
  self.assertIn('DevicePolicyManager',native)
  self.assertIn('public static Map<String, Object> pause(',native)
  self.assertIn('public static Map<String, Object> resume(',native)
  self.assertIn('case "fanatikaPauseSleepTimer"',read('android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java'))
 def test_watch_next_clean_home(self):
  panel=read('lib/widgets/fanatika_watch_next_panel.dart')
  self.assertNotIn('No Watch Next titles available',panel)
  self.assertNotIn('Allow TV listings access to display Watch Next',panel)
  self.assertIn('service.launchItem(widget.item)',panel)
 def test_input_only_and_arc_favorites_untouched(self):
  self.assertIn("'Input'",read('lib/widgets/settings/unified_settings_pages.dart'))
  self.assertNotIn("text: 'Input'",read('lib/widgets/fanatika_quick_settings_dialog.dart'))
  apps=read('lib/providers/apps_service.dart')
  for method in ['addToFavorites','removeFromFavorites','reorderApplication']:
   self.assertIn(method,apps)
if __name__=='__main__': unittest.main()
