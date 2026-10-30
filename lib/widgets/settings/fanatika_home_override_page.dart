import 'package:flutter/material.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

/// Optional workaround for Xiaomi/Google TV builds that ignore the HOME role.
/// No root, factory launcher disable, or command-line setup is required.
class FanatikaHomeOverridePage extends StatefulWidget {
  static const routeName = 'fanatika_home_override';
  const FanatikaHomeOverridePage({super.key});
  @override State<FanatikaHomeOverridePage> createState() => _FanatikaHomeOverridePageState();
}

class _FanatikaHomeOverridePageState extends State<FanatikaHomeOverridePage>
    with WidgetsBindingObserver {
  final _channel = FLauncherChannel();
  bool _requested = true;
  bool _active = false;
  bool _busy = false;
  String _message = '';
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }
  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }
  Future<void> _refresh() async {
    try {
      final status = await _channel.fanatikaHomeOverrideStatus();
      if (!mounted) return;
      setState(() {
        _requested = status['requested'] == true;
        _active = status['active'] == true;
        _message = '${status['message'] ?? ''}';
      });
    } catch (e) {
      if (mounted) setState(() => _message = 'Cannot read HOME override status: $e');
    }
  }
  Future<void> _action(Future<Map<String, dynamic>> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await operation();
      if (mounted) setState(() => _message = '${result['message'] ?? ''}');
    } catch (e) {
      if (mounted) setState(() => _message = 'Android settings unavailable: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }
  @override Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String subtitle, VoidCallback onPressed,
        {bool first = false}) => FocusableSettingsTile(
          autofocus: first, leading: Icon(icon), title: Text(title),
          subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right),
          onPressed: onPressed);
    return Column(children: [
      Text('Fanatika as HOME', style: Theme.of(context).textTheme.titleLarge),
      const Divider(),
      Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
        const Text('Use Fanatika when you press the remote HOME button, even when Xiaomi ignores the normal HOME selection.'),
        const SizedBox(height: 12),
        Text(_active && _requested ? 'Status: Ready — press HOME to test'
            : _active ? 'Status: Accessibility ON, override paused'
            : 'Status: One-time Android approval needed',
            style: TextStyle(color: _active && _requested ? Colors.lightGreenAccent : Colors.white)),
        const SizedBox(height: 8),
        tile(Icons.accessibility_new, '1. Enable on this TV',
          'Android Accessibility → Fanatika HOME Override → On',
          () => _action(_channel.fanatikaHomeOverrideOpenAccessibility), first: true),
        tile(Icons.toggle_on_outlined, _requested ? 'Pause HOME override' : 'Resume HOME override',
          _requested ? 'Return to normal Android HOME behavior' : 'Use Fanatika for HOME again',
          () => _action(() => _channel.fanatikaHomeOverrideEnable(!_requested))),
        tile(Icons.refresh, 'Check permission', 'Read the current Android Accessibility state',
          _refresh),
        tile(Icons.security, 'Restricted settings help',
          'If blocked, open Fanatika app info and allow restricted settings if your TV offers it',
          () => _action(_channel.fanatikaHomeOverrideOpenAppInfo)),
        const SizedBox(height: 12),
        const Text('Google TV and its recovery services remain enabled. '
          'This service observes only Home activity transitions, not screen content. '
          'Some firmware may briefly display Google TV, deny the redirect, or turn Accessibility off. '
          'To restore the original behavior, pause this switch or disable the service in Android Accessibility.'),
        if (_message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message)),
      ])),
    ]);
  }
}
