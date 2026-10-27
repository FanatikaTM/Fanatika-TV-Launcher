"""Fanatika v2.7 integration checks. Not substitutes for Flutter compile or Xiaomi hardware tests."""
import unittest
from pathlib import Path
from xml.etree import ElementTree as ET
R=Path(__file__).resolve().parent
def read(p): return (R/p).read_text(encoding='utf-8')
class FanatikaV27Checks(unittest.TestCase):
 def test_version(self): self.assertIn('version: 2.8.2+4135',read('pubspec.yaml'))
 def test_favorites_intact(self):
  a=read('lib/providers/apps_service.dart')
  for method in ['getOrCreateFavoritesCategory','addToFavorites','removeFromFavorites','reorderApplication']:
   self.assertIn(method,a)
 def test_separate_updates_and_submenus(self):
  settings=read('lib/widgets/settings/settings_panel_page.dart')
  for route in ['FanatikaUpdatesPage.routeName','FanatikaToolsHub.routeName','FanatikaUsbPage.routeName']:
   self.assertIn(route,settings)
  hub=read('lib/widgets/settings/fanatika_tools_hub.dart')
  self.assertIn('FanatikaV2Page(sections: item.sections)',hub)
  panel=read('lib/widgets/settings/fanatika_v2_page.dart')
  self.assertNotIn('Automatic update checks',panel)
  self.assertNotIn('Remote Button Tester',panel)
  self.assertNotIn('Quick app search',panel)
  self.assertIn('FanatikaToolSection(',panel)
 def test_update_guards_retained(self):
  update=read('lib/widgets/settings/fanatika_updates_page.dart')
  for key in ['Every $v days','FanatikaUpdateDialogs.offer','fanatikaReleaseRepo','installApk']:
   self.assertIn(key,update)
  java=read('android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java')
  for key in ['fanatikaVerifyReleaseApk','fanatikaInstallVerifiedReleaseApk','getPackageArchiveInfo']:
   self.assertIn(key,java)
 def test_weather_permission_and_fallback(self):
  main=read('android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java')
  device=read('android/app/src/main/java/com/leanbitlab/ltvL/FanatikaDeviceFiles.java')
  weather=read('lib/widgets/fanatika_weather_card.dart')
  manifest=read('android/app/src/main/AndroidManifest.xml')
  self.assertIn('ACCESS_COARSE_LOCATION',manifest)
  self.assertNotIn('ACCESS_FINE_LOCATION',manifest)
  self.assertIn('fanatikaRequestLocationPermission',main)
  self.assertIn('getLastKnownLocation',device)
  self.assertIn('getCurrentLocation',device)
  self.assertIn('Math.round(fix.getLatitude()*10.0)',device)
  self.assertIn('fetchWeatherByCoordinates',weather)
  self.assertIn('data = await fetchWeather(widget.city',weather)
 def test_usb_safer_storage(self):
  main=read('android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java')
  device=read('android/app/src/main/java/com/leanbitlab/ltvL/FanatikaDeviceFiles.java')
  usb=read('lib/widgets/settings/fanatika_usb_page.dart')
  for key in ['Intent.ACTION_OPEN_DOCUMENT','CATEGORY_OPENABLE','fanatikaUsbVolumes']:
   self.assertIn(key,main)
  self.assertIn('StorageVolume',device)
  self.assertIn('MediaStore.Images.Media.EXTERNAL_CONTENT_URI',device)
  self.assertIn('40L*1024*1024',device)
  self.assertIn('validateImportedJson',usb)
  self.assertIn('FanatikaBackupService.export',usb)
  for dangerous in ['Runtime.getRuntime','pm disable','chmod 777','MANAGE_EXTERNAL_STORAGE']:
   self.assertNotIn(dangerous,main+device+usb)
 def test_styling(self):
  ui=read('lib/widgets/settings/fanatika_v2_page.dart')
  hero=read('lib/flauncher.dart')
  for value in ['Outline','Elegant','Mono','Soft','Steel','Sunset']:
   self.assertIn(value,ui)
  self.assertIn('fontFamily:',hero)
  self.assertIn('fontStyle:',hero)
 def test_manifest_parses(self):ET.parse(R/'android/app/src/main/AndroidManifest.xml')
 def test_workflow_keystore_lifecycle(self):
  wf=read('.github/workflows/build-fanatika-signed.yml')
  self.assertLess(wf.index('Fanatika source checks'),wf.index('Verify signing secrets'))
  self.assertIn('rm -f android/app/upload-keystore.jks',wf)
  self.assertIn('tests_fanatika_v27',wf)
  self.assertFalse((R/'android/app/upload-keystore.jks').exists())
if __name__=='__main__':unittest.main()
