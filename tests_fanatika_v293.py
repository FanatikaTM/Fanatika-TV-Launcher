"""v2.9.3: opt-in, reversible HOME override; no OEM app modifications."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
ROOT=Path(__file__).parent
R=lambda p:(ROOT/p).read_text(encoding='utf-8')
ANDROID='{http://schemas.android.com/apk/res/android}'
J='android/app/src/main/java/com/leanbitlab/ltvL/'
class HomeOverride293(unittest.TestCase):
 def test_manifest_and_a11y_are_restricted(self):
  root=ET.fromstring(R('android/app/src/main/AndroidManifest.xml'))
  services=[s for s in root.findall('.//service') if s.attrib.get(ANDROID+'name')=='.FanatikaHomeOverrideService']
  self.assertEqual(len(services),0)
  self.assertNotIn('FanatikaHomeOverrideService',R('android/app/src/main/AndroidManifest.xml'))
  xml=ET.fromstring(R('android/app/src/main/res/xml/fanatika_home_override_accessibility.xml'))
  self.assertEqual(xml.attrib[ANDROID+'canRetrieveWindowContent'],'false')
  self.assertEqual(xml.attrib[ANDROID+'accessibilityEventTypes'],'typeWindowStateChanged')
 def test_home_only_and_throttle(self):
  s=R(J+'FanatikaHomeOverrideService.java')
  self.assertIn('com.google.android.apps.tv.launcherx.home.HomeActivity',s)
  self.assertIn('com.google.android.apps.tv.launcherx.home.VanillaModeHomeActivity',s)
  self.assertIn('TYPE_WINDOW_STATE_CHANGED',s)
  self.assertIn('1700L',s)
  self.assertIn('Intent.FLAG_ACTIVITY_NEW_TASK',s)
  self.assertNotIn('pm disable',s)
  self.assertNotIn('performGlobalAction',s)
 def test_consent_and_recovery(self):
  ctrl=R(J+'FanatikaHomeOverrideController.java')
  self.assertIn('ACTION_ACCESSIBILITY_SETTINGS',ctrl)
  self.assertIn('home_override_enabled',R(J+'FanatikaHomeOverrideService.java'))
  self.assertIn('setEnabled(Context c, boolean enabled)',ctrl)
  self.assertIn('Fanatika HOME Override',R('android/app/src/main/res/values/fanatika_home_override_strings.xml'))
 def test_navigation_and_channels(self):
  s=R('lib/widgets/settings/unified_settings_pages.dart')
  self.assertNotIn('Make Fanatika HOME',s)
  self.assertNotIn('FanatikaHomeOverridePage.routeName',s)
  self.assertIn('fanatikaHomeOverrideOpenAccessibility',R('lib/flauncher_channel.dart'))
  self.assertIn('fanatikaHomeOverrideStatus',R(J+'MainActivity.java'))
  self.assertIn('version: 2.9.8+4151',R('pubspec.yaml'))
 def test_original_favorites_and_sleep_and_plex(self):
  self.assertIn('addToFavorites',R('lib/providers/apps_service.dart'))
  self.assertIn('FanatikaSleepController.handleRemoteKey',R(J+'FanatikaSleepKeyService.java'))
  self.assertIn('Start Plex pairing',R('lib/widgets/settings/plex_continue_watching_page.dart'))
