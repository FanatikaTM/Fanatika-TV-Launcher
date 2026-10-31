// Fanatika additions — GPL-3.0-or-later.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/settings/fanatika_panel_style.dart';

const mountainWallpapers = [
  ('01_Violet_Sunset.jpg', 'Violet Sunset'),
  ('02_Starlit_Alps.jpg', 'Starlit Alps'),
  ('03_Golden_Lake.jpg', 'Golden Lake'),
  ('04_Amber_Peaks.jpg', 'Amber Peaks'),
  ('05_Midnight_Blue.jpg', 'Midnight Blue'),
  ('06_Soft_Mountain_Dusk.jpg', 'Soft Mountain Dusk'),
  ('07_Alpine_Lake_Photoreal.jpg', 'Alpine lake — photorealistic'),
  ('08_Winter_Twilight_Photoreal.jpg', 'Winter twilight — photorealistic'),
];

class FanatikaMountainsDialog extends StatefulWidget {
  const FanatikaMountainsDialog({super.key});
  @override
  State<FanatikaMountainsDialog> createState() => _FanatikaMountainsDialogState();
}

class _FanatikaMountainsDialogState extends State<FanatikaMountainsDialog> {
  bool _busy = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final width = (screen.width * 0.83).clamp(280.0, 950.0).toDouble()
      .clamp(1.0, (screen.width - 24).clamp(1.0, double.infinity)).toDouble();
    final height = (screen.height * 0.85).clamp(280.0, 590.0).toDouble()
      .clamp(1.0, (screen.height - MediaQuery.viewInsetsOf(context).bottom - 24)
        .clamp(1.0, double.infinity)).toDouble();
    return Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      decoration: FanatikaPanelStyle.decoration,
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(children: [
            const Expanded(child: Text('Mountain wallpapers', style: TextStyle(fontSize: 24))),
            IconButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
          ]),
          const Text('Choose a wallpaper to apply. Includes photographic-style mountain scenery. The new landscapes are digitally generated, not location-identifiable photographs. Original Arc wallpaper settings are unchanged.'),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 16),
          Expanded(child: GridView.builder(
            itemCount: mountainWallpapers.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: width < 680 ? 2 : 3, childAspectRatio: 1.48, mainAxisSpacing: 14, crossAxisSpacing: 14),
            itemBuilder: (context, i) {
              final (file, label) = mountainWallpapers[i];
              final path = 'assets/mountains/$file';
              return OutlinedButton(
                onPressed: _busy ? null : () => _apply(path),
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                child: Column(children: [
                  Expanded(child: Image.asset(path, width: double.infinity, fit: BoxFit.cover)),
                  Padding(padding: const EdgeInsets.all(6), child: Text(label, maxLines: 1)),
                ]),
              );
            },
          )),
          if (_busy) const LinearProgressIndicator(),
        ]),
      ),
    ),
  );
  }
  Future<void> _apply(String assetPath) async {
    setState(() { _busy = true; _error = null; });
    try {
      await context.read<WallpaperService>().applyBundledMountain(assetPath);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = 'Unable to apply wallpaper: $e'; });
    }
  }
}
