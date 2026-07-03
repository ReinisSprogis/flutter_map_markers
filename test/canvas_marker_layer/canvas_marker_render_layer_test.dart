import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_render_layer.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as coord;
import 'package:flutter/material.dart';

void main() {
  testWidgets('CanvasMarkerRenderLayer creates RenderObject', (
    WidgetTester tester,
  ) async {
    final marker = CanvasMarker(
      position: coord.LatLng(1, 2),
      painter:
          (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {},
    );
    final camera = MapCamera(
      crs: const Epsg3857(),
      center: coord.LatLng(1, 2),
      zoom: 10,
      rotation: 0,
      size: const Size(100, 100),
      nonRotatedSize: const Size(100, 100),
      pixelOrigin: Offset.zero,
    );
    final widget = CanvasMarkerRenderLayer(
      markers: [marker],
      camera: camera,
      showDebugRect: false,
      showDebugHitArea: false,
      cullMarkers: true,
      drawHitMarkerLast: false,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
    expect(find.byType(CanvasMarkerRenderLayer), findsOneWidget);
  });
}
