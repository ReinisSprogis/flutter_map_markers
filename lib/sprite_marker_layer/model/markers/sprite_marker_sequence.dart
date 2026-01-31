
part of '../../marker_core.dart';
class SpriteMarkerSequence extends SpriteMarker {
  int sequenceIndex;
  List<Sequence> sequences;



  /// Whether this marker should advance frames over time.
  bool animating;
  Duration _accumulated = Duration.zero;

  bool isVisible;
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
    this.animating = true,
    this.isVisible = true
  });

  void play() {
    animating = true;
  }

  void pause() {
    animating = false;
  }

  void stop() {
    animating = false;
  }

  /// Reset to the first frame of the current cycle.
  ///
  /// If [animate] is true, also starts animating.
  void resetAnimation({bool animate = false}) {
    sequences[sequenceIndex].frameIndex = 0;
    animating = animate;
  }

  @override
  int get spriteIndex {
    
    int frameIndex = sequences[sequenceIndex].frameIndex;
    final spriteIdx = sequences[sequenceIndex].frames[frameIndex];
    return spriteIdx;
  } 
}
