import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:vector_math/vector_math_64.dart' hide Colors;

/// A render object that draws [CanvasMarker]s and performs marker hit testing.
///
/// ## Why this exists
///
/// `flutter_map` is typically wrapped in a [GestureDetector] and/or has its own
/// gesture handling for panning, zooming, and rotation. When markers are
/// implemented as separate widgets on top of the map, taps often go through the
/// Flutter gesture arena and can:
///
/// - Trigger map taps even when a marker was the real target.
/// - Add per-marker widget overhead that scales poorly for many markers.
/// - Become inconsistent when the map is rotated because the visual marker
///   rotation does not match the hit-test space.
///
/// This layer solves those issues by:
///
/// - Painting markers on a single canvas (fast for many markers).
/// - Owning marker hit testing in the exact same coordinate space used for
///   painting (deterministic interaction).
/// - Joining the gesture arena *only when* a real marker hit is detected, so
///   map gestures keep working normally.
///
/// ## Coordinate spaces
///
/// - Marker painters receive screen-space offsets computed via
///   [MapCamera.getOffsetFromOrigin].
/// - Hit testing uses the same method to compute marker locations.
/// - If a marker opts into counter-rotation (`marker.rotate == true`), painting
///   rotates the canvas backwards (so the marker stays upright). Hit testing
///   must then rotate the pointer position forward by the same amount so the
///   hit area matches what the user sees.
class RenderCanvasMarkerLayer extends RenderBox {
  List<CanvasMarker> _markers;
  MapCamera _camera;
  int? _lastSelectedMarkerIndex;
  bool _paintDebugRect;
  bool _paintDebugHitArea;
  bool _cullMarkers;
  bool _drawHitMarkerLast;

  /// Active pointers currently down.
  ///
  ///  We need to detect multi-touch sequences (pinch/rotate). A gesture
  /// that starts on a marker and later becomes multi-touch must never be
  /// treated as a marker tap.
  final Set<int> _activePointers = <int>{};

  /// The pointer that started a potential marker tap.
  ///
  ///  Tap recognition is per-pointer. We only consider the *first* pointer
  /// for a tap candidate; any additional pointer disqualifies the tap.
  int? _tapCandidatePointer;

  /// The marker index that was hit on pointer down.
  ///
  ///  We want "tap down on marker" + "tap up on same marker" semantics.
  /// This avoids firing on tap-up over a different marker after a drag.
  int? _tapCandidateMarkerIndex;

  /// Whether the tap sequence involved multi-touch at any time.
  ///
  ///  TapGestureRecognizer can lose to pan/scale in the arena, but we
  /// additionally guard against platform differences and unusual sequences
  /// where multi-touch may not cancel the recognizer the way we expect.
  bool _tapCandidateHadMultiTouch = false;

  /// Converts a distance in meters to screen pixels at the given [point].
  double _metersToPixels(LatLng point, double meters) {
    final south = const Distance().offset(point, meters, 180);

    final p1 = camera.getOffsetFromOrigin(point);
    final p2 = camera.getOffsetFromOrigin(south);

    return (p1 - p2).distance;
  }

  /// Recognizes taps for markers.
  ///
  ///  We participate in the gesture arena for true marker hits so that
  /// FlutterMap's tap handlers do not fire when the marker tap wins.
  ///
  /// Note: We only add a pointer to this recognizer when a marker was hit on
  /// pointer-down. This avoids constantly competing with the map for gestures.
  late final TapGestureRecognizer _tapGestureRecognizer =
      TapGestureRecognizer(debugOwner: this)
        ..onTapUp = (details) {
          final markerIndex = _tapCandidateMarkerIndex;
          if (markerIndex == null) return;
          if (_tapCandidateHadMultiTouch) {
            _clearTapCandidate();
            return;
          }

          final localPosition = globalToLocal(details.globalPosition);
          final upIndex = hitTestMarkers(localPosition);
          if (upIndex != markerIndex) {
            _clearTapCandidate();
            return;
          }

          final marker = markers[markerIndex];
          marker.onTap?.call();

          if (drawHitMarkerLast) {
            _lastSelectedMarkerIndex = markerIndex;
            markNeedsPaint();
          }

          _clearTapCandidate();
        }
        ..onTapCancel = () {
          _clearTapCandidate();
        };

