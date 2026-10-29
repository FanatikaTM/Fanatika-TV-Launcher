/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/flauncher_about_dialog.dart';
import 'package:flauncher/widgets/settings/unified_settings_pages.dart';
import 'focusable_settings_tile.dart';

class SettingsPanelPage extends StatelessWidget {
  static const String routeName = 'settings_panel';
  const SettingsPanelPage({super.key});
  @override Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    Widget item(IconData icon, String label, String detail, String route, {bool focus = false}) =>
      FocusableSettingsTile(autofocus: focus, leading: Icon(icon),
        title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        subtitle: Text(detail, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onPressed: () => Navigator.of(context).pushNamed(route));
    return Column(children: [
      Text(localizations.settings, style: Theme.of(context).textTheme.titleLarge),
      const Divider(),
      Expanded(child: ListView(children: [
        item(Icons.home_outlined, 'Home & appearance',
          'Large title, fonts, layout, Arc appearance', UnifiedHomePage.routeName, focus: true),
        item(Icons.apps, 'Apps & Favorites',
          'Arc Favorites, apps and focus behavior', UnifiedAppsPage.routeName),
        item(Icons.movie_filter_outlined, 'Watch Next & weather',
          'Plex Continue Watching, weather and forecast', UnifiedMediaPage.routeName),
        item(Icons.landscape_outlined, 'Wallpapers',
          'Arc wallpapers and Fanatika mountain backgrounds', UnifiedWallpaperPage.routeName),
        item(Icons.settings_outlined, 'TV & tools',
          'Native Input, sleep, backup, USB, system and updates', UnifiedSystemPage.routeName),
        const Divider(),
        FocusableSettingsTile(leading: const Icon(Icons.info_outline),
          title: Text(localizations.aboutFlauncher),
          onPressed: () => showDialog(context: context,
            builder: (_) => FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done && snapshot.hasData
                ? LTvLauncherAboutDialog(packageInfo: snapshot.data!) : Container()))),
      ])),
    ]);
  }
}

