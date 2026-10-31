import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/fanatika_panel_style.dart';

// Add/remove/move controls without a separate launcher menu.
class FanatikaTopBarEditorPage extends StatelessWidget {
  static const routeName = 'fanatika_top_bar_editor';
  const FanatikaTopBarEditorPage({super.key});
  @override Widget build(BuildContext context) {
    final service = context.watch<SettingsService>();
    final tabs = service.fanatikaTopBarTabs;
    return Column(children: [
      const FanatikaPanelHeader(title: 'Customize top bar'),
      const Padding(padding: EdgeInsets.symmetric(vertical: 9, horizontal: 14),
        child: Text('Keep the top bar compact. TV controls are in Settings > TV & tools. '
          'Move tabs to change their order. Home and Settings stay available.',
          style: TextStyle(fontSize: 13, color: Colors.white70))),
      Expanded(child: ListView(children: [
        for (final name in SettingsService.fanatikaAvailableTopBarTabs)
          Builder(builder: (context) {
            final on = tabs.contains(name);
            final locked = name == 'Home' || name == 'Settings';
            final idx = tabs.indexOf(name);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: FanatikaPanelStyle.tile,
                  borderRadius: BorderRadius.circular(19)),
                child: ListTile(
              leading: Icon(on ? Icons.check_box : Icons.check_box_outline_blank),
              title: Text(name),
              subtitle: locked ? const Text('Always available') : null,
              onTap: locked ? null : () async {
                final updated = [...tabs];
                if (on) updated.remove(name); else updated.add(name);
                await context.read<SettingsService>().setFanatikaTopBarTabs(updated);
              },
              trailing: on ? SizedBox(width: 94, child: Row(children: [
                IconButton(tooltip: 'Move $name left',
                  onPressed: idx > 0 ? () async {
                    final updated = [...tabs];
                    final previous = updated[idx-1];
                    updated[idx-1] = name; updated[idx] = previous;
                    await context.read<SettingsService>().setFanatikaTopBarTabs(updated);
                  } : null,
                  icon: const Icon(Icons.arrow_left)),
                IconButton(tooltip: 'Move $name right',
                  onPressed: idx < tabs.length-1 ? () async {
                    final updated = [...tabs];
                    final next = updated[idx+1];
                    updated[idx+1] = name; updated[idx] = next;
                    await context.read<SettingsService>().setFanatikaTopBarTabs(updated);
                  } : null,
                  icon: const Icon(Icons.arrow_right)),
              ])) : null,
              ),
            ));
          }),
      ])),
    ]);
  }
}