  /// Clears the current tap candidate state.
  ///
  ///  This is called on successful taps, cancels, pan-zoom gestures, and
  /// other sequences where a tap can no longer be valid.
  void _clearTapCandidate() {
    _tapCandidatePointer = null;
    _tapCandidateMarkerIndex = null;
    _tapCandidateHadMultiTouch = false;
  }

  @override
  void dispose() {
    _tapGestureRecognizer.dispose();
    super.dispose();
  }

  RenderCanvasMarkerLayer({
    required List<CanvasMarker> markers,
    required MapCamera camera,
    int? lastSelectedMarkerIndex,
    bool paintDebugRect = false,
    bool paintDebugHitArea = false,
    bool cullMarkers = true,
    bool drawHitMarkerLast = false,
  }) : _markers = markers,
       _camera = camera,
       _lastSelectedMarkerIndex = lastSelectedMarkerIndex,
       _paintDebugRect = paintDebugRect,
       _paintDebugHitArea = paintDebugHitArea,
       _cullMarkers = cullMarkers,
       _drawHitMarkerLast = drawHitMarkerLast;

  // Getters and setters
  List<CanvasMarker> get markers => _markers;
  set markers(List<CanvasMarker> value) {
    if (_markers == value) return;
    _markers = value;
    markNeedsPaint();
  }

  MapCamera get camera => _camera;
  set camera(MapCamera value) {
    if (_camera == value) return;
    _camera = value;
    markNeedsPaint();
  }

  int? get lastSelectedMarkerIndex => _lastSelectedMarkerIndex;
  set lastSelectedMarkerIndex(int? value) {
    if (_lastSelectedMarkerIndex == value) return;
    _lastSelectedMarkerIndex = value;
    markNeedsPaint();
  }

  bool get paintDebugRect => _paintDebugRect;
  set paintDebugRect(bool value) {
    if (_paintDebugRect == value) return;
    _paintDebugRect = value;
    markNeedsPaint();
  }

  bool get paintDebugHitArea => _paintDebugHitArea;
  set paintDebugHitArea(bool value) {
    if (_paintDebugHitArea == value) return;
    _paintDebugHitArea = value;
    markNeedsPaint();
  }

  bool get cullMarkers => _cullMarkers;
  set cullMarkers(bool value) {
    if (_cullMarkers == value) return;
    _cullMarkers = value;
    markNeedsPaint();
  }

  bool get drawHitMarkerLast => _drawHitMarkerLast;
  set drawHitMarkerLast(bool value) {
    if (_drawHitMarkerLast == value) return;
    _drawHitMarkerLast = value;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final size = this.size;

    if (markers.isEmpty) return;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.clipRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      doAntiAlias: false,
    );

    // Padding is used to reduce pop-in at the edges when the user pans.
    //  markers are often larger than a point and may still be visible when
    // their anchor position is just outside the viewport.
    const double screenPadding = 0.0;
    CanvasMarker? selectedMarker;

    for (int i = 0; i < markers.length; i++) {
      final marker = markers[i];

      // Skip the selected marker to draw it last.
      //  This provides a deterministic "bring to front" effect for the
      // most recently interacted marker without having to reorder the list.
      if (lastSelectedMarkerIndex == i) {
        selectedMarker = marker;
        continue;
      }

      final screenOffset = camera.getOffsetFromOrigin(marker.position);
      if (marker.size != null) {
        Rect markerRect = marker.size!(
          screenOffset,
          (meters, latLong) => _metersToPixels(latLong, meters),
          (latLng, {referencePoint}) => camera.getOffsetFromOrigin(latLng),
          camera.zoom.ceil(),
        );
        //Cull rect got from marker painter
        markerRect = markerRect.inflate(screenPadding);
        if (cullMarkers &&
            (markerRect.right < 0 ||
                markerRect.left > size.width ||
                markerRect.bottom < 0 ||
                markerRect.top > size.height)) {
          continue;
        }
      } else {
        if (cullMarkers &&
            (screenOffset.dx < -screenPadding ||
                screenOffset.dx > size.width + screenPadding ||
                screenOffset.dy < -screenPadding ||
                screenOffset.dy > size.height + screenPadding)) {
          continue;
        }
      }

      // Cull markers outside visible area.
      //  Painters can be expensive; skipping off-screen markers is a
      // significant performance win for large marker sets.

      _paintMarker(canvas, marker, screenOffset, size);
    }

