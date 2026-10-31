// Android-backed fonts: no copyrighted font files are bundled.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/fanatika_panel_style.dart';

class FanatikaTitleFontPage extends StatelessWidget {
  static const routeName = 'fanatika_title_fonts';
  const FanatikaTitleFontPage({super.key});

  // Values are platform font-family names; availability depends on Android TV.
  static const fonts = <(String, String)>[
    ('Automatic', 'Automatic – keep the existing title style'),
    ('sans-serif', 'Roboto / modern'),
    ('sans-serif-condensed', 'Condensed'),
    ('sans-serif-light', 'Thin / light'),
    ('sans-serif-medium', 'Medium'),
    ('sans-serif-black', 'Heavy'),
    ('serif', 'Classic serif'),
    ('monospace', 'Monospace / technical'),
    ('cursive', 'Cursive'),
    ('casual', 'Casual'),
  ];

  @override Widget build(BuildContext context) {
    final current = context.watch<SettingsService>().fanatikaTitleFont;
    return Column(children: [
      const FanatikaPanelHeader(title: 'Large app title font'),
      Expanded(child: ListView(children: [
        const Padding(padding: EdgeInsets.all(12), child: Text(
          'Choose the font for the big selected-app name only. The top bar, menu fonts, '
          'and Favorites remain unchanged. Fonts may vary by TV firmware.')),
        for (final (family, label) in fonts)
          FocusableSettingsTile(
            autofocus: family == current,
            title: Text(label),
            subtitle: Text('Plex   YouTube   TV', maxLines: 1,
              style: TextStyle(fontFamily: family == 'Automatic' ? null : family,
                fontSize: 27, fontWeight: FontWeight.w500)),
            trailing: family == current ? const Icon(Icons.check_circle) : null,
            onPressed: () async {
              await context.read<SettingsService>().setFanatikaOption(
                'fanatika_v2_title_font', family);
            }),
      ])),
    ]);
  }
}
