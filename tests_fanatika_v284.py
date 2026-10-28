"""Source regressions for v2.8.4; real TV navigation and Flutter build are separate."""
import unittest
from pathlib import Path
R=Path(__file__).resolve().parent
read=lambda p:(R/p).read_text(encoding='utf-8')
class LayoutFocusNav284(unittest.TestCase):
 def test_version_and_ci(self):
  self.assertIn('version: 2.8.4+4137',read('pubspec.yaml'))
  self.assertIn('tests_fanatika_v284',read('.github/workflows/build-fanatika-signed.yml'))
 def test_focus_up_from_watch_next(self):
  panel=read('lib/widgets/fanatika_watch_next_panel.dart')
  launcher=read('lib/flauncher.dart')
  self.assertIn('LogicalKeyboardKey.arrowUp',panel)
  self.assertIn('KeyEventResult.handled',panel)
  self.assertIn('onNavigateUp: () => _appBarKey.currentState?.focusSettings()',launcher)
 def test_title_off_gives_height_to_panels(self):
  launcher=read('lib/flauncher.dart')
  self.assertIn('heroEnabled\n                      ? SizedBox(height: 242, child: topPanels)',launcher)
  self.assertIn('expandVertical: !heroEnabled',launcher)
  self.assertIn('if (heroEnabled) Expanded(',launcher)
  self.assertIn('height: widget.expandVertical ? double.infinity : null',read('lib/widgets/fanatika_weather_card.dart'))
 def test_three_tabs_have_options(self):
  menu=read('lib/widgets/tv_top_navigation_dialog.dart')
  for title in ['Go to Home','Watch Next','Weather','Large selected-app title','Installed applications','Favorites and sections','Updates','USB storage','Sleep and standby','TV inputs and HDMI','All Settings']:
   self.assertIn(title,menu)
  self.assertIn('settings.setShowAppNamesBelowIcons',menu)
  bar=read('lib/widgets/focus_aware_app_bar.dart')
  for key in ['TvTopTab.home','TvTopTab.apps','TvTopTab.tools']:
   self.assertIn(key,bar)
 def test_original_favorites_unmodified(self):
  apps=read('lib/providers/apps_service.dart')
  for f in ['addToFavorites','removeFromFavorites','reorderApplication']:
   self.assertIn(f,apps)
if __name__=='__main__':unittest.main()
