import 'package:flutter_map_markers/sprite_marker_layer/model/animation_mode.dart';

class Sequence {
  final List<int> frames;
  final int startFrame;
  final int fps;
  final AnimationMode mode;
  const Sequence({
    required this.frames,
    this.startFrame = 0,
    this.fps = 24,
    this.mode = AnimationMode.loopForward,
  });
}
