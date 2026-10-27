// Fanatika Quick Settings — Google TV-inspired, independently implemented UI.
// Uses only public Android settings intents / user-approved Fanatika actions.
// Tested target: Xiaomi MiTV-M0EU0. The OEM's exact Quick Settings activity
// and native Sleep Timer aren't public third-party APIs.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/fanatika_sleep_page.dart';
import 'package:flauncher/widgets/settings/fanatika_tools_hub.dart';
import 'package:flauncher/widgets/settings/fanatika_updates_page.dart';
import 'package:flauncher/widgets/settings/fanatika_usb_page.dart';
import 'package:flauncher/widgets/settings/tv_inputs_panel_page.dart';

// Displayed by a separate icon in Fanatika's status bar, without replacing
// the existing Settings and HOME controls.
class FanatikaQuickSettingsDialog extends StatefulWidget {
  const FanatikaQuickSettingsDialog({super.key});
  @override
  State<FanatikaQuickSettingsDialog> createState() => _FanatikaQuickSettingsDialogState();
}

class _FanatikaQuickSettingsDialogState extends State<FanatikaQuickSettingsDialog> {
  static const Color base = Color(0xFF253D5C);
  static const Color tileBlue = Color(0xFF476685);
  final FLauncherChannel _channel = FLauncherChannel();
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  int _page = 0;
  bool _sleepOptions = false;
  bool _busy = false;
  String _notice = '';
  int _remainingSeconds = 0;
  bool _deviceAdminEnabled = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _perform(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() { _busy = true; _notice = ''; });
    try {
      await operation();
    } catch (e) {
      if (mounted) setState(() => _notice = 'TV could not open this control: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSystemAction(String action) => _perform(() async {
    await _channel.launchActivityFromAction(action);
  });

  Future<void> _openPanel(String route) async {
    // A nested settings dialog avoids using a disposed BuildContext.
    await showDialog<void>(
      context: context,
      builder: (_) => SettingsPanel(initialRoute: route),
    );
  }

  Future<void> _openInput() async {
    await _perform(() async {
      final result = await _channel.openTvSourcePicker();
      if (!mounted) return;
      if (result['opened'] != true) {
        setState(() => _notice = result['detail']?.toString() ??
            'The Xiaomi input picker was unavailable; choose a source from Fanatika.');
        await _openPanel(TvInputsPanelPage.routeName);
      }
    });
  }

  Future<void> _openNativeSleepSettings() => _perform(() async {
    // The native Xiaomi timer is controlled by the firmware, not by Fanatika.
    // A public third-party intent to select its exact timer is not available.
    // Opening Settings is a reliable, non-privileged starting point.
    if (mounted) setState(() => _notice =
      'In TV Settings: System > Power & Energy > Power > Sleep Timer.');
    await _channel.openSettings();
  });

  Future<void> _showSleep() async {
    setState(() { _sleepOptions = true; _notice = ''; });
    try {
      final status = await _channel.fanatikaSleepStatus();
      if (mounted) setState(() {
        _deviceAdminEnabled = status['deviceAdminActive'] == true;
        _remainingSeconds = (status['remainingSeconds'] as num?)?.toInt() ?? 0;
      });
    } catch (e) {
      if (mounted) setState(() => _notice = 'Sleep capability unavailable: $e');
    }
  }

