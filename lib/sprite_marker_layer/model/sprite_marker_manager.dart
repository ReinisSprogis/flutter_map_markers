import 'dart:math';
import 'dart:typed_data';

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animated_sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animation_mode.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/static_sprite_marker.dart';
import 'package:latlong2/latlong.dart' as coord;

class SpriteMarkerManager extends ChangeNotifier {
  MapCamera? camera;
  List<SpriteMarker> markers;

  SpriteMarkerManager({
    required this.spriteCycles,
    required this.spriteAtlas,
    this.markers = const [],
  });

  final SpriteAtlas spriteAtlas;

  /// Sprite animation cycles from atlas
  final List<List<int>> spriteCycles;

  /// Marker storage
  final Map<Object, SpriteMarker> _markers = {};
  final Map<Object, _AnimState> _animStates = {};

  /// Number of markers currently managed.
  int get markerCount => _markers.length;

  /// Whether markers outside the viewport should be skipped during buffer builds.
  ///
  /// This is a UI-thread optimization; it avoids generating atlas entries that
  /// would not be visible.
  bool cullMarkers = true;

  // =========================
  // Render buffers (cached)
  // =========================

  Float32List _transforms = Float32List(0); // scos, ssin, tx, ty
  Float32List _rects = Float32List(0); // l, t, r, b
  int _capacity = 0;

  int _writeCount = 0;

  /// Monotonic animation time in seconds.
  ///
  /// Keeping a single clock avoids per-marker time accumulation work.
  double _clockSeconds = 0.0;

  // =========================
  // Dirty flags (coalesced per paint)
  // =========================

  bool _needsCameraRebuild = false;
  bool _needsTransformUpdate = false;
  bool _needsRectUpdate = false;

  /// Direct references for the cached render buffer.
  ///
  /// Using references avoids hash-map lookups in the hot path.
  late List<SpriteMarker?> _bufferMarkers = <SpriteMarker?>[];

  /// Last sprite index per render-buffer slot.
  Int32List _bufferSpriteIndices = Int32List(0);

  // =========================
  // Marker updates (API tick)
  // =========================

  /// Adds or replaces a single marker.
  ///
  /// This is the recommended API for rapidly adding markers (e.g. pointer
  /// hover): it avoids the O(n) diff + full rebuild performed by [updateMarkers].
  ///
  /// If the marker is currently visible, it will be appended to the cached
  /// draw buffer immediately (O(1)). Otherwise it will appear on the next
  /// camera rebuild (pan/zoom/rotate) or if you call [tick] with
  /// `rebuildVisibility: true`.
  void addMarker(SpriteMarker marker) {
    final Object id = marker.id;
    final existing = _markers[id];
    _markers[id] = marker;

    if (marker is AnimatedSpriteMarker) {
      _animStates.putIfAbsent(
        id,
        () => _AnimState(startSeconds: _clockSeconds),
      );
    } else {
      // Keep map clean if a marker switches from animated to static.
      _animStates.remove(id);
    }

    // NOTE: `markers` is treated as a bulk-update snapshot.
    // Maintaining it incrementally causes O(n) copying and defeats the purpose
    // of addMarker(). Rendering uses internal buffers + `markerCount`.

    final currentCamera = camera;
    if (currentCamera != null && existing == null) {
      final appended = _tryAppendVisibleToBuffer(marker, currentCamera);
      if (!appended) {
        // Not visible: we don't want to rebuild the whole buffer per add.
        // It will be picked up on the next camera rebuild.
      }
    } else if (currentCamera != null && existing != null) {
      // If a marker was replaced and it exists in the buffer, update ref.
      for (int i = 0; i < _writeCount; i++) {
        final m = _bufferMarkers[i];
        if (m != null && m.id == id) {
          _bufferMarkers[i] = marker;
          _needsTransformUpdate = true;
          _needsRectUpdate = true;
          break;
        }
      }
    }

    notifyListeners();
  }

  /// Adds or replaces many markers in one shot, notifying listeners once.
  void addMarkers(Iterable<SpriteMarker> newMarkers) {
    for (final m in newMarkers) {
      addMarker(m);
    }
  }

