// Plex Continue Watching: account pairing only, no manual token or server entry.
// Fanatika never reads another Android app's private Plex credentials.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/fanatika_plex_setup.dart';
import 'package:flauncher/widgets/settings/fanatika_panel_style.dart';

class PlexContinueWatchingPage extends StatefulWidget {
  static const routeName = 'fanatika_plex_continue_watching';
  const PlexContinueWatchingPage({super.key});
  @override State<PlexContinueWatchingPage> createState() => _PlexContinueWatchingPageState();
}

class _PlexContinueWatchingPageState extends State<PlexContinueWatchingPage> {
  bool _busy = false;
  String _status = '';
  FanatikaPlexPin? _pin;

  Future<void> _runSetup(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _status = ''; });
    try { await action(); }
    catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Bad state: ', ''));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  // The ONLY connection path: user-approved Plex PIN pairing.
  Future<void> _pair() async => _runSetup(() async {
    final pin = await FanatikaPlexSetup.startPairing();
    if (mounted) setState(() { _pin = pin; _status = 'Approve the code at plex.tv/link.'; });
  });

  Future<void> _checkPin() async => _runSetup(() async {
    final pin = _pin;
    if (pin == null) return;
    final accountToken = await FanatikaPlexSetup.checkPairing(pin);
    if (!mounted) return;
    if (accountToken == null) {
      setState(() => _status = 'Plex sign-in not approved yet. Enter the code, then check again.');
      return;
    }
    final servers = await FanatikaPlexSetup.accountServers(accountToken);
    if (!mounted) return;
    if (servers.isEmpty) {
      setState(() => _status = 'Signed in, but no Plex Media Server is available to this account.');
      return;
    }
    final chosen = servers.length == 1 ? servers.first :
      await showDialog<FanatikaPlexServer>(context: context,
        builder: (ctx) => SimpleDialog(title: const Text('Choose your Plex server'), children: [
          for (final server in servers) SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, server),
            child: Text('${server.name} • ${Uri.parse(server.url).host}')),
        ]));
    if (!mounted || chosen == null) return;
    final settings = context.read<SettingsService>();
    // Save the server token only after the account holder has approved the PIN.
    await settings.setPlexContinueWatchingConfig(
      url: chosen.url, token: chosen.token, enabled: true, allowHttp: chosen.allowHttp);
    await settings.setShowWatchNextSection(true);
    if (!mounted) return;
    await context.read<WatchNextService>().refreshPermissionAndItems();
    if (mounted) setState(() { _pin = null; _status = 'Plex connected. Continue Watching updated.'; });
  });

  Future<void> _refresh() async => _runSetup(() async {
    await context.read<WatchNextService>().refreshPermissionAndItems();
    if (mounted) setState(() => _status = 'Continue Watching refreshed.');
  });

  Future<void> _clear() async => _runSetup(() async {
    await context.read<SettingsService>().clearPlexContinueWatchingConfig();
    if (!mounted) return;
    await context.read<WatchNextService>().refreshPermissionAndItems();
    if (mounted) setState(() { _pin = null; _status = 'Plex disconnected from Fanatika.'; });
  });

  @override Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final connected = settings.plexContinueWatchingEnabled &&
      settings.plexServerUrl.isNotEmpty && settings.plexAccessToken.isNotEmpty;
    return Column(children: [
      const FanatikaPanelHeader(title: 'Plex Continue Watching'),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(6, 8, 6, 24), children: [
        Text(connected ? 'Plex connected' : 'Connect your Plex account',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const Text('Pair Fanatika with your Plex account once. No server address or token needs to be typed on the TV.'),
        const SizedBox(height: 20),
        FilledButton.icon(
          autofocus: true,
          onPressed: _busy ? null : _pair,
          icon: const Icon(Icons.login),
          label: Text(connected ? 'Sign in with another Plex account' : 'Start Plex pairing'),
        ),
        if (_pin != null) ...[
          const SizedBox(height: 18),
          const Text('On your phone or computer, open https://plex.tv/link'),
          const SizedBox(height: 10),
          SelectableText(_pin!.code,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _busy ? null : _checkPin,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('I approved Plex — Connect')),
        ],
        if (connected) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh), label: const Text('Refresh shows now')),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Refresh interval'),
            subtitle: Text('Every ${settings.plexRefreshMinutes} minutes'),
            trailing: const Icon(Icons.timer_outlined),
            onTap: _busy ? null : () async {
              final selected = await showDialog<int>(context: context,
                builder: (ctx) => SimpleDialog(title: const Text('Plex refresh interval'), children: [
                  for (final minutes in [5, 15, 30, 60]) SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, minutes),
                    child: Text('Every $minutes minutes')),
                ]));
              if (selected != null) await settings.setPlexRefreshMinutes(selected);
            },
          ),
          TextButton.icon(onPressed: _busy ? null : _clear,
            icon: const Icon(Icons.link_off), label: const Text('Disconnect Plex')),
        ],
        if (_busy) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
        if (_status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12),
          child: Text(_status, style: const TextStyle(color: Colors.white70))),
        const SizedBox(height: 20),
        const Text('Plex login is approved by you at plex.tv/link. Fanatika stores its own server access token privately and excludes it from exported backups.',
          style: TextStyle(color: Colors.white60, fontSize: 12)),
      ])),
    ]);
  }
}
