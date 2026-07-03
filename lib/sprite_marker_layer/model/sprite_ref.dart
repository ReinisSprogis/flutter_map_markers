/// Reference to a sprite inside a SpriteAtlasSet.
class SpriteRef {
  /// Index inside SpriteAtlasSet
  final int atlas;

  /// Index inside SpriteAtlas.sprites
  final int sprite;

  const SpriteRef(this.atlas, this.sprite);

  /// A constant representing an empty SpriteRef, where both atlas and sprite indices are set to -1.
  static const SpriteRef empty = SpriteRef(-1, -1);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpriteRef && atlas == other.atlas && sprite == other.sprite;
  }

  @override
  int get hashCode => atlas.hashCode ^ sprite.hashCode;

  /// Checks if the SpriteRef is empty frame.
  bool get isEmpty => atlas < 0 || sprite < 0;
}
