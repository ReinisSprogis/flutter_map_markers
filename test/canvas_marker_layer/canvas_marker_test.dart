import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:latlong2/latlong.dart' as coord;
import 'package:flutter/material.dart';

void main() {
  group('CanvasMarker', () {
    test('toJson returns correct map', () {
      final marker = CanvasMarker(
        position: coord.LatLng(1, 2),
        painter:
            (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {},
      );
      final json = marker.toJson();
      expect(json['lat'], 1);
      expect(json['lng'], 2);
    });

    test('copyWith copies and overrides properties', () {
      final marker = CanvasMarker(
        position: coord.LatLng(1, 2),
        painter:
            (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {},
      );
      final newMarker = marker.copyWith(position: coord.LatLng(3, 4));
      expect(newMarker.position.latitude, 3);
      expect(newMarker.position.longitude, 4);
    });
  });
}
