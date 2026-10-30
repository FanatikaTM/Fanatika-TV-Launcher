// Fanatika sleep timer: compact, non-intrusive TV remote interface.
// Uses the existing user-approved Device Administrator request. Xiaomi may
// display its lock screen instead of entering hardware standby.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flauncher/flauncher_channel.dart';

class FanatikaSleepTimerDialog extends StatefulWidget {
  const FanatikaSleepTimerDialog({super.key});
  @override State<FanatikaSleepTimerDialog> createState() => _FanatikaSleepTimerDialogState();
}

class _FanatikaSleepTimerDialogState extends State<FanatikaSleepTimerDialog> {
  final _channel = FLauncherChannel();
  static const _durations = <(int,String)>[
    (15,'15 minutes'), (30,'30 minutes'), (45,'45 minutes'),
    (60,'1 hour'), (90,'1 hour 30 minutes'), (120,'2 hours'), (180,'3 hours')
  ];
  Timer? _ticker;
  bool _running = false;
  bool _paused = false;
  bool _busy = false;
  bool _adminEnabled = false;
  int _remaining = 0;
  int _duration = 0;
  String _error = '';

  @override void initState() {
    super.initState();
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_running && !_paused && _remaining > 0) {
        setState(() => _remaining--);
      }
      // Refresh from Android periodically to avoid drift and catch external changes.
      if (DateTime.now().second % 15 == 0) _refresh(silent: true);
    });
  }
  @override void dispose() { _ticker?.cancel(); super.dispose(); }

  Future<void> _refresh({bool silent = false}) async {
    try {
      final status = await _channel.fanatikaSleepStatus();
      if (!mounted) return;
      final remain = (status['remainingSeconds'] as num?)?.toInt() ?? 0;
      setState(() {
        _remaining = remain;
        _running = remain > 0;
        _paused = status['paused'] == true;
        _adminEnabled = status['deviceAdminActive'] == true;
        if (!_running) _duration = 0;
        else if (_duration < _remaining) _duration = _remaining;
        if (!silent) _error = '';
      });
    } catch (_) {
      if (!silent && mounted) setState(() => _error = 'Cannot read sleep timer.');
    }
  }

  Future<void> _perform(Future<Map<String,dynamic>> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _error = ''; });
    try {
      final result = await action();
      if (!mounted) return;
      if (result['ok'] != true) {
        setState(() => _error = result['message']?.toString() ?? 'Timer unavailable.');
      }
      await _refresh(silent: true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Sleep timer is not supported on this TV.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start(int minutes) async {
    _duration = minutes * 60;
    await _perform(() => _channel.fanatikaSleepTimer(minutes));
  }

  String _clock(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2,'0')}:${(seconds % 60).toString().padLeft(2,'0')}';
  String _endsAt() {
    final end = DateTime.now().add(Duration(seconds: _remaining));
    return '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  @override Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: width < 650 ? width * 0.85 : 430,
        constraints: BoxConstraints(maxHeight: height * 0.88),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          // Same dark surface used by Arc/Fanatika's unified settings panels.
          color: const Color(0xFF1E1E1E),
          border: Border.all(color: Colors.white24),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Sleep timer', style: TextStyle(color: Colors.white,
            fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (!_running)
            Flexible(child: ListView(shrinkWrap: true, children: [
              for (var i=0; i<_durations.length; i++) ...[
                _option(_durations[i].$2, () => _start(_durations[i].$1), autofocus: i==0),
                if (i < _durations.length-1) const SizedBox(height: 9),
              ]
            ]))
          else ...[
            const SizedBox(height: 14),
            SizedBox(width: 175, height: 175, child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(
                value: _duration > 0 ? (_remaining/_duration).clamp(0.0, 1.0) : 0,
                strokeWidth: 4, backgroundColor: Colors.white24,
                color: const Color(0xFF82D2FD))),
              Text(_clock(_remaining), style: const TextStyle(color: Colors.white,
                fontSize: 35, fontWeight: FontWeight.w500)),
            ])),
            const SizedBox(height: 20),
            Text(_paused ? 'Timer paused' : 'Sleep requested at ${_endsAt()}',
              style: const TextStyle(color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 22),
            _option(_paused ? 'Resume timer' : 'Pause timer',
              () => _perform(_paused ? _channel.fanatikaResumeSleepTimer :
                _channel.fanatikaPauseSleepTimer), autofocus: true),
            const SizedBox(height: 10),
            _option('Cancel timer', () => _perform(_channel.fanatikaCancelSleepTimer)),
            const SizedBox(height: 80),
          ],
          if (!_adminEnabled) Padding(padding: const EdgeInsets.only(top: 10),
            child: TextButton(onPressed: () async {
              try {
                await _channel.fanatikaRequestSleepAdmin();
                await _refresh(silent: true);
              } catch (_) {
                if (mounted) setState(() => _error = 'TV sleep permission unavailable.');
              }
            }, child: const Text('Enable sleep permission',
              style: TextStyle(color: Colors.white)))),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2)),
          if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10),
            child: Text(_error, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12))),
        ]),
      ),
    );
  }

  Widget _option(String label, VoidCallback action, {bool autofocus=false}) =>
    _TimerOption(label: label, onTap: _busy ? null : action, autofocus: autofocus);
}

class _TimerOption extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool autofocus;
  const _TimerOption({required this.label, required this.onTap, this.autofocus=false});
  @override State<_TimerOption> createState() => _TimerOptionState();
}
class _TimerOptionState extends State<_TimerOption> {
  bool _focused = false;
  @override Widget build(BuildContext context) => Material(
    color: _focused ? Colors.white : const Color(0xFF343434),
    borderRadius: BorderRadius.circular(23),
    child: InkWell(
      autofocus: widget.autofocus,
      onFocusChange: (v) => setState(() => _focused = v),
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(23),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 19),
        child: Text(widget.label, style: TextStyle(fontSize: 16,
          fontWeight: _focused ? FontWeight.w600 : FontWeight.w400,
          color: _focused ? const Color(0xFF1E1E1E) : Colors.white),
          textAlign: TextAlign.left)),
    ),
  );
}
