import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/sprite_marker_layer/marker_core.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/markers/sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas.dart';
import 'package:latlong2/latlong.dart';

/// A render object that draws [SpriteMarker]s using sprite atlas rendering
/// for optimal performance when displaying many markers.
class RenderSpriteMarkerLayer extends RenderBox {
  SpriteAtlas _spriteAtlas;
  List<SpriteMarker> _markers;
  MapCamera _camera;
  bool _cullMarkers;
  bool _spriteSizeInMeters;
  AnimationPlayer? _animationPlayer;

  /// Active pointers currently down for tap detection.
  final Set<int> _activePointers = <int>{};

  /// The pointer that started a potential marker tap.
  int? _tapCandidatePointer;

  /// The marker index that was hit on pointer down.
  int? _tapCandidateMarkerIndex;

  /// Whether the tap sequence involved multi-touch at any time.
  bool _tapCandidateHadMultiTouch = false;

  RenderSpriteMarkerLayer({
    required SpriteAtlas spriteAtlas,
    required List<SpriteMarker> markers,
    required MapCamera camera,
    bool cullMarkers = true,
    bool spriteSizeInMeters = false,
    AnimationPlayer? animationPlayer,
  }) : _spriteAtlas = spriteAtlas,
       _markers = markers,
       _camera = camera,
       _cullMarkers = cullMarkers,
       _spriteSizeInMeters = spriteSizeInMeters,
       _animationPlayer = animationPlayer {
    _startListening();
  }

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

  void _onAnimationUpdate() {
    // Animations/camera updates mutate internal render buffers; repaint.
    markNeedsPaint();
  }

  bool _isListening = false;
  void _startListening() {
    if (_isListening) return;
    _animationPlayer?.addListener(_onAnimationUpdate);
    _isListening = true;
  }

  void _stopListening() {
    if (!_isListening) return;
    _animationPlayer?.removeListener(_onAnimationUpdate);
    _isListening = false;
  }

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

  bool get spriteSizeInMeters => _spriteSizeInMeters;
  set spriteSizeInMeters(bool value) {
    if (_spriteSizeInMeters != value) {
      _spriteSizeInMeters = value;
      markNeedsPaint();
    }
  }

