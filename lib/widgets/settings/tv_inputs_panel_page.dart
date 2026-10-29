// Native-only TV input entry. Never recreate or override Xiaomi's source picker.
import 'package:flutter/material.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

class TvInputsPanelPage extends StatefulWidget {
  static const routeName = 'tv_inputs';
  const TvInputsPanelPage({super.key});
  @override State<TvInputsPanelPage> createState() => _TvInputsPanelPageState();
}

class _TvInputsPanelPageState extends State<TvInputsPanelPage> {
  String _notice = 'Requesting the TV manufacturer input menu…';
  bool _opening = false;
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _open(); });
  }
  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final result = await FLauncherChannel().openTvSourcePicker();
      if (!mounted) return;
      if (result['opened'] == true) {
        // Closing Fanatika's panel after requesting the OEM's real picker.
        Navigator.of(context, rootNavigator: true).maybePop();
      } else {
        setState(() => _notice = 'The native input menu is unavailable to this app. '
          'Use the INPUT/SOURCE button on the original TV remote. '
          'No custom or experimental HDMI switching is used.');
      }
    } catch (_) {
      if (mounted) setState(() => _notice = 'The TV blocked access to its native input menu. '
          'Use the physical INPUT/SOURCE button.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
  @override Widget build(BuildContext context) => Column(children: [
    Text('Input', style: Theme.of(context).textTheme.titleLarge),
    const Divider(),
    Padding(padding: const EdgeInsets.all(12), child: Text(_notice)),
    FocusableSettingsTile(
      autofocus: true, leading: const Icon(Icons.input),
      title: const Text('Input'), onPressed: _open),
  ]);
}
