// Low-resolution artwork sampling. Color is computed once when art is loaded,
// never in an animation frame or in response to a remote focus change.
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FanatikaArtworkColor {
  static const Color fallback = Color(0xFFD7E9F5);

  static Future<Color> sample(Uint8List bytes) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      if (bytes.isEmpty) return fallback;
      codec = await ui.instantiateImageCodec(bytes,
          targetWidth: 24, targetHeight: 24);
      final frame = await codec.getNextFrame();
      image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return fallback;
      final rgba = data.buffer.asUint8List();
      int r = 0, g = 0, b = 0, count = 0;
      for (var i = 0; i + 3 < rgba.length; i += 16) {
        if (rgba[i + 3] < 128) continue;
        final red = rgba[i], green = rgba[i + 1], blue = rgba[i + 2];
        if (red + green + blue < 75) continue;
        r += red; g += green; b += blue; count++;
      }
      if (count == 0) return fallback;
      final color = Color.fromARGB(255, r ~/ count, g ~/ count, b ~/ count);
      final hsl = HSLColor.fromColor(color);
      return hsl.withSaturation(hsl.saturation.clamp(0.28, 0.75).toDouble())
          .withLightness(hsl.lightness.clamp(0.43, 0.65).toDouble()).toColor();
    } catch (_) {
      return fallback;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
}
