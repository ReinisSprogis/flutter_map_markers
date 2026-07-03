import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/markers/sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_ref.dart';
import 'package:latlong2/latlong.dart' as coord;
import 'package:flutter/material.dart';

class TestSpriteMarker extends SpriteMarker<TestSpriteMarker> {
  @override
  SpriteRef get currentSpriteRef => const SpriteRef(0, 0);

  @override
  bool get spriteSizeInMeters => false;
  @override
  int get spriteIndex => 0;
  @override
  Alignment get anchor => Alignment.center;
  @override
  bool get counterRotate => false;
  @override
  double get scale => 1.0;
  @override
  double get rotation => 0.0;

  TestSpriteMarker({
    required String id,
    required coord.LatLng position,
    VoidCallback? onTap,
    bool isVisible = true,
    Offset transform = Offset.zero,
    void Function(TestSpriteMarker, int)? onUpdate,
  }) : super(
         id: id,
         position: position,
         onTap: onTap,
         isVisible: isVisible,
         transform: transform,
         onUpdate: onUpdate,
       );
}

void main() {
  group('SpriteMarker', () {
    test('properties and construction', () {
      final marker = TestSpriteMarker(id: 'id', position: coord.LatLng(1, 2));
      expect(marker.id, 'id');
      expect(marker.position.latitude, 1);
      expect(marker.position.longitude, 2);
      expect(marker.isVisible, isTrue);
      expect(marker.transform, Offset.zero);
    });

    test('onTap callback', () {
      bool tapped = false;
      final marker = TestSpriteMarker(
        id: 'id',
        position: coord.LatLng(1, 2),
        onTap: () => tapped = true,
      );
      marker.onTap?.call();
      expect(tapped, isTrue);
    });
  });
}
