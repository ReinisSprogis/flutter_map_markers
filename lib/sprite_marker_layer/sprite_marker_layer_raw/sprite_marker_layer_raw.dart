import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_marker_manager.dart';
import 'package:flutter_map_markers/sprite_marker_layer/sprite_marker_layer_raw/sprite_marker_layer_raw_leaf.dart';

class SpriteMarkerLayerRaw extends StatelessWidget {
  final SpriteMarkerManager markerManager;
  const SpriteMarkerLayerRaw({super.key, required this.markerManager});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    // Always forward the camera; the manager will skip rebuilds when values
    // are unchanged.
    markerManager.updateCamera(camera);

    return MobileLayerTransformer(
      child: SpriteMarkerLayerRawLeaf(markerManager: markerManager),
    );
  }
}
