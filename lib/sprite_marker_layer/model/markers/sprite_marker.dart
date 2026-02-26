import 'package:flutter/material.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_ref.dart';
import 'package:latlong2/latlong.dart' as coord;

/// SpriteMarker represents a marker that renders a sprite from a sprite atlas
/// at a specific geographic position.
 abstract class SpriteMarker<T extends SpriteMarker<T>> {

  /// Unique identifier for the marker.
  final String id;

  /// Geographic position of the marker.
  coord.LatLng position;

  /// Callback function that is called when the marker is tapped.
   VoidCallback? onTap;
  
  /// Whether the marker is visible.
  bool isVisible;

  SpriteMarker({
    required this.id,
    required this.position,
    this.onTap,
    required this.isVisible,
    this.transform = Offset.zero,
    this.onUpdate,
  });

    /// Index of the sprite in the atlas (0-based).
  int get spriteIndex;

  /// Returns the anchor alignment for the sprite.
  Alignment get anchor;

  /// Returns whether the sprite should counter-rotate against the map rotation.
  bool get counterRotate;

  /// Returns the scale factor for the sprite.
  double get scale;
  
  /// Returns the rotation in radians for the sprite.
  double get rotation;

  /// Whether the sprite size is defined in meters (true) or pixels (false).
  bool get spriteSizeInMeters;

  /// An offset to apply to the sprite's screen position.
  Offset transform;

  /// Called on each update tick with the delta time in milliseconds.
    final void Function(T marker, int deltaTimeMs)? onUpdate;

  SpriteRef get currentSpriteRef;
}
