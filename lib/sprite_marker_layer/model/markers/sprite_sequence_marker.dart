part of '../../marker_core.dart';

class SpriteSequenceMarker extends SpriteMarker {
  int sequenceIndex;
  List<Sequence> sequences;

  /// Whether this marker should advance frames over time.
  bool animating;
  Duration _accumulated = Duration.zero;

  SpriteSequenceMarker({
    required super.id,
    required super.position,
    this.sequenceIndex = 0,
    required this.sequences,
    super.onTap,
    this.animating = true,
    super.isVisible = true,
    super.transform = Offset.zero,
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
  
  /// Returns the anchor alignment for the current sequence.
  @override
  Alignment get anchor => sequences[sequenceIndex].anchor;
  
  @override
  bool get counterRotate => sequences[sequenceIndex].counterRotate;

  @override
  double get scale => sequences[sequenceIndex].scale;

  @override
  double get rotation => sequences[sequenceIndex].rotation;

  @override
  bool get spriteSizeInMeters => sequences[sequenceIndex].spriteSizeInMeters;

}
