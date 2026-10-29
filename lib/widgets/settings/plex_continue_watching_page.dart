// Fanatika Plex setup. Remote-friendly and opt-in. No Plex token in exports.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/plex_continue_watching_client.dart';

class PlexContinueWatchingPage extends StatefulWidget {
  static const routeName = 'fanatika_plex_continue_watching';
  const PlexContinueWatchingPage({super.key});

  @override
  State<PlexContinueWatchingPage> createState() => _PlexContinueWatchingPageState();
}

class _PlexContinueWatchingPageState extends State<PlexContinueWatchingPage> {
  late final TextEditingController _server;
  late final TextEditingController _token;
  bool _enabled = false;
  bool _allowHttp = false;
  bool _busy = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _server = TextEditingController(text: settings.plexServerUrl);
    _token = TextEditingController(text: settings.plexAccessToken);
    _enabled = settings.plexContinueWatchingEnabled;
    _allowHttp = settings.plexAllowHttp;
  }

  @override
  void dispose() {
    _server.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    setState(() { _busy = true; _status = 'Connecting to Plex…'; });
    PlexContinueWatchingClient? client;
    try {
      client = PlexContinueWatchingClient(_server.text, _token.text,
        allowHttp: _allowHttp);
      final titles = await client.load(limit: 10);
      if (mounted) setState(() => _status = 'Connected to Plex. ${titles.length} Continue Watching items found.');
    } catch (e) {
      if (mounted) setState(() => _status = e is PlexContinueWatchingException
        ? e.message : 'Unable to reach Plex. Check the TV network and server URL.');
    } finally {
      client?.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() { _busy = true; _status = ''; });
    try {
      await context.read<SettingsService>().setPlexContinueWatchingConfig(
        url: _server.text, token: _token.text, enabled: _enabled,
        allowHttp: _allowHttp);
      if (!mounted) return;
      if (_enabled) await context.read<SettingsService>().setShowWatchNextSection(true);
      if (mounted) setState(() => _status = 'Saved. Plex will appear above other Android TV Watch Next items after refresh.');
      if (mounted) await context.read<WatchNextService>().refreshPermissionAndItems();
    } catch (e) {
      if (mounted) setState(() => _status = e is FormatException
        ? e.message : 'Could not save Plex settings.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    await context.read<SettingsService>().clearPlexContinueWatchingConfig();
    if (!mounted) return;
    _server.clear(); _token.clear();
    setState(() { _enabled = false; _allowHttp = false; _status = 'Plex credentials cleared from Fanatika.'; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(title: const Text('Plex Continue Watching')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Show movies and episodes directly from Plex Media Server, even if Plex does not publish Android TV Watch Next rows.',
        style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 14),
      SwitchListTile(
        title: const Text('Enable Plex Watch Next'),
        value: _enabled, onChanged: _busy ? null : (value) => setState(() => _enabled = value),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _server, autocorrect: false,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(labelText: 'Plex server address',
          hintText: 'https://your-server.plex.direct:32400', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _token, autocorrect: false, obscureText: true,
        enableSuggestions: false,
        decoration: const InputDecoration(labelText: 'Plex access token',
          border: OutlineInputBorder()),
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        title: const Text('Allow HTTP on my trusted LAN'),
        subtitle: const Text('Not encrypted; permitted only for private LAN IPs or .local. Prefer HTTPS with a valid certificate.'),
        value: _allowHttp, onChanged: _busy ? null : (value) => setState(() => _allowHttp = value),
      ),
      const SizedBox(height: 8),
      ListTile(
        title: const Text('Plex refresh interval'),
        subtitle: Text('Every ${context.watch<SettingsService>().plexRefreshMinutes} minutes'),
        trailing: const Icon(Icons.timer_outlined),
        onTap: _busy ? null : () async {
          final settings = context.read<SettingsService>();
          final selected = await showDialog<int>(context: context, builder: (ctx) => SimpleDialog(
            title: const Text('Refresh Plex Continue Watching'),
            children: [for (final minutes in [5,15,30,60])
              SimpleDialogOption(onPressed: () => Navigator.pop(ctx, minutes),
                child: Text('Every $minutes minutes'))],
          ));
          if (selected != null) await settings.setPlexRefreshMinutes(selected);
        },
      ),
      const SizedBox(height: 6),
      const Text('Your token stays in the TV launcher app preferences and is excluded from Fanatika exported backups. Do not share your token.',
        style: TextStyle(color: Colors.white60, fontSize: 12)),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        FilledButton.icon(onPressed: _busy ? null : _save,
          icon: const Icon(Icons.save), label: const Text('Save')),
        OutlinedButton.icon(onPressed: _busy ? null : _test,
          icon: const Icon(Icons.wifi_find), label: const Text('Test Plex')),
        TextButton.icon(onPressed: _busy ? null : _clear,
          icon: const Icon(Icons.delete_outline), label: const Text('Clear')),
      ]),
      if (_busy) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
      if (_status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12),
        child: Text(_status, style: const TextStyle(color: Colors.white70))),
      const SizedBox(height: 6),
      const Text('If Plex is temporarily offline, the last successfully loaded titles stay visible for up to six hours while the launcher is running. No Plex token is exported.',
        style: TextStyle(color: Colors.white60, fontSize: 12)),
      const SizedBox(height: 16),
      const Text('Selecting a Plex title opens its details in the Plex app on supported versions. Automatic resume is controlled by Plex and may not work with recent Plex updates.',
        style: TextStyle(color: Colors.white60, fontSize: 12)),
    ]),
  );
}
