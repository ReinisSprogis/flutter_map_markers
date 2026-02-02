import 'dart:ui' as ui;

/// Information about a single sprite within a sprite atlas.
class SpriteInfo {
  /// Creates sprite information with position and size within an atlas.
  const SpriteInfo({
    this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Optional unique identifier for the sprite.
  final String? id;

  /// X position of the sprite in the atlas.
  final double x;

  /// Y position of the sprite in the atlas.
  final double y;

  /// Width of the sprite.
  final double width;

  /// Height of the sprite.
  final double height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpriteInfo &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          id == other.id;

  @override
  int get hashCode =>
      x.hashCode ^ y.hashCode ^ width.hashCode ^ height.hashCode ^ (id?.hashCode ?? 0);

  @override
  String toString() =>
      'SpriteInfo(x: $x, y: $y, width: $width, height: $height, id: $id)';
}

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
    required double spriteWidth,
    required double spriteHeight,
  }) {
    final sprites = List.generate(spriteCount, (index) {
      return SpriteInfo(
        x: index * spriteWidth,
        y: 0,
        width: spriteWidth,
        height: spriteHeight,
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
    required double spriteWidth,
    required double spriteHeight,
  }) {
    final sprites = List.generate(spriteCount, (index) {
      return SpriteInfo(
        x: 0,
        y: index * spriteHeight,
        width: spriteWidth,
        height: spriteHeight,
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
    required double spriteWidth,
    required double spriteHeight,
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
