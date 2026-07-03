import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_ref.dart';

void main() {
  group('SpriteRef', () {
    test('empty SpriteRef is empty', () {
      expect(SpriteRef.empty.isEmpty, isTrue);
      expect(SpriteRef(-1, 0).isEmpty, isTrue);
      expect(SpriteRef(0, -1).isEmpty, isTrue);
      expect(SpriteRef(-1, -1).isEmpty, isTrue);
    });

    test('non-empty SpriteRef is not empty', () {
      expect(SpriteRef(0, 0).isEmpty, isFalse);
      expect(SpriteRef(1, 2).isEmpty, isFalse);
    });

    test('equality and hashCode', () {
      final a = SpriteRef(1, 2);
      final b = SpriteRef(1, 2);
      final c = SpriteRef(2, 1);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
