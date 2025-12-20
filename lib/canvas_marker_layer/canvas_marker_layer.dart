import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_render_layer.dart';

/// A layer that displays a list of [CanvasMarker]s on a FlutterMap using
class CanvasMarkerLayer extends StatelessWidget {
  /// The list of markers to display on the map.
  final List<CanvasMarker> markers;

  /// Whether to show debug marker bounds rectangles.
  final bool showDebugRect;

  //// Whether to show debug hit areas for markers.
  final bool showDebugHitArea;

  /// If you perform hit testing, this determines whether the hit marker is drawn last.
  /// Ensures the hit marker is always on top of other markers.
  final bool drawHitMarkerLast;

  /// Whether to cull markers that are outside the visible area.
  final bool cullMarkers;

  const CanvasMarkerLayer({
    super.key,
    required this.markers,
    this.showDebugRect = false,
    this.showDebugHitArea = false,
    this.drawHitMarkerLast = false,
    this.cullMarkers = true,
  });

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: CanvasMarkerRenderLayer(
        markers: markers,
        camera: camera,
        showDebugRect: showDebugRect,
        showDebugHitArea: showDebugHitArea,
        drawHitMarkerLast: drawHitMarkerLast,
        cullMarkers: cullMarkers,
      ),
    );
  }
}
