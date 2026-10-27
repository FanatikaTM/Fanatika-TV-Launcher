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
          color: Colors.black,
          child: const Center(child: Icon(
            Icons.tv_rounded, color: Color(0xFFE4ECF5), size: 96,
          )),
        )),
      ),
    )),
  ]);
}
