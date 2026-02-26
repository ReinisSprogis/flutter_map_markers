part of '../../marker_core.dart';

class SpriteSequenceMarker extends SpriteMarker<SpriteSequenceMarker> {
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
    super.onUpdate,
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
    final spriteRef = sequences[sequenceIndex].frames[frameIndex];
    return spriteRef.sprite;
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

  @override
  SpriteRef get currentSpriteRef {
    int frameIndex = sequences[sequenceIndex].frameIndex;
    return sequences[sequenceIndex].frames[frameIndex];
  }
}
