// Optional release checks, only when the launcher is in use. No silent installs.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/fanatika_release_checker.dart';

class FanatikaAutoUpdateObserver extends StatefulWidget {
  final Widget child;
  const FanatikaAutoUpdateObserver({super.key, required this.child});
  @override
  State<FanatikaAutoUpdateObserver> createState() => _FanatikaAutoUpdateObserverState();
}

class _FanatikaAutoUpdateObserverState extends State<FanatikaAutoUpdateObserver>
    with WidgetsBindingObserver {
  bool _checking = false;
  Timer? _checkTimer;
  int? _observedCadence;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCheck());
    // Lightweight periodic wake-up while the launcher remains open.
    _checkTimer = Timer.periodic(const Duration(hours: 6), (_) => _maybeCheck());
  }
  @override
  void dispose() {
    _checkTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _maybeCheck();
  }
  Future<void> _maybeCheck() async {
    if (!mounted || _checking) return;
    final settings = context.read<SettingsService>();
    final days = settings.fanatikaUpdateCheckDays;
    if (days == 0) return;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    const oneDay = Duration.millisecondsPerDay;
    final lastSuccess = settings.fanatikaUpdateLastSuccessMs;
    final lastAttempt = settings.fanatikaUpdateLastAttemptMs;
    if (lastSuccess > 0 && now >= lastSuccess && now - lastSuccess < days * oneDay) return;
    // Failed checks retry no sooner than 24 hours (avoid repeated 404s offline).
    if (lastAttempt > 0 && now >= lastAttempt && now - lastAttempt < oneDay) return;
    _checking = true;
    try {
      final result = await FanatikaReleaseChecker.check();
      if (!mounted) return;
      await settings.markFanatikaUpdateAttempt(now, success: result.checked);
      if (!mounted || !result.updateAvailable ||
          settings.fanatikaUpdateLastAlertedTag == result.latestVersion) return;
      await settings.markFanatikaUpdateAlerted(result.latestVersion);
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Fanatika update available'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result.message), const SizedBox(height: 12),
            SelectableText(result.releaseUrl, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            const Text('No APK was downloaded or installed. Review the release and its signing certificate first.'),
          ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'))],
      ));
    } catch (_) {
      if (mounted) await settings.markFanatikaUpdateAttempt(now, success: false);
    } finally {
      _checking = false;
    }
  }
  @override
  Widget build(BuildContext context) {
    final cadence = context.select<SettingsService, int>((s) => s.fanatikaUpdateCheckDays);
    if (_observedCadence != cadence) {
      _observedCadence = cadence;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCheck());
    }
    return widget.child;
  }
}