  AnimationPlayer? get animationPlayer => _animationPlayer;
  set animationPlayer(AnimationPlayer? value) {
    if (_animationPlayer != value) {
      _stopListening();
      _animationPlayer = value;
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
    // final List<SpriteMarker> visibleMarkers = _cullMarkers
    //     ? _getVisibleMarkers()
    //     : _markers;

    // if (visibleMarkers.isEmpty) {
    //   return;
    // }

    _drawSpritesUsingAtlas(canvas, markers, offset);
  }

  /// Gets markers that are visible within the current viewport.
  List<SpriteMarker> _getVisibleMarkers() {
    final bounds = _camera.visibleBounds;
    return _markers.where((marker) {
      return bounds.contains(marker.position);
    }).toList();
  }

  /// Converts a distance in meters to screen pixels at the given [point].
  double _metersToPixels(LatLng point, double meters) {
    final south = const Distance().offset(point, meters, 180);

    final p1 = camera.getOffsetFromOrigin(point);
    final p2 = camera.getOffsetFromOrigin(south);

    return (p1 - p2).distance;
  }

  /// Draws all visible sprites using the efficient drawRawAtlas method.
  void _drawSpritesUsingAtlas(
    Canvas canvas,
    List<SpriteMarker> visibleMarkers,
    Offset offset,
  ) {
    final int markerCount = visibleMarkers.length;

    // Preallocate maximum possible size
    final Float32List rectList = Float32List(markerCount * 4);
    final Float32List transformList = Float32List(markerCount * 4);

    int writeIndex = 0;

    for (int i = 0; i < markerCount; i++) {
      final SpriteMarker marker = visibleMarkers[i];
      if (!marker.isVisible) continue;
      final double rotation = marker.rotation;
      final bool counterRotate = marker.counterRotate;
      final double scale0 = marker.scale;
      final Alignment anchor = marker.anchor;
      final int spriteIndex = marker.spriteIndex;

      // Convert world → screen
      final Offset screenOffset = _camera.getOffsetFromOrigin(marker.position);

      if (!screenOffset.dx.isFinite || !screenOffset.dy.isFinite) continue;
      // print(' index ${marker.spriteIndex}');
      final SpriteInfo spriteInfo = _spriteAtlas.getSpriteInfo(
        marker.spriteIndex,
      );

      if (spriteInfo.width <= 0 || spriteInfo.height <= 0) continue;
     

      double totalRotation = marker.rotation;
      if (marker.counterRotate) {
        totalRotation -= _camera.rotationRad;
      }

      if (!totalRotation.isFinite) continue;

      final double scale = _spriteSizeInMeters
          // Treat 1 sprite pixel as 1 meter.
          // So a 48px-wide sprite will represent 48 meters when marker.scale==1.
          ? (marker.scale * _metersToPixels(marker.position, 2))
          : marker.scale;

      if (scale <= 0) continue;

      // Convert Alignment (-1.0 to 1.0) to anchor point (0.0 to 1.0)
      final double anchorX = spriteInfo.width * (marker.anchor.x + 1.0) / 2.0;
      final double anchorY = spriteInfo.height * (marker.anchor.y + 1.0) / 2.0;

      final double dx = screenOffset.dx + offset.dx;
      final double dy = screenOffset.dy + offset.dy;
       //AABB culling
      if(dx < 0 || dy < 0) continue;
      if(dx + spriteInfo.width > _camera.size.width) continue;
      if(dy + spriteInfo.height > _camera.size.height) continue;
      
      if (!dx.isFinite || !dy.isFinite) continue;

      final RSTransform transform = RSTransform.fromComponents(
        rotation: totalRotation,
        scale: scale,
        anchorX: anchorX,
        anchorY: anchorY,
        translateX: dx,
        translateY: dy,
      );

      final int t = writeIndex * 4;

      transformList[t + 0] = transform.scos;
      transformList[t + 1] = transform.ssin;
      transformList[t + 2] = transform.tx;
      transformList[t + 3] = transform.ty;

      rectList[t + 0] = spriteInfo.x;
      rectList[t + 1] = spriteInfo.y;
      rectList[t + 2] = spriteInfo.x + spriteInfo.width;
      rectList[t + 3] = spriteInfo.y + spriteInfo.height;

      writeIndex++;
    }

    if (writeIndex == 0) return;

    final Paint paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver
      ..filterQuality = FilterQuality.high;

    // =========================
    // CHUNKED DRAWING (KEY PART)
    // =========================

    const int kAtlasBatchSize = 256; // safe for skwasm

    for (int start = 0; start < writeIndex; start += kAtlasBatchSize) {
      final int count = (start + kAtlasBatchSize <= writeIndex)
          ? kAtlasBatchSize
          : (writeIndex - start);

      canvas.drawRawAtlas(
        _spriteAtlas.image,
        Float32List.sublistView(transformList, start * 4, (start + count) * 4),
        Float32List.sublistView(rectList, start * 4, (start + count) * 4),
        null, // colors
        null,
        null,
        paint,
      );
    }
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
      if (marker is SpriteSequenceMarker && !marker.isVisible) continue;
      final Offset screenOffset = _camera.getOffsetFromOrigin(marker.position);

      // Get sprite info for hit testing
      final SpriteInfo spriteInfo = _spriteAtlas.getSpriteInfo(
        marker.spriteIndex,
      );

      final double scale = _spriteSizeInMeters
          ? (marker.scale * _metersToPixels(marker.position, 2))
          : marker.scale;

      if (!scale.isFinite || scale <= 0) continue;

      // Convert Alignment (-1.0 to 1.0) to anchor point (0.0 to 1.0)
      final double anchorX = spriteInfo.width * (marker.anchor.x + 1.0) / 2.0;
      final double anchorY = spriteInfo.height * (marker.anchor.y + 1.0) / 2.0;

      // Simple rectangular hit testing (axis-aligned, ignores rotation).
      // Position refers to the anchor point.
      final double width = spriteInfo.width * scale;
      final double height = spriteInfo.height * scale;

      // If marker rotates with map (rotate=false), its hit box rotates with map.
      // If marker stays upright (rotate=true), its hit box stays upright.
      // But we are in a rotated coordinate system (MobileLayerTransformer).
      // So if rotate=true, the marker is counter-rotated visually.
      // We need to check if localPosition is inside the rotated rect.

      // For now, let's assume simple unrotated hit box in the transformed space
      // This is an approximation but should work for small markers.
      // TODO: Implement precise rotated hit testing.

      final Rect hitRect = Rect.fromLTWH(
        screenOffset.dx - (anchorX * scale),
        screenOffset.dy - (anchorY * scale),
        width,
        height,
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
