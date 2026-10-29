import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';

// Add/remove/move controls without a separate launcher menu.
class FanatikaTopBarEditorPage extends StatelessWidget {
  static const routeName = 'fanatika_top_bar_editor';
  const FanatikaTopBarEditorPage({super.key});
  @override Widget build(BuildContext context) {
    final service = context.watch<SettingsService>();
    final tabs = service.fanatikaTopBarTabs;
    return Column(children: [
      const Text('Customize top bar', style: TextStyle(fontSize: 21,
        fontWeight: FontWeight.w600)),
      const Divider(),
      const Padding(padding: EdgeInsets.symmetric(vertical: 9, horizontal: 14),
        child: Text('Select the text tabs you want. Move them up or down to change '
          'their order. Home and Settings remain available for recovery.',
          style: TextStyle(fontSize: 13, color: Colors.white70))),
      Expanded(child: ListView(children: [
        for (final name in SettingsService.fanatikaAvailableTopBarTabs)
          Builder(builder: (context) {
            final on = tabs.contains(name);
            final locked = name == 'Home' || name == 'Settings';
            final idx = tabs.indexOf(name);
            return ListTile(
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
                  icon: const Icon(Icons.arrow_upward)),
                IconButton(tooltip: 'Move $name right',
                  onPressed: idx < tabs.length-1 ? () async {
                    final updated = [...tabs];
                    final next = updated[idx+1];
                    updated[idx+1] = name; updated[idx] = next;
                    await context.read<SettingsService>().setFanatikaTopBarTabs(updated);
                  } : null,
                  icon: const Icon(Icons.arrow_downward)),
              ])) : null,
            );
          }),
      ])),
    ]);
  }
}
