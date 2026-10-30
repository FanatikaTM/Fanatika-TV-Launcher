// One Arc-style settings hierarchy for Arc + Fanatika features.
// The existing home bar and the original Arc Favorites editor are preserved.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/fanatika_v2_page.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flauncher/widgets/settings/appearance_panel_page.dart';
import 'package:flauncher/widgets/settings/fanatika_top_bar_editor_page.dart';
import 'package:flauncher/widgets/settings/wallpaper_panel_page.dart';
import 'package:flauncher/widgets/settings/plex_continue_watching_page.dart';
import 'package:flauncher/widgets/settings/fanatika_sleep_page.dart';
import 'package:flauncher/widgets/settings/fanatika_usb_page.dart';
import 'package:flauncher/widgets/settings/fanatika_updates_page.dart';
import 'package:flauncher/widgets/settings/date_time_format_page.dart';

class _MergedMenu {
  static Widget group(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
    child: Text(label.toUpperCase(), style: const TextStyle(
      color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12)));

  static Widget route(BuildContext context, IconData icon, String name,
      String route, {String? detail, bool autofocus = false, Object? args}) =>
    FocusableSettingsTile(autofocus: autofocus, leading: Icon(icon),
      title: Text(name),
      subtitle: detail == null ? null : Text(detail),
      trailing: const Icon(Icons.chevron_right),
      onPressed: () => Navigator.of(context).pushNamed(route, arguments: args));

  static Widget action(IconData icon, String title, VoidCallback action,
      {String? detail, bool autofocus = false}) =>
    FocusableSettingsTile(autofocus: autofocus, leading: Icon(icon),
      title: Text(title),
      subtitle: detail == null ? null : Text(detail),
      trailing: const Icon(Icons.chevron_right), onPressed: action);

  static Widget option(String title, bool enabled,
      Future<void> Function(bool) update, {IconData icon = Icons.tune, bool autofocus = false}) =>
    FocusableSettingsTile(autofocus: autofocus, leading: Icon(icon),
      title: Text(title),
      trailing: Switch(value: enabled, onChanged: update),
      onPressed: () => update(!enabled));

  static Widget page(BuildContext context, String title, List<Widget> children) =>
    Column(children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const Divider(),
      Expanded(child: ListView(padding: const EdgeInsets.only(bottom: 24), children: children)),
    ]);
}

class UnifiedHomePage extends StatelessWidget {
  static const routeName = 'merged_home_settings';
  const UnifiedHomePage({super.key});
  @override Widget build(BuildContext context) => _MergedMenu.page(context, 'Home & appearance', [
    _MergedMenu.route(context, Icons.title, 'Large app title',
      FanatikaV2Page.routeName, autofocus: true,
      args: const ['Large selected-app title'],
      detail: 'Font, style, size, position and preview'),
    _MergedMenu.route(context, Icons.wallpaper_outlined, 'Wallpapers',
      UnifiedWallpaperPage.routeName, detail: 'Photos and Arc wallpaper library'),
    _MergedMenu.route(context, Icons.brush_outlined, 'Appearance & focus',
      AppearancePanelPage.routeName, detail: 'Arc blur, background and focus border'),
    _MergedMenu.route(context, Icons.access_time_outlined, 'Date & time format',
      DateTimeFormatPage.routeName, detail: 'Clock and date formats on the top bar'),
    _MergedMenu.route(context, Icons.view_quilt_outlined, 'Top bar',
      FanatikaTopBarEditorPage.routeName, detail: 'Add, remove or reorder tabs'),
    _MergedMenu.route(context, Icons.tune, 'Extra layout options',
      FanatikaV2Page.routeName,
      args: const ['Layouts and performance', 'Status bar customization'],
      detail: 'Presets, animations and bar style'),
  ]);
}

class UnifiedAppsPage extends StatelessWidget {
  static const routeName = 'merged_apps_settings';
  const UnifiedAppsPage({super.key});
  @override Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return _MergedMenu.page(context, 'Apps & Favorites', [
      _MergedMenu.route(context, Icons.favorite_border, 'Favorites & sections',
        LauncherSectionsPanelPage.routeName, autofocus: true,
        detail: 'Original Arc add, remove and reorder'),
      _MergedMenu.route(context, Icons.apps, 'Installed apps',
        ApplicationsPanelPage.routeName),
      _MergedMenu.option('Show app labels', s.showAppNamesBelowIcons,
        s.setShowAppNamesBelowIcons, icon: Icons.text_fields),
      _MergedMenu.route(context, Icons.auto_awesome, 'App focus & layout',
        FanatikaV2Page.routeName, args: const ['Favorites and section layout'],
        detail: 'Center rows, enlarge focus and glow'),
      _MergedMenu.route(context, Icons.edit_note, 'App descriptions & backgrounds',
        FanatikaV2Page.routeName, args: const ['App customization']),
    ]);
  }
}

