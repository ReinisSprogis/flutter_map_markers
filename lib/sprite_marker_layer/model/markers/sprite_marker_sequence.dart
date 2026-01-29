import 'package:flutter/material.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/markers/sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sequence.dart';

class SpriteMarkerSequence extends SpriteMarker {
  int sequenceIndex;
  List<Sequence> sequences;

  /// Index of the current frame within the selected animation cycle.
  ///
  /// This is **not** the atlas sprite index.
  /// For example, for cycle `[6,7,8,9]`:
  /// - `cycleFrameIndex = 0` -> `spriteIndex = 6`
  /// - `cycleFrameIndex = 3` -> `spriteIndex = 9`
  int frameIndex;

  /// Whether this marker should advance frames over time.
  bool animating;

  SpriteMarkerSequence({
    required super.id,
    required super.position,
    this.sequenceIndex = 0,
    required this.sequences,
    super.scale = 1.0,
    super.rotation = 0.0,
    super.rotate = false,
    super.alpha = 255,
    super.color = Colors.transparent,
    super.onTap,
    super.anchor = Alignment.center,
    this.frameIndex = 0,
    this.animating = true,
  });

  /// Start animating. Optionally set a starting frame within the cycle.
  void animate({int? fromFrameIndex}) {
    if (fromFrameIndex != null) {
      frameIndex = fromFrameIndex;
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
    frameIndex = 0;
    animating = animate;
  }

  @override
  int get spriteIndex => sequences[sequenceIndex].frames[frameIndex];
}
