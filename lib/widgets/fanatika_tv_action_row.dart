// Remote-first menu row: a single keyboard focus target with a visible
// selected fallback, so a TV firmware that delays modal focus won't leave the
// app-action dialog looking completely unfocused.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FanatikaTvActionRow extends StatefulWidget {
  final FocusNode focusNode;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onPressed;
  final VoidCallback? moveUp;
  final VoidCallback? moveDown;
  final ValueChanged<bool>? onFocusChanged;
  final bool autofocus;
  final bool selected;

  const FanatikaTvActionRow({
    super.key,
    required this.focusNode,
    required this.icon,
    required this.title,
    required this.onPressed,
    this.subtitle,
    this.moveUp,
    this.moveDown,
    this.onFocusChanged,
    this.autofocus = false,
    this.selected = false,
  });

  @override State<FanatikaTvActionRow> createState() => _FanatikaTvActionRowState();
}

class _FanatikaTvActionRowState extends State<FanatikaTvActionRow> {
  bool _hasFocus = false;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      widget.moveUp?.call();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      widget.moveDown?.call();
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.enter ||
         key == LogicalKeyboardKey.select ||
         key == LogicalKeyboardKey.gameButtonA ||
         key == LogicalKeyboardKey.space)) {
      widget.onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override Widget build(BuildContext context) {
    final highlighted = _hasFocus || widget.selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: _onKeyEvent,
        onFocusChange: (focused) {
          if (mounted && focused != _hasFocus) setState(() => _hasFocus = focused);
          widget.onFocusChanged?.call(focused);
          if (focused) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Scrollable.ensureVisible(context,
                alignment: 0.18,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic);
            });
          }
        },
        // GestureDetector isn't focusable. There is exactly ONE D-pad target:
        // the Focus node above. InkWell's implicit focus interfered with some
        // Xiaomi firmware and the menu showed no selection.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 95),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: highlighted ? const Color(0xFF1975CC) : const Color(0x332C3D56),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: highlighted ? const Color(0xFFFFFFFF) : Colors.transparent,
                width: highlighted ? 2.6 : 1.0,
              ),
              boxShadow: highlighted ? const [
                BoxShadow(color: Color(0x993FA6EC), blurRadius: 14, spreadRadius: 0.6),
              ] : const [],
            ),
            child: Row(children: [
              Icon(widget.icon, color: Colors.white, size: 23),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, children: [
                  Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 17,
                      fontWeight: FontWeight.w700)),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(widget.subtitle!, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFF0F6FF), fontSize: 12)),
                  ],
                ])),
              if (highlighted) const Icon(Icons.check_circle_outline, color: Colors.white),
            ]),
          ),
        ),
      ),
    );
  }
}
