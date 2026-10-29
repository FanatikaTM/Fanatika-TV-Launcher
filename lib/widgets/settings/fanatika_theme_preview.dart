// Fanatika v2.3 — safe, remote-friendly preview; no settings saved before Apply.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/fanatika_tv_controls.dart';
import 'package:flauncher/widgets/settings/fanatika_title_font_page.dart';

class FanatikaThemePreview extends StatefulWidget {
  const FanatikaThemePreview({super.key});
  @override
  State<FanatikaThemePreview> createState() => _FanatikaThemePreviewState();
}

class _FanatikaThemePreviewState extends State<FanatikaThemePreview> {
  late String _style;
  late String _font;
  late double _size;
  late double _opacity;
  late String _position;
  late double _spacing;
  late double _shadow;
  late double _outline;
  late int _weight;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsService>();
    _style = s.fanatikaTitleStyle;
    _font = s.fanatikaTitleFont;
    _size = s.fanatikaHeroSize;
    _opacity = s.fanatikaHeroOpacity;
    _position = s.fanatikaHeroPlacement;
    _spacing = s.fanatikaTitleSpacing;
    _shadow = s.fanatikaTitleShadow;
    _outline = s.fanatikaTitleOutline;
    _weight = s.fanatikaTitleWeight;
  }

  Future<void> _chooseStyle() async {
    final selected = await FanatikaTvControls.choose<String>(context,
      title: 'Title style preview', values: const ['Classic','Bold','Cinema','Glass','Glow','Neon','Minimal','Wide','Shadow','Outline','Elegant','Sunset','Steel'],
      label: (v) => v, current: _style);
    if (selected != null && mounted) setState(() => _style = selected);
  }

  Future<void> _chooseFont() async {
    final selected = await FanatikaTvControls.choose<String>(context,
      title: 'Large title font preview',
      values: FanatikaTitleFontPage.fonts.map((entry) => entry.$1).toList(),
      label: (v) => FanatikaTitleFontPage.fonts.firstWhere((entry) => entry.$1 == v).$2,
      current: _font);
    if (selected != null && mounted) setState(() => _font = selected);
  }

  Future<void> _choosePreset() async {
    final selected = await FanatikaTvControls.choose<String>(context,
      title: 'Large title preset',
      values: const ['Cinema','Minimal','Neon','Outline','Classic'],
      label: (v) => v, current: _style);
    if (selected == null || !mounted) return;
    setState(() {
      _style = selected;
      switch (selected) {
        case 'Minimal': _font = 'sans-serif-light'; _size = 48; _weight = 300; _shadow = 0.5; _spacing = 0.0; break;
        case 'Neon': _font = 'sans-serif-medium'; _size = 68; _weight = 700; _shadow = 1.5; _spacing = 1.0; break;
        case 'Outline': _font = 'sans-serif-black'; _size = 64; _weight = 900; _outline = 2.0; _spacing = 0.0; break;
        case 'Classic': _font = 'serif'; _size = 58; _weight = 500; _shadow = 0.8; _spacing = 0.0; break;
        default: _font = 'sans-serif'; _size = 66; _weight = 800; _shadow = 1.0; _spacing = 0.35;
      }
    });
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
    await s.setFanatikaOption('fanatika_v2_title_spacing', _spacing);
    await s.setFanatikaOption('fanatika_v2_title_shadow', _shadow);
    await s.setFanatikaOption('fanatika_v2_title_outline', _outline);
    await s.setFanatikaOption('fanatika_v2_title_weight', _weight);
    await s.setFanatikaOption('fanatika_v2_title_style', _style);
    await s.setFanatikaOption('fanatika_v2_title_font', _font);
    await s.setFanatikaOption('fanatika_v2_hero_size', _size);
    await s.setFanatikaOption('fanatika_v2_hero_opacity', _opacity);
    await s.setFanatikaOption('fanatika_v2_hero_position', _position);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: SizedBox(
        width: media.width.clamp(440.0, 790.0) * 0.78,
        height: media.height.clamp(420.0, 790.0) * 0.82,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Text('Live title preview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Expanded(child: ListView(children: [
              Container(
                height: 140, alignment: _position == 'center' ? Alignment.center : Alignment.centerLeft,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF061127), Color(0xFF273F5B)]),
                  borderRadius: BorderRadius.circular(18)),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(
                  'Plex', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: _font == 'Automatic' ? null : _font, fontSize: _size, fontWeight: _weight >= 100 ? FontWeight.values[(_weight ~/ 100 - 1).clamp(0, 8).toInt()] : (_style == 'Minimal' ? FontWeight.w300 : FontWeight.w800),
                    letterSpacing: _spacing + (_style == 'Wide' ? 2.5 : 0.0),
                    color: Colors.white.withValues(alpha: _opacity),
                    shadows: _style == 'Outline' || _style == 'Steel'
                      ? [Shadow(color: Colors.black, offset: Offset(_outline,0)), Shadow(color: Colors.black, offset: Offset(-_outline,0)),
                         Shadow(color: Colors.black, offset: Offset(0,_outline)), Shadow(color: Colors.black, offset: Offset(0,-_outline))]
                      : _style == 'Glow' || _style == 'Neon'
                      ? [Shadow(color: Colors.lightBlueAccent, blurRadius: 18 * _shadow), Shadow(color: Colors.black, blurRadius: 30 * _shadow)]
                      : [Shadow(color: Colors.black87, blurRadius: 14 * _shadow)])))),
              const SizedBox(height: 8),
              FanatikaTvControls.action(icon: Icons.auto_awesome, title: 'Apply a ready-made title preset', onPressed: _choosePreset),
              FanatikaTvControls.action(icon: Icons.font_download_outlined, title: 'Font: $_font', onPressed: _chooseFont),
              FanatikaTvControls.action(icon: Icons.palette, title: 'Style: $_style', onPressed: _chooseStyle, autofocus: true),
              FanatikaTvControls.action(icon: Icons.format_size, title: 'Size: ${_size.toInt()} px', onPressed: _chooseSize),
              FanatikaTvControls.action(icon: Icons.format_align_left, title: 'Alignment: $_position', onPressed: _choosePosition),
              FanatikaTvControls.action(icon: Icons.text_fields, title: 'Letter spacing: ${_spacing.toStringAsFixed(1)}', onPressed: () async {
                final value = await FanatikaTvControls.choose<double>(context,
                  title: 'Large title character spacing', values: const [-1,0,0.35,1,2,3,5].map((n) => n.toDouble()).toList(),
                  label: (n) => n.toStringAsFixed(1), current: _spacing);
                if (value != null && mounted) setState(() => _spacing = value);
              }),
              FanatikaTvControls.action(icon: Icons.format_bold, title: 'Font weight: ${_weight == 0 ? 'Automatic' : _weight}', onPressed: () async {
                final value = await FanatikaTvControls.choose<int>(context,
                  title: 'Large title weight', values: const [0,300,400,500,600,700,800,900],
                  label: (n) => n == 0 ? 'Automatic' : '$n', current: _weight);
                if (value != null && mounted) setState(() => _weight = value);
              }),
              FanatikaTvControls.action(icon: Icons.border_outer, title: 'Outline width: ${_outline.toStringAsFixed(1)}', onPressed: () async {
                final value = await FanatikaTvControls.choose<double>(context,
                  title: 'Outline thickness (Outline/Steel styles)', values: const [0,0.5,1,1.5,2,3].map((n) => n.toDouble()).toList(),
                  label: (n) => n.toStringAsFixed(1), current: _outline);
                if (value != null && mounted) setState(() => _outline = value);
              }),
              FanatikaTvControls.action(icon: Icons.blur_on, title: 'Shadow: ${(_shadow * 100).round()}%', onPressed: () async {
                final value = await FanatikaTvControls.choose<double>(context,
                  title: 'Large title shadow strength', values: const [0,0.5,1,1.5,2].map((n) => n.toDouble()).toList(),
                  label: (n) => '${(n * 100).round()}%', current: _shadow);
                if (value != null && mounted) setState(() => _shadow = value);
              }),
              FanatikaTvControls.action(icon: Icons.opacity, title: 'Opacity: ${(_opacity*100).round()}%', onPressed: () async {
                final o = await FanatikaTvControls.choose<double>(context, title: 'Preview opacity',
                  values: const [0.4,0.5,0.6,0.7,0.8,0.9,1.0],
                  label: (v) => '${(v*100).round()}%', current: _opacity);
                if (o != null && mounted) setState(() => _opacity = o);
              }),
            ])),
            const Divider(),
            Row(children: [
              Expanded(child: FanatikaTvControls.action(icon: Icons.close, title: 'Cancel',
                onPressed: () => Navigator.of(context).pop(false))),
              Expanded(child: FanatikaTvControls.action(icon: Icons.check, title: 'Apply changes',
                onPressed: _apply)),
            ]),
          ]),
        ),
      ),
    );
  }
}
