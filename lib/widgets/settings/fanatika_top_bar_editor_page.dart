import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/fanatika_panel_style.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

// One focus target per entry. OK adds/removes a tab; LEFT/RIGHT reorders it.
// No nested IconButtons stealing the TV remote's focus.
class FanatikaTopBarEditorPage extends StatelessWidget {
  static const routeName = 'fanatika_top_bar_editor';
  const FanatikaTopBarEditorPage({super.key});

  Future<void> _toggle(SettingsService service, List<String> tabs, String name) async {
    if (name == 'Home' || name == 'Settings') return;
    final updated = [...tabs];
    if (updated.contains(name)) { updated.remove(name); }
    else { updated.add(name); }
    await service.setFanatikaTopBarTabs(updated);
  }

  Future<void> _move(SettingsService service, List<String> tabs,
      String name, int direction) async {
    final index = tabs.indexOf(name);
    final other = index + direction;
    if (index < 0 || other < 0 || other >= tabs.length) return;
    final updated = [...tabs];
    updated[index] = updated[other];
    updated[other] = name;
    await service.setFanatikaTopBarTabs(updated);
  }

  Widget _entry(SettingsService service, List<String> tabs, String name,
      {required bool enabled, bool first = false}) {
    final locked = name == 'Home' || name == 'Settings';
    final order = tabs.indexOf(name);
    return FocusableSettingsTile(
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent || !enabled) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _move(service, tabs, name, -1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _move(service, tabs, name, 1);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        key: ValueKey('topbar_$name'),
        focusId: 'topbar_$name',
        autofocus: first,
        leading: Icon(enabled ? Icons.check_circle : Icons.radio_button_unchecked,
          color: enabled ? const Color(0xFF85D4FF) : Colors.white54),
        title: Text(enabled ? '${order + 1}. $name' : name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        subtitle: Text(locked ? 'Always shown · Left / Right to move'
          : enabled ? 'OK to hide · Left / Right to move'
                    : 'OK to add to the top bar',
          style: const TextStyle(fontSize: 12, color: Colors.white70)),
        trailing: enabled ? const Icon(Icons.swap_horiz, color: Colors.white70)
          : const Icon(Icons.add, color: Colors.white70),
        onPressed: () => _toggle(service, tabs, name),
    );
  }

  @override Widget build(BuildContext context) {
    final service = context.watch<SettingsService>();
    final tabs = service.fanatikaTopBarTabs;
    final hidden = SettingsService.fanatikaAvailableTopBarTabs
      .where((name) => !tabs.contains(name)).toList();
    return Column(children: [
      const FanatikaPanelHeader(title: 'Customize top bar'),
      const Padding(padding: EdgeInsets.symmetric(vertical: 9, horizontal: 14),
        child: Text('Press OK to show or hide a tab. Use Left / Right on a visible tab '
          'to move it. The blue row shows your remote position.',
          style: TextStyle(fontSize: 13, color: Colors.white70))),
      Expanded(child: ListView(children: [
        const Padding(padding: EdgeInsets.fromLTRB(18, 10, 8, 4),
          child: Text('VISIBLE TABS', style: TextStyle(color: Colors.white70,
            fontWeight: FontWeight.bold))),
        for (var i = 0; i < tabs.length; i++)
          _entry(service, tabs, tabs[i], enabled: true, first: i == 0),
        if (hidden.isNotEmpty)
          const Padding(padding: EdgeInsets.fromLTRB(18, 18, 8, 4),
            child: Text('AVAILABLE TABS', style: TextStyle(color: Colors.white70,
              fontWeight: FontWeight.bold))),
        for (final name in hidden)
          _entry(service, tabs, name, enabled: false),
      ])),
    ]);
  }
}
