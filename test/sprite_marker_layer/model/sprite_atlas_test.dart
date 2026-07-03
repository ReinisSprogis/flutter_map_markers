import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_info.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class FakeImage implements ui.Image {
  @override
  int get width => 128;
  @override
  int get height => 64;
  @override
  void dispose() {}
  @override
  bool get debugDisposed => false;
  @override
  Future<ByteData?> toByteData({ui.ImageByteFormat? format}) async => null;
  @override
  ui.Color getColor(int x, int y) => throw UnimplementedError();
  @override
  int get hashCode => 0;
  @override
  bool operator ==(Object other) => identical(this, other);
  @override
  ui.Image clone() => this;
  @override
  ui.ColorSpace get colorSpace => throw UnimplementedError();
  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() => null;
  @override
  bool isCloneOf(ui.Image other) => false;
}

void main() {
  group('SpriteAtlas', () {
    final fakeImage = FakeImage();
    final spriteInfo = SpriteInfo(
      id: 'id',
      x: 0,
      y: 0,
      width: 64,
      height: 64,
      sourceWidth: 64,
      sourceHeight: 64,
      offsetX: 0,
      offsetY: 0,
    );
    final atlas = SpriteAtlas(image: fakeImage, sprites: [spriteInfo]);

    test('properties are set correctly', () {
      expect(atlas.image, equals(fakeImage));
      expect(atlas.sprites, contains(spriteInfo));
    });

    test('horizontal factory creates correct sprites', () {
      final horizontalAtlas = SpriteAtlas.horizontal(
        image: fakeImage,
        spriteCount: 2,
        spriteWidth: 64,
        spriteHeight: 64,
      );
      expect(horizontalAtlas.sprites.length, 2);
      expect(horizontalAtlas.sprites[0].x, 0);
      expect(horizontalAtlas.sprites[1].x, 64);
    });
  });
}
