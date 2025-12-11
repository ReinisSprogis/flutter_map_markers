import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_layer_painter.dart';
import 'package:flutter_map_markers/util/no_op_canvas.dart';
import 'package:flutter_map_markers/util/utility.dart';

/// Draw markers directly on canvas without option for rasterization.
/// Use this layer if you want to draw markers without the overhead of rasterization.

/// Draw markers directly on canvas without option for rasterization.
/// Use this layer if you want to draw markers without the overhead of rasterization.
class CanvasMarkerLayer extends StatefulWidget {
  /// List of markers to be drawn on the canvas.
  final List<CanvasMarker> markers;

  /// Whether to show debug marker bounds rectangles.
  final bool showDebugRect;

  /// Whether to show debug hit areas for markers.
  final bool showDebugHitArea;

  /// If you perform hit testing, this determines whether the hit marker is drawn last.
  /// Ensures the hit marker is always on top of other markers.
  final bool drawHitMarkerLast;

  /// Whether to cull markers that are outside the visible area.
  final bool cullMarkers;

  /// Duration for debouncing hover events to prevent excessive callback invocations.
  /// Set to Duration.zero to disable debouncing.
  /// Defaults to 50 milliseconds.
  final Duration hoverDebounceDuration;

  const CanvasMarkerLayer({
    super.key,
    required this.markers,
    this.showDebugRect = false,
    this.showDebugHitArea = false,
    this.drawHitMarkerLast = false,
    this.cullMarkers = true,
    this.hoverDebounceDuration = const Duration(milliseconds: 50),
  });

  @override
  State<CanvasMarkerLayer> createState() => _CanvasMarkerLayerState();
}

class _CanvasMarkerLayerState extends State<CanvasMarkerLayer> {
  MapCamera? _camera;
  int? _lastHitMarkerIndex;
  int? _hoveredMarkerIndex;
  Timer? _hoverDebounceTimer;
  int? _pendingHoverMarkerIndex;

  // Gesture usage flags
  late bool _hasAnyTapGesture;
  late bool _hasAnyDoubleTapGesture;
  late bool _hasAnyLongPressGesture;
  late bool _hasAnyHoverGesture;

  @override
  void initState() {
    super.initState();
    _checkGestureUsage();
  }

  void _checkGestureUsage() {
    _hasAnyTapGesture = false;
    _hasAnyDoubleTapGesture = false;
    _hasAnyLongPressGesture = false;
    _hasAnyHoverGesture = false;

    for (final marker in widget.markers) {
      if (marker.onTap != null) _hasAnyTapGesture = true;
      if (marker.onDoubleTap != null) _hasAnyDoubleTapGesture = true;
      if (marker.onLongPress != null) _hasAnyLongPressGesture = true;
      if (marker.onHover != null) _hasAnyHoverGesture = true;

      // Early exit if all gestures are found
      if (_hasAnyTapGesture && _hasAnyDoubleTapGesture && _hasAnyLongPressGesture && _hasAnyHoverGesture) {
        break;
      }
    }
  }