    // Draw selected marker last (on top).
    //  makes the last-hit marker visually prominent and ensures it
    // receives hit priority when overlapping.
    if (selectedMarker != null) {
      final screenOffset = camera.getOffsetFromOrigin(selectedMarker.position);
      _paintMarker(canvas, selectedMarker, screenOffset, size);
    }

    canvas.restore();
  }

  void _paintMarker(
    Canvas canvas,
    CanvasMarker marker,
    Offset screenOffset,
    Size size,
  ) {
    final shouldRotate = marker.rotate;

    canvas.save();

    if (shouldRotate) {
      // Only rotate the visual marker, not its anchor position.
      //  Users expect the marker to stay upright while the map rotates.
      canvas.translate(screenOffset.dx, screenOffset.dy);
      canvas.rotate(-camera.rotationRad);
      canvas.translate(-screenOffset.dx, -screenOffset.dy);
    }
    
    // Paint the marker.
    marker.painter(
      canvas,
      screenOffset,
      (meters, latLong) => _metersToPixels(latLong, meters),
      (latLng, {referencePoint}) => camera.getOffsetFromOrigin(latLng),
      camera.zoom.ceil(),
    );

    if (paintDebugRect && marker.size != null) {
      final debugPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

       canvas.drawRect(marker.size!(screenOffset,
        (meters, latLong) => _metersToPixels(latLong, meters),
        (latLng, {referencePoint}) => camera.getOffsetFromOrigin(latLng),
        camera.zoom.ceil()), debugPaint);
    }

    if (paintDebugHitArea && marker.hitArea != null) {
      final hitPath = marker.hitArea!(
        screenOffset,
        (meters, latLong) => _metersToPixels(latLong, meters),
        (ll, {referencePoint}) => camera.getOffsetFromOrigin(ll),
        camera.zoom.ceil(),
      );

      final hitPaint = Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawPath(hitPath, hitPaint);
    }

    canvas.restore();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) {
      return false;
    }

    // Always add ourselves so we can inspect pointer events in [handleEvent].
    //
    // Why we return `false`:
    // - Returning `true` here would stop hit testing and prevent FlutterMap
    //   (and other siblings) from receiving events.
    // - Returning `false` keeps the map interactive while still letting us
    //   observe pointer-down and conditionally join the gesture arena.
    //
    // This also keeps expensive marker hit-testing out of hover/move paths
    // where it would otherwise run every frame.
    result.add(BoxHitTestEntry(this, position));
    return false;
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    // Desktop trackpad pan/zoom (and some platforms) emit pan-zoom events.
    //  these represent scrolling/zooming intent and should never trigger
    // marker taps even if they begin over a marker.
    if (event is PointerPanZoomStartEvent ||
        event is PointerPanZoomUpdateEvent ||
        event is PointerPanZoomEndEvent) {
      _clearTapCandidate();
      return;
    }

    if (event is PointerDownEvent) {
      _activePointers.add(event.pointer);

      // If a second pointer goes down while we're tracking a candidate, we
      // never want to treat this sequence as a marker tap.
      if (_activePointers.length > 1) {
        _tapCandidateHadMultiTouch = true;
      }

      final index = hitTestMarkers(entry.localPosition);
      if (index == null || index < 0 || index >= markers.length) {
        return;
      }

      // Only start a tap recognizer for the first pointer.
      //
      // 
      // - Taps are single-pointer gestures.
      // - If multi-touch happens later (pinch/rotate), the recognizer will be
      //   cancelled by the arena and we also guard via
      //   [_tapCandidateHadMultiTouch].
      if (_activePointers.length != 1) {
        _tapCandidateHadMultiTouch = true;
        return;
      }

      _tapCandidatePointer = event.pointer;
      _tapCandidateMarkerIndex = index;
      _tapCandidateHadMultiTouch = false;

      // Participate in the gesture arena.
      //
      //  This prevents FlutterMap's onTap from firing when the marker tap
      // wins, but will naturally lose to pan/scale gestures.
      _tapGestureRecognizer.addPointer(event);
      return;
    }

    if (event is PointerMoveEvent) {
      // No-op.
      //  TapGestureRecognizer handles movement thresholds and cancellation.
      return;
    }

    if (event is PointerUpEvent) {
      _activePointers.remove(event.pointer);
      return;
    }

    if (event is PointerCancelEvent) {
      _activePointers.remove(event.pointer);
      if (_tapCandidatePointer == event.pointer) {
        _clearTapCandidate();
      }
      return;
    }
  }

  int? hitTestMarkers(Offset hitScreenOffset) {
    final zoom = camera.zoom;
    final rotation = camera.rotationRad;
    final isMapRotated = rotation != 0;

    // Try the last hit marker first.
    //  User interactions often repeatedly hit the same (or nearby) marker.
    // This short-circuits the full scan in common cases.
    if (_lastSelectedMarkerIndex != null &&
        _lastSelectedMarkerIndex! >= 0 &&
        _lastSelectedMarkerIndex! < markers.length) {
      final marker = markers[_lastSelectedMarkerIndex!];
      if (_isMarkerHit(
        marker,
        _lastSelectedMarkerIndex!,
        hitScreenOffset,
        zoom,
        rotation,
        isMapRotated,
      )) {
        return _lastSelectedMarkerIndex;
      }
    }

    // Search all markers from top to bottom.
    //  Painting order means later markers appear "on top"; iterating from
    // the end yields expected hit behavior for overlapping markers.
    for (int i = markers.length - 1; i >= 0; i--) {
      if (_isMarkerHit(
        markers[i],
        i,
        hitScreenOffset,
        zoom,
        rotation,
        isMapRotated,
      )) {
        _lastSelectedMarkerIndex = i;
        return i;
      }
    }

    return null;
  }

  bool _isMarkerHit(
    CanvasMarker marker,
    int index,
    Offset hitScreenOffset,
    double zoom,
    double rotation,
    bool isMapRotated,
  ) {
    // Use getOffsetFromOrigin to match the coordinate space used in painting.
    //  Using the same projection function prevents subtle discrepancies
    // between what the user sees and what can be tapped.
    final markerScreenOffset = camera.getOffsetFromOrigin(marker.position);

    // When marker.rotate = true, the painter rotates the canvas backward.
    //  this keeps the marker upright relative to the screen.
    //
    // Hit testing must rotate the pointer position forward by the same amount
    // to keep the hit target aligned with the painted marker.
    final shouldRotateHitPoint = isMapRotated && marker.rotate;

    Offset getEffectiveHitPoint() {
      if (!shouldRotateHitPoint) {
        return hitScreenOffset;
      }

      // Rotate the hit point forward to match the rotated marker's coordinate
      // space.
      final Matrix4 matrix = Matrix4.identity()
        ..translateByDouble(markerScreenOffset.dx, markerScreenOffset.dy, 0, 1)
        ..rotateZ(
          rotation,
        ) // Forward rotation to match painter's backward rotation
        ..translateByDouble(
          -markerScreenOffset.dx,
          -markerScreenOffset.dy,
          0,
          1,
        );

      final transformed = matrix.transform3(
        Vector3(hitScreenOffset.dx, hitScreenOffset.dy, 0),
      );
      return Offset(transformed.x, transformed.y);
    }

    final effectiveHitPoint = getEffectiveHitPoint();

    // --- HitArea Path ---
    //  Some markers have non-rectangular tappable areas (e.g. pin shapes).
    if (marker.hitArea != null) {
      Path hitPath = marker.hitArea!(
        markerScreenOffset,
        (meters, latLong) => _metersToPixels(latLong, meters),
        (ll, {referencePoint}) => camera.getOffsetFromOrigin(ll),
        zoom.ceil(),
      );

      if (hitPath.contains(effectiveHitPoint)) {
        return true;
      }
    } else if (marker.size != null) {
      // --- Size Rect ---
      //  Markers can specify a rectangular hit area via the size callback.
      final Rect bounds = marker.size!(
        markerScreenOffset,
        (meters, latLong) => _metersToPixels(latLong, meters),
        (ll, {referencePoint}) => camera.getOffsetFromOrigin(ll),
        zoom.ceil(),
      );

      if (bounds.contains(effectiveHitPoint)) {
        return true;
      }
    }

    return false;
  }
}
