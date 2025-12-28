import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as coord;

/// SpriteMarker represents a marker that renders a sprite from a sprite atlas
/// at a specific geographic position.
class SpriteMarker {
  /// The geographic position where the marker should be displayed.
  final coord.LatLng position;

  /// Index of the sprite in the atlas (0-based).
  /// The sprite information (size, position) comes from the SpriteAtlas.
  final int spriteIndex;

  /// Scale factor for rendering the sprite (1.0 = original size).
  final double scale;

  /// Rotation angle in radians. 0 means no rotation.
  final double rotation;

  /// Alpha transparency (0-255, where 255 is fully opaque).
  final int alpha;

  /// Color tint to apply to the sprite. The alpha channel of this color is ignored;
  /// use the [alpha] property for transparency.
  final Color color;

  /// Callback function that is called when the marker is tapped.
  final VoidCallback? onTap;

  /// Whether the marker should counter-rotate against camera rotation to stay upright.
  final bool rotate;

  const SpriteMarker({
    required this.position,
    required this.spriteIndex,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.alpha = 255,
    this.color = Colors.transparent,
    this.onTap,
    this.rotate = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpriteMarker &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          spriteIndex == other.spriteIndex &&
          scale == other.scale &&
          rotation == other.rotation &&
          alpha == other.alpha &&
          color == other.color &&
          rotate == other.rotate;

  @override
  int get hashCode =>
      position.hashCode ^
      spriteIndex.hashCode ^
      scale.hashCode ^
      rotation.hashCode ^
      alpha.hashCode ^
      color.hashCode ^
      rotate.hashCode;

  /// Creates a copy of this marker with some properties optionally overridden.
  SpriteMarker copyWith({
    coord.LatLng? position,
    int? spriteIndex,
    double? scale,
    double? rotation,
    int? alpha,
    Color? color,
    VoidCallback? onTap,
    bool? rotate,
  }) {
    return SpriteMarker(
      position: position ?? this.position,
      spriteIndex: spriteIndex ?? this.spriteIndex,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      alpha: alpha ?? this.alpha,
      color: color ?? this.color,
      onTap: onTap ?? this.onTap,
      rotate: rotate ?? this.rotate,
    );
  }
}
