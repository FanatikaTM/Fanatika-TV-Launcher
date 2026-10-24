import 'package:flauncher/providers/settings_service.dart';
import 'package:provider/provider.dart';
// Fanatika TV Launcher - manufacturer-aware, non-root source selection.
// Original Arc Favorites/categories are unchanged.
import 'package:flutter/material.dart';
import 'package:flauncher/flauncher_channel.dart';

class TvInputsPanelPage extends StatefulWidget {
  static const routeName = 'tv_inputs';
  const TvInputsPanelPage({super.key});
  @override
  State<TvInputsPanelPage> createState() => _TvInputsPanelPageState();
}

class _TvInputsPanelPageState extends State<TvInputsPanelPage> {
  final FLauncherChannel _native = FLauncherChannel();
  List<Map<String, dynamic>> _inputs = const [];
  bool _loading = true;
  String _status = 'Discovering sources…';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final all = await _native.getTvInputs();
      if (!mounted) return;
      setState(() {
        _inputs = all;
        _status = all.isEmpty ? 'No TV inputs were exposed by Android.' :
            'Select a source below. Switching may depend on the TV manufacturer.';
      });
    } catch (error) {
      if (mounted) setState(() => _status = 'Input discovery is unavailable: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final title = item['label']?.toString() ?? 'TV input';
    if (id.isEmpty) return;
    final response = await _native.openTvInput(id);
    if (!mounted) return;
    final opened = response['opened'] == true;
    setState(() => _status = '$title: ${response['detail'] ?? 'Unknown response'}');
    // Only offer the experimental vendor fallback after a standard request failed.
    if (opened || item['type'] != 1007 || !mounted) return; // TV_INPUT_TYPE_HDMI = 1007
    final tryVendor = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Experimental Xiaomi HDMI switching'),
        content: const Text(
          'Your TV did not accept the standard Android input request. '
          'Some Xiaomi televisions use a vendor-specific HDMI command; '
          'this has NOT been verified for your MiTV-MOSR4 firmware. '
          'It may select the wrong input or do nothing. '
          'No system packages or HOME settings will be changed. Try it?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Try HDMI')),
        ],
      ),
    );
    if (tryVendor != true || !mounted) return;
    final vendor = await _native.tryXiaomiHdmi(id);
    if (mounted) setState(() => _status = '$title: ${vendor['detail'] ?? 'Unknown result'}');
  }

  Future<void> _openMenu() async {
    final response = await _native.openTvSourcePicker();
    if (mounted) setState(() => _status = response['detail']?.toString() ?? 'Input menu unavailable');
  }

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).textTheme;
    return Column(children: [
      Text('TV Sources / Inputs', style: styles.titleLarge),
      const Divider(),
      Expanded(child: ListView(children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('HDMI and TV input options reported by Android. Some TVs only allow switching via their original INPUT button.'),
        ),
        ListTile(
          leading: const Icon(Icons.settings_input_hdmi),
          title: const Text('Open TV input menu'),
          onTap: _openMenu,
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Refresh available inputs'),
          onTap: _refresh,
        ),
        if (_loading) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
        for (final item in _inputs)
          ListTile(
            leading: Icon(item['passthrough'] == true ? Icons.settings_input_hdmi : Icons.live_tv),
            title: Text(context.watch<SettingsService>().fanatikaInputNames[item['id']?.toString()] ?? item['label']?.toString() ?? 'TV input'),
            subtitle: Text(item['state'] == 1 ? 'Connected' : 'Input available; state ${item['state']}'),
            onTap: () => _select(item),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_status, style: styles.bodySmall),
        ),
      ])),
    ]);
  }
}
