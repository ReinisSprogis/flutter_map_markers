import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/markers/sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas.dart';
import 'package:flutter_map_markers/sprite_marker_layer/sprite_marker_layer/sprite_marker_layer_render_box.dart';

class SpriteMarkerRenderLayer extends LeafRenderObjectWidget {
  final SpriteAtlas spriteAtlas;
  final List<SpriteMarker> markers;
  final MapCamera camera;
  final bool cullMarkers;
  final bool spriteSizeInMeters;

  const SpriteMarkerRenderLayer({
    super.key,
    required this.spriteAtlas,
    required this.markers,
    required this.camera,
    this.cullMarkers = true,
    this.spriteSizeInMeters = false,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSpriteMarkerLayer(
      spriteAtlas: spriteAtlas,
      markers: markers,
      camera: camera,
      cullMarkers: cullMarkers,
      spriteSizeInMeters: spriteSizeInMeters,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderSpriteMarkerLayer renderObject,
  ) {
    renderObject
      ..spriteAtlas = spriteAtlas
      ..markers = markers
      ..camera = camera
      ..cullMarkers = cullMarkers
      ..spriteSizeInMeters = spriteSizeInMeters;
  }
}
