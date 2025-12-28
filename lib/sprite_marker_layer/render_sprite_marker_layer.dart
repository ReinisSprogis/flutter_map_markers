import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/sprite_atlas.dart';

/// A render object that draws [SpriteMarker]s using sprite atlas rendering
/// for optimal performance when displaying many markers.
class RenderSpriteMarkerLayer extends RenderBox {
  SpriteAtlas _spriteAtlas;
  List<SpriteMarker> _markers;
  MapCamera _camera;
  bool _cullMarkers;

  /// Active pointers currently down for tap detection.
  final Set<int> _activePointers = <int>{};

  /// The pointer that started a potential marker tap.
  int? _tapCandidatePointer;

  /// The marker index that was hit on pointer down.
  int? _tapCandidateMarkerIndex;

  /// Whether the tap sequence involved multi-touch at any time.
  bool _tapCandidateHadMultiTouch = false;

  /// Recognizes taps for markers.
  late final TapGestureRecognizer _tapGestureRecognizer =
      TapGestureRecognizer(debugOwner: this)
        ..onTapUp = (details) {
          final markerIndex = _tapCandidateMarkerIndex;
          if (markerIndex == null) return;
          if (_tapCandidateHadMultiTouch) {
            _clearTapCandidate();
            return;
          }

          // Execute the marker's onTap callback if present
          if (markerIndex < _markers.length) {
            _markers[markerIndex].onTap?.call();
          }
          _clearTapCandidate();
        };

  RenderSpriteMarkerLayer({
    required SpriteAtlas spriteAtlas,
    required List<SpriteMarker> markers,
    required MapCamera camera,
    bool cullMarkers = true,
  }) : _spriteAtlas = spriteAtlas,
       _markers = markers,
       _camera = camera,
       _cullMarkers = cullMarkers;

  SpriteAtlas get spriteAtlas => _spriteAtlas;
  set spriteAtlas(SpriteAtlas value) {
    if (_spriteAtlas != value) {
      _spriteAtlas = value;
      markNeedsPaint();
    }
  }

  List<SpriteMarker> get markers => _markers;
  set markers(List<SpriteMarker> value) {
    if (_markers != value) {
      _markers = value;
      markNeedsPaint();
    }
  }

  MapCamera get camera => _camera;
  set camera(MapCamera value) {
    if (_camera != value) {
      _camera = value;
      markNeedsPaint();
    }
  }

  bool get cullMarkers => _cullMarkers;
  set cullMarkers(bool value) {
    if (_cullMarkers != value) {
      _cullMarkers = value;
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_markers.isEmpty) {
      return;
    }

    final Canvas canvas = context.canvas;
    final List<SpriteMarker> visibleMarkers = _cullMarkers
        ? _getVisibleMarkers()
        : _markers;

    if (visibleMarkers.isEmpty) {
      return;
    }

    _drawSpritesUsingAtlas(canvas, visibleMarkers, offset);
  }

  /// Gets markers that are visible within the current viewport.
  List<SpriteMarker> _getVisibleMarkers() {
    final bounds = _camera.visibleBounds;
    return _markers.where((marker) {
      return bounds.contains(marker.position);
    }).toList();
  }

