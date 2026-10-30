// Lightweight countdown on Fanatika's own home screen only.
// The system alarm is owned by FanatikaSleepController; this is a display.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flauncher/flauncher_channel.dart';

class FanatikaSleepCountdownBadge extends StatefulWidget {
  const FanatikaSleepCountdownBadge({super.key});
  @override
  State<FanatikaSleepCountdownBadge> createState() => _FanatikaSleepCountdownBadgeState();
}

class _FanatikaSleepCountdownBadgeState extends State<FanatikaSleepCountdownBadge>
    with WidgetsBindingObserver {
  final _channel = FLauncherChannel();
  Timer? _ticker;
  int _remaining = 0;
  bool _paused = false;
  bool _fetching = false;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining > 0 && !_paused) setState(() => _remaining--);
      if (++_ticks % 5 == 0) _refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final status = await _channel.fanatikaSleepStatus();
      if (!mounted) return;
      setState(() {
        _remaining = (status['remainingSeconds'] as num?)?.toInt() ?? 0;
        _paused = status['paused'] == true;
      });
    } catch (_) {
      // Permission or service may be unavailable: do not show an error overlay.
    } finally {
      _fetching = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  String _format(int seconds) =>
      '${(seconds ~/ 3600).toString().padLeft(2, '0')}:'
      '${((seconds ~/ 60) % 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_remaining <= 0) return const SizedBox.shrink();
    return IgnorePointer(child: Semantics(
      label: 'Sleep timer ${_format(_remaining)} remaining',
      child: DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xEE1E1E1E),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white30)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bedtime_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 9),
            Text(_paused ? '${_format(_remaining)} paused' : _format(_remaining),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600,
                fontSize: 15)),
          ])),
      ),
    ));
  }
}
