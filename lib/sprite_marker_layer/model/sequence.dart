import 'package:flutter_map_markers/sprite_marker_layer/model/animation_mode.dart';

class Sequence {
  final List<int> frames;
  int frameIndex;
  final int fps;
  final AnimationMode mode;
  bool isReversing;
  void Function()? onAnimationEnd;
  Sequence({
    required this.frames,
    this.frameIndex = 0,
    this.fps = 24,
    this.isReversing = false,
    this.mode = AnimationMode.loopForward,
    this.onAnimationEnd,
  });
}