  Future<void> _scheduleSleep(int minutes) async {
    if (!_deviceAdminEnabled) {
      await _openNativeSleepSettings();
      return;
    }
    final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Set sleep timer?'),
      content: Text('Request TV sleep in $minutes minutes? The TV may lock rather '
          'than enter standby depending on MiTV-M0EU0 firmware.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Set timer')),
      ],
    )) ?? false;
    if (!accepted || !mounted) return;
    await _perform(() async {
      final response = await _channel.fanatikaSleepTimer(minutes);
      if (!mounted) return;
      setState(() => _notice = response['message']?.toString() ??
          (response['ok'] == true ? 'Timer scheduled' : 'TV rejected timer'));
      if (response['ok'] == true) await _showSleep();
    });
  }

  Future<void> _cancelSleep() async {
    await _perform(() async {
      final response = await _channel.fanatikaCancelSleepTimer();
      if (mounted) setState(() {
        _remainingSeconds = 0;
        _notice = response['message']?.toString() ?? 'Timer cancelled';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final panelWidth = (size.width * 0.42).clamp(420.0, 520.0).toDouble();
    final panelHeight = (size.height * 0.91).clamp(470.0, 685.0).toDouble();
    return Dialog(
      alignment: Alignment.centerRight,
      insetPadding: const EdgeInsets.only(left: 10, top: 12, right: 24, bottom: 12),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: panelWidth,
        height: panelHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x449EC9F4), width: 1),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xF9577191), base, Color(0xF7213450)]),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 8))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 14),
          child: Column(children: [
            _header(),
            const SizedBox(height: 12),
            Expanded(child: _sleepOptions ? _sleepBody() : _page == 0 ? _mainTiles() : _secondaryTiles()),
            if (_busy) const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(minHeight: 3)),
            if (_notice.isNotEmpty) Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(_notice, style: const TextStyle(fontSize: 12, color: Color(0xFFFFE1AD)),
                maxLines: 3, overflow: TextOverflow.ellipsis)),
            _bottomNavigation(),
          ]),
        ),
      ),
    );
  }

  Widget _header() => Row(children: [
    if (_sleepOptions) IconButton(
      tooltip: 'Back to Quick Settings',
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => setState(() => _sleepOptions = false)),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(DateFormat('EEE, MMM d').format(_now),
        style: const TextStyle(color: Color(0xFFDFEBFC), fontSize: 14)),
      Text(DateFormat('HH:mm').format(_now),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 25)),
    ])),
    Column(children: [
      IconButton(tooltip: 'All settings', icon: const Icon(Icons.settings_outlined, color: Colors.white),
        onPressed: () => _openPanel('settings_panel')),
      const Text('All settings', style: TextStyle(fontSize: 10, color: Colors.white70)),
    ]),
    IconButton(tooltip: 'Close Quick Settings',
      icon: const Icon(Icons.close_rounded, color: Colors.white70),
      onPressed: () => Navigator.pop(context)),
  ]);

  Widget _mainTiles() => GridView.count(
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2, childAspectRatio: 2.5,
    mainAxisSpacing: 9, crossAxisSpacing: 9,
    children: [
      _QuickTile(icon: Icons.wallpaper, text: 'Screensaver', autofocus: true,
        onPressed: () => _perform(_channel.startAmbientMode)),
      _QuickTile(icon: Icons.input, text: 'Input source', onPressed: _openInput),
      _QuickTile(icon: Icons.tune, text: 'Picture',
        onPressed: () => _openSystemAction('android.settings.DISPLAY_SETTINGS')),
      _QuickTile(icon: Icons.volume_up_outlined, text: 'Sound',
        onPressed: () => _openSystemAction('android.settings.SOUND_SETTINGS')),
      _QuickTile(icon: Icons.wifi, text: 'Wi-Fi', onPressed: () => _perform(_channel.openWifiSettings)),
      _QuickTile(icon: Icons.home_outlined, text: 'Home settings',
        onPressed: () => _openSystemAction('android.settings.HOME_SETTINGS')),
      _QuickTile(icon: Icons.bluetooth, text: 'Bluetooth',
        onPressed: () => _openSystemAction('android.settings.BLUETOOTH_SETTINGS')),
      _QuickTile(icon: Icons.bedtime_outlined, text: 'Sleep timer', onPressed: _showSleep),
    ],
  );

  Widget _secondaryTiles() => GridView.count(
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2, childAspectRatio: 2.5,
    mainAxisSpacing: 9, crossAxisSpacing: 9,
    children: [
      _QuickTile(icon: Icons.tune, text: 'Tools', autofocus: true,
        onPressed: () => _openPanel(FanatikaToolsHub.routeName)),
      _QuickTile(icon: Icons.system_update, text: 'Updates',
        onPressed: () => _openPanel(FanatikaUpdatesPage.routeName)),
      _QuickTile(icon: Icons.usb, text: 'USB storage',
        onPressed: () => _openPanel(FanatikaUsbPage.routeName)),
      _QuickTile(icon: Icons.bedtime, text: 'Sleep & standby',
        onPressed: () => _openPanel(FanatikaSleepPage.routeName)),
      _QuickTile(icon: Icons.settings_input_hdmi, text: 'TV inputs',
        onPressed: () => _openPanel(TvInputsPanelPage.routeName)),
      _QuickTile(icon: Icons.settings_outlined, text: 'System settings',
        onPressed: () => _perform(_channel.openSettings)),
    ],
  );

  Widget _sleepBody() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Sleep timer', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    FilledButton.icon(onPressed: _openNativeSleepSettings,
      icon: const Icon(Icons.tv), label: const Text('TV native Sleep Timer settings')),
    const SizedBox(height: 8),
    if (!_deviceAdminEnabled) const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text('The Xiaomi timer is controlled by TV firmware. In TV Settings open '
          'System > Power & Energy > Power > Sleep Timer. The durations below '
          'are Fanatika timers, available only with Device Administrator sleep permission.',
        style: TextStyle(fontSize: 12, color: Color(0xFFFFE1AD)))),
    Expanded(child: GridView.count(crossAxisCount: 1, childAspectRatio: 8.5,
      mainAxisSpacing: 6,
      children: [
        for (final entry in const <(int, String)>[
          (15, '15 minutes'), (30, '30 minutes'), (45, '45 minutes'),
          (60, '1 hour'), (90, '1 hour 30 minutes'),
          (120, '2 hours'), (180, '3 hours')])
          _QuickTile(icon: Icons.timer_outlined, text: entry.$2, compact: true,
            onPressed: () => _scheduleSleep(entry.$1)),
      ],
    )),
    if (_remainingSeconds > 0) Text(
      'Remaining: ~${(_remainingSeconds / 60).ceil()} minutes',
      style: const TextStyle(fontSize: 12, color: Colors.white70)),
    Row(children: [
      TextButton(onPressed: _cancelSleep, child: const Text('Cancel timer')),
      Expanded(child: TextButton(onPressed: () => _openPanel(FanatikaSleepPage.routeName),
        child: const Text('Sleep permissions'))),
    ]),
  ]);

  Widget _bottomNavigation() => Row(children: [
    const Text('Quick Settings', style: TextStyle(fontSize: 11, color: Colors.white60)),
    const Spacer(),
    if (!_sleepOptions) ...[
      IconButton(onPressed: () => setState(() => _page = 0),
        icon: Icon(_page == 0 ? Icons.circle : Icons.circle_outlined, size: 13,
          color: _page == 0 ? Colors.white : Colors.white54)),
      IconButton(onPressed: () => setState(() => _page = 1),
        icon: Icon(_page == 1 ? Icons.circle : Icons.circle_outlined, size: 13,
          color: _page == 1 ? Colors.white : Colors.white54)),
      IconButton(onPressed: () => setState(() => _page = 1 - _page),
        icon: const Icon(Icons.chevron_right, size: 23)),
    ],
  ]);
}

class _QuickTile extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;
  final bool autofocus;
  final bool compact;
  const _QuickTile({required this.icon, required this.text, required this.onPressed,
    this.autofocus = false, this.compact = false});
  @override State<_QuickTile> createState() => _QuickTileState();
}
class _QuickTileState extends State<_QuickTile> {
  bool focused = false;
  @override Widget build(BuildContext context) => Material(
    color: focused ? const Color(0xFFEDF2F8) : _FanatikaQuickSettingsDialogState.tileBlue,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      borderRadius: BorderRadius.circular(19),
      autofocus: widget.autofocus,
      onFocusChange: (active) => setState(() => focused = active),
      onTap: widget.onPressed,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        child: Row(children: [
          Icon(widget.icon, color: focused ? const Color(0xFF253D5C) : Colors.white,
            size: widget.compact ? 18 : 22),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.text,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700,
              color: focused ? const Color(0xFF253D5C) : Colors.white,
              fontSize: widget.compact ? 13 : 15))),
        ]),
      ),
    ),
  );
}
