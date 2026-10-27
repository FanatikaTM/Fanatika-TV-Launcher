// Fanatika v2.6: read-only public GitHub release metadata.
// Download and installation are separate user-approved operations.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class FanatikaReleaseResult {
  final bool checked;
  final bool updateAvailable;
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String message;
  final String apkUrl;
  final String apkName;
  final String assetSha256;
  final int assetSize;
  const FanatikaReleaseResult({required this.checked, required this.updateAvailable,
    required this.currentVersion, required this.latestVersion, required this.releaseUrl,
    required this.message, this.apkUrl = '', this.apkName = '', this.assetSha256 = '',
    this.assetSize = 0});
}

class FanatikaReleaseChecker {
  // Configure a PUBLIC APK-only release repository in Fanatika tools.
  // The development repository can remain private.
  static const String defaultReleaseRepo = 'FanatikaTM/Fanatika-TV-Launcher-Releases';
  static final RegExp _repoPattern = RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$');
  static String normalizedRepo(String input) {
    final trimmed = input.trim();
    if (!_repoPattern.hasMatch(trimmed) || trimmed.contains('..') || trimmed.length > 150) {
      throw const FormatException('Use GitHub owner/repository, for example owner/releases');
    }
    return trimmed;
  }
  static Uri endpointFor(String repo) => Uri.https('api.github.com',
      '/repos/${normalizedRepo(repo)}/releases/latest');
  static Uri pageFor(String repo) => Uri.https('github.com',
      '/${normalizedRepo(repo)}/releases');

  static List<int>? parseVersion(String input) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:\+\d+)?$').firstMatch(input.trim());
    if (match == null) return null;
    return [int.parse(match.group(1)!), int.parse(match.group(2)!), int.parse(match.group(3)!)];
  }
  static bool newerThan(String release, String installed) {
    final candidate = parseVersion(release);
    final current = parseVersion(installed);
    if (candidate == null || current == null) return false;
    for (var i = 0; i < 3; i++) {
      if (candidate[i] != current[i]) return candidate[i] > current[i];
    }
    return false;
  }

  static Map<String, Object>? _universalApk(Map payload, String repo, String tag) {
    final assets = payload['assets'];
    if (assets is! List) return null;
    for (final raw in assets) {
      if (raw is! Map) continue;
      final name = raw['name'];
      final rawUrl = raw['browser_download_url'];
      if (name is! String || rawUrl is! String ||
          !RegExp(r'universal.*\.apk$', caseSensitive: false).hasMatch(name)) continue;
      final uri = Uri.tryParse(rawUrl);
      if (uri == null || uri.scheme != 'https' || uri.host != 'github.com' ||
          !uri.path.startsWith('/$repo/releases/download/$tag/')) continue;
      final digest = raw['digest'];
      final sha = digest is String && RegExp(r'^sha256:[0-9a-fA-F]{64}$').hasMatch(digest)
          ? digest.substring(7).toLowerCase() : '';
      final size = raw['size'];
      final length = size is int ? size : 0;
      if (length < 0 || length > 250 * 1024 * 1024) continue;
      return {'name': name, 'url': rawUrl, 'sha256': sha, 'size': length};
    }
    return null;
  }

  static Future<FanatikaReleaseResult> check({String releaseRepo = defaultReleaseRepo,
    http.Client? client}) async {
    final current = await PackageInfo.fromPlatform();
    String repo;
    try { repo = normalizedRepo(releaseRepo); }
    on FormatException catch (e) {
      return FanatikaReleaseResult(checked: false, updateAvailable: false,
        currentVersion: current.version, latestVersion: '', releaseUrl: '', message: e.message);
    }
    final owned = client == null;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.get(endpointFor(repo),
        headers: const {'Accept': 'application/vnd.github+json',
          'User-Agent': 'Fanatika-TV-Launcher', 'X-GitHub-Api-Version': '2022-11-28'},
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        return FanatikaReleaseResult(checked: false, updateAvailable: false,
          currentVersion: current.version, latestVersion: '', releaseUrl: pageFor(repo).toString(),
          message: response.statusCode == 404
            ? 'No public APK release found at $repo. Create a public GitHub Releases repository and publish a signed universal APK.'
            : 'Could not check GitHub releases (HTTP ${response.statusCode}).');
      }
      final payload = jsonDecode(response.body);
      if (payload is! Map) throw const FormatException('Invalid GitHub release response');
      final tag = payload['tag_name'];
      if (tag is! String || parseVersion(tag) == null || payload['draft'] == true || payload['prerelease'] == true) {
        return FanatikaReleaseResult(checked: false, updateAvailable: false,
          currentVersion: current.version, latestVersion: '', releaseUrl: pageFor(repo).toString(),
          message: 'Release must be a published, stable version such as v2.6.0.');
      }
      final newer = newerThan(tag, current.version);
      final asset = _universalApk(payload, repo, tag);
      return FanatikaReleaseResult(checked: true, updateAvailable: newer,
        currentVersion: current.version, latestVersion: tag,
        releaseUrl: pageFor(repo).toString(),
        apkUrl: asset?['url'] as String? ?? '',
        apkName: asset?['name'] as String? ?? '',
        assetSha256: asset?['sha256'] as String? ?? '',
        assetSize: asset?['size'] as int? ?? 0,
        message: newer
          ? (asset == null ? 'New version $tag was found, but no universal signed APK was attached.'
              : 'New release $tag is available (installed: ${current.version}). Review before downloading.')
          : 'Version ${current.version} is up to date (latest public release: $tag).');
    } catch (e) {
      return FanatikaReleaseResult(checked: false, updateAvailable: false,
        currentVersion: current.version, latestVersion: '', releaseUrl: pageFor(repo).toString(),
        message: 'Release check unavailable. Confirm public repository and internet access.');
    } finally {
      if (owned) httpClient.close();
    }
  }
}
