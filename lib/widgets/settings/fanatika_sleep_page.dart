// Fanatika Sleep / Standby: opt-in permissions, timers, and remote shortcuts.
// Original Arc Launcher Favorites and settings are left untouched.
import 'package:flutter/material.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/widgets/fanatika_sleep_timer_dialog.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/fanatika_tv_controls.dart';

class FanatikaSleepPage extends StatefulWidget {
  static const routeName = 'fanatika_sleep_settings';
  const FanatikaSleepPage({super.key});
  @override
  State<FanatikaSleepPage> createState() => _FanatikaSleepPageState();
}

class _FanatikaSleepPageState extends State<FanatikaSleepPage> with WidgetsBindingObserver {
  final _native = FLauncherChannel();
  Map<String, dynamic> _status = {};
  String _notice = '';
  bool _working = false;
  static const _remoteKeys = <int, String>{
    0: 'None (disabled)',
    82: 'MENU — hold for 1 second',
    165: 'INFO — hold for 1 second',
    172: 'GUIDE — hold for 1 second',
    183: 'RED — hold for 1 second',
    184: 'GREEN — hold for 1 second',
    185: 'YELLOW — hold for 1 second',
    186: 'BLUE — hold for 1 second',
  };
  static const _durations = [15, 30, 45, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final result = await _native.fanatikaSleepStatus();
      if (mounted) setState(() => _status = result);
    } catch (e) {
      if (mounted) setState(() => _notice = 'Cannot read Android sleep capabilities: $e');
    }
  }

  Future<void> _perform(Future<Map<String, dynamic>> Function() task) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final result = await task();
      if (mounted) setState(() => _notice = result['message']?.toString() ?? 'No response from Android');
    } catch (e) {
      if (mounted) setState(() => _notice = 'Android could not complete the request: $e');
    } finally {
      if (mounted) setState(() => _working = false);
      await _refresh();
    }
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(title: Text(title), content: Text(message), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ]),
      ) ?? false;

  Widget _tile(IconData icon, String label, VoidCallback onPressed, {String? subtitle, bool autofocus = false}) =>
      FanatikaTvControls.action(
        icon: icon, title: label, subtitle: subtitle,
        autofocus: autofocus, onPressed: onPressed,
      );

  Future<void> _selectKey() async {
    final chosen = await FanatikaTvControls.choose<int>(context,
      title: 'Remote sleep shortcut', values: _remoteKeys.keys.toList(),
      label: (v) => _remoteKeys[v] ?? 'Unknown',
      current: (_status['shortcutKey'] as int?) ?? 0);
    if (chosen == null || !mounted) return;
    if (chosen != 0) {
      final confirmed = await _confirm('Assign a long-press key?',
        'Only keys that your Xiaomi remote forwards to applications can work. '
        'HOME, POWER, BACK, volume and arrow keys are deliberately unavailable. '
        'A short press is not intercepted, but your remote may still perform its original action before a long hold. '
        'Do you want to assign ${_remoteKeys[chosen]}?');
      if (!confirmed || !mounted) return;
    }
    await _perform(() async {
      final result = await _native.fanatikaSetSleepShortcut(chosen);
      if (result['ok'] == true && mounted) {
        await context.read<SettingsService>().setFanatikaOption('fanatika_v2_sleep_shortcut_key', chosen);
      }
      return result;
    });
  }

  Future<void> _sleepNow() async {
    final allowed = await _confirm('Try standby now?',
      'Android will be asked to lock/sleep the TV. On some Xiaomi versions it may display a lock screen '
      'instead of standby, or refuse the request. Confirm that you can unlock the TV with its remote.');
    if (!allowed || !mounted) return;
    await _perform(_native.fanatikaSleepNow);
  }

  Future<void> _schedule(int minutes) async {
    await showDialog<void>(context: context,
      builder: (_) => const FanatikaSleepTimerDialog());
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final adminSupported = _status['deviceAdminSupported'] == true;
    final adminActive = _status['deviceAdminActive'] == true;
    final global = _status['accessibilityActive'] == true;
    final key = (_status['shortcutKey'] as int?) ?? 0;
    final remain = (_status['remainingSeconds'] as int?) ?? 0;
    return Column(children: [
      const Padding(padding: EdgeInsets.all(10), child: Text('Sleep / Standby',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
      if (_working) const LinearProgressIndicator(),
      Expanded(child: ListView(children: [
        const ListTile(title: Text('Android permission'), subtitle: Text(
          'Sleep requires an optional Device Administrator force-lock permission. '
          'Only Android can grant it; no root access or ADB shell commands are used.')),
        _tile(adminActive ? Icons.check_circle : Icons.security,
          adminActive ? 'Sleep permission enabled' : 'Enable sleep permission on TV',
          () => _perform(_native.fanatikaRequestSleepAdmin),
          subtitle: !adminSupported ? 'Device-policy service unavailable; use Xiaomi system sleep settings' :
            adminActive ? 'You can revoke it in Android security settings' : 'Required for timer and shortcut',
          autofocus: true,
        ),
        _tile(Icons.tv_outlined, 'Open TV native Sleep Timer settings',
          () => _perform(() async {
            await _native.openSettings();
            return {'message': 'TV Settings > System > Power & Energy > Power > Sleep Timer. Native Xiaomi timer is not controlled by Fanatika.'};
          }), subtitle: 'Recommended for MiTV-M0EU0; uses the original TV timer'),
        _tile(Icons.settings_outlined, 'Open Xiaomi display and sleep settings',
          () => _perform(() async {
            final opened = await _native.fanatikaOpenDisplaySleepSettings();
            return {'message': opened ? 'Check TV sleep / standby settings.'
              : 'Xiaomi settings are unavailable through this action.'};
          }), subtitle: 'Firmware-controlled fallback. This does not bypass permission.'),
        if (!adminActive) const Padding(padding: EdgeInsets.all(12), child: Text(
          'This Xiaomi firmware has not granted Device Administrator permission. '
          'Sleep Now and the automatic timer cannot force standby. You can still configure '
          'your TV’s own sleep settings. Do not disable system apps to work around this.',
          style: TextStyle(color: Colors.amberAccent))),
        const Divider(),
        const ListTile(title: Text('Configurable remote button')),
        _tile(Icons.settings_remote, 'Shortcut: ${_remoteKeys[key] ?? 'Unknown'}', _selectKey,
          subtitle: 'Hold for at least one second. Default is disabled.'),
        _tile(global ? Icons.check_circle : Icons.accessibility_new,
          global ? 'Global shortcut service enabled' : 'Enable global shortcut service (optional)',
          () => _perform(_native.fanatikaOpenSleepAccessibility),
          subtitle: 'Without the service, shortcut detection works only while the launcher is open. '
            'Accessibility permission is configured manually; it does not read screen content.'),
        const ListTile(title: Text('If a selected button is never received by Android, '
          'its shortcut cannot work. The original HOME and POWER keys are protected.')),
        const Divider(),
        const ListTile(title: Text('Sleep timer')),
        for (final m in _durations)
          if (adminActive) _tile(Icons.timer_outlined, 'Sleep after $m minutes', () => _schedule(m)),
        if (remain > 0)
          ListTile(title: Text('Time remaining: approximately ${(remain / 60).ceil()} minutes')),
        _tile(Icons.timer_off_outlined, 'Cancel sleep timer',
          () => _perform(_native.fanatikaCancelSleepTimer)),
        const Divider(),
        if (adminActive) _tile(Icons.bedtime, 'Try sleep now', _sleepNow,
          subtitle: 'Requires confirmation. May lock rather than turn the TV off.'),
        _tile(Icons.refresh, 'Refresh permission and timer status', _refresh),
        const Padding(padding: EdgeInsets.all(12), child: Text(
          'This is standby/lock, not a shutdown or power-off. Android TV and Xiaomi firmware control the final result. '
          'Sleep timers are inexact and require the device to stay powered on. '
          'If the TV shows a PIN lock screen, use your normal unlock method.',
          style: TextStyle(fontSize: 12, color: Colors.white70))),
        if (_notice.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(_notice)),
      ])),
    ]);
  }
}
