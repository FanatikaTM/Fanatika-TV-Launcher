// Fanatika Plex setup. Remote-friendly and opt-in. No Plex token in exports.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/plex_continue_watching_client.dart';
import 'package:flauncher/providers/fanatika_plex_setup.dart';

class PlexContinueWatchingPage extends StatefulWidget {
  static const routeName = 'fanatika_plex_continue_watching';
  const PlexContinueWatchingPage({super.key});

  @override
  State<PlexContinueWatchingPage> createState() => _PlexContinueWatchingPageState();
}

class _PlexContinueWatchingPageState extends State<PlexContinueWatchingPage> {
  late final TextEditingController _server;
  late final TextEditingController _token;
  final FocusNode _serverFocus = FocusNode(debugLabel: 'Plex server address');
  final FocusNode _tokenFocus = FocusNode(debugLabel: 'Plex token');
  final FocusNode _saveFocus = FocusNode(debugLabel: 'Save Plex settings');
  bool _enabled = false;
  bool _allowHttp = false;
  bool _busy = false;
  String _status = '';
  FanatikaPlexPin? _pin;
  List<FanatikaPlexServer> _discovered = [];

  Future<void> _runSetup(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _status = ''; });
    try { await action(); }
    catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Bad state: ', ''));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  // Option 1: Use the Android TV feed already exported by installed apps.
  Future<void> _checkAndroidFeed() async => _runSetup(() async {
    final feed = context.read<WatchNextService>();
    await feed.refreshPermissionAndItems();
    if (!mounted) return;
    final count = feed.items.where((item) => item.packageName == 'com.plexapp.android' && item.source != 'plex').length;
    setState(() => _status = feed.hasPermission
      ? 'Android TV is publishing $count Plex Watch Next entries. '
        '${count == 0 ? 'Plex may not publish recommendations on this TV. Try Plex pairing.' : 'These entries are shown without a Plex token.'}'
      : 'Android Watch Next permission is unavailable. Grant permission in TV settings or use Plex sign-in.');
  });

  // Option 2: Probe LAN with Plex GDM. No credentials leave the device.
  Future<void> _discover() async => _runSetup(() async {
    final servers = await FanatikaPlexSetup.discoverLocal();
    if (!mounted) return;
    setState(() { _discovered = servers; _status = servers.isEmpty
      ? 'No Plex servers detected by LAN broadcast. You can still sign in to Plex or enter a server address.'
      : '${servers.length} Plex server(s) found. Select one below, then pair your account.'; });
  });

  // Option 3: PIN sign-in, never reading another app's private storage.
  Future<void> _pair() async => _runSetup(() async {
    final pin = await FanatikaPlexSetup.startPairing();
    if (mounted) setState(() { _pin = pin; _status = 'Go to plex.tv/link on your phone and enter the displayed code.'; });
  });

  Future<void> _checkPin() async => _runSetup(() async {
    final pin = _pin;
    if (pin == null) return;
    final accountToken = await FanatikaPlexSetup.checkPairing(pin);
    if (!mounted) return;
    if (accountToken == null) {
      setState(() => _status = 'Not approved yet. Approve the code at plex.tv/link, then check again.');
      return;
    }
    final servers = await FanatikaPlexSetup.accountServers(accountToken);
    if (!mounted) return;
    // Keep the account token only for this pairing step; never save it to disk.
    if (servers.isEmpty) { setState(() => _status = 'Signed in, but the account returned no accessible Plex Media Servers.'); return; }
    final chosen = await showDialog<FanatikaPlexServer>(context: context,
      builder: (ctx) => SimpleDialog(title: const Text('Choose your Plex server'), children: [
        for (final server in servers) SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, server),
          child: Text('${server.name}  •  ${Uri.parse(server.url).host}')),
      ]));
    if (!mounted || chosen == null) return;
    _server.text = chosen.url;
    _token.text = chosen.token;
    setState(() { _allowHttp = chosen.allowHttp; _enabled = true; _pin = null;
      _status = 'Server selected. Press Test Plex, then Save to enable the row.'; });
  });


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
    _serverFocus.dispose();
    _tokenFocus.dispose();
    _saveFocus.dispose();
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
    // Permanent actions stay reachable while the TV keyboard hides the form.
    bottomNavigationBar: SafeArea(top: false,
      child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: FilledButton.icon(
          focusNode: _saveFocus,
          onPressed: _busy ? null : _save,
          icon: const Icon(Icons.save), label: const Text('Save'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(
          onPressed: _busy ? null : _test, child: const Text('Test Plex'))),
        const SizedBox(width: 8),
        TextButton(onPressed: _busy ? null : _clear, child: const Text('Clear')),
      ]))),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Show movies and episodes directly from Plex Media Server, even if Plex does not publish Android TV Watch Next rows.',
        style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 14),
      SwitchListTile(
        title: const Text('Enable Plex Watch Next'),
        value: _enabled, onChanged: _busy ? null : (value) => setState(() => _enabled = value),
      ),
      const SizedBox(height: 14),
      const Text('OPTION 1 — Android TV Watch Next (installed Plex app)',
        style: TextStyle(fontWeight: FontWeight.bold)),
      OutlinedButton.icon(onPressed: _busy ? null : _checkAndroidFeed,
        icon: const Icon(Icons.tv), label: const Text('Check Plex entries from Android TV')),
      const SizedBox(height: 12),
      const Text('OPTION 2 — Find Plex servers on your local network',
        style: TextStyle(fontWeight: FontWeight.bold)),
      OutlinedButton.icon(onPressed: _busy ? null : _discover,
        icon: const Icon(Icons.wifi_find), label: const Text('Discover Plex servers')),
      for (final server in _discovered) ListTile(
        title: Text(server.name), subtitle: Text(server.url),
        trailing: const Icon(Icons.chevron_right),
        onTap: _busy ? null : () => setState(() { _server.text = server.url;
          _allowHttp = server.allowHttp;
          _status = 'Found server selected. Sign in to Plex to authorize access.'; }),
      ),
      const SizedBox(height: 12),
      const Text('OPTION 3 — Sign in to Plex (recommended)',
        style: TextStyle(fontWeight: FontWeight.bold)),
      OutlinedButton.icon(onPressed: _busy ? null : _pair,
        icon: const Icon(Icons.login), label: const Text('Start Plex pairing')),
      if (_pin != null) ...[
        const Text('On a phone or computer open https://plex.tv/link', style: TextStyle(fontSize: 14)),
        SelectableText(_pin!.code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        OutlinedButton(onPressed: _busy ? null : _checkPin, child: const Text('I approved Plex — Check sign-in')),
      ],
      const SizedBox(height: 12),
      const Text('Advanced — Manual connection', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextField(
        controller: _server, focusNode: _serverFocus, autocorrect: false,
        keyboardType: TextInputType.url, textInputAction: TextInputAction.next,
        onSubmitted: (_) => _tokenFocus.requestFocus(),
        decoration: const InputDecoration(labelText: 'Plex server address',
          hintText: 'https://your-server.plex.direct:32400', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _token, focusNode: _tokenFocus, autocorrect: false, obscureText: true,
        enableSuggestions: false, textInputAction: TextInputAction.done,
        onSubmitted: (_) { _tokenFocus.unfocus(); _saveFocus.requestFocus(); _save(); },
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
      const Text('Press Done on the TV keyboard to save, or use the Save button below.'),
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
