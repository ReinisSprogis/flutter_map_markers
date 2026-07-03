import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_layer.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as coord;

void main() {
  testWidgets('CanvasMarkerLayer builds with markers', (
    WidgetTester tester,
  ) async {
    final marker = CanvasMarker(
      position: coord.LatLng(1, 2),
      painter:
          (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: MapOptions(
              initialCenter: coord.LatLng(1, 2),
              initialZoom: 10,
              // Add dummy nonRotatedSize if required by your flutter_map version
            ),
            children: [
              CanvasMarkerLayer(markers: [marker]),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(CanvasMarkerLayer), findsOneWidget);
  });
}
