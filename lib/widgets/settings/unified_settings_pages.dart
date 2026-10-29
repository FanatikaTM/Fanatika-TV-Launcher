// One Arc-style settings hierarchy for Arc + Fanatika features.
// The existing home bar and the original Arc Favorites editor are preserved.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/fanatika_tv_controls.dart';
import 'package:flauncher/widgets/settings/fanatika_v2_page.dart';
import 'package:flauncher/widgets/settings/fanatika_theme_preview.dart';
import 'package:flauncher/widgets/settings/fanatika_title_font_page.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flauncher/widgets/settings/appearance_panel_page.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/fanatika_top_bar_editor_page.dart';
import 'package:flauncher/widgets/settings/wallpaper_panel_page.dart';
import 'package:flauncher/widgets/settings/plex_continue_watching_page.dart';
import 'package:flauncher/widgets/settings/fanatika_sleep_page.dart';
import 'package:flauncher/widgets/settings/fanatika_usb_page.dart';
import 'package:flauncher/widgets/settings/fanatika_updates_page.dart';
import 'package:flauncher/widgets/settings/general_settings_page.dart';

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
  @override Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return _MergedMenu.page(context, 'Home & appearance', [
      _MergedMenu.group('Large selected-app title'),
      _MergedMenu.option('Show large title', s.showFanatikaHero, s.setShowFanatikaHero,
        icon: Icons.title, autofocus: true),
      _MergedMenu.route(context, Icons.font_download_outlined, 'Title font',
        FanatikaTitleFontPage.routeName, detail: s.fanatikaTitleFont),
      _MergedMenu.action(Icons.auto_awesome, 'Text style: ${s.fanatikaTitleStyle}', () async {
        final chosen = await FanatikaTvControls.choose<String>(context,
          title: 'Title text style',
          values: const ['Classic','Bold','Cinema','Glass','Glow','Neon',
            'Minimal','Wide','Shadow','Outline','Elegant','Mono','Soft','Steel','Sunset'],
          label: (v) => v, current: s.fanatikaTitleStyle);
        if (chosen != null && context.mounted) {
          await context.read<SettingsService>().setFanatikaOption('fanatika_v2_title_style', chosen);
        }
      }),
      _MergedMenu.action(Icons.format_size, 'Title size: ${s.fanatikaHeroSize.round()}', () async {
        final chosen = await FanatikaTvControls.choose<double>(context,
          title: 'Title size', values: const [28.0,36.0,44.0,52.0,60.0,72.0,84.0,96.0],
          label: (v) => '${v.round()} px', current: s.fanatikaHeroSize);
        if (chosen != null && context.mounted) {
          await context.read<SettingsService>().setFanatikaOption('fanatika_v2_hero_size', chosen);
        }
      }),
      _MergedMenu.action(Icons.visibility_outlined, 'Preview title before applying',
        () => showDialog<void>(context: context,
          builder: (_) => const FanatikaThemePreview())),
      _MergedMenu.group('Arc + Fanatika appearance'),
      _MergedMenu.route(context, Icons.brush_outlined, 'Appearance and focus border',
        AppearancePanelPage.routeName, detail: 'Original Arc options and home appearance'),
      _MergedMenu.route(context, Icons.view_quilt_outlined, 'Top bar: add, remove and reorder',
        FanatikaTopBarEditorPage.routeName, detail: 'Text tabs inside the original bar style'),
      _MergedMenu.route(context, Icons.tune, 'Additional title and layout options',
        FanatikaV2Page.routeName, args: const [
          'Large selected-app title', 'Layouts and performance',
          'Diagnostics and appearance preview']),
    ]);
  }
}