  /// Removes a marker by id.
  bool removeMarker(Object id) {
    final removed = _markers.remove(id) != null;
    _animStates.remove(id);
    if (!removed) return false;

    // Mark for rebuild; easiest correct path.
    _needsCameraRebuild = true;

    // `markers` snapshot is not maintained incrementally.

    notifyListeners();
    return true;
  }

  /// Clears all markers.
  void clearMarkers() {
    _markers.clear();
    _animStates.clear();
    markers = const [];
    _writeCount = 0;
    _needsCameraRebuild = false;
    _needsTransformUpdate = false;
    _needsRectUpdate = false;
    notifyListeners();
  }

  void updateMarkers(List<SpriteMarker> incoming) {
    final incomingIds = incoming.map((m) => m.id).toSet();

    // removals
    for (final id in _markers.keys.toList()) {
      if (!incomingIds.contains(id)) {
        _markers.remove(id);
        _animStates.remove(id);
      }
    }

    // add / update
    for (final marker in incoming) {
      _markers[marker.id] = marker;
      if (marker is AnimatedSpriteMarker) {
        _animStates.putIfAbsent(marker.id, () => _AnimState());
      }
    }
    markers = _markers.values.toList();
    final currentCamera = camera;
    if (currentCamera == null) {
      notifyListeners();
      return;
    }
    _rebuildRenderBuffersForCamera(currentCamera);
    _needsCameraRebuild = false;
    _needsTransformUpdate = false;
    _needsRectUpdate = false;
    notifyListeners();
  }

  bool _tryAppendVisibleToBuffer(SpriteMarker marker, MapCamera currentCamera) {
    if (cullMarkers && !currentCamera.visibleBounds.contains(marker.position)) {
      return false;
    }

    final screen = currentCamera.getOffsetFromOrigin(marker.position);
    if (!screen.dx.isFinite || !screen.dy.isFinite) return false;

    final int spriteIndex = _resolveSpriteIndexAtTime(marker);
    final sprite = spriteAtlas.getSpriteInfo(spriteIndex);
    if (sprite.width <= 0 || sprite.height <= 0) return false;

    double rotation = marker.rotation;
    final double scale = marker.scale;
    final bool rotate = marker.rotate;

    if (rotate) {
      rotation -= currentCamera.rotationRad;
    }
    if (!rotation.isFinite || !scale.isFinite || scale <= 0) return false;

    final double anchorX = sprite.width * (marker.anchor.x + 1.0) / 2.0;
    final double anchorY = sprite.height * (marker.anchor.y + 1.0) / 2.0;

    final double c = cos(rotation);
    final double s = sin(rotation);
    final double scos = c * scale;
    final double ssin = s * scale;

    final double tx = screen.dx - scos * anchorX + ssin * anchorY;
    final double ty = screen.dy - ssin * anchorX - scos * anchorY;

    _ensureCapacity(_writeCount + 1);
    final int base = _writeCount * 4;

    _transforms[base + 0] = scos;
    _transforms[base + 1] = ssin;
    _transforms[base + 2] = tx;
    _transforms[base + 3] = ty;

    _rects[base + 0] = sprite.x;
    _rects[base + 1] = sprite.y;
    _rects[base + 2] = sprite.x + sprite.width;
    _rects[base + 3] = sprite.y + sprite.height;

    _bufferMarkers[_writeCount] = marker;
    _bufferSpriteIndices[_writeCount] = spriteIndex;
    _writeCount++;

    return true;
  }

  // =========================
  // Frame update (per frame)
  // =========================

