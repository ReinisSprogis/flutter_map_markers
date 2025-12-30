import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as coord;

/// SpriteMarker represents a marker that renders a sprite from a sprite atlas
/// at a specific geographic position.
 abstract class SpriteMarker {
  final String id;
  coord.LatLng position;
  double scale;
  double rotation;
  bool rotate;
  /// Alpha transparency (0-255, where 255 is fully opaque).
  int alpha;
  /// Color tint to apply to the sprite. The alpha channel of this color is ignored;
  /// use the [alpha] property for transparency.
  Color color;
  /// Callback function that is called when the marker is tapped.
   VoidCallback? onTap;
  /// Alignment anchor for the sprite. Defaults to center.
  Alignment anchor;
  
  /// Index of the sprite in the atlas (0-based).
  int get spriteIndex;

  SpriteMarker({
    required this.id,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.rotate = false,
    this.alpha = 255,
    this.color = Colors.transparent,
    this.onTap,
    this.anchor = Alignment.center,

  });
}
