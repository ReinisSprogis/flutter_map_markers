import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';

/// A custom painter that draws all visible markers on the screen at once,
/// rather than painting them tile by tile.
class CanvasMarkerLayerPainter extends CustomPainter {
  /// List of markers to be drawn on the canvas.
  final List<CanvasMarker> markers;
  /// Camera used for calculating marker positions.
  final MapCamera camera;
  /// Optional index of the last selected marker to draw it last.
  final int? lastSelectedMarkerIndex;
  /// Whether to paint debug rectangles around markers.
  final bool paintDebugRect;
  /// Whether to paint debug hit areas for markers.
  final bool paintDebugHitArea;

  /// Whether to cull markers that are outside the visible area.
  final bool cullMarkers;

  CanvasMarkerLayerPainter({required this.markers, required this.camera, this.lastSelectedMarkerIndex, required this.paintDebugRect, required this.paintDebugHitArea, required this.cullMarkers});
  // If marker index matching the latest hit test, draw it last.
  CanvasMarker? _selectedMarker;

  double metersToPixels(double meters, double latitude, double zoom) {
    double tileSize = 255.0;
    const earthCircumference = 40075016.686;
    const maxLat = 85.05112878;

    final clampedLat = latitude.clamp(-maxLat, maxLat);
    final latitudeRadians = clampedLat * pi / 180.0;
    final scale = tileSize * pow(2.0, zoom);

    final metersPerPixel = earthCircumference * cos(latitudeRadians) / scale;
    return meters / metersPerPixel;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (markers.isNotEmpty) {}

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height), doAntiAlias: false);

    const double screenPadding = 100.0;

    for (int i = 0; i < markers.length; i++) {
      final marker = markers[i];
      if (lastSelectedMarkerIndex == i) {
        _selectedMarker = marker;
        continue;
      }

      final screenOffset = camera.getOffsetFromOrigin(marker.position);
      if (cullMarkers && (screenOffset.dx < -screenPadding || screenOffset.dx > size.width + screenPadding || screenOffset.dy < -screenPadding || screenOffset.dy > size.height + screenPadding)) {
        continue;
      }

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
        (meters, latitude) => metersToPixels(meters, latitude, camera.zoom),
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
          (meters, lat) => metersToPixels(meters, lat, camera.zoom),
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

    // Draw selected marker last
    if (_selectedMarker != null) {
      final marker = _selectedMarker!;
      final screenOffset = camera.getOffsetFromOrigin(marker.position);
      final shouldRotate = marker.rotate;

      canvas.save();

      if (shouldRotate) {
        canvas.translate(screenOffset.dx, screenOffset.dy);
        canvas.rotate(-camera.rotationRad);
        canvas.translate(-screenOffset.dx, -screenOffset.dy);
      }

      final rect = marker.painter(
        canvas,
        screenOffset,
        (meters, latitude) => metersToPixels(meters, latitude, camera.zoom),
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
          (meters, lat) => metersToPixels(meters, lat, camera.zoom),
          (ll, {referencePoint}) => camera.getOffsetFromOrigin(ll),
          camera.zoom.ceil(),
        );

        final hitPaint = Paint()
          ..color = Colors.deepOrange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawPath(hitPath, hitPaint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CanvasMarkerLayerPainter oldDelegate) {
    // Repaint if the marker list or camera has changed
    return oldDelegate.markers != markers || oldDelegate.camera != camera || oldDelegate.lastSelectedMarkerIndex != lastSelectedMarkerIndex ||
           oldDelegate.paintDebugRect != paintDebugRect || oldDelegate.paintDebugHitArea != paintDebugHitArea;
  }
}
