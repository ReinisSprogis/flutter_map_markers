import 'package:flutter/material.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animation_mode.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_marker.dart';

class AnimatedSpriteMarker extends SpriteMarker {
  int cycleIndex;
  List<List<int>> animationCycles;
  int fps;
  AnimationMode mode;

  bool playing = true;
  AnimatedSpriteMarker({
    required super.id,
    required super.position,
    this.cycleIndex = 0,
    required this.animationCycles,
    super.scale = 1.0,
    super.rotation = 0.0,
    super.rotate = false,
    super.alpha = 255,
    super.color = Colors.transparent,
    super.onTap,
    super.anchor = Alignment.center,
    this.fps = 10,
    this.mode = AnimationMode.loop,
  });

  @override
  int get spriteIndex =>0;
}
