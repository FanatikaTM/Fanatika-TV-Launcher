// Fanatika v2.3 — safe, remote-friendly preview; no settings saved before Apply.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/fanatika_tv_controls.dart';

class FanatikaThemePreview extends StatefulWidget {
  const FanatikaThemePreview({super.key});
  @override
  State<FanatikaThemePreview> createState() => _FanatikaThemePreviewState();
}

class _FanatikaThemePreviewState extends State<FanatikaThemePreview> {
  late String _style;
  late double _size;
  late double _opacity;
  late String _position;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsService>();
    _style = s.fanatikaTitleStyle;
    _size = s.fanatikaHeroSize;
    _opacity = s.fanatikaHeroOpacity;
    _position = s.fanatikaHeroPlacement;
  }

  Future<void> _chooseStyle() async {
    final selected = await FanatikaTvControls.choose<String>(context,
      title: 'Title style preview', values: const ['Classic','Bold','Cinema','Glass','Glow'],
      label: (v) => v, current: _style);
    if (selected != null && mounted) setState(() => _style = selected);
  }

  Future<void> _chooseSize() async {
    final selected = await FanatikaTvControls.choose<double>(context,
      title: 'Title size preview', values: const [28,36,44,52,60,72,84,96].map((x) => x.toDouble()).toList(),
      label: (v) => '${v.toInt()} px', current: _size);
    if (selected != null && mounted) setState(() => _size = selected);
  }

  Future<void> _choosePosition() async {
    final selected = await FanatikaTvControls.choose<String>(context, title: 'Title alignment',
      values: const ['left', 'center'], label: (v) => v, current: _position);
    if (selected != null && mounted) setState(() => _position = selected);
  }

  Future<void> _apply() async {
    final s = context.read<SettingsService>();
    await s.setFanatikaOption('fanatika_v2_title_style', _style);
    await s.setFanatikaOption('fanatika_v2_hero_size', _size);
    await s.setFanatikaOption('fanatika_v2_hero_opacity', _opacity);
    await s.setFanatikaOption('fanatika_v2_hero_position', _position);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Preview title appearance'),
    content: SizedBox(width: 470, height: 440, child: Column(children: [
      Container(
        height: 175, padding: const EdgeInsets.all(14),
        alignment: _position == 'center' ? Alignment.center : Alignment.centerLeft,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF061127), Color(0xFF273F5B)]),
          borderRadius: BorderRadius.circular(18)),
        child: Text('Plex', maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: _size, fontWeight: _style == 'Classic' ? FontWeight.w600 : FontWeight.w800,
            letterSpacing: _style == 'Bold' ? 1.4 : 0.3,
            color: Colors.white.withValues(alpha: _opacity),
            shadows: _style == 'Glow'
              ? const [Shadow(color: Colors.lightBlueAccent, blurRadius: 18), Shadow(color: Colors.black, blurRadius: 30)]
              : const [Shadow(color: Colors.black87, blurRadius: 14)])),
      ),
      const SizedBox(height: 14),
      FanatikaTvControls.action(icon: Icons.palette, title: 'Style: $_style', onPressed: _chooseStyle),
      FanatikaTvControls.action(icon: Icons.format_size, title: 'Size: ${_size.toInt()} px', onPressed: _chooseSize),
      FanatikaTvControls.action(icon: Icons.format_align_left, title: 'Alignment: $_position', onPressed: _choosePosition),
      FanatikaTvControls.action(icon: Icons.opacity, title: 'Opacity: ${(_opacity*100).round()}%', onPressed: () async {
        final o = await FanatikaTvControls.choose<double>(context, title: 'Preview opacity',
          values: const [0.4,0.5,0.6,0.7,0.8,0.9,1.0],
          label: (v) => '${(v*100).round()}%', current: _opacity);
        if (o != null && mounted) setState(() => _opacity = o);
      }),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      FilledButton(onPressed: _apply, child: const Text('Apply changes'))],
  );
}
