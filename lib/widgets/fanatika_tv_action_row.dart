// A single remote focus target with explicit D-pad movement and activation.
// Kept separate from the Arc Favorites editor and its data operations.
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
  final bool autofocus;

  const FanatikaTvActionRow({
    super.key,
    required this.focusNode,
    required this.icon,
    required this.title,
    required this.onPressed,
    this.subtitle,
    this.moveUp,
    this.moveDown,
    this.autofocus = false,
  });

  @override State<FanatikaTvActionRow> createState() => _FanatikaTvActionRowState();
}

class _FanatikaTvActionRowState extends State<FanatikaTvActionRow> {
  bool _focused = false;

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

  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
    child: Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _onKeyEvent,
      onFocusChange: (focused) {
        if (mounted && focused != _focused) setState(() => _focused = focused);
        if (focused) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Scrollable.ensureVisible(context,
              alignment: 0.18,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic);
          });
        }
      },
      child: InkWell(
        canRequestFocus: false, // Do not create a second invisible D-pad stop.
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 95),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _focused ? const Color(0xFF176CB5) : const Color(0x332C3D56),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _focused ? const Color(0xFFECF9FF) : Colors.transparent,
              width: _focused ? 2.3 : 1,
            ),
            boxShadow: _focused ? const [
              BoxShadow(color: Color(0x663FA6EC), blurRadius: 15, spreadRadius: 1),
            ] : const [],
          ),
          child: Row(children: [
            Icon(widget.icon, color: Colors.white, size: 23),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
                Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w600)),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(widget.subtitle!, maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFE0EAF3), fontSize: 12)),
                ],
              ])),
            if (_focused) const Icon(Icons.chevron_right, color: Colors.white),
          ]),
        ),
      ),
    ),
  );
}
