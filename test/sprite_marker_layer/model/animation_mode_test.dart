import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animation_mode.dart';

void main() {
  group('AnimationMode', () {
    test('values contains all expected modes', () {
      expect(
        AnimationMode.values,
        containsAll([
          AnimationMode.loopForward,
          AnimationMode.loopBackward,
          AnimationMode.forwardOnce,
          AnimationMode.reverseOnce,
          AnimationMode.pingPong,
          AnimationMode.random,
        ]),
      );
    });

    test('values length is correct and unique', () {
      expect(AnimationMode.values.length, 6);
      expect(AnimationMode.values.toSet().length, AnimationMode.values.length);
    });

    test('invalid index throws RangeError', () {
      expect(() => AnimationMode.values[100], throwsRangeError);
      expect(() => AnimationMode.values[-1], throwsRangeError);
    });

    test('switch exhaustiveness', () {
      String describe(AnimationMode mode) {
        switch (mode) {
          case AnimationMode.loopForward:
            return 'loopForward';
          case AnimationMode.loopBackward:
            return 'loopBackward';
          case AnimationMode.forwardOnce:
            return 'forwardOnce';
          case AnimationMode.reverseOnce:
            return 'reverseOnce';
          case AnimationMode.pingPong:
            return 'pingPong';
          case AnimationMode.random:
            return 'random';
        }
      }

      for (final mode in AnimationMode.values) {
        expect(describe(mode), contains(mode.toString().split('.').last));
      }
    });

    test('toString returns correct names', () {
      expect(AnimationMode.loopForward.toString(), contains('loopForward'));
      expect(AnimationMode.loopBackward.toString(), contains('loopBackward'));
      expect(AnimationMode.forwardOnce.toString(), contains('forwardOnce'));
      expect(AnimationMode.reverseOnce.toString(), contains('reverseOnce'));
      expect(AnimationMode.pingPong.toString(), contains('pingPong'));
      expect(AnimationMode.random.toString(), contains('random'));
    });
  });
}
