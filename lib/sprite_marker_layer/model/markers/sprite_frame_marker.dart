import 'package:flutter/material.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/markers/sprite_marker.dart';

///Displays single frame sprite from a sprite atlas at the given position on the map.
class SpriteFrameMarker extends SpriteMarker<SpriteFrameMarker> {
  /// Index of the sprite in the atlas (0-based).
  /// The sprite information (size, position) comes from the SpriteAtlas.
  @override
  Alignment anchor;

  @override
  bool counterRotate;

  @override
  double scale;

  @override 
  double rotation;

  @override
  bool spriteSizeInMeters;

  @override
  int spriteIndex;
  SpriteFrameMarker({
    required super.id,
    required super.position,
    required this.spriteIndex,
    this.scale = 1.0,
    this.rotation = 0.0,
    super.onTap,
    this.counterRotate = false,
    this.anchor = Alignment.bottomCenter,
    super.isVisible = true,
    this.spriteSizeInMeters = false,
    super.transform = Offset.zero,
    super.onUpdate,
  });
  
}
