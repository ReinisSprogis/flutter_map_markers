import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas_set.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_info.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_ref.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class FakeImage implements ui.Image {
  @override
  int get width => 1;
  @override
  int get height => 1;
  @override
  void dispose() {}
  @override
  bool get debugDisposed => false;
  @override
  Future<ByteData?> toByteData({ui.ImageByteFormat? format}) async => null;
  @override
  ui.Color getColor(int x, int y) => throw UnimplementedError();
  @override
  int get hashCode => super.hashCode;
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
  group('SpriteAtlasSet', () {
    final fakeImage = FakeImage();
    final spriteInfo = SpriteInfo(
      id: 'id',
      x: 0,
      y: 0,
      width: 1,
      height: 1,
      sourceWidth: 1,
      sourceHeight: 1,
      offsetX: 0,
      offsetY: 0,
    );
    final atlas = SpriteAtlas(image: fakeImage, sprites: [spriteInfo]);
    final set = SpriteAtlasSet([atlas]);

    test('atlas returns correct atlas', () {
      expect(set.atlas(0), equals(atlas));
    });

    test('imageOf returns correct image', () {
      expect(set.imageOf(0), equals(fakeImage));
    });

    test('spriteOf returns correct sprite', () {
      final ref = SpriteRef(0, 0);
      expect(set.spriteOf(ref), equals(spriteInfo));
    });
  });
}
