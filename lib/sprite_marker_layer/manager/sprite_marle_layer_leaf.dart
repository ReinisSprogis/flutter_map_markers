import 'package:flutter/widgets.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_marker_manager.dart';
import 'package:flutter_map_markers/sprite_marker_layer/manager/sprite_marker_render_box.dart';

class SpriteMarkerLayerLeaf extends LeafRenderObjectWidget {
  final SpriteMarkerManager markerManager;
  const SpriteMarkerLayerLeaf({super.key, required this.markerManager});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return SpriteMarkerRenderBox(markerManager: markerManager);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant SpriteMarkerRenderBox renderObject,
  ) {
    renderObject.markerManager = markerManager;
  }
}