  /// Advances animations (and optionally marker transforms) for the currently
  /// buffered visible markers.
  ///
  /// This is the preferred per-frame API:
  /// - Call [updateMarkers] when adding/removing markers.
  /// - Mutate marker fields in place for motion.
  /// - Call `tick(deltaMs, markersMoved: true)` each frame.
  void tick(
    int deltaTime, {
    bool markersMoved = false,
    bool rebuildVisibility = false,
  }) {
    final currentCamera = camera;
    if (currentCamera == null) return;

    // deltaTime is expected to be in milliseconds.
    final double dtSeconds = deltaTime / 1000.0;
    if (dtSeconds.isFinite && dtSeconds > 0) {
      _clockSeconds += dtSeconds;
    }

    // Mark rects dirty when time advances (animation).
    // Even if no AnimatedSpriteMarkers exist, this is cheap to check at flush.
    if (dtSeconds.isFinite && dtSeconds > 0) {
      _needsRectUpdate = true;
    }

    if (markersMoved) {
      _needsTransformUpdate = true;
    }

    if (rebuildVisibility) {
      _needsCameraRebuild = true;
    }

    // Coalesce work to paint(): tick just marks dirty and schedules repaint.
    notifyListeners();
  }

  /// Backwards-compatible alias: advances animation frames.
  /// Prefer [tick].
  void update(int deltaTime) {
    tick(deltaTime);
  }

  void updateCamera(MapCamera newCamera) {
    final old = camera;
    camera = newCamera;

    // Avoid rebuilding when FlutterMap rebuilds the layer with a new MapCamera
    // instance that carries identical values.
    if (old != null && _sameCameraValues(old, newCamera)) {
      return;
    }

    // Panning can call this multiple times per frame; rebuild once in draw().
    _needsCameraRebuild = true;
    notifyListeners();
  }

  /// Call this when you mutate markers **in place** (e.g. change `position`,
  /// `rotation`, `scale`, `anchor`, etc) and want the layer to reflect those
  /// changes.
  ///
  /// For performance, when [rebuildVisibility] is false this only updates the
  /// transforms for markers currently present in the cached render buffer
  /// (i.e. the markers that were visible at the last full rebuild). This is
  /// usually enough when markers move small distances and stay on screen.
  ///
  /// If your markers may enter/leave the viewport while moving, pass
  /// [rebuildVisibility]=true occasionally (or every frame if you need strict
  /// correctness and accept the cost).
  void notifyMarkersMoved({bool rebuildVisibility = false}) {
    final currentCamera = camera;
    if (currentCamera == null) return;

    if (rebuildVisibility) {
      _needsCameraRebuild = true;
      notifyListeners();
      return;
    }

    _needsTransformUpdate = true;
    notifyListeners();
  }

  // =========================
  // Rendering preparation
  // =========================

  void buildRenderBuffers({
    required List<SpriteMarker> visibleMarkers,
    required Offset Function(coord.LatLng) worldToScreen,
    required SpriteAtlas spriteAtlas,
    required double cameraRotation,
    required Offset offset,
  }) {
    _ensureCapacity(visibleMarkers.length);
    _writeCount = 0;

    for (final marker in visibleMarkers) {
      final screen = worldToScreen(marker.position);
      if (!screen.dx.isFinite || !screen.dy.isFinite) continue;

      final int spriteIndex = _resolveSpriteIndexAtTime(marker);
      final sprite = spriteAtlas.getSpriteInfo(spriteIndex);
      if (sprite.width <= 0 || sprite.height <= 0) continue;

      // All SpriteMarkers have these properties from the base class
      double rotation = marker.rotation;
      double scale = marker.scale;
      bool rotate = marker.rotate;

      // When rotate=true, counter-rotate to keep marker upright
      if (rotate) {
        rotation -= cameraRotation;
      }

      final double dx = screen.dx + offset.dx;
      final double dy = screen.dy + offset.dy;

      // Convert Alignment (-1.0 to 1.0) to anchor point (0.0 to 1.0)
      final double anchorX = sprite.width * (marker.anchor.x + 1.0) / 2.0;
      final double anchorY = sprite.height * (marker.anchor.y + 1.0) / 2.0;

      final RSTransform t = RSTransform.fromComponents(
        rotation: rotation,
        scale: scale,
        anchorX: anchorX,
        anchorY: anchorY,
        translateX: dx,
        translateY: dy,
      );

      final int base = _writeCount * 4;

      _transforms[base + 0] = t.scos;
      _transforms[base + 1] = t.ssin;
      _transforms[base + 2] = t.tx;
      _transforms[base + 3] = t.ty;

      _rects[base + 0] = sprite.x;
      _rects[base + 1] = sprite.y;
      _rects[base + 2] = sprite.x + sprite.width;
      _rects[base + 3] = sprite.y + sprite.height;

      _writeCount++;
    }
  }

