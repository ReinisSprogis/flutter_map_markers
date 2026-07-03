/// Information about a single sprite within a sprite atlas.
class SpriteInfo {
  /// Creates sprite information with position and size within an atlas.
  const SpriteInfo({
    this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.offsetX,
    required this.offsetY,
  });

  /// Optional unique identifier for the sprite.
  final String? id;

  /// X position of the sprite in the atlas.
  final int x;

  /// Y position of the sprite in the atlas.
  final int y;

  /// Width of the sprite in the atlas.
  final int width;

  /// Height of the sprite in the atlas.
  final int height;

  /// Original untrimmed size width of the sprite before packing.
  final int sourceWidth;
  
  /// Original untrimmed size height of the sprite before packing.
  final int sourceHeight;

  /// Position X of trimmed rect inside original image
  final int offsetX;

  /// Position Y of trimmed rect inside original image
  final int offsetY;

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