  @override
  void didUpdateWidget(CanvasMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) {
      _checkGestureUsage();
    }
  }

  @override
  void dispose() {
    _hoverDebounceTimer?.cancel();
    super.dispose();
  }

  void _handleHover(int? newHitMarkerIndex) {
    if (newHitMarkerIndex != _hoveredMarkerIndex) {
      // Call onHover(false) for previously hovered marker
      if (_hoveredMarkerIndex != null && _hoveredMarkerIndex! < widget.markers.length) {
        final prevMarker = widget.markers[_hoveredMarkerIndex!];
        if (prevMarker.onHover != null) {
          prevMarker.onHover!(false);
        }
      }
      // Call onHover(true) for newly hovered marker
      if (newHitMarkerIndex != null && newHitMarkerIndex < widget.markers.length) {
        final marker = widget.markers[newHitMarkerIndex];
        if (marker.onHover != null) {
          marker.onHover!(true);
        }
      }
      _hoveredMarkerIndex = newHitMarkerIndex;
    }
  }

  int? _hitTestOffset(Offset hitScreenOffset) {
    final zoom = _camera!.zoom;
    final rotation = _camera!.rotationRad;
    final isMapRotated = rotation != 0;

    // Try last hit marker first
    if (_lastHitMarkerIndex != null && _lastHitMarkerIndex! >= 0 && _lastHitMarkerIndex! < widget.markers.length) {
      final marker = widget.markers[_lastHitMarkerIndex!];
      if (_isMarkerHit(marker, _lastHitMarkerIndex!, hitScreenOffset, zoom, rotation, isMapRotated)) {
        return _lastHitMarkerIndex;
      }
    }

    // Search all markers from top to bottom
    for (int i = widget.markers.length - 1; i >= 0; i--) {
      if (_isMarkerHit(widget.markers[i], i, hitScreenOffset, zoom, rotation, isMapRotated)) {
        return i;
      }
    }

    if (widget.drawHitMarkerLast) {
      _lastHitMarkerIndex = null;
    }

    return null;
  }

  bool _isMarkerHit(CanvasMarker marker, int index, Offset hitScreenOffset, double zoom, double rotation, bool isMapRotated) {
    final markerScreenOffset = _camera!.latLngToScreenOffset(marker.position);
    final shouldRotatePath = isMapRotated && !marker.rotate;

    Path applyRotation(Path path) {
      final Matrix4 matrix = Matrix4.identity()
        ..translate(markerScreenOffset.dx, markerScreenOffset.dy)
        ..rotateZ(rotation)
        ..translate(-markerScreenOffset.dx, -markerScreenOffset.dy);
      return path.transform(matrix.storage);
    }

    // --- HitArea Path ---
    if (marker.hitArea != null) {
      Path hitPath = marker.hitArea!(
        markerScreenOffset,
        (meters, lat) => Utility.metersToPixels(meters, marker.position.latitude, zoom),
        (ll, {referencePoint}) => _camera!.latLngToScreenOffset(ll),
        zoom.ceil(),
      );

      if (shouldRotatePath) {
        hitPath = applyRotation(hitPath);
      }

      if (hitPath.contains(hitScreenOffset)) {
        if (widget.drawHitMarkerLast) {
          _lastHitMarkerIndex = index;
        }
        return true;
      }
    }
    // --- Fallback Rect ---
    else {
      final Rect bounds = marker.painter(
        NoOpCanvas(),
        markerScreenOffset,
        (meters, lat) => Utility.metersToPixels(meters, marker.position.latitude, zoom),
        (ll, {referencePoint}) => _camera!.latLngToScreenOffset(ll),
        zoom.ceil(),
      );

      if (shouldRotatePath) {
        Path rotatedRect = applyRotation(Path()..addRect(bounds));
        if (rotatedRect.contains(hitScreenOffset)) {
          if (widget.drawHitMarkerLast) {
            _lastHitMarkerIndex = index;
          }
          return true;
        }
      } else {
        if (bounds.contains(hitScreenOffset)) {
          if (widget.drawHitMarkerLast) {
            _lastHitMarkerIndex = index;
          }
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    _camera = MapCamera.of(context);

    return MobileLayerTransformer(
      child: MouseRegion(
        onHover: !_hasAnyHoverGesture
            ? null
            : (event) {
                final hitMarkerIndex = _hitTestOffset(event.localPosition);

                if (widget.hoverDebounceDuration == Duration.zero) {
                  // No debouncing - handle immediately
                  _handleHover(hitMarkerIndex);
                } else {
                  // Apply debouncing
                  _pendingHoverMarkerIndex = hitMarkerIndex;
                  _hoverDebounceTimer?.cancel();
                  _hoverDebounceTimer = Timer(widget.hoverDebounceDuration, () {
                    if (mounted && _pendingHoverMarkerIndex != _hoveredMarkerIndex) {
                      _handleHover(_pendingHoverMarkerIndex);
                    }
                  });
                }
              },
        onExit: !_hasAnyHoverGesture
            ? null
            : (event) {
                _hoverDebounceTimer?.cancel();
                _handleHover(null);
              },
        child: GestureDetector(
          onTapUp: !_hasAnyTapGesture
              ? null
              : (TapUpDetails details) {
                  final hitMarkerIndex = _hitTestOffset(details.localPosition);
                  if (hitMarkerIndex != null) {
                    final marker = widget.markers[hitMarkerIndex];
                    if (marker.onTap != null) {
                      marker.onTap!();
                    }
                  }
                },
          onDoubleTapDown: !_hasAnyDoubleTapGesture
              ? null
              : (TapDownDetails details) {
                  final hitMarkerIndex = _hitTestOffset(details.localPosition);
                  if (hitMarkerIndex != null) {
                    final marker = widget.markers[hitMarkerIndex];
                    if (marker.onDoubleTap != null) {
                      marker.onDoubleTap!();
                    }
                  }
                },
          onLongPressStart: !_hasAnyLongPressGesture
              ? null
              : (LongPressStartDetails details) {
                  final hitMarkerIndex = _hitTestOffset(details.localPosition);
                  if (hitMarkerIndex != null) {
                    final marker = widget.markers[hitMarkerIndex];
                    if (marker.onLongPress != null) {
                      marker.onLongPress!();
                    }
                  }
                },
          child: RepaintBoundary(
            child: CustomPaint(
              willChange: true,
              painter: CanvasMarkerLayerPainter(
                markers: widget.markers,
                camera: _camera!,
                paintDebugHitArea: widget.showDebugHitArea,
                paintDebugRect: widget.showDebugRect,
                lastSelectedMarkerIndex: widget.drawHitMarkerLast ? _lastHitMarkerIndex : null,
                cullMarkers: widget.cullMarkers,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