  void _rebuildRenderBuffersForCamera(MapCamera camera) {
    // Allocation-free rebuild: iterate markers once and cull inline.
    // We build in local layer coordinates (offset applied at draw time via
    // canvas.translate), so we don't need to rebuild just because the RenderBox
    // paint offset changed.
    final bounds = camera.visibleBounds;
    final worldToScreen = camera.getOffsetFromOrigin;
    final cameraRotation = camera.rotationRad;

    _ensureCapacity(_markers.length);
    _writeCount = 0;

    for (final marker in _markers.values) {
      if (cullMarkers && !bounds.contains(marker.position)) {
        continue;
      }

      final screen = worldToScreen(marker.position);
      if (!screen.dx.isFinite || !screen.dy.isFinite) continue;

      final int spriteIndex = _resolveSpriteIndexAtTime(marker);
      final sprite = spriteAtlas.getSpriteInfo(spriteIndex);
      if (sprite.width <= 0 || sprite.height <= 0) continue;

      double rotation = marker.rotation;
      final double scale = marker.scale;
      final bool rotate = marker.rotate;

      if (rotate) {
        rotation -= cameraRotation;
      }

      if (!rotation.isFinite || !scale.isFinite || scale <= 0) continue;

      // Convert Alignment (-1.0 to 1.0) to anchor point (0.0 to 1.0)
      final double anchorX = sprite.width * (marker.anchor.x + 1.0) / 2.0;
      final double anchorY = sprite.height * (marker.anchor.y + 1.0) / 2.0;

      final int base = _writeCount * 4;

      final double c = cos(rotation);
      final double s = sin(rotation);
      final double scos = c * scale;
      final double ssin = s * scale;

      final double tx = screen.dx - scos * anchorX + ssin * anchorY;
      final double ty = screen.dy - ssin * anchorX - scos * anchorY;

      _transforms[base + 0] = scos;
      _transforms[base + 1] = ssin;
      _transforms[base + 2] = tx;
      _transforms[base + 3] = ty;

      _rects[base + 0] = sprite.x;
      _rects[base + 1] = sprite.y;
      _rects[base + 2] = sprite.x + sprite.width;
      _rects[base + 3] = sprite.y + sprite.height;

      _bufferMarkers[_writeCount] = marker;
      _bufferSpriteIndices[_writeCount] = spriteIndex;

      _writeCount++;
    }
  }

  // =========================
  // Drawing
  // =========================
  final Paint paint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.srcOver
    ..filterQuality = FilterQuality.high;

  void draw(Canvas canvas, Offset offset) {
    _flushPendingUpdatesForDraw();
    if (_writeCount == 0) return;

    // Important: do NOT rebuild buffers here. Rebuilding in draw() makes the UI
    // thread pay the full O(n) marker transform cost during paint, and it also
    // defeats caching. Apply the RenderBox paint offset via canvas translation.
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    const int batchSize = 256;

    for (int start = 0; start < _writeCount; start += batchSize) {
      final count = (start + batchSize <= _writeCount)
          ? batchSize
          : (_writeCount - start);

      canvas.drawRawAtlas(
        spriteAtlas.image,
        Float32List.sublistView(_transforms, start * 4, (start + count) * 4),
        Float32List.sublistView(_rects, start * 4, (start + count) * 4),
        null,
        null,
        null,
        paint,
      );
    }

    canvas.restore();
  }

