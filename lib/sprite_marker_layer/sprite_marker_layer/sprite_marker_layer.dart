import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/sprite_marker_layer/marker_core.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/markers/sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas.dart';
import 'package:flutter_map_markers/sprite_marker_layer/sprite_marker_layer/sprite_marker_layer_leaf.dart';

/// A layer that displays a list of [SpriteMarker]s on a FlutterMap using
/// efficient sprite atlas rendering for optimal performance with many markers.
class SpriteMarkerLayer extends StatelessWidget {
  /// The sprite atlas containing the image and sprite definitions.
  final SpriteAtlas spriteAtlas;

  /// The list of sprite markers to display on the map.
  final List<SpriteMarker> markers;

  /// Whether to cull markers that are outside the visible area.
  /// Defaults to true for better performance.
  final bool cullMarkers;

  /// If true, interprets the sprite's pixel dimensions as meters.
  ///
  /// Example: a 48x48 sprite will be rendered as a 48m x 48m object on the map
  /// at the marker's latitude and current zoom.
  ///
  /// When false (default), [SpriteMarker.scale] behaves like a traditional
  /// pixel scale factor (zoom-independent).
  final bool spriteSizeInMeters;

  final AnimationPlayer? animationPlayer;
  const SpriteMarkerLayer({
    super.key,
    required this.spriteAtlas,
    required this.markers,
    this.cullMarkers = true,
    this.spriteSizeInMeters = false,
    this.animationPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: SpriteMarkerRenderLayer(
        spriteAtlas: spriteAtlas,
        markers: markers,
        camera: camera,
        cullMarkers: cullMarkers,
        spriteSizeInMeters: spriteSizeInMeters,
        animationPlayer: animationPlayer
      ),
    );
  }
}
