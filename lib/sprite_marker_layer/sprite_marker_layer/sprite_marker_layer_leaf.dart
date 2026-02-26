import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/sprite_marker_layer/marker_core.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/markers/sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas_set.dart';
import 'package:flutter_map_markers/sprite_marker_layer/sprite_marker_layer/sprite_marker_layer_render_box.dart';

class SpriteMarkerRenderLayer extends LeafRenderObjectWidget {
  final SpriteAtlasSet atlases;
  final List<SpriteMarker> markers;
  final MapCamera camera;
  final bool cullMarkers;
  final bool spriteSizeInMeters;
  final AnimationPlayer? animationPlayer;
  const SpriteMarkerRenderLayer({
    super.key,
    required this.atlases,
    required this.markers,
    required this.camera,
    this.cullMarkers = true,
    this.spriteSizeInMeters = false,
    this.animationPlayer,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSpriteMarkerLayer(
      atlasSets: atlases,
      markers: markers,
      camera: camera,
      cullMarkers: cullMarkers,
      spriteSizeInMeters: spriteSizeInMeters,
      animationPlayer: animationPlayer,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderSpriteMarkerLayer renderObject,
  ) {
    renderObject
      ..atlasSets = atlases
      ..markers = markers
      ..camera = camera
      ..cullMarkers = cullMarkers
      ..animationPlayer = animationPlayer;
  }
}