  void _flushPendingUpdatesForDraw() {
    final currentCamera = camera;
    if (currentCamera == null) return;

    // If camera changed (pan/zoom/rotate) rebuild visible set and transforms.
    if (_needsCameraRebuild) {
      _rebuildRenderBuffersForCamera(currentCamera);
      _needsCameraRebuild = false;
      _needsTransformUpdate = false;
      _needsRectUpdate = false;
      return;
    }

    if (_writeCount == 0) {
      _needsTransformUpdate = false;
      _needsRectUpdate = false;
      return;
    }

    if (_needsTransformUpdate) {
      final bounds = currentCamera.visibleBounds;
      final worldToScreen = currentCamera.getOffsetFromOrigin;
      final cameraRotation = currentCamera.rotationRad;

      bool needsFullRebuild = false;

      for (int i = 0; i < _writeCount; i++) {
        final marker = _bufferMarkers[i];
        if (marker == null) continue;

        if (cullMarkers && !bounds.contains(marker.position)) {
          needsFullRebuild = true;
          break;
        }

        final screen = worldToScreen(marker.position);
        if (!screen.dx.isFinite || !screen.dy.isFinite) {
          needsFullRebuild = true;
          break;
        }

        final int spriteIndex = _bufferSpriteIndices[i];
        final sprite = spriteAtlas.getSpriteInfo(spriteIndex);
        if (sprite.width <= 0 || sprite.height <= 0) continue;

        double rotation = marker.rotation;
        final double scale = marker.scale;
        final bool rotate = marker.rotate;

        if (rotate) {
          rotation -= cameraRotation;
        }

        if (!rotation.isFinite || !scale.isFinite || scale <= 0) continue;

        final double anchorX = sprite.width * (marker.anchor.x + 1.0) / 2.0;
        final double anchorY = sprite.height * (marker.anchor.y + 1.0) / 2.0;

        final double c = cos(rotation);
        final double s = sin(rotation);
        final double scos = c * scale;
        final double ssin = s * scale;

        final double tx = screen.dx - scos * anchorX + ssin * anchorY;
        final double ty = screen.dy - ssin * anchorX - scos * anchorY;

        final int base = i * 4;
        _transforms[base + 0] = scos;
        _transforms[base + 1] = ssin;
        _transforms[base + 2] = tx;
        _transforms[base + 3] = ty;
      }

      if (needsFullRebuild) {
        _rebuildRenderBuffersForCamera(currentCamera);
        _needsTransformUpdate = false;
        _needsRectUpdate = false;
        return;
      }

      _needsTransformUpdate = false;
    }

    if (_needsRectUpdate) {
      for (int i = 0; i < _writeCount; i++) {
        final marker = _bufferMarkers[i];
        if (marker == null) continue;
        if (marker is! AnimatedSpriteMarker) continue;

        final int newSpriteIndex = _resolveSpriteIndexAtTime(marker);
        if (_bufferSpriteIndices[i] == newSpriteIndex) continue;

        final sprite = spriteAtlas.getSpriteInfo(newSpriteIndex);
        final int base = i * 4;
        _rects[base + 0] = sprite.x;
        _rects[base + 1] = sprite.y;
        _rects[base + 2] = sprite.x + sprite.width;
        _rects[base + 3] = sprite.y + sprite.height;

        _bufferSpriteIndices[i] = newSpriteIndex;
      }

      _needsRectUpdate = false;
    }
  }

  // =========================
  // Helpers
  // =========================

  /// Gets markers that are visible within the current viewport.
  List<SpriteMarker> _getVisibleMarkers(
    List<SpriteMarker> allMarkers,
    MapCamera camera,
  ) {
    final bounds = camera.visibleBounds;
    return allMarkers.where((marker) {
      return bounds.contains(marker.position);
    }).toList();
  }

  bool _sameCameraValues(MapCamera a, MapCamera b) {
    // These are the values that affect world->screen transforms.
    return a.zoom == b.zoom &&
        a.rotationRad == b.rotationRad &&
        a.center == b.center;
  }

