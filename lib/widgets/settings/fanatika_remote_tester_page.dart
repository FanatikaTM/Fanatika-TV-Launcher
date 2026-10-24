// Fanatika v2.3 — read-only, foreground-only remote control button tester.
// License: GPL-3.0-or-later; retains Arc Favorites unchanged.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FanatikaRemoteTesterPage extends StatefulWidget {
  static const routeName = 'fanatika_remote_tester';
  const FanatikaRemoteTesterPage({super.key});
  @override
  State<FanatikaRemoteTesterPage> createState() => _FanatikaRemoteTesterPageState();
}

class _FanatikaRemoteTesterPageState extends State<FanatikaRemoteTesterPage> {
  final FocusNode _node = FocusNode(debugLabel: 'Remote test capture');
  final List<String> _events = <String>[];
  final Map<LogicalKeyboardKey, DateTime> _keyDown = {};
  String _last = 'Press a remote key';

  @override
  void dispose() { _node.dispose(); super.dispose(); }

  void _record(KeyEvent event) {
    final logical = event.logicalKey;
    final physical = event.physicalKey;
    final when = DateTime.now();
    String kind;
    if (event is KeyDownEvent) {
      _keyDown[logical] = when;
      kind = 'DOWN';
    } else if (event is KeyRepeatEvent) {
      kind = 'REPEAT (held)';
    } else if (event is KeyUpEvent) {
      final start = _keyDown.remove(logical);
      final hold = start == null ? '?' : '${when.difference(start).inMilliseconds} ms';
      kind = 'UP, held $hold';
    } else { kind = 'EVENT'; }
    final label = '${logical.keyLabel.isEmpty ? logical.debugName ?? 'Unknown' : logical.keyLabel}  '
        'logical 0x${logical.keyId.toRadixString(16)}  '
        'physical 0x${physical.usbHidUsage.toRadixString(16)}  $kind';
    if (!mounted) return;
    setState(() {
      _last = label;
      _events.insert(0, label);
      if (_events.length > 24) _events.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Remote Button Tester', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      const Text('Select Capture and press buttons. Only events Android delivers to Fanatika can appear. '
        'HOME, POWER and OEM-reserved keys may never arrive; this test does not remap them.'),
      const SizedBox(height: 16),
      KeyboardListener(
        focusNode: _node,
        autofocus: true,
        onKeyEvent: _record,
        child: Focus(
          canRequestFocus: false,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blueGrey.shade900,
              border: Border.all(color: _node.hasFocus ? Colors.lightBlueAccent : Colors.white30, width: 2),
              borderRadius: BorderRadius.circular(16)),
            child: Text(_last, style: const TextStyle(fontSize: 17, color: Colors.white)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      TextButton.icon(
        onPressed: () { _node.requestFocus(); setState(() { _events.clear(); _last = 'Capture active'; }); },
        icon: const Icon(Icons.keyboard), label: const Text('Capture buttons / Clear history'),
      ),
      const Divider(),
      Expanded(child: ListView(children: _events.map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5), child: Text(e, style: const TextStyle(fontSize: 13)),
      )).toList())),
    ]),
  );
}
