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
import 'package:flauncher/widgets/settings/fanatika_tv_controls.dart';
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
          FanatikaTvControls.section('Large selected-app title'),
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
            'fanatika_v2_title_style', ['Classic','Bold','Cinema','Glass'], (v) => v,
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
