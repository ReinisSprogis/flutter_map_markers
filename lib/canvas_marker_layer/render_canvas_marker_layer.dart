import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/util/no_op_canvas.dart';
import 'package:flutter_map_markers/util/utility.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

/// Custom RenderBox that paints canvas markers and owns hit testing so marker
/// taps bypass the gesture arena and block FlutterMap gestures only when a
/// marker is actually hit. Painting and hit testing share the same coordinate
/// space to keep interactions deterministic, including when the map is
/// rotated.
class RenderCanvasMarkerLayer extends RenderBox {
  List<CanvasMarker> _markers;
  MapCamera _camera;
  int? _lastSelectedMarkerIndex;
  bool _paintDebugRect;
  bool _paintDebugHitArea;
  bool _cullMarkers;
  bool _drawHitMarkerLast;

  // Tap tracking to ensure marker taps only fire for true taps, not for
  // panning/zooming/rotating gestures that started on top of a marker.
  final Set<int> _activePointers = <int>{};
  int? _tapCandidatePointer;
  int? _tapCandidateMarkerIndex;
  bool _tapCandidateHadMultiTouch = false;

  late final TapGestureRecognizer _tapGestureRecognizer = TapGestureRecognizer(debugOwner: this)
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

  double _metersToPixels(double meters, double latitude, double zoom) {
    return Utility.metersToPixels(meters, latitude, zoom);
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
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height), doAntiAlias: false);

    const double screenPadding = 100.0;
    CanvasMarker? selectedMarker;

    for (int i = 0; i < markers.length; i++) {
      final marker = markers[i];

      // Skip selected marker to draw it last
      if (lastSelectedMarkerIndex == i) {
        selectedMarker = marker;
        continue;
      }

      final screenOffset = camera.getOffsetFromOrigin(marker.position);

      // Cull markers outside visible area
      if (cullMarkers &&
          (screenOffset.dx < -screenPadding || screenOffset.dx > size.width + screenPadding || screenOffset.dy < -screenPadding || screenOffset.dy > size.height + screenPadding)) {
        continue;
      }

      _paintMarker(canvas, marker, screenOffset, size);
    }

    // Draw selected marker last (on top)
    if (selectedMarker != null) {
      final screenOffset = camera.getOffsetFromOrigin(selectedMarker.position);
      _paintMarker(canvas, selectedMarker, screenOffset, size);
    }

    canvas.restore();
  }

  void _paintMarker(Canvas canvas, CanvasMarker marker, Offset screenOffset, Size size) {
    final shouldRotate = marker.rotate;

    canvas.save();

    if (shouldRotate) {
      // Only rotate visual marker, not position
      canvas.translate(screenOffset.dx, screenOffset.dy);
      canvas.rotate(-camera.rotationRad);
      canvas.translate(-screenOffset.dx, -screenOffset.dy);
    }

    final rect = marker.painter(
      canvas,
      screenOffset,
      (meters, latitude) => _metersToPixels(meters, latitude, camera.zoom),
      (latLng, {referencePoint}) => camera.getOffsetFromOrigin(latLng),
      camera.zoom.ceil(),
    );

    if (paintDebugRect) {
      final debugPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(rect, debugPaint);
    }

    if (paintDebugHitArea && marker.hitArea != null) {
      final hitPath = marker.hitArea!(
        screenOffset,
        (meters, lat) => _metersToPixels(meters, lat, camera.zoom),
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

    // Always add ourselves so we can inspect PointerDown events in handleEvent,
    // but return false so FlutterMap and other siblings still participate in
    // hit testing. This keeps marker hit-testing out of hover/move paths where
    // it would otherwise run every frame.
    result.add(BoxHitTestEntry(this, position));
    return false;
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    // Desktop trackpad pan/zoom (and some platforms) emit pan-zoom events.
    // These should never trigger marker taps.
    if (event is PointerPanZoomStartEvent || event is PointerPanZoomUpdateEvent || event is PointerPanZoomEndEvent) {
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

      // Only start a tap recognizer for the first pointer. If multi-touch
      // happens later (pinch/rotate), the recognizer will be cancelled by the
      // arena and we additionally guard via `_tapCandidateHadMultiTouch`.
      if (_activePointers.length != 1) {
        _tapCandidateHadMultiTouch = true;
        return;
      }

      _tapCandidatePointer = event.pointer;
      _tapCandidateMarkerIndex = index;
      _tapCandidateHadMultiTouch = false;

      // Participate in the gesture arena. This prevents FlutterMap's onTap from
      // firing when the marker tap wins, but will naturally lose to pan/scale.
      _tapGestureRecognizer.addPointer(event);
      return;
    }

    if (event is PointerMoveEvent) {
      // No-op: TapGestureRecognizer handles movement and cancellation.
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

    // Try last hit marker first for performance
    if (_lastSelectedMarkerIndex != null && _lastSelectedMarkerIndex! >= 0 && _lastSelectedMarkerIndex! < markers.length) {
      final marker = markers[_lastSelectedMarkerIndex!];
      if (_isMarkerHit(marker, _lastSelectedMarkerIndex!, hitScreenOffset, zoom, rotation, isMapRotated)) {
        return _lastSelectedMarkerIndex;
      }
    }

    // Search all markers from top to bottom
    for (int i = markers.length - 1; i >= 0; i--) {
      if (_isMarkerHit(markers[i], i, hitScreenOffset, zoom, rotation, isMapRotated)) {
        _lastSelectedMarkerIndex = i;
        return i;
      }
    }

    return null;
  }

  bool _isMarkerHit(CanvasMarker marker, int index, Offset hitScreenOffset, double zoom, double rotation, bool isMapRotated) {
    // Use getOffsetFromOrigin to match the coordinate space used in the painter
    final markerScreenOffset = camera.getOffsetFromOrigin(marker.position);

    // When marker.rotate = true, the painter rotates the canvas backward
    // so we need to rotate the hit point forward to match
    // When marker.rotate = false, no rotation is applied
    final shouldRotateHitPoint = isMapRotated && marker.rotate;

    Offset getEffectiveHitPoint() {
      if (!shouldRotateHitPoint) {
        return hitScreenOffset;
      }

      // Rotate the hit point forward to match the rotated marker's coordinate space
      final Matrix4 matrix = Matrix4.identity()
        ..translateByDouble(markerScreenOffset.dx, markerScreenOffset.dy, 0, 1)
        ..rotateZ(rotation) // Forward rotation to match painter's backward rotation
        ..translateByDouble(-markerScreenOffset.dx, -markerScreenOffset.dy, 0, 1);

      final transformed = matrix.transform3(Vector3(hitScreenOffset.dx, hitScreenOffset.dy, 0));
      return Offset(transformed.x, transformed.y);
    }

    final effectiveHitPoint = getEffectiveHitPoint();

    // --- HitArea Path ---
    if (marker.hitArea != null) {
      Path hitPath = marker.hitArea!(
        markerScreenOffset,
        (meters, lat) => Utility.metersToPixels(meters, marker.position.latitude, zoom),
        (ll, {referencePoint}) => camera.getOffsetFromOrigin(ll),
        zoom.ceil(),
      );

      if (hitPath.contains(effectiveHitPoint)) {
        return true;
      }
    }
    // --- Fallback Rect ---
    else {
      final Rect bounds = marker.painter(
        NoOpCanvas(),
        markerScreenOffset,
        (meters, lat) => Utility.metersToPixels(meters, marker.position.latitude, zoom),
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
