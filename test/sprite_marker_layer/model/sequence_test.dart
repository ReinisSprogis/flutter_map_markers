import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sequence.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_ref.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animation_mode.dart';
import 'package:flutter/material.dart';

void main() {
  group('Sequence', () {
    final frames = [
      const SpriteRef(0, 0),
      const SpriteRef(0, 1),
      const SpriteRef(0, 2),
    ];

    test('default values and construction', () {
      final seq = Sequence(frames: frames);
      expect(seq.frames, frames);
      expect(seq.frameIndex, 0);
      expect(seq.fps, 24);
      expect(seq.mode, AnimationMode.loopForward);
      expect(seq.isReversing, false);
      expect(seq.anchor, Alignment.bottomCenter);
      expect(seq.counterRotate, false);
      expect(seq.scale, 1.0);
      expect(seq.rotation, 0.0);
      expect(seq.spriteSizeInMeters, false);
      expect(seq.transform, Offset.zero);
    });

    test('frameIndex bounds', () {
      final seq = Sequence(frames: frames, frameIndex: 1);
      expect(seq.frameIndex, 1);
      seq.frameIndex = 2;
      expect(seq.frameIndex, 2);
      seq.frameIndex = 0;
      expect(seq.frameIndex, 0);
    });

    test('onSequenceFrame callback', () {
      int? calledIndex;
      final seq = Sequence(
        frames: frames,
        onSequenceFrame: (i) => calledIndex = i,
      );
      seq.onSequenceFrame?.call(2);
      expect(calledIndex, 2);
    });

    test('onAnimationEnd callback', () {
      bool called = false;
      final seq = Sequence(frames: frames, onAnimationEnd: () => called = true);
      seq.onAnimationEnd?.call();
      expect(called, isTrue);
    });
  });
}
