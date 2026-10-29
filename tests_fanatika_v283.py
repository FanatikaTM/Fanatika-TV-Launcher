"""v2.8.3 source regressions — not a Flutter/TV hardware test."""
import unittest
from pathlib import Path
R=Path(__file__).resolve().parent
read=lambda p:(R/p).read_text(encoding='utf-8')
class NeutralUI283(unittest.TestCase):
 def test_build(self):
  self.assertIn('version: 2.8.7+4140',read('pubspec.yaml'))
  self.assertIn('tests_fanatika_v283',read('.github/workflows/build-fanatika-signed.yml'))
 def test_tabs_visible_on_logical_widths(self):
  source=read('lib/widgets/focus_aware_app_bar.dart')
  for marker in ["Text('Home'","Text('Apps'","Text('Tools'","SingleChildScrollView("]:self.assertIn(marker,source)
  self.assertNotIn('width >= 980',source)
 def test_gray_quick_panel(self):
  source=read('lib/widgets/fanatika_quick_settings_dialog.dart')
  self.assertIn('Color(0xFF1E1E1E)',source)
  self.assertIn('Color(0xFF303030)',source)
  self.assertIn('surfaceContainerHigh',source)
 def test_native_input_first_with_fallback(self):
  native=read('android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java')
  segment=native.split('private Map<String, Object> openTvSourcePicker()',1)[1].split('private Map<String, Object> tryXiaomiHdmi(',1)[0]
  self.assertLess(segment.index('com.android.tv.action.VIEW_INPUTS'),segment.index('android.intent.action.TV_INPUT'))
  self.assertIn('ActivityNotFoundException',segment)
  self.assertIn('SecurityException',segment)
  self.assertIn('startActivity(intent)',segment)
  self.assertIn('await _channel.openTvSourcePicker()',read('lib/widgets/fanatika_quick_settings_dialog.dart'))
  self.assertNotIn('_openPanel(TvInputsPanelPage.routeName)',read('lib/widgets/fanatika_quick_settings_dialog.dart'))
 def test_branding_about_only(self):
  self.assertIn('applicationName: "Fanatika TV Launcher"',read('lib/widgets/settings/flauncher_about_dialog.dart'))
  self.assertIn('android:label="TV Launcher"',read('android/app/src/main/AndroidManifest.xml'))
  self.assertIn("title: 'TV Launcher'",read('lib/flauncher_app.dart'))
  self.assertNotIn("'assets/splash_fanatika_tv.png'",read('lib/widgets/fanatika_startup_splash.dart'))
  for p in ['lib/widgets/settings/settings_panel_page.dart','lib/widgets/fanatika_quick_settings_dialog.dart','lib/widgets/settings/fanatika_updates_page.dart']:
   self.assertNotIn("Text('Fanatika",read(p))
 def test_existing_favorites(self):
  source=read('lib/providers/apps_service.dart')
  for f in ['addToFavorites','removeFromFavorites','reorderApplication']:self.assertIn(f,source)
if __name__=='__main__':unittest.main()
