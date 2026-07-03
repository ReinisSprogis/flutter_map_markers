import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_markers/marker_presets/marker_presets.dart';
import 'package:flutter/material.dart';

void main() {
  group('MarkerPresets', () {
    test('ballMarkerPath returns valid path and center', () {
      final (path, arcCenter) = MarkerPresets.ballMarkerPath(
        const Offset(0, 0),
      );
      expect(path, isA<Path>());
      expect(arcCenter, isA<Offset>());
    });

    test('raindropMarkerPath returns valid path and center', () {
      final (path, center) = MarkerPresets.raindropMarkerPath(
        const Offset(0, 0),
      );
      expect(path, isA<Path>());
      expect(center, isA<Offset>());
    });
  });
}
