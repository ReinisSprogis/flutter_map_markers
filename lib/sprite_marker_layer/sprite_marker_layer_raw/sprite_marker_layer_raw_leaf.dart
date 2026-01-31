import 'package:flutter/widgets.dart';
import 'package:flutter_map_markers/sprite_marker_layer/sprite_marker_layer_raw/sprite_marker_manager.dart';
import 'package:flutter_map_markers/sprite_marker_layer/sprite_marker_layer_raw/sprite_marker_layer_raw_render_box.dart';

class SpriteMarkerLayerRawLeaf extends LeafRenderObjectWidget {
  final SpriteMarkerManager markerManager;
  const SpriteMarkerLayerRawLeaf({super.key, required this.markerManager});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return SpriteMarkerLayerRawRenderBox(markerManager: markerManager);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant SpriteMarkerLayerRawRenderBox renderObject,
  ) {
    renderObject.markerManager = markerManager;
  }
}
