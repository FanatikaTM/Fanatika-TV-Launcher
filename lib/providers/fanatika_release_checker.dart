// Fanatika TV Launcher: read-only GitHub release checking.
// Never downloads APKs or changes HOME / original Arc Favorites.
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
  const FanatikaReleaseResult({required this.checked, required this.updateAvailable,
    required this.currentVersion, required this.latestVersion, required this.releaseUrl,
    required this.message});
}

class FanatikaReleaseChecker {
  static final Uri endpoint = Uri.https('api.github.com',
      '/repos/FanatikaTM/Fanatika-TV-Launcher/releases/latest');
  static final Uri releasesPage = Uri.https('github.com',
      '/FanatikaTM/Fanatika-TV-Launcher/releases');

  // Public releases only. The private repo's API returns 404 without a token.
  // Only compare numeric SemVer triplets; malformed tags can never prompt install.
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

  static Future<FanatikaReleaseResult> check({http.Client? client}) async {
    final current = await PackageInfo.fromPlatform();
    final owned = client == null;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.get(endpoint,
        headers: const {'Accept': 'application/vnd.github+json',
          'User-Agent': 'Fanatika-TV-Launcher', 'X-GitHub-Api-Version': '2022-11-28'},
      ).timeout(const Duration(seconds: 9));
      if (response.statusCode != 200) {
        return FanatikaReleaseResult(checked: false, updateAvailable: false,
          currentVersion: current.version, latestVersion: '', releaseUrl: '',
          message: response.statusCode == 404
            ? 'No public Fanatika release found. Private repositories and repositories without published Releases cannot be checked from the TV.'
            : 'Could not check GitHub releases (HTTP ${response.statusCode}).');
      }
      final payload = jsonDecode(response.body);
      final tag = payload is Map ? payload['tag_name'] : null;
      if (tag is! String || parseVersion(tag) == null) {
        return FanatikaReleaseResult(checked: false, updateAvailable: false,
          currentVersion: current.version, latestVersion: '', releaseUrl: '',
          message: 'GitHub release has no recognized stable version tag (for example v2.4.1).');
      }
      final newer = newerThan(tag, current.version);
      final url = payload is Map ? payload['html_url'] : null;
      final approvedUrl = url is String &&
          Uri.tryParse(url)?.host == 'github.com' &&
          Uri.parse(url).path.startsWith('/FanatikaTM/Fanatika-TV-Launcher/releases/')
          ? url : releasesPage.toString();
      final debugVariant = current.packageName.endsWith('.debug');
      return FanatikaReleaseResult(checked: true, updateAvailable: newer,
        currentVersion: current.version, latestVersion: tag, releaseUrl: approvedUrl,
        message: newer
          ? 'Update available: $tag (installed: ${current.version}). Review the signed GitHub release before installing.${debugVariant ? ' This debug build cannot be replaced with a release APK.' : ''}'
          : 'Fanatika is up to date: ${current.version} (latest public release: $tag).');
    } catch (_) {
      return FanatikaReleaseResult(checked: false, updateAvailable: false,
        currentVersion: current.version, latestVersion: '', releaseUrl: '',
        message: 'Update check unavailable. Confirm internet access or try again later.');
    } finally {
      if (owned) httpClient.close();
    }
  }
}
