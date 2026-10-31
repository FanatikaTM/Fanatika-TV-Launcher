import 'package:flauncher/actions.dart';
import 'package:flutter/material.dart';
import 'package:flauncher/widgets/settings/fanatika_panel_style.dart';

class SidePanelDialog extends StatelessWidget {
  final Widget child;
  final double width;
  final bool isRightSide;

  const SidePanelDialog({
    required this.child,
    this.width = 250,
    this.isRightSide = false,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final maxWidth = (screen.width - 36).clamp(1.0, double.infinity).toDouble();
    final panelWidth = width.clamp(1.0, maxWidth).toDouble();
    final panelHeight = FanatikaPanelStyle.panelHeight(screen, keyboard: keyboardHeight);
    return Align(
      alignment: isRightSide ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isRightSide ? 12 : 24, right: isRightSide ? 24 : 12),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: panelWidth,
            height: panelHeight,
            decoration: FanatikaPanelStyle.decoration,
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 14),
            child: Actions(
              actions: { BackIntent: BackAction(context) },
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
