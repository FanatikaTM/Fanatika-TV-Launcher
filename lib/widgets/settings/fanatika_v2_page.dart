// Fanatika TV Launcher v2 on-TV tools. Original Arc settings and Favorites stay intact.
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/fanatika_backup_service.dart';
import 'package:flauncher/providers/fanatika_release_checker.dart';
import 'package:flauncher/widgets/fanatika_update_dialog.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/widgets/settings/fanatika_tv_controls.dart';
import 'package:flauncher/widgets/settings/tv_inputs_panel_page.dart';
import 'package:flauncher/widgets/settings/fanatika_sleep_page.dart';
import 'package:flauncher/widgets/settings/fanatika_remote_tester_page.dart';
import 'package:flauncher/widgets/settings/fanatika_theme_preview.dart';

class FanatikaV2Page extends StatefulWidget {
  static const routeName = 'fanatika_v2_settings';
  const FanatikaV2Page({super.key});
  @override
  State<FanatikaV2Page> createState() => _FanatikaV2PageState();
}

class _FanatikaV2PageState extends State<FanatikaV2Page> {
  bool unlocked = false;
  String status = '';
  bool working = false;
  final native = FLauncherChannel();

  Future<String?> askText(String title, {String value = '', bool secret = false}) async {
    final controller = TextEditingController(text: value);
    final answer = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, obscureText: secret, autofocus: true, maxLength: 120,
        decoration: const InputDecoration(hintText: 'Enter a value'),
        onSubmitted: (s) => Navigator.pop(ctx, s)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('OK'))],
    ));
    controller.dispose();
    return answer;
  }

  Future<bool> confirm(String title, String message) async => await showDialog<bool>(
    context: context, builder: (ctx) => AlertDialog(title: Text(title), content: Text(message), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
    ]),
  ) ?? false;

  String hashPin(String pin, String salt) => sha256.convert(utf8.encode('$salt:$pin')).toString();
  Future<void> authenticate() async {
    final settings = context.read<SettingsService>();
    final pin = await askText('Enter settings PIN', secret: true);
    if (pin == null) return;
    final stored = settings.fanatikaSettingsPin.split(':');
    if (stored.length == 2 && hashPin(pin, stored[0]) == stored[1]) {
      setState(() => unlocked = true);
    } else {
      setState(() => status = 'Incorrect PIN');
    }
  }

  Future<void> changePin() async {
    final settings = context.read<SettingsService>();
    final existing = settings.fanatikaSettingsPin;
    if (existing.isNotEmpty) {
      final old = await askText('Current PIN', secret: true);
      final pair = existing.split(':');
      if (old == null || pair.length != 2 || hashPin(old, pair[0]) != pair[1]) {
        setState(() => status = 'Current PIN incorrect'); return;
      }
    }
    final pin = await askText('New PIN (4–8 digits, blank to disable)', secret: true);
    if (pin == null) return;
    if (pin.isNotEmpty && !RegExp(r'^\d{4,8}$').hasMatch(pin)) {
      setState(() => status = 'PIN must be 4–8 digits'); return;
    }
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256))
        .map((i) => i.toRadixString(16).padLeft(2, '0')).join();
    await settings.setFanatikaOption('fanatika_v2_pin', pin.isEmpty ? '' : '$salt:${hashPin(pin, salt)}');
    setState(() => status = pin.isEmpty ? 'PIN disabled' : 'PIN enabled');
  }

  Future<void> guard(Future<void> Function() action) async {
    if (working) return;
    setState(() => working = true);
    try { await action(); } catch (e) { if (mounted) setState(() => status = 'Error: $e'); }
    if (mounted) setState(() => working = false);
  }

  Future<void> exportBackup() => guard(() async {
    final okToExport = await confirm('Export settings and Favorites?',
      'Fanatika will save a JSON file in Downloads/Fanatika. Other people with access '
      'to your TV files may be able to read the preferences. Signing keys, passwords, '
      'PINs and API credentials are not included. Continue?');
    if (!okToExport || !mounted) return;
    final settings = context.read<SettingsService>();
    final apps = context.read<AppsService>();
    final ok = await FanatikaBackupService.export(settings, apps);
    if (mounted) setState(() => status = ok ? 'Backup saved in Downloads/Fanatika (no file picker required)' : 'Backup was not saved');
  });

  Future<void> importBackup() => guard(() async {
    final data = await FanatikaBackupService.selectImport();
    if (data == null || !mounted) return;
    final count = (data['favorites'] as List).length;
    final ok = await confirm('Restore Fanatika settings?',
      'Restore preferences and $count Favorites from the newest Fanatika backup in Downloads/Fanatika? Current Favorites and appearance settings will change. Apps not installed are skipped. Home settings stay unchanged.');
    if (!ok || !mounted) return;
    // Before overwriting anything save a separate recovery copy through SAF.
    final saved = await FanatikaBackupService.export(context.read<SettingsService>(), context.read<AppsService>());
    if (!saved || !mounted) {
      setState(() => status = 'Restoration cancelled: safety backup was not saved'); return;
    }
    await FanatikaBackupService.restore(data, context.read<SettingsService>(), context.read<AppsService>());
    if (mounted) setState(() => status = 'Restored preferences and Favorites. Restart launcher to refresh layout.');
  });

  Future<void> editDescription() async {
    final apps = context.read<AppsService>().applications;
    if (apps.isEmpty) return;
    final result = await FanatikaTvControls.choose<String>(context,
      title: 'Choose app for description',
      values: apps.take(150).map((a) => a.packageName).toList(),
      label: (id) => apps.firstWhere((a) => a.packageName == id).name);
    if (!mounted || result == null) return;
    final settings = context.read<SettingsService>();
    final value = await askText('Description', value: settings.fanatikaDescriptions[result] ?? '');
    if (value != null) await settings.setFanatikaMapValue('fanatika_v2_descriptions', result, value);
  }

  Future<void> editInputNames() async {
    final inputs = await native.getTvInputs();
    if (!mounted) return;
    final keys = inputs.map((i) => i['id']?.toString() ?? '').where((i) => i.isNotEmpty).toList();
    if (keys.isEmpty) {
      setState(() => status = 'No selectable Android TV inputs were found'); return;
    }
    final selected = await FanatikaTvControls.choose<String>(context, title: 'Name TV input',
      values: keys, label: (id) => inputs.firstWhere((i) => i['id']?.toString() == id)['label']?.toString() ?? id);
    final choice = selected == null ? null : inputs.firstWhere((i) => i['id']?.toString() == selected);
    if (!mounted || choice == null) return;
    final settings = context.read<SettingsService>();
    final id = choice['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final text = await askText('Custom input name', value: settings.fanatikaInputNames[id] ?? '');
    if (text != null) await settings.setFanatikaMapValue('fanatika_v2_input_names', id, text);
  }

  Future<void> checkForUpdates() => guard(() async {
    final repo = context.read<SettingsService>().fanatikaReleaseRepo;
    final result = await FanatikaReleaseChecker.check(releaseRepo: repo);
    if (!mounted) return;
    setState(() => status = result.message);
    if (result.updateAvailable) {
      await FanatikaUpdateDialogs.offer(context, result);
    } else {
      await FanatikaUpdateDialogs.showStatus(context, result.message);
    }
  });

  Future<void> configureUpdateSource() => guard(() async {
    final settings = context.read<SettingsService>();
    final result = await askText('Public APK release repository (owner/repo)',
      value: settings.fanatikaReleaseRepo);
    if (result == null || !mounted) return;
    await settings.setFanatikaReleaseRepo(FanatikaReleaseChecker.normalizedRepo(result));
    if (mounted) setState(() => status = 'Release source saved. The repository must be PUBLIC and contain signed APK releases.');
  });

  Future<void> searchInstalledApps() async {
    final query = await askText('Search installed apps');
    if (!mounted || query == null || query.trim().isEmpty) return;
    final apps = context.read<AppsService>();
    final matching = apps.applications.where((a) =>
      a.name.toLowerCase().contains(query.trim().toLowerCase()) ||
      a.packageName.toLowerCase().contains(query.trim().toLowerCase())).take(60).toList();
    if (matching.isEmpty) { setState(() => status = 'No matching apps'); return; }
    final id = await FanatikaTvControls.choose<String>(context,
      title: 'Open app', values: matching.map((a) => a.packageName).toList(),
      label: (id) => matching.firstWhere((a) => a.packageName == id).name);
    if (id != null && mounted) await guard(() => apps.launchApp(
      matching.firstWhere((a) => a.packageName == id)));
  }

  Future<void> chooseAppBackground() async {
    final apps = context.read<AppsService>();
    final favorites = apps.categories.where((c) => c.name == 'Favorites')
      .expand((c) => c.applications).toList();
    if (favorites.isEmpty) { setState(() => status = 'Add Favorites in Arc settings first'); return; }
    final id = await FanatikaTvControls.choose<String>(context, title: 'Favorite app',
      values: favorites.map((a) => a.packageName).toList(),
      label: (id) => favorites.firstWhere((a) => a.packageName == id).name);
    if (id == null || !mounted) return;
    const options = <String>['', '01_Violet_Sunset.jpg','02_Starlit_Alps.jpg',
      '03_Golden_Lake.jpg','04_Amber_Peaks.jpg','05_Midnight_Blue.jpg',
      '06_Soft_Mountain_Dusk.jpg', '07_Bansko_Pirin.jpg',
      '08_Pirin_River.jpg', '09_Mountain_River.jpg',
      '10_Bansko_Winter.jpg', '11_Pirin_Alpine_Lake.jpg'];
    final selected = await FanatikaTvControls.choose<String>(context,
      title: 'Background for selected favorite', values: options,
      label: (name) => name.isEmpty ? 'None — use regular wallpaper' :
        name.replaceAll(RegExp(r'^\d+_'), '').replaceAll('_', ' ').replaceAll('.jpg', ''),
      current: context.read<SettingsService>().fanatikaAppBackgrounds[id]);
    if (selected != null && mounted) {
      await guard(() => context.read<SettingsService>()
        .setFanatikaMapValue('fanatika_v23_app_backgrounds', id, selected));
    }
  }

  Future<void> localUpdate() => guard(() async {
    final file = await FanatikaBackupService.selectReviewedUpdate();
    if (file == null || !mounted) return;
    final ok = await confirm('Install reviewed Fanatika APK?',
      'Only APKs with package ID com.fanatika.tvlauncher are accepted by the picker. Android will also verify the signing certificate. A differently signed APK will be rejected. Continue to Android installer?');
    if (ok) {
      await native.installApk(file);
      if (mounted) setState(() => status = 'Android installer opened; installation not yet verified');
    }
  });

  Widget tile(IconData icon, String title, VoidCallback handler, {String? subtitle}) =>
    FanatikaTvControls.action(icon: icon, title: title, subtitle: subtitle, onPressed: handler);
  Widget switcher(String title, bool checked, Future<void> Function(bool) apply, {IconData icon = Icons.tune}) =>
    FanatikaTvControls.toggle(icon: icon, title: title, value: checked,
      onPressed: () => guard(() => apply(!checked)));

  Future<void> chooseSetting<T>(SettingsService s, String title, String key,
      List<T> values, String Function(T) label, T current) async {
    final selected = await FanatikaTvControls.choose<T>(context, title: title,
      values: values, label: label, current: current);
    if (selected != null && mounted) await guard(() => s.setFanatikaOption(key, selected as Object));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    if (s.fanatikaSettingsPin.isNotEmpty && !unlocked) {
      return Column(children: [
        const Padding(padding: EdgeInsets.all(12), child: Text('Protected settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
        FanatikaTvControls.action(icon: Icons.lock_open, title: 'Unlock settings',
          autofocus: true, onPressed: authenticate),
        if (status.isNotEmpty) Text(status),
      ]);
    }
    return Column(children: [
      const Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Text('Fanatika customization',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
      const Divider(height: 1),
      Expanded(child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          FanatikaTvControls.section('Backup and restore'),
          FanatikaTvControls.action(icon: Icons.file_upload_outlined, title: 'Export settings & Favorites',
            autofocus: true, onPressed: exportBackup),
          tile(Icons.file_download_outlined, 'Import settings & Favorites', importBackup),
          FanatikaTvControls.section('Diagnostics and appearance preview'),
          tile(Icons.gamepad_outlined, 'Remote Button Tester',
            () => Navigator.of(context).pushNamed(FanatikaRemoteTesterPage.routeName),
            subtitle: 'Test key codes and long presses without remapping'),
          tile(Icons.visibility_outlined, 'Live theme preview', () async {
            await showDialog<bool>(context: context,
              builder: (_) => const FanatikaThemePreview());
          }, subtitle: 'Preview changes; Apply only when ready'),
          tile(Icons.health_and_safety_outlined, 'Launcher health checks', () async {
            final apps = context.read<AppsService>();
            final details = <String>[
              'Installed apps loaded: ${apps.initialized ? 'Yes' : 'Not yet'}',
              'Applications detected: ${apps.applications.length}',
              'Favorite applications: Managed by original Arc Launcher',
              'Weather configured: ${s.showFanatikaWeather ? 'Yes' : 'Disabled'}',
              'Weather city: ${s.fanatikaWeatherCity}',
              'Performance mode: ${s.fanatikaPerformance ? 'On' : 'Off'}',
              'Recovery profile: ${s.fanatikaRecoveryProfileActive ? 'Active' : 'Off'}',
              'HDMI, Wi-Fi and sleep permissions depend on TV firmware. Use those tools separately.',
            ];
            if (!mounted) return;
            await showDialog<void>(context: context, builder: (c) => AlertDialog(
              title: const Text('Read-only launcher health checks'),
              content: SingleChildScrollView(child: Text(details.join('\n'))),
              actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
            ));
          }, subtitle: 'Read-only status; no Android settings changed'),
          tile(Icons.settings_backup_restore_outlined,
            s.fanatikaRecoveryProfileActive ? 'Restore previous visual settings' : 'Activate visual recovery profile',
            () async {
              final ok = await confirm('Visual recovery profile',
                s.fanatikaRecoveryProfileActive
                  ? 'Restore the exact appearance switches saved before recovery?'
                  : 'Temporarily disable optional weather, title and animations. This does not change HOME, system packages or Favorites. Restore afterward from this button.');
              if (!ok || !mounted) return;
              await guard(() => s.fanatikaRecoveryProfileActive
                ? s.restoreFanatikaRecoveryProfile()
                : s.enableFanatikaRecoveryProfile());
            }, subtitle: 'Manual recovery for problematic appearance settings'),
          tile(Icons.search, 'Quick app search', searchInstalledApps,
            subtitle: 'Find installed apps without changing Favorites'),
          switcher('Remember last focused favorite', s.fanatikaRememberLast,
            (v) => s.setFanatikaOption('fanatika_v23_remember_last', v),
            icon: Icons.bookmark_outline),
          tile(Icons.wallpaper_outlined, 'Background per favorite app', chooseAppBackground,
            subtitle: 'Optional mountain photo when you highlight a Favorite'),
          FanatikaTvControls.section('Favorites and section layout'),
          switcher('Center short app rows (all sections)', s.fanatikaCenterSections,
            (v) => s.setFanatikaOption('fanatika_v2_center_sections', v), icon: Icons.align_horizontal_center),
          switcher('Enlarge selected app', s.fanatikaFocusGrow,
            (v) => s.setFanatikaOption('fanatika_v2_focus_grow', v), icon: Icons.zoom_out_map),
          switcher('Glow around selected app', s.fanatikaFocusGlow,
            (v) => s.setFanatikaOption('fanatika_v2_focus_glow', v), icon: Icons.flare),
          FanatikaTvControls.section('Status bar customization'),
          tile(Icons.view_stream_outlined, 'Status bar style', () => chooseSetting<String>(
            s, 'Status bar style', 'fanatika_v2_bar_style',
            ['Transparent', 'Glass', 'Solid', 'Compact'], (v) => v, s.fanatikaStatusBarStyle),
            subtitle: s.fanatikaStatusBarStyle),
          switcher('Applications shortcut in status bar', s.fanatikaStatusApps,
            (v) => s.setFanatikaOption('fanatika_v2_status_apps', v), icon: Icons.apps),
          switcher('Fanatika tools shortcut in status bar', s.fanatikaStatusTools,
            (v) => s.setFanatikaOption('fanatika_v2_status_tools', v), icon: Icons.tune),
          switcher('Sleep settings shortcut in status bar', s.fanatikaStatusSleep,
            (v) => s.setFanatikaOption('fanatika_v2_status_sleep', v), icon: Icons.bedtime),
          switcher('Weather settings shortcut in status bar', s.fanatikaStatusWeather,
            (v) => s.setFanatikaOption('fanatika_v2_status_weather', v), icon: Icons.cloud_outlined),
          FanatikaTvControls.section('Large selected-app title'),
          switcher('Lock title to fixed position', s.fanatikaFixedTitle,
            (v) => s.setFanatikaOption('fanatika_v2_fixed_title', v), icon: Icons.push_pin_outlined),
          switcher('Show large app title', s.showFanatikaHero, s.setShowFanatikaHero, icon: Icons.title),
          tile(Icons.format_size, 'Title size', () => chooseSetting<double>(s, 'Title size',
            'fanatika_v2_hero_size', [28, 36, 44, 52, 60, 72, 84, 96].map((n) => n.toDouble()).toList(),
            (v) => '${v.round()} px', s.fanatikaHeroSize),
            subtitle: '${s.fanatikaHeroSize.round()} px'),
          tile(Icons.format_align_left, 'Title position', () => chooseSetting<String>(s, 'Title position',
            'fanatika_v2_hero_position', ['left', 'center'], (v) => v == 'left' ? 'Left' : 'Center',
            s.fanatikaHeroPlacement), subtitle: s.fanatikaHeroPlacement),
          tile(Icons.opacity, 'Title opacity', () => chooseSetting<double>(s, 'Title opacity',
            'fanatika_v2_hero_opacity', [0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0],
            (v) => '${(v*100).round()}%', s.fanatikaHeroOpacity),
            subtitle: '${(s.fanatikaHeroOpacity * 100).round()}%'),
          tile(Icons.auto_awesome, 'Text style', () => chooseSetting<String>(s, 'App title text style',
            'fanatika_v2_title_style', ['Classic','Bold','Cinema','Glass','Glow','Neon','Minimal','Wide','Shadow'], (v) => v,
            s.fanatikaTitleStyle), subtitle: s.fanatikaTitleStyle),
          tile(Icons.edit_note, 'Custom app descriptions', editDescription),
          FanatikaTvControls.section('Weather'),
          switcher('Show weather', s.showFanatikaWeather, s.setShowFanatikaWeather, icon: Icons.cloud_outlined),
          tile(Icons.location_city, 'Weather city', () async {
            final value = await askText('Weather city', value: s.fanatikaWeatherCity);
            if (value != null) await s.setFanatikaWeatherCity(value);
          }, subtitle: s.fanatikaWeatherCity),
          switcher('Fahrenheit', s.fanatikaFahrenheit, s.setFanatikaFahrenheit, icon: Icons.thermostat),
          tile(Icons.calendar_month, 'Forecast days', () => chooseSetting<int>(s, 'Forecast days',
            'fanatika_v2_forecast_days', [3,5], (v) => '$v days', s.fanatikaForecastDays),
            subtitle: '${s.fanatikaForecastDays} days'),
          tile(Icons.schedule, 'Weather refresh', () => chooseSetting<int>(s, 'Weather refresh',
            'fanatika_v2_weather_refresh', [30,60,120,180], (v) => '$v minutes', s.fanatikaWeatherRefresh),
            subtitle: '${s.fanatikaWeatherRefresh} minutes'),
          FanatikaTvControls.section('Wallpaper and sources'),
          switcher('Smart mountain wallpapers', s.fanatikaSmartMountains,
            (v) => s.setFanatikaOption('fanatika_v2_smart_mountains', v), icon: Icons.landscape),
          tile(Icons.input, 'Rename TV / HDMI sources', editInputNames),
          tile(Icons.settings_input_hdmi, 'Open sources',
            () => Navigator.of(context).pushNamed(TvInputsPanelPage.routeName)),
          FanatikaTvControls.section('Layouts and performance'),
          for (final preset in ['Minimal','Cinema','Classic'])
            tile(Icons.dashboard_customize_outlined, '$preset preset',
              () => guard(() => s.setFanatikaLayout(preset)),
              subtitle: s.fanatikaLayoutPreset == preset ? 'Selected' : null),
          switcher('App focus animations', s.fanatikaFocusAnimations,
            (v) => s.setFanatikaOption('fanatika_v2_focus_animations', v), icon: Icons.animation),
          switcher('Performance mode', s.fanatikaPerformance, s.setFanatikaPerformance, icon: Icons.speed),
          FanatikaTvControls.section('Sleep and standby'),
          tile(Icons.bedtime_outlined, 'Remote sleep shortcut & timer',
            () => Navigator.of(context).pushNamed(FanatikaSleepPage.routeName),
            subtitle: 'Sleep now, timers, permissions and remote keys'),
          FanatikaTvControls.section('Security and quick settings'),
          tile(Icons.pin, s.fanatikaSettingsPin.isEmpty ? 'Set settings PIN' : 'Change or remove PIN', changePin),
          tile(Icons.system_update, 'Install reviewed Fanatika APK', localUpdate),
          tile(Icons.update, 'Automatic update checks', () async {
            final setting = context.read<SettingsService>();
            final value = await FanatikaTvControls.choose<int>(context,
              title: 'Check for updates', values: SettingsService.fanatikaUpdateCadenceChoices,
              label: (days) => days == 0 ? 'Off' : 'Every $days days',
              current: setting.fanatikaUpdateCheckDays);
            if (value != null) await guard(() => setting.setFanatikaUpdateCheckDays(value));
          }, subtitle: s.fanatikaUpdateCheckDays == 0 ? 'Off (default)' :
              'Every ${s.fanatikaUpdateCheckDays} days when launcher opens; asks before download or installation'),
          tile(Icons.public, 'Public release source', configureUpdateSource,
            subtitle: 'GitHub: ${s.fanatikaReleaseRepo} (must be public)'),
          tile(Icons.new_releases_outlined, 'Check, download and install Fanatika update', checkForUpdates,
            subtitle: 'Review, download, verify APK signature, then confirm in Android installer'),
          tile(Icons.wifi, 'Wi-Fi settings', () => guard(native.openWifiSettings)),
          tile(Icons.bluetooth, 'Bluetooth settings',
            () => guard(() => native.launchActivityFromAction('android.settings.BLUETOOTH_SETTINGS'))),
          tile(Icons.display_settings, 'Display settings',
            () => guard(() => native.launchActivityFromAction('android.settings.DISPLAY_SETTINGS'))),
          tile(Icons.settings, 'Android system settings', () => guard(native.openSettings)),
          if (working) const LinearProgressIndicator(),
          if (status.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(status)),
        ],
      ))),
    ]);
  }
}