  /// Draws all visible sprites using the efficient drawRawAtlas method.
  void _drawSpritesUsingAtlas(
    Canvas canvas,
    List<SpriteMarker> visibleMarkers,
    Offset offset,
  ) {
    final int markerCount = visibleMarkers.length;

    // Prepare data for drawRawAtlas
    final Float32List rectList = Float32List(markerCount * 4);
    final Float32List transformList = Float32List(markerCount * 4);
    final Int32List colorList = Int32List(markerCount);

    for (int i = 0; i < markerCount; i++) {
      final SpriteMarker marker = visibleMarkers[i];
      // Use getOffsetFromOrigin to get screen coordinates
      final Offset screenOffset = _camera.getOffsetFromOrigin(marker.position);

      // Get sprite info from atlas
      final SpriteInfo spriteInfo = _spriteAtlas.getSpriteInfo(
        marker.spriteIndex,
      );

      // Define source rectangle in sprite atlas
      rectList[i * 4 + 0] = spriteInfo.x;
      rectList[i * 4 + 1] = spriteInfo.y;
      rectList[i * 4 + 2] = spriteInfo.x + spriteInfo.width;
      rectList[i * 4 + 3] = spriteInfo.y + spriteInfo.height;

      // Calculate rotation
      // MobileLayerTransformer rotates the canvas by rotationRad (Clockwise).
      // If marker.rotate is true (Stay Upright), we must counter-rotate by rotationRad (Counter-Clockwise).
      // RSTransform rotation is Counter-Clockwise.
      // So we add rotationRad.
      double totalRotation = marker.rotation;
      if (marker.rotate) {
        totalRotation -= _camera.rotationRad;
      }

      // RSTransform handles the translate-rotate-translate automatically:
      // 1. Translates to the anchor point (center of sprite)
      // 2. Applies rotation around that point
      // 3. Translates to the final position
      final RSTransform transform = RSTransform.fromComponents(
        rotation: totalRotation,
        scale: marker.scale,
        anchorX: spriteInfo.width / 2.0,
        anchorY: spriteInfo.height / 2.0,
        translateX: screenOffset.dx,
        translateY: screenOffset.dy,
      );

      transformList[i * 4 + 0] = transform.scos;
      transformList[i * 4 + 1] = transform.ssin;
      transformList[i * 4 + 2] = transform.tx;
      transformList[i * 4 + 3] = transform.ty;

      // Handle color and alpha
      if (marker.color == Colors.transparent) {
        // For transparent color, use only alpha without color tinting
        colorList[i] = marker.alpha << 24;
      } else {
        // Combine marker alpha with the marker's base color
        colorList[i] = (marker.alpha << 24) | (marker.color.value & 0x00FFFFFF);
      }
    }

    final Paint paint = Paint();
    // Use null for colors if all markers are transparent to preserve original sprite colors
    final bool hasColorTinting = visibleMarkers.any(
      (m) => m.color != Colors.transparent,
    );

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.drawRawAtlas(
      _spriteAtlas.image,
      transformList,
      rectList,
      hasColorTinting ? colorList : null,
      BlendMode.srcOver,
      null,
      paint,
    );
    canvas.restore();
  }

  @override
  bool hitTestSelf(Offset position) {
    return true; // Always participate in hit testing
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      _handlePointerDown(event, entry);
    } else if (event is PointerUpEvent) {
      _handlePointerUp(event);
    } else if (event is PointerCancelEvent) {
      _handlePointerCancel(event);
    }
  }

  void _handlePointerDown(PointerDownEvent event, BoxHitTestEntry entry) {
    _activePointers.add(event.pointer);

    if (_activePointers.length > 1) {
      _tapCandidateHadMultiTouch = true;
      return;
    }

    final Offset localPosition = entry.localPosition;
    final int? hitMarkerIndex = _findMarkerAtPosition(localPosition);

    if (hitMarkerIndex != null) {
      _tapCandidatePointer = event.pointer;
      _tapCandidateMarkerIndex = hitMarkerIndex;
      _tapCandidateHadMultiTouch = false;
      _tapGestureRecognizer.addPointer(event);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);

    if (event.pointer == _tapCandidatePointer) {
      // Let the tap gesture recognizer handle the actual tap
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);

    if (event.pointer == _tapCandidatePointer) {
      _clearTapCandidate();
    }
  }

  /// Finds the index of the marker at the given local position, or null if none.
  int? _findMarkerAtPosition(Offset localPosition) {
    final double rotationRad = _camera.rotationRad;
    final double cosR = cos(-rotationRad);
    final double sinR = sin(-rotationRad);

    for (int i = _markers.length - 1; i >= 0; i--) {
      final SpriteMarker marker = _markers[i];
      final Offset screenOffset = _camera.getOffsetFromOrigin(marker.position);

      // Get sprite info for hit testing
      final SpriteInfo spriteInfo = _spriteAtlas.getSpriteInfo(
        marker.spriteIndex,
      );

      // Simple rectangular hit testing
      final double halfWidth = (spriteInfo.width * marker.scale) / 2;
      final double halfHeight = (spriteInfo.height * marker.scale) / 2;

      // If marker rotates with map (rotate=false), its hit box rotates with map.
      // If marker stays upright (rotate=true), its hit box stays upright.
      // But we are in a rotated coordinate system (MobileLayerTransformer).
      // So if rotate=true, the marker is counter-rotated visually.
      // We need to check if localPosition is inside the rotated rect.

      // For now, let's assume simple unrotated hit box in the transformed space
      // This is an approximation but should work for small markers.
      // TODO: Implement precise rotated hit testing.

      Rect hitRect = Rect.fromCenter(
        center: screenOffset,
        width: halfWidth * 2,
        height: halfHeight * 2,
      );

      if (hitRect.contains(localPosition)) {
        return i;
      }
    }
    return null;
  }

  void _clearTapCandidate() {
    _tapCandidatePointer = null;
    _tapCandidateMarkerIndex = null;
    _tapCandidateHadMultiTouch = false;
  }

  @override
  void detach() {
    _tapGestureRecognizer.dispose();
    super.detach();
  }
}