class UnifiedMediaPage extends StatelessWidget {
  static const routeName = 'merged_media_settings';
  const UnifiedMediaPage({super.key});
  @override Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return _MergedMenu.page(context, 'Watch Next & weather', [
      _MergedMenu.option('Show Watch Next', s.showWatchNextSection,
        s.setShowWatchNextSection, icon: Icons.movie, autofocus: true),
      _MergedMenu.route(context, Icons.movie_filter_outlined, 'Plex Continue Watching',
        PlexContinueWatchingPage.routeName,
        detail: 'One-time Plex pairing and refresh settings'),
      _MergedMenu.route(context, Icons.cloud_outlined, 'Weather',
        FanatikaV2Page.routeName, args: const ['Weather'],
        detail: 'Location, city, forecast and units'),
    ]);
  }
}

class UnifiedWallpaperPage extends StatelessWidget {
  static const routeName = 'merged_wallpaper_settings';
  const UnifiedWallpaperPage({super.key});
  @override Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return _MergedMenu.page(context, 'Wallpapers', [
      _MergedMenu.route(context, Icons.wallpaper_outlined, 'Wallpaper library',
        WallpaperPanelPage.routeName, autofocus: true,
        detail: 'Original Arc image picker and slideshow options'),
      _MergedMenu.option('Smart mountain wallpapers', s.fanatikaSmartMountains,
        (v) => s.setFanatikaOption('fanatika_v2_smart_mountains', v),
        icon: Icons.landscape),
    ]);
  }
}

class UnifiedSystemPage extends StatelessWidget {
  static const routeName = 'merged_system_settings';
  const UnifiedSystemPage({super.key});
  Future<void> _openNativeInputs(BuildContext context) async {
    try {
      final result = await FLauncherChannel().openTvSourcePicker();
      if (!context.mounted) return;
      if (result['opened'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Input is not available on this TV. Use its remote.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The TV did not allow access to its native Input menu.')));
      }
    }
  }
  @override Widget build(BuildContext context) => _MergedMenu.page(context, 'TV & tools', [
    _MergedMenu.action(Icons.input, 'Input',
      () => _openNativeInputs(context), autofocus: true,
      detail: 'Native TV source menu'),
    _MergedMenu.route(context, Icons.bedtime_outlined, 'Sleep timer',
      FanatikaSleepPage.routeName),
    _MergedMenu.action(Icons.settings_applications, 'Android TV settings',
      () => context.read<AppsService>().openSettings()),
    _MergedMenu.route(context, Icons.backup_outlined, 'Backup & restore',
      FanatikaV2Page.routeName, args: const ['Backup and restore']),
    _MergedMenu.route(context, Icons.system_update, 'Updates',
      FanatikaUpdatesPage.routeName),
    _MergedMenu.route(context, Icons.more_horiz, 'Advanced tools',
      UnifiedAdvancedPage.routeName,
      detail: 'USB, PIN and diagnostics'),
  ]);
}

// Only rarely used controls go one level deeper; no second settings hub.
class UnifiedAdvancedPage extends StatelessWidget {
  static const routeName = 'merged_advanced_settings';
  const UnifiedAdvancedPage({super.key});
  @override Widget build(BuildContext context) => _MergedMenu.page(context, 'Advanced tools', [
    _MergedMenu.route(context, Icons.usb, 'USB files', FanatikaUsbPage.routeName, autofocus: true),
    _MergedMenu.route(context, Icons.pin, 'Security & connectivity',
      FanatikaV2Page.routeName, args: const ['Security and quick settings'],
      detail: 'PIN, Wi-Fi, Bluetooth and display'),
    _MergedMenu.route(context, Icons.health_and_safety_outlined, 'Diagnostics & recovery',
      FanatikaV2Page.routeName, args: const ['Diagnostics and appearance preview']),
  ]);
}
