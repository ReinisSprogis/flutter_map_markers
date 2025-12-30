import 'dart:ui';

import 'package:flutter/services.dart';

class SpriteUtil {
    /// Load atlas image from asset path
  static Future<Image> loadAtlasImageFromAssets(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final Codec codec = await instantiateImageCodec(bytes);
    final FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }
}