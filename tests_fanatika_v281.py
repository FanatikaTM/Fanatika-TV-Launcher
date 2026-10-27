"""Fanatika v2.8.1 Google TV-inspired UI and OEM sleep safety checks."""
import unittest
from pathlib import Path
R=Path(__file__).resolve().parent
def read(p): return (R/p).read_text(encoding='utf-8')
class QuickSettings281(unittest.TestCase):
 def test_version_and_workflow(self):
  self.assertIn('version: 2.8.1+4134',read('pubspec.yaml'))
  self.assertIn('tests_fanatika_v281',read('.github/workflows/build-fanatika-signed.yml'))
 def test_short_menu_names(self):
  self.assertIn("title: const Text('Tools')",read('lib/widgets/settings/settings_panel_page.dart'))
  self.assertIn("title: const Text('Updates')",read('lib/widgets/settings/settings_panel_page.dart'))
 def test_pill_navigation(self):
  source=read('lib/widgets/focus_aware_app_bar.dart')
  for part in ["Text('Home'","Text('Apps'","Text('Tools'","onHomeRequested"]:
   self.assertIn(part,source)
  self.assertIn('_scrollController.animateTo(0.0',read('lib/flauncher.dart'))
 def test_native_sleep_is_safe(self):
  source=read('lib/widgets/fanatika_quick_settings_dialog.dart')
  self.assertIn('TV native Sleep Timer settings',source)
  self.assertIn('await _channel.openSettings()',source)
  self.assertIn('fanatikaSleepTimer(minutes)',source)
  for bad in ['pm disable','WRITE_SECURE_SETTINGS','KEYCODE_HOME']:
   self.assertNotIn(bad,source)
 def test_arc_favorites(self):
  source=read('lib/providers/apps_service.dart')
  for f in ['addToFavorites','removeFromFavorites','reorderApplication']:
   self.assertIn(f,source)
if __name__=='__main__': unittest.main()
