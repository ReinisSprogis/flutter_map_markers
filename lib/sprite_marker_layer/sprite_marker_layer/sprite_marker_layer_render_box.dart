import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/sprite_marker_layer/marker_core.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/markers/sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas.dart';
import 'package:latlong2/latlong.dart';

/// Cached projection parameters to avoid expensive per-marker calculations.
class _ProjectionCache {
  final Crs crs;
  final double zoomScale;
  final double originX;
  final double originY;

  _ProjectionCache({
    required this.crs,
    required this.zoomScale,
    required this.originX,
    required this.originY,
  });

  /// Creates a projection cache from the current camera state.
  factory _ProjectionCache.fromCamera(MapCamera camera) {
    final crs = camera.crs;
    final zoomScale = crs.scale(camera.zoom);
    final origin = camera.pixelOrigin;
    return _ProjectionCache(
      crs: crs,
      zoomScale: zoomScale,
      originX: origin.dx,
      originY: origin.dy,
    );
  }

  /// Converts a LatLng to screen offset using cached projection parameters.
  /// Equivalent to camera.getOffsetFromOrigin() but much faster for batch operations.
  Offset latLngToOffset(LatLng point) {
    final (x, y) = crs.latLngToXY(point, zoomScale);
    return Offset(x - originX, y - originY);
  }
}

/// A render object that draws [SpriteMarker]s using sprite atlas rendering
/// for optimal performance when displaying many markers.
class RenderSpriteMarkerLayer extends RenderBox {
  SpriteAtlas _spriteAtlas;
  List<SpriteMarker> _markers;
  MapCamera _camera;
  bool _cullMarkers;
  AnimationPlayer? _animationPlayer;

  /// Active pointers currently down for tap detection.
  final Set<int> _activePointers = <int>{};

  /// The pointer that started a potential marker tap.
  int? _tapCandidatePointer;

  /// The marker index that was hit on pointer down.
  int? _tapCandidateMarkerIndex;

  /// Whether the tap sequence involved multi-touch at any time.
  bool _tapCandidateHadMultiTouch = false;

  // Preallocate maximum possible size
  Float32List? rectList;
  Float32List? transformList;

  /// Cached pixel data for transparency hit testing.
  ByteData? _atlasPixelData;
  int _atlasPixelWidth = 0;
  int _atlasPixelHeight = 0;

  /// Threshold for alpha channel to consider a pixel as "hit" (0-255).
  static const int _alphaHitThreshold = 10;

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
       _animationPlayer = animationPlayer {
    _startListening();
    _loadAtlasPixelData();
  }

  /// Loads pixel data from the sprite atlas for transparency hit testing.
  Future<void> _loadAtlasPixelData() async {
    final image = _spriteAtlas.image;
    _atlasPixelWidth = image.width;
    _atlasPixelHeight = image.height;
    _atlasPixelData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
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
      _atlasPixelData = null; // Invalidate cached pixel data
      _loadAtlasPixelData();
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
    final int markerCount = _markers.length;
    if (markerCount == 0) return;

    final Canvas canvas = context.canvas;

    // Ensure buffers are large enough (grow only, never shrink)
    final int requiredSize = markerCount * 4;
    if (rectList == null || rectList!.length < requiredSize) {
      rectList = Float32List(requiredSize);
    }
    if (transformList == null || transformList!.length < requiredSize) {
      transformList = Float32List(requiredSize);
    }

    _drawSpritesUsingAtlas(canvas, _markers, offset);
  }

  /// Gets markers that are visible within the current viewport.
  /// Note not implemented as it takes more time than it saves.
  /// It is faster to just draw all markers with the GPU.
  /// Perhaps revisit this in the future.
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

  Paint spritePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.srcOver
    ..filterQuality = FilterQuality.high;

