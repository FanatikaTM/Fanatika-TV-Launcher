"""v2.9.7: prevent duplicate menu entries and prevent cramped dialogs."""
import unittest
from pathlib import Path
R=Path(__file__).parent
read=lambda p:(R/p).read_text(encoding='utf8')
class V297(unittest.TestCase):
 def test_input_has_only_one_primary_entry(self):
  s=read('lib/widgets/settings/unified_settings_pages.dart')
  self.assertIn("!context.watch<SettingsService>().fanatikaTopBarTabs.contains('Input')",s)
  self.assertIn('if (showInputHere)',s)
  self.assertIn('autofocus: !showInputHere',s)
 def test_quick_controls_not_duplicated_in_advanced(self):
  s=read('lib/widgets/settings/fanatika_v2_page.dart')
  self.assertIn("'Change or remove PIN'",s)
  self.assertNotIn("tile(Icons.wifi, 'Wi-Fi settings'",s)
  self.assertNotIn("tile(Icons.bluetooth, 'Bluetooth settings'",s)
  self.assertNotIn("tile(Icons.display_settings, 'Display settings'",s)
 def test_switch_rows_only_one_remote_focus_target(self):
  s=read('lib/widgets/settings/unified_settings_pages.dart')
  self.assertIn('trailing: ExcludeFocus(child: IgnorePointer(',s)
 def test_modal_screen_constraints(self):
  s=read('lib/widgets/side_panel_dialog.dart')
  self.assertIn('MediaQuery.sizeOf(context)',s)
  self.assertIn('MediaQuery.viewInsetsOf(context)',s)
  self.assertIn('height: panelHeight',s)
 def test_settings_only_one_modal(self):
  s=read('lib/widgets/fanatika_top_bar_tabs.dart')
  self.assertIn('if (_settingsDialogOpen) return;',s)
  self.assertIn('_settingsDialogOpen = false;',s)
 def test_legacy_submenu_names_are_specific(self):
  s=read('lib/widgets/settings/fanatika_v2_page.dart')
  self.assertIn('FanatikaPanelHeader(title: widget.sections.length == 1',s)
  self.assertIn('maxLines: 2',s)
 def test_version(self):
  self.assertIn('version: 2.9.9+4152', read('pubspec.yaml'))
