// Plex Media Server Continue Watching integration; independent of TV Provider.
// GPL-3.0-or-later. Never send a Plex token in a URL, or to another host via redirect.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flauncher/models/watch_next_item.dart';
import 'package:http/http.dart' as http;

class PlexContinueWatchingException implements Exception {
  final String message;
  const PlexContinueWatchingException(this.message);
  @override String toString() => message;
}

class PlexContinueWatchingClient {
  final Uri baseUri;
  final String token;
  final bool allowHttp;
  final http.Client _http;

  PlexContinueWatchingClient(String serverUrl, this.token, {this.allowHttp = false, http.Client? client})
      : baseUri = _validateBase(serverUrl, allowHttp), _http = client ?? http.Client();

  static Uri _validateBase(String value, bool allowHttp) {
    final u = Uri.tryParse(value.trim());
    if (u == null || !u.hasAuthority || !['http', 'https'].contains(u.scheme) ||
        u.userInfo.isNotEmpty || u.hasQuery || u.hasFragment ||
        (u.path.isNotEmpty && u.path != '/') ||
        (u.scheme == 'http' && (!allowHttp || !_isLocalHost(u.host)))) {
      throw const PlexContinueWatchingException('Invalid Plex server address or insecure HTTP not approved.');
    }
    return u.replace(path: '', query: null, fragment: null);
  }

  static bool _isLocalHost(String host) {
    if (host.endsWith('.local')) return true;
    final address = InternetAddress.tryParse(host);
    if (address == null) return false;
    final parts = address.rawAddress;
    if (address.type == InternetAddressType.IPv4) {
      return parts[0] == 10 ||
          (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) ||
          (parts[0] == 192 && parts[1] == 168);
    }
    return parts.isNotEmpty && (parts[0] & 0xfe) == 0xfc; // IPv6 ULA
  }

  Uri _endpoint(String path, [Map<String, String> params = const {}]) =>
    baseUri.replace(path: path, queryParameters: params.isEmpty ? null : params);

  Future<http.Response> _fetch(Uri url) async {
    // A redirect may point to a different host. NEVER forward X-Plex-Token.
    if (url.scheme != baseUri.scheme || url.host != baseUri.host || url.port != baseUri.port) {
      throw const PlexContinueWatchingException('Plex image/server address does not match configured server.');
    }
    final request = http.Request('GET', url);
    request.followRedirects = false;
    request.headers.addAll({
      'Accept': 'application/json',
      'X-Plex-Token': token,
      'X-Plex-Product': 'Fanatika TV Launcher',
      'X-Plex-Client-Identifier': 'fanatika-tv-launcher-local',
    });
    final stream = await _http.send(request).timeout(const Duration(seconds: 9));
    final response = await http.Response.fromStream(stream);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const PlexContinueWatchingException('Plex access denied. Check your access token and server account.');
    }
    if (response.isRedirect) {
      throw const PlexContinueWatchingException('Plex server redirected the request. Use its direct address.');
    }
    if (response.statusCode != 200) {
      throw PlexContinueWatchingException('Plex server returned HTTP ${response.statusCode}.');
    }
    return response;
  }

  Future<Map<String, dynamic>> _json(Uri url) async {
    final response = await _fetch(url);
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map && data['MediaContainer'] is Map) {
        return Map<String, dynamic>.from(data['MediaContainer'] as Map);
      }
    } catch (_) { /* Response might be XML if proxy strips Accept header. */ }
    throw const PlexContinueWatchingException('Plex did not return JSON. Verify the server URL and API access.');
  }

  static List<Map<String, dynamic>> _metadata(Map<String, dynamic> container) {
    final results = <Map<String, dynamic>>[];
    void append(dynamic values) {
      if (values is List) {
        for (final entry in values) {
          if (entry is Map) results.add(Map<String, dynamic>.from(entry));
        }
      }
    }
    append(container['Metadata']);
    if (container['Hub'] is List) {
      for (final hub in container['Hub']) {
        if (hub is Map) append(hub['Metadata']);
      }
    }
    return results;
  }

  Future<List<WatchNextItem>> load({int limit = 20}) async {
    if (token.trim().isEmpty) throw const PlexContinueWatchingException('Plex access token is missing.');
    // Current Plex Media Server provides a flattened Continue Watching items endpoint.
    var records = <Map<String, dynamic>>[];
    try {
      records = _metadata(await _json(_endpoint('/hubs/continueWatching/items', {'count': '$limit'})));
    } on PlexContinueWatchingException catch (e) {
      // Only try the older hub endpoint when this API endpoint is missing.
      if (!e.message.contains('HTTP 404')) rethrow;
    }
    if (records.isEmpty) {
      records = _metadata(await _json(_endpoint('/hubs/continueWatching', {'count': '$limit'})));
    }
    String serverId = '';
    try {
      final identity = await _json(_endpoint('/identity'));
      serverId = (identity['machineIdentifier'] ?? '').toString();
    } catch (_) { /* Items still display; launcher fallback opens Plex. */ }

    final items = <WatchNextItem>[];
    final seen = <String>{};
    for (final record in records) {
      final ratingKey = (record['ratingKey'] ?? '').toString();
      if (ratingKey.isEmpty || !seen.add(ratingKey)) continue;
      final type = (record['type'] ?? '').toString();
      final title = (record['title'] ?? '').toString();
      if (title.isEmpty) continue;
      final isEpisode = type == 'episode';
      final label = isEpisode
          ? '${record['grandparentTitle'] ?? record['parentTitle'] ?? ''} – $title'.trim()
          : title;
      final artwork = (record['grandparentThumb'] ?? record['thumb'] ?? '').toString();
      final posterPath = artwork.startsWith('/') ? artwork : '';
      final posterUri = posterPath.isEmpty ? null : _endpoint(posterPath).toString();
      final duration = _number(record['duration']);
      final offset = _number(record['viewOffset']);
      final progress = duration > 0 ? ((offset * 100) / duration).round().clamp(0, 100) : 0;
      final deepKey = isEpisode
        ? (record['grandparentRatingKey'] ?? ratingKey).toString() : ratingKey;
      final deepLink = serverId.isEmpty ? null :
        'plex://libraries/${Uri.encodeComponent(serverId)}/unmatched/'
        '${isEpisode ? 'tv/' : ''}%2Flibrary%2Fmetadata%2F${Uri.encodeComponent(deepKey)}';
      items.add(WatchNextItem(
        id: -items.length - 1, title: label, description: (record['summary'] ?? '').toString(),
        posterUri: posterUri, packageName: 'com.plexapp.android',
        source: 'plex', plexRatingKey: ratingKey,
        plexServerId: serverId, plexIsShow: isEpisode,
        plexViewOffset: offset, contentId: ratingKey,
        progressPercent: progress, duration: duration,
        intentUri: deepLink,
      ));
      if (items.length == limit) break;
    }
    return items;
  }

  static int _number(dynamic value) => value is num
    ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  Future<Uint8List> poster(String imageUrl) async {
    final uri = Uri.parse(imageUrl);
    final response = await _fetch(uri);
    if (response.bodyBytes.length > 6 * 1024 * 1024) {
      throw const PlexContinueWatchingException('Plex artwork exceeds 6 MiB.');
    }
    return response.bodyBytes;
  }

  void dispose() => _http.close();
}
