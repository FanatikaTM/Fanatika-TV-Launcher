"""v2.9.6: artwork is not cropped; refresh button is absent from HOME."""
import unittest
from pathlib import Path
R=Path(__file__).parent
read=lambda p:(R/p).read_text(encoding='utf8')
class V296(unittest.TestCase):
 def test_unclipped_covers(self):
  panel=read('lib/widgets/fanatika_watch_next_panel.dart')
  self.assertIn('fit: BoxFit.contain',panel)
  self.assertIn('SingleChildScrollView(',panel)
  self.assertIn('Scrollable.ensureVisible(',panel)
  # v2.9.10 uses a taller rounded cover; the old fixed extent was removed.
  self.assertIn('width: 272,',panel)
  self.assertIn('height: 226,',panel)
  self.assertIn('borderRadius: BorderRadius.circular(28)',panel)
  self.assertIn('ClipRRect(',panel)
  self.assertNotIn('fit: BoxFit.cover',panel)
 def test_no_refresh_button_on_home(self):
  panel=read('lib/widgets/fanatika_watch_next_panel.dart')
  home=read('lib/flauncher.dart')
  for part in ('refreshFocusNode', "tooltip: 'Refresh shows'",'IconButton.filledTonal', 'Icons.refresh'):
   self.assertNotIn(part,panel)
  self.assertNotIn('_watchNextRefreshFocusNode',home)
  self.assertIn('feed.hasItems',home)
 def test_feed_still_auto_refreshes(self):
  svc=read('lib/providers/watch_next_service.dart')
  self.assertIn('Timer.periodic(',svc)
  self.assertIn('refreshPermissionAndItems()',svc)
 def test_home_is_navigation_only(self):
  bar=read('lib/widgets/fanatika_top_bar_tabs.dart')
  self.assertIn("case 'Home':",bar)
  self.assertIn('onGoHome!();',bar)
  self.assertIn('onHomeRequested: _returnToHomeFromTab', read('lib/flauncher.dart'))
 def test_version(self):
  self.assertIn('version: 2.9.10+4153',read('pubspec.yaml'))
