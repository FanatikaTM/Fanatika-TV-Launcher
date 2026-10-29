// ADB shell-requested backups require the launcher to be open, and are saved locally.
// No backup is sent to the Windows computer or external servers.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/fanatika_backup_service.dart';

class FanatikaRemoteBackupObserver extends StatefulWidget {
  final Widget child;
  const FanatikaRemoteBackupObserver({super.key, required this.child});
  @override State<FanatikaRemoteBackupObserver> createState() => _BackupState();
}
class _BackupState extends State<FanatikaRemoteBackupObserver> {
  static const MethodChannel _channel = MethodChannel('com.fanatika.tvlauncher/remote_settings');
  Timer? _timer;
  bool _busy = false;
  @override void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => unawaited(_check()));
  }
  Future<void> _check() async {
    if (_busy || !mounted) return;
    _busy = true;
    try {
      if (await _channel.invokeMethod<bool>('consumeBackup') != true || !mounted) return;
      String result;
      try {
        final ok = await FanatikaBackupService.export(
          context.read<SettingsService>(), context.read<AppsService>());
        result = ok ? 'saved-to-tv-downloads' : 'failed-to-save';
      } catch (_) { result = 'failed-to-save'; }
      await _channel.invokeMethod('backupStatus', result);
    } on MissingPluginException { // Only on Android with the new control bridge.
    } catch (_) { // Keep the launcher usable if an optional method fails.
    } finally { _busy = false; }
  }
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) => widget.child;
}