  /// Draws all visible sprites using the efficient drawRawAtlas method.
  void _drawSpritesUsingAtlas(
    Canvas canvas,
    List<SpriteMarker> visibleMarkers,
    Offset offset,
  ) {
    final int markerCount = visibleMarkers.length;
    final cameraRect = _camera.crs.projection.bounds;

    // Cache camera rotation once per frame
    final double cameraRotationRad = _camera.rotationRad;

    // Cache projection parameters once per frame for efficient batch conversion
    final projCache = _ProjectionCache.fromCamera(_camera);

    // Direct buffer references to avoid repeated null checks
    final Float32List transforms = transformList!;
    final Float32List rects = rectList!;

    int writeIndex = 0;

    for (int i = 0; i < markerCount; i++) {
      final SpriteMarker marker = visibleMarkers[i];
      if (!marker.isVisible) continue;

      // Cache polymorphic accesses
      final int spriteIndex = marker.spriteIndex;
      final SpriteInfo spriteInfo = _spriteAtlas.getSpriteInfo(spriteIndex);

      // Early continue for invalid sprites
      final double spriteWidth = spriteInfo.width;
      final double spriteHeight = spriteInfo.height;
      if (spriteWidth <= 0 || spriteHeight <= 0) continue;

      final double markerScale = marker.scale;
      final bool spriteSizeInMeters = marker.spriteSizeInMeters;

      final double scale = spriteSizeInMeters
          ? (markerScale * _metersToPixels(marker.position, 2))
          : markerScale;

      if (scale <= 0) continue;

      // Convert world → screen using cached projection (much faster than getOffsetFromOrigin)
      final Offset screenOffset = projCache.latLngToOffset(marker.position);

      double totalRotation = marker.rotation;
      if (marker.counterRotate) {
        totalRotation -= cameraRotationRad;
      }

      // Convert Alignment (-1..1) → anchor in pixels
      final Alignment anchor = marker.anchor;
      final double anchorX = spriteWidth * (anchor.x + 1.0) * 0.5;
      final double anchorY = spriteHeight * (anchor.y + 1.0) * 0.5;

      final double dx = screenOffset.dx + offset.dx + marker.transform.dx;
      final double dy = screenOffset.dy + offset.dy + marker.transform.dy;

      // Compute transform directly (avoid RSTransform allocation)
      double scos = scale;
      double ssin = 0.0;
      if (totalRotation != 0.0) {
        scos = math.cos(totalRotation) * scale;
        ssin = math.sin(totalRotation) * scale;
      }

      final int t = writeIndex * 4;

      transforms[t] = scos;
      transforms[t + 1] = ssin;
      transforms[t + 2] = dx - anchorX * scos + anchorY * ssin;
      transforms[t + 3] = dy - anchorX * ssin - anchorY * scos;

      rects[t] = spriteInfo.x;
      rects[t + 1] = spriteInfo.y;
      rects[t + 2] = spriteInfo.x + spriteWidth;
      rects[t + 3] = spriteInfo.y + spriteHeight;

      writeIndex++;
    }

    if (writeIndex == 0) return;

    const int kAtlasBatchSize = 256; // skwasm-safe

    for (int start = 0; start < writeIndex; start += kAtlasBatchSize) {
      final int count = (start + kAtlasBatchSize <= writeIndex)
          ? kAtlasBatchSize
          : (writeIndex - start);

      canvas.drawRawAtlas(
        _spriteAtlas.image,
        Float32List.sublistView(transforms, start * 4, (start + count) * 4),
        Float32List.sublistView(rects, start * 4, (start + count) * 4),
        null,
        null,
        cameraRect,
        spritePaint,
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
  /// Uses two-layer hit testing: first bounding rect, then pixel transparency.
  int? _findMarkerAtPosition(Offset localPosition) {
    final double cameraRotationRad = _camera.rotationRad;

    // Cache projection parameters for efficient batch conversion
    final projCache = _ProjectionCache.fromCamera(_camera);

    for (int i = _markers.length - 1; i >= 0; i--) {
      final SpriteMarker marker = _markers[i];
      if (!marker.isVisible) continue;

      // Use cached projection instead of expensive getOffsetFromOrigin
      final Offset screenOffset = projCache.latLngToOffset(marker.position);

      // Get sprite info for hit testing
      final SpriteInfo spriteInfo = _spriteAtlas.getSpriteInfo(
        marker.spriteIndex,
      );
      final double spriteWidth = spriteInfo.width;
      final double spriteHeight = spriteInfo.height;

      if (spriteWidth <= 0 || spriteHeight <= 0) continue;

      final double scale = marker.spriteSizeInMeters
          ? (marker.scale * _metersToPixels(marker.position, 2))
          : marker.scale;

      if (!scale.isFinite || scale <= 0) continue;

      // Convert Alignment (-1.0 to 1.0) to anchor point
      final Alignment anchor = marker.anchor;
      final double anchorX = spriteWidth * (anchor.x + 1.0) * 0.5;
      final double anchorY = spriteHeight * (anchor.y + 1.0) * 0.5;

      final double width = spriteWidth * scale;
      final double height = spriteHeight * scale;

      // Calculate marker total rotation
      double totalRotation = marker.rotation;
      if (marker.counterRotate) {
        totalRotation -= cameraRotationRad;
      }

      // Transform local position to marker-local coordinates
      final double markerCenterX = screenOffset.dx + marker.transform.dx;
      final double markerCenterY = screenOffset.dy + marker.transform.dy;

      // Offset from marker anchor to hit point
      double hitDx = localPosition.dx - markerCenterX;
      double hitDy = localPosition.dy - markerCenterY;

      // Rotate hit point into marker's local coordinate system if rotated
      if (totalRotation != 0.0) {
        final double cosR = math.cos(-totalRotation);
        final double sinR = math.sin(-totalRotation);
        final double rotatedDx = hitDx * cosR - hitDy * sinR;
        final double rotatedDy = hitDx * sinR + hitDy * cosR;
        hitDx = rotatedDx;
        hitDy = rotatedDy;
      }

      // Convert to sprite-local coordinates (0,0 at top-left of sprite)
      final double localX = hitDx + anchorX * scale;
      final double localY = hitDy + anchorY * scale;

      // First layer: bounding rect hit test
      if (localX < 0 || localX >= width || localY < 0 || localY >= height) {
        continue;
      }

      // Second layer: pixel transparency hit test
      if (_isPixelTransparent(spriteInfo, localX, localY, scale)) {
        continue;
      }

      return i;
    }
    return null;
  }

  /// Checks if the pixel at the given local coordinates is transparent.
  /// [localX] and [localY] are in scaled screen coordinates relative to sprite top-left.
  bool _isPixelTransparent(
    SpriteInfo spriteInfo,
    double localX,
    double localY,
    double scale,
  ) {
    final ByteData? pixelData = _atlasPixelData;
    if (pixelData == null) {
      // Pixel data not loaded yet, treat as opaque (pass hit test)
      return false;
    }

    // Convert screen coordinates to sprite pixel coordinates
    final int spritePixelX = (localX / scale).floor();
    final int spritePixelY = (localY / scale).floor();

    // Check bounds within sprite
    if (spritePixelX < 0 ||
        spritePixelX >= spriteInfo.width.toInt() ||
        spritePixelY < 0 ||
        spritePixelY >= spriteInfo.height.toInt()) {
      return true; // Outside sprite bounds = transparent
    }

    // Calculate atlas pixel coordinates
    final int atlasX = spriteInfo.x.toInt() + spritePixelX;
    final int atlasY = spriteInfo.y.toInt() + spritePixelY;

    // Bounds check for atlas
    if (atlasX < 0 ||
        atlasX >= _atlasPixelWidth ||
        atlasY < 0 ||
        atlasY >= _atlasPixelHeight) {
      return true;
    }

    // RGBA format: 4 bytes per pixel, alpha is the 4th byte (index 3)
    final int pixelIndex = (atlasY * _atlasPixelWidth + atlasX) * 4;
    final int alpha = pixelData.getUint8(pixelIndex + 3);

    return alpha < _alphaHitThreshold;
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
