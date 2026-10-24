// Fanatika TV Launcher v2 on-TV tools. Original Arc settings and Favorites stay intact.
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/fanatika_backup_service.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/tv_inputs_panel_page.dart';
import 'package:flauncher/widgets/settings/fanatika_sleep_page.dart';

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
    final settings = context.read<SettingsService>();
    final apps = context.read<AppsService>();
    final ok = await FanatikaBackupService.export(settings, apps);
    if (mounted) setState(() => status = ok ? 'Backup exported to selected location' : 'Backup cancelled');
  });

  Future<void> importBackup() => guard(() async {
    final data = await FanatikaBackupService.selectImport();
    if (data == null || !mounted) return;
    final count = (data['favorites'] as List).length;
    final ok = await confirm('Restore Fanatika settings?',
      'Restore preferences and $count Favorites from this backup? Current Favorites and appearance settings will change. Apps not installed on this TV are skipped. Home system settings are not changed.');
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
    final result = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Choose app for description'),
      children: apps.take(150).map((a) => SimpleDialogOption(
        onPressed: () => Navigator.pop(ctx, a.packageName), child: Text(a.name),
      )).toList(),
    ));
    if (!mounted || result == null) return;
    final settings = context.read<SettingsService>();
    final value = await askText('Description', value: settings.fanatikaDescriptions[result] ?? '');
    if (value != null) await settings.setFanatikaMapValue('fanatika_v2_descriptions', result, value);
  }

  Future<void> editInputNames() async {
    final inputs = await native.getTvInputs();
    if (!mounted) return;
    final choice = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Name an HDMI / TV input'), children: inputs.map((i) => SimpleDialogOption(
        onPressed: () => Navigator.pop(ctx, i), child: Text(i['label']?.toString() ?? i['id']?.toString() ?? 'Input'),
      )).toList(),
    ));
    if (!mounted || choice == null) return;
    final settings = context.read<SettingsService>();
    final id = choice['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final text = await askText('Custom input name', value: settings.fanatikaInputNames[id] ?? '');
    if (text != null) await settings.setFanatikaMapValue('fanatika_v2_input_names', id, text);
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
      FocusableSettingsTile(leading: Icon(icon), title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle), onPressed: handler);
  Widget switcher(String title, bool checked, Future<void> Function(bool) apply) =>
      SwitchListTile(title: Text(title), value: checked, onChanged: (v) => guard(() => apply(v)));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    if (s.fanatikaSettingsPin.isNotEmpty && !unlocked) {
      return Column(children: [const Text('Fanatika protected settings'),
        tile(Icons.lock_open, 'Unlock settings', authenticate), Text(status)]);
    }
    return Column(children: [
      const Text('Fanatika customization', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
      const Divider(),
      Expanded(child: ListView(children: [
        const ListTile(title: Text('Backup and Restore')),
        tile(Icons.file_upload_outlined, 'Export settings & Favorites', exportBackup),
        tile(Icons.file_download_outlined, 'Import settings & Favorites', importBackup),
        const Divider(),
        const ListTile(title: Text('Visual home-screen editor')),
        switcher('Large selected-app title', s.showFanatikaHero, s.setShowFanatikaHero),
        ListTile(title: Text('Title size: ${s.fanatikaHeroSize.round()}'), subtitle: Slider(
          value: s.fanatikaHeroSize, min: 28, max: 96, divisions: 17,
          onChanged: (v) => s.setFanatikaOption('fanatika_v2_hero_size', v),
        )),
        tile(Icons.format_align_left, 'Title position', () async {
          final newValue = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
            title: const Text('Title placement'),
            children: ['left','center'].map((p) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, p), child: Text(p))).toList(),
          ));
          if (newValue != null) await s.setFanatikaOption('fanatika_v2_hero_position', newValue);
        }, subtitle: s.fanatikaHeroPlacement),
        ListTile(title: Text('Title opacity: ${(s.fanatikaHeroOpacity * 100).round()}%'),
          subtitle: Slider(value: s.fanatikaHeroOpacity, min: 0.3, max: 1.0, divisions: 14,
            onChanged: (v) => s.setFanatikaOption('fanatika_v2_hero_opacity', v))),
        tile(Icons.edit_note, 'Custom app descriptions', editDescription),
        const Divider(),
        const ListTile(title: Text('Advanced weather')),
        switcher('Show weather', s.showFanatikaWeather, s.setShowFanatikaWeather),
        tile(Icons.location_city, 'Weather city', () async {
          final value = await askText('Weather city', value: s.fanatikaWeatherCity);
          if (value != null) await s.setFanatikaWeatherCity(value);
        }, subtitle: s.fanatikaWeatherCity),
        switcher('Fahrenheit', s.fanatikaFahrenheit, s.setFanatikaFahrenheit),
        tile(Icons.calendar_month, 'Forecast days: ${s.fanatikaForecastDays}', () async {
          await s.setFanatikaOption('fanatika_v2_forecast_days', s.fanatikaForecastDays == 5 ? 3 : 5);
        }, subtitle: 'Switch between 3 and 5 days'),
        tile(Icons.schedule, 'Weather refresh: ${s.fanatikaWeatherRefresh} minutes', () async {
          final next = s.fanatikaWeatherRefresh == 30 ? 60 : s.fanatikaWeatherRefresh == 60 ? 120 : 30;
          await s.setFanatikaOption('fanatika_v2_weather_refresh', next);
        }),
        const Divider(),
        const ListTile(title: Text('Wallpaper & inputs')),
        switcher('Smart bundled mountain wallpaper (day/night)', s.fanatikaSmartMountains,
          (v) => s.setFanatikaOption('fanatika_v2_smart_mountains', v)),
        tile(Icons.input, 'Rename TV / HDMI sources', editInputNames),
        tile(Icons.settings_input_hdmi, 'Open sources', () => Navigator.of(context).pushNamed(TvInputsPanelPage.routeName)),
        const Divider(),
        const ListTile(title: Text('Layouts and performance')),
        for (final preset in ['Minimal','Cinema','Classic'])
          tile(Icons.dashboard_customize_outlined, '$preset preset', () => guard(() => s.setFanatikaLayout(preset)),
            subtitle: s.fanatikaLayoutPreset == preset ? 'Selected' : null),
        switcher('App focus animations', s.fanatikaFocusAnimations,
          (v) => s.setFanatikaOption('fanatika_v2_focus_animations', v)),
        switcher('Performance mode', s.fanatikaPerformance, s.setFanatikaPerformance),
        const Divider(),
        const ListTile(title: Text('Sleep / Standby')),
        tile(Icons.bedtime_outlined, 'Remote sleep shortcut & timer',
          () => Navigator.of(context).pushNamed(FanatikaSleepPage.routeName),
          subtitle: 'Choose remote long-press key, or 15 / 30 / 60 / 90 / 120-minute timer'),
        const Divider(),
        const ListTile(title: Text('Security, updates and quick settings')),
        tile(Icons.pin, s.fanatikaSettingsPin.isEmpty ? 'Set settings PIN' : 'Change or remove settings PIN', changePin),
        tile(Icons.system_update, 'Install manually selected Fanatika update', localUpdate,
          subtitle: 'Requires APK signed with the same certificate; no upstream Arc auto-updates'),
        tile(Icons.wifi, 'Wi-Fi settings', () => guard(native.openWifiSettings)),
        tile(Icons.bluetooth, 'Bluetooth settings', () => guard(() => native.launchActivityFromAction('android.settings.BLUETOOTH_SETTINGS'))),
        tile(Icons.display_settings, 'Display settings', () => guard(() => native.launchActivityFromAction('android.settings.DISPLAY_SETTINGS'))),
        tile(Icons.settings, 'Android system settings', () => guard(native.openSettings)),
        if (working) const LinearProgressIndicator(),
        if (status.isNotEmpty) Padding(padding: const EdgeInsets.all(10), child: Text(status)),
      ])),
    ]);
  }
}
