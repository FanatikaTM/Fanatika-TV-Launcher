// Fanatika update UI. The user must approve download and Android installation.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/fanatika_backup_service.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/fanatika_release_checker.dart';
import 'package:flauncher/providers/fanatika_apk_downloader.dart';

class FanatikaUpdateDialogs {
  static Future<bool> backupBeforeInstall(BuildContext context) async {
    final backup = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Back up before updating'),
      content: const Text('Save the current settings and original Arc Favorites order to Downloads/Fanatika before installing the update? Plex tokens and PINs are excluded. A backup is strongly recommended.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel update')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Back up and continue')),
      ],
    )) ?? false;
    if (!backup || !context.mounted) return false;
    try {
      final ok = await FanatikaBackupService.export(context.read<SettingsService>(), context.read<AppsService>());
      if (ok) return true;
      if (context.mounted) await showStatus(context, 'Backup was not saved; update cancelled. Check TV storage.');
    } catch (_) {
      if (context.mounted) await showStatus(context, 'Backup failed; update cancelled. Check TV storage and retry.');
    }
    return false;
  }

  static Future<void> showStatus(BuildContext context, String message) => showDialog<void>(
    context: context, builder: (ctx) => AlertDialog(
      title: const Text('Updates'), content: Text(message),
      actions: [TextButton(autofocus: true, onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'))]));

  static Future<void> offer(BuildContext context, FanatikaReleaseResult release) async {
    if (!context.mounted) return;
    if (release.apkUrl.isEmpty) {
      await showStatus(context, '${release.message}\n\nA signed UNIVERSAL APK must be attached to the public release.');
      return;
    }
    final approved = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Version ${release.latestVersion} available'),
      content: SingleChildScrollView(child: Text(
        'Installed version: ${release.currentVersion}\n'
        'Release: ${release.latestVersion}\n'
        'File: ${release.apkName}\n'
        'Size: ${release.assetSize > 0 ? '${(release.assetSize / 1048576).toStringAsFixed(1)} MB' : 'Unknown'}\n\n'
        'Download from a public GitHub release? The APK will be checked against the installed package, '
        'version code and signing certificate before installation.\n'
        'Installation always requires your confirmation on the TV.')),
      actions: [
        TextButton(autofocus: true, onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Download and verify')),
      ],
    )) ?? false;
    if (!approved || !context.mounted) return;

    final downloaded = await showDialog<FanatikaDownloadedApk>(context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateDownloadDialog(release: release));
    if (downloaded == null || !context.mounted) return;
    final channel = FLauncherChannel();
    try {
      final verified = await channel.fanatikaVerifyReleaseApk(downloaded.path);
      if (!context.mounted) return;
      if (verified['ok'] != true) {
        await showStatus(context, verified['detail']?.toString() ?? 'Android rejected the APK identity or signing certificate');
        return;
      }
      final install = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Install verified update?'),
        content: Text('Version ${release.latestVersion}\n'
          'Downloaded ${downloaded.bytes} bytes\n'
          'SHA-256: ${downloaded.sha256}\n\n'
          '${verified['detail']}\n\n'
          'Android will show its own installation confirmation. Favorites and settings are preserved '
          'by normal updates signed with the same key.'),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open Android installer')),
        ],
      )) ?? false;
      if (!install || !context.mounted) return;
      if (!await backupBeforeInstall(context) || !context.mounted) return;
      final result = await channel.fanatikaInstallVerifiedReleaseApk(downloaded.path);
      if (!context.mounted) return;
      if (result['needsPermission'] == true) {
        final openSettings = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Allow installation permission'),
          content: const Text('Android requires permission to install APKs from this launcher. '
              'Open Android settings, approve it if you trust this update, then check again.'),
          actions: [
            TextButton(autofocus: true, onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open settings')),
          ],
        )) ?? false;
        if (openSettings) await channel.fanatikaOpenUnknownSources();
      } else if (result['ok'] != true) {
        await showStatus(context, result['detail']?.toString() ?? 'Unable to open installer');
      }
    } catch (e) {
      if (context.mounted) await showStatus(context, 'Unable to verify or install the update: $e');
    }
  }
}

class _UpdateDownloadDialog extends StatefulWidget {
  final FanatikaReleaseResult release;
  const _UpdateDownloadDialog({required this.release});
  @override State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}
class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  double? fraction;
  String label = 'Connecting to GitHub…';
  String? error;
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _download());
  }
  Future<void> _download() async {
    try {
      final file = await FanatikaApkDownloader.download(widget.release,
        progress: (received, expected) {
          if (!mounted) return;
          setState(() {
            fraction = expected > 0 ? (received / expected).clamp(0.0, 1.0) : null;
            label = 'Downloaded ${(received / 1048576).toStringAsFixed(1)} MB'
                '${expected > 0 ? ' / ${(expected / 1048576).toStringAsFixed(1)} MB' : ''}';
          });
        });
      if (mounted) Navigator.of(context).pop(file);
    } catch (e) {
      if (mounted) setState(() { error = 'Download failed: $e'; fraction = null; });
    }
  }
  @override Widget build(BuildContext context) => PopScope(
    canPop: error != null,
    child: AlertDialog(
      title: const Text('Downloading update'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (error == null) LinearProgressIndicator(value: fraction),
        const SizedBox(height: 14),
        Text(error ?? label),
      ]),
      actions: error == null ? [] : [TextButton(autofocus: true,
        onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ),
  );
}
