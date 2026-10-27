// Fanatika customization submenus. Original Arc screens remain accessible.
import 'package:flutter/material.dart';
import 'package:flauncher/widgets/settings/fanatika_v2_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

class FanatikaToolsHub extends StatelessWidget {
  static const routeName = 'fanatika_tools_hub';
  const FanatikaToolsHub({super.key});
  static const categories = <({String title, IconData icon, List<String> sections})>[
    (title: 'Favorites & sections', icon: Icons.apps, sections: ['Favorites and section layout','Layouts and performance']),
    (title: 'Title & appearance', icon: Icons.text_fields, sections: ['Large selected-app title','Status bar customization']),
    (title: 'Weather', icon: Icons.cloud_outlined, sections: ['Weather']),
    (title: 'Wallpapers & inputs', icon: Icons.landscape_outlined, sections: ['Wallpaper and sources']),
    (title: 'Backup, recovery & privacy', icon: Icons.backup_outlined, sections: ['Backup and restore','Security and quick settings']),
    (title: 'Theme preview & diagnostics', icon: Icons.preview_outlined, sections: ['Diagnostics and appearance preview']),
    (title: 'Sleep & standby', icon: Icons.bedtime_outlined, sections: ['Sleep and standby']),
  ];
  @override Widget build(BuildContext context) => Column(children: [
    const Padding(padding: EdgeInsets.all(12), child: Text('Tools', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Divider(height: 1),
    Expanded(child: ListView.builder(itemCount: categories.length, itemBuilder: (context, index) {
      final item = categories[index];
      return FocusableSettingsTile(
        autofocus: index == 0,
        leading: Icon(item.icon),
        title: Text(item.title), trailing: const Icon(Icons.chevron_right),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: SafeArea(child: FanatikaV2Page(sections: item.sections))),
        )),
      );
    }))
  ]);
}
