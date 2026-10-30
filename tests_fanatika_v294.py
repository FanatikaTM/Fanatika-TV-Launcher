"""v2.9.4 remote and UI regression checks (source checks, not device tests)."""
import unittest
from pathlib import Path
import xml.etree.ElementTree as ET
ROOT=Path(__file__).parent
read=lambda p:(ROOT/p).read_text(encoding='utf-8')
class V294(unittest.TestCase):
 def test_plex_only_pairs(self):
  s=read('lib/widgets/settings/plex_continue_watching_page.dart')
  for key in ['startPairing()', 'checkPairing(pin)', 'accountServers(accountToken)', 'setPlexContinueWatchingConfig(', 'plex.tv/link']:
   self.assertIn(key,s)
  for old in ['_discover()', '_checkAndroidFeed()', 'Manual server setup', 'TextField(']:
   self.assertNotIn(old,s)
 def test_watch_next_only_artwork_and_title(self):
  s=read('lib/widgets/fanatika_watch_next_panel.dart')
  for marker in ['SingleChildScrollView(', 'Scrollable.ensureVisible(', 'LogicalKeyboardKey.arrowRight',
    'LogicalKeyboardKey.arrowLeft', 'widget.item.title', 'focusNode: widget.refreshFocusNode']:
   self.assertIn(marker,s)
  for old in ["Text('Watch Next'", "'Plex  •  '", 'border: Border.all(color: Colors.white24)']:
   self.assertNotIn(old,s)
 def test_home_navigation_and_favorites_preserved(self):
  s=read('lib/flauncher.dart')
  for marker in ['onHomeRequested: _returnToHomeFromTab',
    'onNavigateDown: () => _firstFavoriteFocusNode.requestFocus()',
    'handleUpNavigationToSettings: true', 'feed.hasItems ? _firstWatchNextFocusNode']:
   self.assertIn(marker,s)
  for method in ['addToFavorites','removeFromFavorites','reorderApplication']:
   self.assertIn(method,read('lib/providers/apps_service.dart'))
 def test_home_override_removed_and_clock_moved(self):
  menu=read('lib/widgets/settings/unified_settings_pages.dart')
  manifest=read('android/app/src/main/AndroidManifest.xml')
  ET.fromstring(manifest)
  self.assertNotIn('Make Fanatika HOME',menu)
  self.assertNotIn('Arc system preferences',menu)
  self.assertNotIn('FanatikaHomeOverrideService',manifest)
  self.assertIn("'Date & time format'",menu)
  self.assertIn('DateTimeFormatPage.routeName',menu)
 def test_current_version(self):
  self.assertIn('version: 2.9.4+4147',read('pubspec.yaml'))