class UnifiedAppsPage extends StatelessWidget {
  static const routeName = 'merged_apps_settings';
  const UnifiedAppsPage({super.key});
  @override Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return _MergedMenu.page(context, 'Apps & Favorites', [
      _MergedMenu.group('Original Arc app management'),
      _MergedMenu.route(context, Icons.apps, 'Installed applications',
        ApplicationsPanelPage.routeName, autofocus: true),
      _MergedMenu.route(context, Icons.favorite_border, 'Favorites and sections',
        LauncherSectionsPanelPage.routeName,
        detail: 'Add, remove, move and reorder using Arc Favorites'),
      _MergedMenu.group('Fanatika display options'),
      _MergedMenu.option('Show app names under icons', s.showAppNamesBelowIcons,
        s.setShowAppNamesBelowIcons, icon: Icons.text_fields),
      _MergedMenu.option('Center short app rows', s.fanatikaCenterSections,
        (v) => s.setFanatikaOption('fanatika_v2_center_sections', v),
        icon: Icons.align_horizontal_center),
      _MergedMenu.option('Enlarge focused app', s.fanatikaFocusGrow,
        (v) => s.setFanatikaOption('fanatika_v2_focus_grow', v),
        icon: Icons.zoom_out_map),
      _MergedMenu.option('Glow around focused app', s.fanatikaFocusGlow,
        (v) => s.setFanatikaOption('fanatika_v2_focus_glow', v),
        icon: Icons.flare),
      _MergedMenu.route(context, Icons.edit_note, 'App descriptions and backgrounds',
        FanatikaV2Page.routeName,
        args: const ['Diagnostics and appearance preview']),
    ]);
  }
}

class UnifiedMediaPage extends StatelessWidget {
  static const routeName = 'merged_media_settings';
  const UnifiedMediaPage({super.key});
  Future<void> _chooseCity(BuildContext context, SettingsService s) async {
    final ctrl = TextEditingController(text: s.fanatikaWeatherCity);
    try {
      final city = await showDialog<String>(context: context,
        builder: (ctx) => AlertDialog(title: const Text('Weather city'),
          content: TextField(controller: ctrl, autofocus: true,
            decoration: const InputDecoration(hintText: 'City'),
            onSubmitted: (v) => Navigator.pop(ctx, v)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
          ]));
      if (city != null && city.trim().isNotEmpty && context.mounted) {
        await context.read<SettingsService>().setFanatikaWeatherCity(city.trim());
      }
    } finally { ctrl.dispose(); }
  }
  @override Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return _MergedMenu.page(context, 'Watch Next & weather', [
      _MergedMenu.group('Continue Watching'),
      _MergedMenu.option('Show Watch Next', s.showWatchNextSection,
        s.setShowWatchNextSection, icon: Icons.movie, autofocus: true),
      _MergedMenu.route(context, Icons.movie_filter_outlined, 'Plex Continue Watching',
        PlexContinueWatchingPage.routeName,
        detail: 'Plex server, token and connection test'),
      _MergedMenu.group('Weather'),
      _MergedMenu.option('Show weather', s.showFanatikaWeather,
        s.setShowFanatikaWeather, icon: Icons.cloud_outlined),
      _MergedMenu.option('Use approximate TV location', s.fanatikaWeatherAutoLocation,
        (v) => s.setFanatikaOption('fanatika_v27_auto_weather_location', v),
        icon: Icons.my_location),
      _MergedMenu.action(Icons.location_city, 'Weather city',
        () => _chooseCity(context, s), detail: s.fanatikaWeatherCity),
      _MergedMenu.option('Use Fahrenheit', s.fanatikaFahrenheit,
        s.setFanatikaFahrenheit, icon: Icons.thermostat),
      _MergedMenu.route(context, Icons.settings_outlined, 'Forecast and refresh options',
        FanatikaV2Page.routeName, args: const ['Weather']),
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
      _MergedMenu.route(context, Icons.image_outlined, 'Background for selected apps',
        FanatikaV2Page.routeName,
        args: const ['Diagnostics and appearance preview']),
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
    _MergedMenu.group('TV controls'),
    _MergedMenu.action(Icons.input, 'Input',
      () => _openNativeInputs(context), autofocus: true,
      detail: 'Open the original TV Input menu'),
    _MergedMenu.route(context, Icons.bedtime_outlined, 'Sleep / standby',
      FanatikaSleepPage.routeName),
    _MergedMenu.action(Icons.settings_applications, 'Android TV settings',
      () => context.read<AppsService>().openSettings()),
    _MergedMenu.group('Arc system & maintenance'),
    _MergedMenu.route(context, Icons.settings, 'Arc system preferences',
      GeneralSettingsPage.routeName, detail: 'Clock, brightness, Wi-Fi and back button'),
    _MergedMenu.route(context, Icons.backup_outlined, 'Backup, restore and recovery',
      FanatikaV2Page.routeName, args: const [
        'Backup and restore', 'Security and quick settings']),
    _MergedMenu.route(context, Icons.usb, 'USB files', FanatikaUsbPage.routeName),
    _MergedMenu.route(context, Icons.system_update, 'Updates',
      FanatikaUpdatesPage.routeName),
  ]);
}
