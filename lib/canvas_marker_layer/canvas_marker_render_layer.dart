import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/render_canvas_marker_layer.dart';

class CanvasMarkerRenderLayer extends LeafRenderObjectWidget {
  final List<CanvasMarker> markers;
  final MapCamera camera;
  final int? lastSelectedMarkerIndex;
  final bool showDebugRect;
  final bool showDebugHitArea;
  final bool cullMarkers;
  final bool drawHitMarkerLast;

  const CanvasMarkerRenderLayer({
    super.key,
    required this.markers,
    required this.camera,
    this.lastSelectedMarkerIndex,
    this.showDebugRect = false,
    this.showDebugHitArea = false,
    this.cullMarkers = true,
    this.drawHitMarkerLast = false,
  });

  @override
  RenderCanvasMarkerLayer createRenderObject(BuildContext context) {
    return RenderCanvasMarkerLayer(
      markers: markers,
      camera: camera,
      lastSelectedMarkerIndex: lastSelectedMarkerIndex,
      paintDebugRect: showDebugRect,
      paintDebugHitArea: showDebugHitArea,
      cullMarkers: cullMarkers,
      drawHitMarkerLast: drawHitMarkerLast,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCanvasMarkerLayer renderObject,
  ) {
    renderObject
      ..markers = markers
      ..camera = camera
      ..lastSelectedMarkerIndex = lastSelectedMarkerIndex
      ..paintDebugRect = showDebugRect
      ..paintDebugHitArea = showDebugHitArea
      ..cullMarkers = cullMarkers
      ..drawHitMarkerLast = drawHitMarkerLast;
  }
}
