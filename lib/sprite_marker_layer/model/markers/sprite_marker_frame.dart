import 'package:flutter/material.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/markers/sprite_marker.dart';

class SpriteMarkerFrame extends SpriteMarker {
  /// Index of the sprite in the atlas (0-based).
  /// The sprite information (size, position) comes from the SpriteAtlas.
  @override
  final int spriteIndex;

  SpriteMarkerFrame({
    required super.id,
    required super.position,
    required this.spriteIndex,
    super.scale = 1.0,
    super.rotation = 0.0,
    super.alpha = 255,
    super.color = Colors.transparent,
    super.onTap,
    super.rotate = false,
    super.anchor = Alignment.center,
  });
}
