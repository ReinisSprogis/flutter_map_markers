import 'package:flutter/material.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animation_mode.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/markers/sprite_marker.dart';

class SpriteMarkerSequence extends SpriteMarker {
  int cycleIndex;
  List<List<int>> animationCycles;
  int fps;
  AnimationMode mode;

  /// Index of the current frame within the selected animation cycle.
  ///
  /// This is **not** the atlas sprite index.
  /// For example, for cycle `[6,7,8,9]`:
  /// - `cycleFrameIndex = 0` -> `spriteIndex = 6`
  /// - `cycleFrameIndex = 3` -> `spriteIndex = 9`
  int cycleFrameIndex;

  /// Whether this marker should advance frames over time.
  bool animating;

  SpriteMarkerSequence({
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
    this.cycleFrameIndex = 0,
    this.animating = true,
  });

  @Deprecated('Use animating instead.')
  bool get playing => animating;

  @Deprecated('Use animating instead.')
  set playing(bool value) => animating = value;

  /// Start animating. Optionally set a starting frame within the cycle.
  void animate({int? fromFrameIndex}) {
    if (fromFrameIndex != null) {
      cycleFrameIndex = fromFrameIndex;
    }
    animating = true;
  }

  /// Stop animating and keep the current frame.
  void stop() {
    animating = false;
  }

  /// Reset to the first frame of the current cycle.
  ///
  /// If [animate] is true, also starts animating.
  void resetAnimation({bool animate = false}) {
    cycleFrameIndex = 0;
    animating = animate;
  }

  @override
  int get spriteIndex => animationCycles[cycleIndex][cycleFrameIndex];
}
