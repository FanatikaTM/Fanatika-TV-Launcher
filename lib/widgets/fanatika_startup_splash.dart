// Short app-start transition. This is NOT a firmware boot animation.
import 'package:flutter/material.dart';

class FanatikaStartupSplash extends StatefulWidget {
  final Widget child;
  const FanatikaStartupSplash({super.key, required this.child});
  @override
  State<FanatikaStartupSplash> createState() => _FanatikaStartupSplashState();
}

class _FanatikaStartupSplashState extends State<FanatikaStartupSplash> {
  bool _show = true;
  @override
  Widget build(BuildContext context) => Stack(children: [
    widget.child,
    if (_show) Positioned.fill(child: IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1, end: 0),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
        onEnd: () { if (mounted) setState(() => _show = false); },
        builder: (_, opacity, __) => Opacity(opacity: opacity, child: ColoredBox(
          color: const Color(0xFF091426),
          child: Center(child: Transform.scale(
            scale: 1 + opacity * 0.14,
            child: Image.asset('assets/icon.png', width: 152, height: 152),
          )),
        )),
      ),
    )),
  ]);
}
