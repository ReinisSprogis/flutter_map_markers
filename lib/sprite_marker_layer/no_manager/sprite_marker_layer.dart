import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas.dart';
import 'package:flutter_map_markers/sprite_marker_layer/no_manager/sprite_marker_render_layer.dart';

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

  const SpriteMarkerLayer({
    super.key,
    required this.spriteAtlas,
    required this.markers,
    this.cullMarkers = true,
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
      ),
    );
  }
}
