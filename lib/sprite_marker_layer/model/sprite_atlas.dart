import 'dart:ui' as ui;

import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_info.dart';


/// A sprite atlas containing an image and information about sprites within it.
class SpriteAtlas {
  /// Creates a sprite atlas with an image and sprite definitions.
  const SpriteAtlas({required this.image, required this.sprites});

  /// The atlas image containing all sprites.
  final ui.Image image;

  /// List of sprite information defining where each sprite is located in the atlas.
  final List<SpriteInfo> sprites;

  /// Creates a sprite atlas for horizontally arranged sprites of equal size.
  ///
  /// All sprites are arranged side by side in a single row.
  /// Example: For a 128x64 image with 2 sprites of 64x64 each.
  factory SpriteAtlas.horizontal({
    required ui.Image image,
    required int spriteCount,
    required int spriteWidth,
    required int spriteHeight,
  }) {
    final sprites = List.generate(spriteCount, (index) {
      return SpriteInfo(
        x: index * spriteWidth,
        y: 0,
        width: spriteWidth,
        height: spriteHeight,
        sourceWidth: spriteWidth,
        sourceHeight: spriteHeight,
        offsetX: 0,
        offsetY: 0,
      );
    });

    return SpriteAtlas(image: image, sprites: sprites);
  }

  /// Creates a sprite atlas for vertically arranged sprites of equal size.
  ///
  /// All sprites are arranged in a single column.
  /// Example: For a 64x128 image with 2 sprites of 64x64 each.
  factory SpriteAtlas.vertical({
    required ui.Image image,
    required int spriteCount,
    required int spriteWidth,
    required int spriteHeight,
  }) {
    final sprites = List.generate(spriteCount, (index) {
      return SpriteInfo(
        x: 0,
        y: index * spriteHeight,
        width: spriteWidth,
        height: spriteHeight,
        sourceWidth: spriteWidth,
        sourceHeight: spriteHeight,
        offsetX: 0,
        offsetY: 0,
      );
    });

    return SpriteAtlas(image: image, sprites: sprites);
  }

  /// Creates a sprite atlas for grid-arranged sprites of equal size.
  ///
  /// Sprites are arranged in rows and columns, indexed left-to-right, top-to-bottom.
  /// Example: For a 4x4 grid, sprite indices are:
  /// ```
  /// 0  1  2  3
  /// 4  5  6  7
  /// 8  9  10 11
  /// 12 13 14 15
  /// ```
  factory SpriteAtlas.grid({
    required ui.Image image,
    required int columns,
    required int rows,
    required int spriteWidth,
    required int spriteHeight,
  }) {
    final sprites = <SpriteInfo>[];

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        sprites.add(
          SpriteInfo(
            x: col * spriteWidth,
            y: row * spriteHeight,
            width: spriteWidth,
            height: spriteHeight,
            sourceWidth: spriteWidth,
            sourceHeight: spriteHeight,
            offsetX: 0,
            offsetY: 0,
          ),
        );
      }
    }

    return SpriteAtlas(image: image, sprites: sprites);
  }

  /// Creates a sprite atlas with custom sprite positions and sizes.
  ///
  /// Use this for sprites that have different sizes or irregular arrangements.
  factory SpriteAtlas.custom({
    required ui.Image image,
    required List<SpriteInfo> sprites,
  }) {
    return SpriteAtlas(image: image, sprites: sprites);
  }

  /// Gets the sprite information for the given index.
  ///
  /// Throws [RangeError] if the index is out of bounds.
  SpriteInfo getSpriteInfo(int index) {
    if (index < 0 || index >= sprites.length) {
      throw RangeError.index(index, sprites, 'sprites');
    }
    return sprites[index];
  }

  /// The number of sprites in this atlas.
  int get spriteCount => sprites.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpriteAtlas &&
          runtimeType == other.runtimeType &&
          image == other.image &&
          sprites == other.sprites;

  @override
  int get hashCode => image.hashCode ^ sprites.hashCode;
}
