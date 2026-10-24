// Download signed release APKs into private app storage. No silent install.
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flauncher/providers/fanatika_release_checker.dart';

class FanatikaDownloadedApk {
  final String path;
  final int bytes;
  final String sha256;
  const FanatikaDownloadedApk(this.path, this.bytes, this.sha256);
}

class _HashSink implements Sink<Digest> {
  Digest? digest;
  @override void add(Digest value) { digest = value; }
  @override void close() {}
}

class FanatikaApkDownloader {
  static const int maxBytes = 250 * 1024 * 1024;
  static Future<FanatikaDownloadedApk> download(FanatikaReleaseResult release,
      {void Function(int received, int expected)? progress, http.Client? client}) async {
    if (!release.updateAvailable || release.apkUrl.isEmpty || release.apkName.isEmpty) {
      throw StateError('No reviewed universal APK asset is available');
    }
    final uri = Uri.parse(release.apkUrl);
    if (uri.scheme != 'https' || uri.host != 'github.com' ||
        !uri.path.contains('/releases/download/') ||
        !release.apkName.toLowerCase().endsWith('.apk')) {
      throw const FormatException('Untrusted APK download URL');
    }
    final owned = client == null;
    final httpClient = client ?? http.Client();
    File? output;
    try {
      final request = http.Request('GET', uri);
      final response = await httpClient.send(request).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode} downloading update');
      if (response.contentLength != null && response.contentLength! > maxBytes) {
        throw const FormatException('APK is over the size limit');
      }
      final dir = Directory('${(await getApplicationSupportDirectory()).path}/fanatika_updates');
      await dir.create(recursive: true);
      output = File('${dir.path}/fanatika-reviewed-release.apk');
      if (await output.exists()) await output.delete();
      final fileSink = output.openWrite();
      final hashSink = _HashSink();
      final hashInput = sha256.startChunkedConversion(hashSink);
      var count = 0;
      try {
        await for (final chunk in response.stream.timeout(const Duration(seconds: 45))) {
          count += chunk.length;
          if (count > maxBytes) throw const FormatException('APK exceeded maximum size');
          fileSink.add(chunk);
          hashInput.add(chunk);
          progress?.call(count, response.contentLength ?? release.assetSize);
        }
        await fileSink.flush();
      } finally {
        await fileSink.close();
        hashInput.close();
      }
      if (count == 0 || (release.assetSize > 0 && count != release.assetSize)) {
        throw const FormatException('APK download was incomplete');
      }
      final actual = hashSink.digest.toString();
      if (release.assetSha256.isNotEmpty && actual != release.assetSha256) {
        throw const FormatException('SHA-256 does not match the GitHub release asset');
      }
      return FanatikaDownloadedApk(output.path, count, actual);
    } catch (_) {
      if (output != null && await output.exists()) await output.delete();
      rethrow;
    } finally {
      if (owned) httpClient.close();
    }
  }
}
