import 'package:flutter/material.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animation_mode.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_ref.dart';

class Sequence {
  final List<SpriteRef> frames;
  int frameIndex;
  final int fps;
  final AnimationMode mode;
  bool isReversing;
  void Function()? onAnimationEnd;
  /// Anchor point of the sprite relative to its position.
  /// Defaults to [Alignment.bottomCenter].
  Alignment anchor;
  /// Whether the sprite should counter-rotate against the map rotation.
  bool counterRotate;

  /// Scale factor for the sprite in this sequence.
  /// Defaults to 1.0.
  double scale;

  /// Rotation in radians for the sprite in this sequence.
  double rotation;

  bool spriteSizeInMeters;

  Offset transform;

///Called once per frame change in the sequence.
///
///For example if the sequence FPS is set to 1 this will be called once per second when frame updates.
 final void Function(int frameIndex)? onSequenceFrame;



  Sequence({
    required this.frames,
    this.frameIndex = 0,
    this.fps = 24,
    this.isReversing = false,
    this.mode = AnimationMode.loopForward,
    this.onAnimationEnd,
    this.anchor = Alignment.bottomCenter,
    this.counterRotate = false,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.spriteSizeInMeters = false,
    this.onSequenceFrame,
    this.transform = Offset.zero,
  });
}
