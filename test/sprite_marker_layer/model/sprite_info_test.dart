import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_info.dart';

void main() {
  group('SpriteInfo', () {
    test('equality and hashCode', () {
      const info1 = SpriteInfo(
        id: 'a',
        x: 1,
        y: 2,
        width: 10,
        height: 20,
        sourceWidth: 10,
        sourceHeight: 20,
        offsetX: 0,
        offsetY: 0,
      );
      const info2 = SpriteInfo(
        id: 'a',
        x: 1,
        y: 2,
        width: 10,
        height: 20,
        sourceWidth: 10,
        sourceHeight: 20,
        offsetX: 0,
        offsetY: 0,
      );
      const info3 = SpriteInfo(
        id: 'b',
        x: 2,
        y: 3,
        width: 11,
        height: 21,
        sourceWidth: 11,
        sourceHeight: 21,
        offsetX: 1,
        offsetY: 1,
      );
      expect(info1, equals(info2));
      expect(info1.hashCode, equals(info2.hashCode));
      expect(info1, isNot(equals(info3)));
    });

    test('properties are set correctly', () {
      const info = SpriteInfo(
        id: 'id',
        x: 5,
        y: 6,
        width: 7,
        height: 8,
        sourceWidth: 9,
        sourceHeight: 10,
        offsetX: 11,
        offsetY: 12,
      );
      expect(info.id, 'id');
      expect(info.x, 5);
      expect(info.y, 6);
      expect(info.width, 7);
      expect(info.height, 8);
      expect(info.sourceWidth, 9);
      expect(info.sourceHeight, 10);
      expect(info.offsetX, 11);
      expect(info.offsetY, 12);
    });
  });
}
