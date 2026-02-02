part of '../marker_core.dart';

class AnimationPlayer extends ChangeNotifier {
  List<SpriteMarker> markers = [];
  late final _SpriteTicker _ticker;
  final Random _random = Random();
  VoidCallback onPlayerStop = () {};
  AnimationPlayer({required TickerProvider vsync}) {
    _ticker = _SpriteTicker(vsync, _onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool get isRunning => _ticker.isActive;

  void addMarker(SpriteMarker marker) {
    markers.add(marker);
    if (!_ticker.isActive) _ticker.start();
  }

  void removeMarker(SpriteMarker marker) {
    markers.remove(marker);
  }

  void start() => _ticker.start();
  void stop() {
    _ticker.stop();
    onPlayerStop();
  } 

 

  void _onTick(Duration delta) {
    bool anyAnimating = false;
    bool anyFrameChanged = false;
    // final snapshot = List<SpriteMarker>.from(markers);

    for (final marker in markers) {
      if (marker is SpriteSequenceMarker &&
          marker.animating &&
          marker.isVisible) {
        final (changed, stillAnimating) = _updateFrame(marker, delta);
        anyAnimating = anyAnimating || stillAnimating;
        anyFrameChanged = anyFrameChanged || changed;
      }
    }

    if (anyFrameChanged) notifyListeners();
    if (!anyAnimating) _ticker.stop();
  }

  (bool frameChanged, bool stillAnimating) _updateFrame(
    SpriteSequenceMarker marker,
    Duration delta,
  ) {
    final sequence = marker.sequences[marker.sequenceIndex];
    final spriteCount = sequence.frames.length;

    if (spriteCount == 0) return (false, false);

    // Clamp huge deltas to avoid big jumps
    final clampedDelta = delta > const Duration(milliseconds: 200)
        ? const Duration(milliseconds: 200)
        : delta;

    marker._accumulated += clampedDelta;
    final frameDuration = Duration(
      microseconds: (1000000 / sequence.fps).round(),
    );

    bool frameChanged = false;

    // Advance sprite frames if enough time has accumulated
    while (marker._accumulated >= frameDuration) {
      marker._accumulated -= frameDuration;
      frameChanged = true;

      int idx = sequence.frameIndex;

      switch (sequence.mode) {
        case AnimationMode.loopForward:
          idx = (idx + 1) % spriteCount;
          break;
        case AnimationMode.loopBackward:
          idx = (idx - 1 + spriteCount) % spriteCount;
          break;
        case AnimationMode.forwardOnce:
          if (idx < spriteCount - 1) {
            idx++;
          } else {
            idx = spriteCount - 1;
            marker.animating = false;
            marker._accumulated = Duration.zero;
            sequence.onAnimationEnd?.call();
            break;
          }
          break;
        case AnimationMode.reverseOnce:
          if (idx > 0) {
            idx--;
          } else {
            idx = 0;
            marker.animating = false;
            marker._accumulated = Duration.zero;
            sequence.onAnimationEnd?.call();
            break;
          }
          break;
        case AnimationMode.pingPong:
          if (sequence.isReversing) {
            idx--;
            if (idx <= 0) {
              idx = 0;
              sequence.isReversing = false;
            }
          } else {
            idx++;
            if (idx >= spriteCount - 1) {
              idx = spriteCount - 1;
              sequence.isReversing = true;
            }
          }
          break;
        case AnimationMode.random:
          idx = _random.nextInt(spriteCount);
          break;
      }

      sequence.frameIndex = idx;

      if (frameChanged && sequence.onSequenceFrame != null) {
        sequence.onSequenceFrame!(idx);
      }

      if (!marker.animating) break;
    }

    if (sequence.onUpdate != null && marker.animating) {
      sequence.onUpdate!(clampedDelta.inMilliseconds);
      frameChanged = true;
    }

    return (frameChanged, marker.animating);
  }
}

/// Lightweight ticker wrapper
class _SpriteTicker {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  _SpriteTicker(TickerProvider vsync, void Function(Duration) onDelta) {
    _ticker = vsync.createTicker((elapsed) {
      final delta = elapsed - _lastElapsed;
      _lastElapsed = elapsed;

      // Clamp large jumps
      final clamped = delta > const Duration(milliseconds: 200)
          ? const Duration(milliseconds: 200)
          : delta;

      onDelta(clamped);
    });
  }

  bool get isActive => _ticker.isActive;

  void start() {
    _lastElapsed = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void stop() {
    _ticker.stop();
    _lastElapsed = Duration.zero;
  }

  void dispose() => _ticker.dispose();
}
