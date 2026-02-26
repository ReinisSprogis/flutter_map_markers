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
  final int y;
  final int width;
  final int height;

  // Original untrimmed size
  final int sourceWidth;
  final int sourceHeight;

  // Position of trimmed rect inside original image
  final int offsetX;
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