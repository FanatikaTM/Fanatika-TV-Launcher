// Opt-in Plex discovery and pairing, without accessing other apps' private data.
// GPL-3.0-or-later. Tokens are passed in headers, never query strings or logs.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FanatikaPlexServer {
  final String name, url, token;
  final bool allowHttp;
  const FanatikaPlexServer(this.name, this.url, {this.token = '', this.allowHttp = false});
  @override String toString() => name;
}

class FanatikaPlexPin {
  final int id;
  final String code;
  const FanatikaPlexPin(this.id, this.code);
}

class FanatikaPlexSetup {
  static const _host = 'https://plex.tv/api/v2';
  static const _headers = <String, String>{
    'Accept': 'application/json', 'X-Plex-Product': 'Fanatika TV Launcher',
  };

  static Future<String> _clientId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('fanatika_plex_client_identifier');
    if (id == null || id.isEmpty) {
      final random = Random.secure();
      id = 'fanatika-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
      await prefs.setString('fanatika_plex_client_identifier', id);
    }
    return id;
  }

  static Future<FanatikaPlexPin> startPairing() async {
    final id = await _clientId();
    final response = await http.post(Uri.parse('$_host/pins'),
      headers: {..._headers, 'X-Plex-Client-Identifier': id},
      body: {'strong': 'false'}).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError('Plex pairing unavailable (HTTP ${response.statusCode}).');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final pinId = (json['id'] as num?)?.toInt();
    final code = json['code']?.toString();
    if (pinId == null || code == null || code.isEmpty) {
      throw StateError('Plex returned an invalid pairing code.');
    }
    return FanatikaPlexPin(pinId, code);
  }

  static Future<String?> checkPairing(FanatikaPlexPin pin) async {
    final response = await http.get(Uri.parse('$_host/pins/${pin.id}'), headers: {
      ..._headers, 'X-Plex-Client-Identifier': await _clientId(),
    }).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw StateError('Plex pairing expired or unavailable. Start again.');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final token = json['authToken']?.toString();
    return token == null || token.isEmpty ? null : token;
  }

  static Future<List<FanatikaPlexServer>> accountServers(String accountToken) async {
    if (accountToken.isEmpty) return [];
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse('$_host/resources?includeHttps=1&includeRelay=0'));
      req.followRedirects = false;
      req.headers.addAll({..._headers, 'X-Plex-Client-Identifier': await _clientId(),
        'X-Plex-Token': accountToken});
      final streamed = await client.send(req).timeout(const Duration(seconds: 12));
      if (streamed.statusCode != 200) throw StateError('Plex resources returned HTTP ${streamed.statusCode}.');
      final response = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw StateError('Unexpected Plex resource format.');
      final choices = <FanatikaPlexServer>[];
      for (final obj in decoded) {
        if (obj is! Map) continue;
        final provides = obj['provides']?.toString() ?? '';
        if (!provides.contains('server')) continue;
        final serverToken = obj['accessToken']?.toString() ?? accountToken;
        final name = obj['name']?.toString() ?? 'Plex Media Server';
        final connections = obj['connections'];
        if (connections is! List) continue;
        final urls = <({String url, bool local, bool https})>[];
        for (final conn in connections) {
          if (conn is! Map) continue;
          final url = conn['uri']?.toString() ?? '';
          final u = Uri.tryParse(url);
          if (u == null || !u.hasAuthority || !['http','https'].contains(u.scheme)) continue;
          // No proxies, query tokens, or external redirects are ever followed.
          if (u.hasQuery || u.hasFragment || u.userInfo.isNotEmpty) continue;
          urls.add((url: url, local: conn['local'] == true, https: u.scheme == 'https'));
        }
        urls.sort((a,b) => ((b.local ? 2 : 0) + (b.https ? 1 : 0))
          .compareTo((a.local ? 2 : 0) + (a.https ? 1 : 0)));
        for (final c in urls) {
          if (!c.https && !c.local) continue; // Never use cleartext over the public Internet.
          choices.add(FanatikaPlexServer(name, c.url, token: serverToken, allowHttp: !c.https));
          break;
        }
      }
      return choices;
    } finally { client.close(); }
  }

  // Plex GDM, UDP 32414. Discovery only, without credentials. Some APs block
  // broadcast: that is not an authentication failure and pairing still works.
  static Future<List<FanatikaPlexServer>> discoverLocal() async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      final seen = <String, FanatikaPlexServer>{};
      final sub = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        Datagram? datagram;
        while ((datagram = socket?.receive()) != null) {
          final packet = datagram!;
          final lines = ascii.decode(packet.data, allowInvalid: true).split(RegExp(r'\r?\n'));
          final headers = <String,String>{};
          for (final line in lines) {
            final pos = line.indexOf(':');
            if (pos > 0) headers[line.substring(0,pos).trim().toLowerCase()] = line.substring(pos+1).trim();
          }
          if (!(headers['resource-identifier'] ?? '').isNotEmpty &&
              !(headers['content-type'] ?? '').contains('plex')) continue;
          final port = int.tryParse(headers['port'] ?? '') ?? 32400;
          if (port < 1 || port > 65535) continue;
          final ip = packet.address.address;
          // Only local private IPv4 addresses are accepted for cleartext.
          if (!(ip.startsWith('10.') || ip.startsWith('192.168.') ||
              RegExp(r'^172\.(1[6-9]|2[0-9]|3[01])\.').hasMatch(ip))) continue;
          final url = 'http://$ip:$port';
          seen[url] = FanatikaPlexServer(headers['name'] ?? 'Plex on $ip', url, allowHttp: true);
        }
      });
      socket.send(ascii.encode('M-SEARCH * HTTP/1.0\r\n\r\n'), InternetAddress('255.255.255.255'), 32414);
      await Future<void>.delayed(const Duration(seconds: 3));
      await sub.cancel();
      return seen.values.toList();
    } catch (_) { return []; }
    finally { socket?.close(); }
  }
}
