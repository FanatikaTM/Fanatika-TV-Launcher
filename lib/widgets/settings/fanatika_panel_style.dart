// Shared Quick Menu appearance for every Fanatika settings window.
// Keep the home-screen blue top bar separate from this modal theme.
import 'package:flutter/material.dart';

class FanatikaPanelStyle {
  static const Color base = Color(0xFF1E1E1E);
  static const Color tile = Color(0xFF303030);
  static const Color focusedTile = Color(0xFF145EA8);
  static const Color border = Colors.white24;

  static BoxDecoration get decoration => BoxDecoration(
    borderRadius: BorderRadius.circular(30),
    border: Border.all(color: border, width: 1),
    gradient: const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF242424), base, Color(0xFF191919)],
    ),
    boxShadow: const [BoxShadow(
      color: Colors.black54, blurRadius: 30, offset: Offset(0, 8))],
  );

  static double panelWidth(Size size, {double maximum = 520}) {
    final available = (size.width - 36).clamp(1.0, double.infinity).toDouble();
    return (size.width * 0.42).clamp(420.0, maximum).toDouble()
      .clamp(1.0, available).toDouble();
  }

  static double panelHeight(Size size, {double keyboard = 0}) {
    final available = (size.height - keyboard - 24)
        .clamp(1.0, double.infinity).toDouble();
    return (size.height * 0.91).clamp(470.0, 685.0).toDouble()
        .clamp(1.0, available).toDouble();
  }
}

class FanatikaPanelHeader extends StatelessWidget {
  const FanatikaPanelHeader({super.key, required this.title});
  final String title;
  @override Widget build(BuildContext context) => Column(children: [
    Row(children: [
      IconButton(
        tooltip: 'Back', icon: const Icon(Icons.arrow_back, color: Colors.white70),
        onPressed: () {
          final nested = Navigator.of(context);
          if (nested.canPop()) { nested.pop(); }
          else { Navigator.of(context, rootNavigator: true).maybePop(); }
        }),
      const SizedBox(width: 4),
      Expanded(child: Text(title, maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 21,
          fontWeight: FontWeight.w700))),
    ]),
    const Divider(color: Colors.white24, height: 12),
  ]);
}