  final Random _random = Random();
  int _resolveSpriteIndexAtTime(SpriteMarker marker) {
    if (marker is StaticSpriteMarker) {
      return marker.spriteIndex;
    }

    if (marker is! AnimatedSpriteMarker) {
      return marker.spriteIndex;
    }

    final AnimatedSpriteMarker m = marker;

    // Prefer per-marker cycles (AnimatedSpriteMarker.animationCycles).
    // Fall back to manager-provided cycles if marker doesn't define them.
    final List<List<int>> cycles = m.animationCycles.isNotEmpty
        ? m.animationCycles
        : spriteCycles;
    if (cycles.isEmpty) return 0;
    final int safeCycleIndex =
        (m.cycleIndex >= 0 && m.cycleIndex < cycles.length) ? m.cycleIndex : 0;
    final frames = cycles[safeCycleIndex];
    if (frames.isEmpty) return 0;

    final state = _animStates[m.id];
    if (state == null) return frames.first;

    final double t = state._effectiveTime(
      nowSeconds: _clockSeconds,
      playing: m.playing,
    );

    final int frameCount = frames.length;
    final int raw = (t * m.fps).floor();

    switch (m.mode) {
      case AnimationMode.loop:
        return frames[raw % frameCount];

      case AnimationMode.once:
        if (raw >= frameCount) {
          state.finished = true;
          return frames.last;
        }
        return frames[raw];

      case AnimationMode.reverse:
        return frames[frameCount - 1 - (raw % frameCount)];

      case AnimationMode.pingPong:
        final cycle = raw ~/ frameCount;
        final idx = raw % frameCount;
        return frames[cycle.isEven ? idx : frameCount - 1 - idx];

      case AnimationMode.random:
        return frames[_random.nextInt(frameCount)];
    }
  }

  void _ensureCapacity(int required) {
    if (required <= _capacity) return;

    final int oldCapacity = _capacity;
    final Float32List oldTransforms = _transforms;
    final Float32List oldRects = _rects;
    final Int32List oldSpriteIndices = _bufferSpriteIndices;
    final List<SpriteMarker?> oldBufferMarkers = _bufferMarkers;

    int newCapacity = _capacity == 0 ? 256 : _capacity * 2;
    while (newCapacity < required) {
      newCapacity *= 2;
    }

    final Float32List newTransforms = Float32List(newCapacity * 4);
    final Float32List newRects = Float32List(newCapacity * 4);
    final Int32List newSpriteIndices = Int32List(newCapacity);
    final List<SpriteMarker?> newBufferMarkers = List<SpriteMarker?>.filled(
      newCapacity,
      null,
    );

    // Preserve existing buffered entries. This is critical for incremental
    // operations (e.g. addMarker) where we append without rebuilding.
    final int copyCount = min(_writeCount, oldCapacity);
    if (copyCount > 0) {
      newTransforms.setRange(0, copyCount * 4, oldTransforms);
      newRects.setRange(0, copyCount * 4, oldRects);
      newSpriteIndices.setRange(0, copyCount, oldSpriteIndices);
      newBufferMarkers.setRange(0, copyCount, oldBufferMarkers);
    }

    _transforms = newTransforms;
    _rects = newRects;
    _bufferSpriteIndices = newSpriteIndices;
    _bufferMarkers = newBufferMarkers;
    _capacity = newCapacity;
  }

}

class _AnimState {
  // When playing, the effective animation time is (nowSeconds - _startSeconds).
  // When paused, the effective animation time stays at _frozenSeconds.
  double _startSeconds = 0.0;
  double _frozenSeconds = 0.0;
  bool _wasPlaying = true;
  bool finished = false;

  _AnimState({double startSeconds = 0.0}) : _startSeconds = startSeconds;

  double _effectiveTime({required double nowSeconds, required bool playing}) {
    if (!_wasPlaying && playing) {
      // Resume: keep continuity by shifting the start time.
      _startSeconds = nowSeconds - _frozenSeconds;
      _wasPlaying = true;
    } else if (_wasPlaying && !playing) {
      // Pause: freeze at current effective time.
      _frozenSeconds = (nowSeconds - _startSeconds);
      _wasPlaying = false;
    }

    return playing ? (nowSeconds - _startSeconds) : _frozenSeconds;
  }
}
