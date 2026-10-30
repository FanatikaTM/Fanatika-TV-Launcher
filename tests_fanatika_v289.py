from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parent
def read(file):return (ROOT/file).read_text()
class V289(unittest.TestCase):
 def test_plex_three_options(self):
  page=read('lib/widgets/settings/plex_continue_watching_page.dart')
  for required in ['_checkAndroidFeed','_discover','_pair','_checkPin','_test','_save','plex.tv/link']:
   self.assertIn(required,page)
  service=read('lib/providers/fanatika_plex_setup.dart')
  for required in ['discoverLocal','startPairing','checkPairing','accountServers','X-Plex-Token','32414','followRedirects = false']:
   self.assertIn(required,service)
  self.assertNotIn('getSharedPreferences("com.plexapp.android',service)
 def test_down_to_first_items(self):
  f=read('lib/flauncher.dart')
  self.assertIn('_firstWatchNextFocusNode',f)
  self.assertIn('_firstFavoriteFocusNode',f)
  self.assertIn('onNavigateDown: _focusFirstHomeItem',f)
  self.assertIn('index == 0 ? firstFavoriteFocusNode : null',read('lib/widgets/category_clean_row.dart'))
  self.assertIn('index == 0 ? firstItemFocusNode : null',read('lib/widgets/fanatika_watch_next_panel.dart'))
 def test_weather_location_cascade(self):
  w=read('lib/widgets/fanatika_weather_card.dart')
  self.assertIn('fanatikaApproximateLocation()',w)
  self.assertIn('https://ipwho.is/',w)
  self.assertIn('saved city fallback',w)
 def test_mountain_photo_assets(self):
  p=ROOT/'assets/mountains'
  for name in ['07_Alpine_Lake_Photoreal.jpg','08_Winter_Twilight_Photoreal.jpg']:
   self.assertGreater((p/name).stat().st_size,25000)
  retired = ['07_Bansko_Pirin.jpg', '08_Pirin_River.jpg',
             '09_Mountain_River.jpg', '10_Bansko_Winter.jpg',
             '11_Pirin_Alpine_Lake.jpg']
  picker=read('lib/widgets/settings/fanatika_v2_page.dart')
  for name in retired:
   self.assertFalse((p/name).exists(), f'Obsolete wallpaper still included: {name}')
   self.assertNotIn(name,picker)
  for name in ['07_Alpine_Lake_Photoreal.jpg','08_Winter_Twilight_Photoreal.jpg']:
   self.assertIn(name,picker)
  self.assertIn('cleanup_v289_wallpapers.py', read('.github/workflows/build-fanatika-signed.yml'))
 def test_sleep_color_and_icon(self):
  timer=read('lib/widgets/fanatika_sleep_timer_dialog.dart')
  self.assertIn('0xFF1E1E1E',timer)
  bar=read('lib/widgets/fanatika_top_bar_tabs.dart')
  self.assertIn('Icons.grid_view_rounded',bar)
 def test_version(self):self.assertIn('version: 2.9.3+4146',read('pubspec.yaml'))
