// Fanatika additions — GPL-3.0-or-later.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/wallpaper_service.dart';

const mountainWallpapers = [
  ('01_Violet_Sunset.jpg', 'Violet Sunset'),
  ('02_Starlit_Alps.jpg', 'Starlit Alps'),
  ('03_Golden_Lake.jpg', 'Golden Lake'),
  ('04_Amber_Peaks.jpg', 'Amber Peaks'),
  ('05_Midnight_Blue.jpg', 'Midnight Blue'),
  ('06_Soft_Mountain_Dusk.jpg', 'Soft Mountain Dusk'),
  ('07_Bansko_Pirin.jpg', 'Pirin Panorama (illustration)'),
  ('08_Pirin_River.jpg', 'Pirin Mountain River (illustration)'),
  ('09_Mountain_River.jpg', 'Autumn Mountain River (illustration)'),
  ('10_Bansko_Winter.jpg', 'Bansko-inspired Winter (illustration)'),
  ('11_Pirin_Alpine_Lake.jpg', 'Pirin Alpine Lake (illustration)'),
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
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 950,
      height: 590,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(children: [
            const Expanded(child: Text('Mountain wallpapers', style: TextStyle(fontSize: 24))),
            IconButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
          ]),
          const Text('Choose a wallpaper to apply. The Pirin/Bansko-themed illustrations are artistic interpretations, not location photographs. Other Arc wallpaper settings are unchanged.'),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 16),
          Expanded(child: GridView.builder(
            itemCount: mountainWallpapers.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 1.48, mainAxisSpacing: 14, crossAxisSpacing: 14),
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
