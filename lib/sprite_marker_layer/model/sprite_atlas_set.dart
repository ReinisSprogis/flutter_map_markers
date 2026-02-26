import 'dart:ui' as ui;

import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_info.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_ref.dart';

/// A set of sprite atlases, allowing for multiple atlases to be used in a marker layer.
class SpriteAtlasSet {
  final List<SpriteAtlas> atlases;

  const SpriteAtlasSet(this.atlases);

  SpriteAtlas atlas(int index) => atlases[index];

  ui.Image imageOf(int index) => atlases[index].image;

  SpriteInfo spriteOf(SpriteRef ref) =>
      atlases[ref.atlas].getSpriteInfo(ref.sprite);
}