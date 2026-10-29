// Quick Settings — Google TV-inspired, independently implemented UI.
// Uses only public Android settings intents / user-approved Fanatika actions.
// Tested target: Xiaomi MiTV-M0EU0. The OEM's exact Quick Settings activity
// and native Sleep Timer aren't public third-party APIs.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/widgets/fanatika_sleep_timer_dialog.dart';

// Displayed by a separate icon in Fanatika's status bar, without replacing
// the existing Settings and HOME controls.
class FanatikaQuickSettingsDialog extends StatefulWidget {
  const FanatikaQuickSettingsDialog({super.key});
  @override
  State<FanatikaQuickSettingsDialog> createState() => _FanatikaQuickSettingsDialogState();
}

class _FanatikaQuickSettingsDialogState extends State<FanatikaQuickSettingsDialog> {
  static const Color base = Color(0xFF1E1E1E);
  static const Color tileBlue = Color(0xFF303030);
  final FLauncherChannel _channel = FLauncherChannel();
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _busy = false;
  String _notice = '';

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

  Future<void> _openInput() async {
    await _perform(() async {
      final result = await _channel.openTvSourcePicker();
      if (!mounted) return;
      if (result['opened'] != true) {
        setState(() => _notice = result['detail']?.toString() ??
            'Input unavailable. Use the TV remote Input button.');
        // Never replace the manufacturer's picker with a custom inputs menu.
      }
    });
  }

  Future<void> _openNativeSleepSettings() => _perform(() async {
    // The native Xiaomi timer is controlled by the firmware, not by the launcher.
    // A public third-party intent to select its exact timer is not available.
    // Opening Settings is a reliable, non-privileged starting point.
    if (mounted) setState(() => _notice =
      'In TV Settings: System > Power & Energy > Power > Sleep Timer.');
    await _channel.openSettings();
  });

  Future<void> _showSleep() async {
    // Close the quick panel first, then show only the clean sleep timer.
    final navigator = Navigator.of(context);
    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted) {
        showDialog<void>(context: navigator.context,
          builder: (_) => const FanatikaSleepTimerDialog());
      }
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
          border: Border.all(color: Colors.white24, width: 1),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF242424), base, Color(0xFF191919)]),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 8))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 14),
          child: Column(children: [
            _header(),
            const SizedBox(height: 12),
            Expanded(child: _mainTiles()),
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
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(DateFormat('EEE, MMM d').format(_now),
        style: const TextStyle(color: Color(0xFFDFEBFC), fontSize: 14)),
      Text(DateFormat('HH:mm').format(_now),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 25)),
    ])),
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
      _QuickTile(icon: Icons.input, text: 'Input', onPressed: _openInput),
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

  Widget _bottomNavigation() => const Align(
    alignment: Alignment.centerLeft,
    child: Text('Quick controls', style: TextStyle(fontSize: 11, color: Colors.white60)),
  );
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
    color: focused ? Theme.of(context).colorScheme.surfaceContainerHigh : _FanatikaQuickSettingsDialogState.tileBlue,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      borderRadius: BorderRadius.circular(19),
      autofocus: widget.autofocus,
      onFocusChange: (active) => setState(() => focused = active),
      onTap: widget.onPressed,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        child: Row(children: [
          Icon(widget.icon, color: Colors.white,
            size: widget.compact ? 18 : 22),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.text,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: widget.compact ? 13 : 15))),
        ]),
      ),
    ),
  );
}
