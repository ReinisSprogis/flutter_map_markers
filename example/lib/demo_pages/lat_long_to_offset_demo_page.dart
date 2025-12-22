import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_layer.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
import 'package:flutter_map_markers_example/utility/utility.dart';
import 'package:latlong2/latlong.dart';

/// Demonstration of LatLng to Offset conversion by drawing lines between markers.
class LatLongToOffsetDemoPage extends StatefulWidget {
  const LatLongToOffsetDemoPage({super.key});

  @override
  State<LatLongToOffsetDemoPage> createState() =>
      _LatLongToOffsetDemoPageState();
}

class _LatLongToOffsetDemoPageState extends State<LatLongToOffsetDemoPage> {
  List<CanvasMarker> markers = [];
  @override
  void initState() {
    super.initState();
    markers = _generateMarkers(100);
  }

  final london = LatLng(51.5074, -0.1278);
  List<CanvasMarker> _generateMarkers(int count) {
    List<CanvasMarker> generatedMarkers = [];

    for (int i = 0; i < count; i++) {
      // Random radial spread from city center
      /// Pass the previous marker's position, or null for the first marker
      final LatLng? previousPosition = generatedMarkers.isNotEmpty
          ? generatedMarkers.last.position
          : null;
      final LatLng markerPosition = Utility.randomWalk(
        previousPosition ?? london,
        i,
      );
      final color = Utility.getGradientColor(i, count);

      /// Generates a marker at the given position with the specified styles and behaviors.
      final marker = _generateMarker(markerPosition, previousPosition, color);
      generatedMarkers.add(marker);
    }

    return generatedMarkers;
  }

  /// Draws an arrowhead at the end of a line
  void _drawArrowhead(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    Paint backgroundPaint,
  ) {
    const double arrowLength = 8.0;
    const double arrowAngle = 25 * pi / 180; // 25 degrees in radians

    // Calculate the direction vector from start to end
    final Offset direction = end - start;
    final double length = direction.distance;

    if (length == 0) return; // Avoid division by zero

    // Normalize the direction vector (this points from start to end)
    final Offset normalizedDirection = direction / length;

    // To draw arrowhead, we need to go backwards from the end point
    // So we use the negative direction
    final Offset backwardDirection = -normalizedDirection;

    // Calculate arrowhead points by rotating the backward direction vector
    final double cosAngle = cos(arrowAngle);
    final double sinAngle = sin(arrowAngle);

    // Rotate backward direction by +arrowAngle and -arrowAngle
    final Offset arrowPoint1 =
        Offset(
              backwardDirection.dx * cosAngle - backwardDirection.dy * sinAngle,
              backwardDirection.dx * sinAngle + backwardDirection.dy * cosAngle,
            ) *
            arrowLength +
        end;

    final Offset arrowPoint2 =
        Offset(
              backwardDirection.dx * cosAngle + backwardDirection.dy * sinAngle,
              -backwardDirection.dx * sinAngle +
                  backwardDirection.dy * cosAngle,
            ) *
            arrowLength +
        end;

    // Draw the arrowhead lines
    canvas.drawLine(end, arrowPoint1, backgroundPaint);
    canvas.drawLine(end, arrowPoint2, backgroundPaint);
    canvas.drawLine(end, arrowPoint1, paint);
    canvas.drawLine(end, arrowPoint2, paint);
  }

  CanvasMarker _generateMarker(
    LatLng position,
    LatLng? previousPosition,
    Color color,
  ) {
    /// Marker created from preset text marker with price tag.
    /// You can check the implementation by ctrl+clicking on the method name and create your own custom version based on it.
    final Paint circlePaint = Paint()..color = Colors.orange.withAlpha(128);
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final backgroundLinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    return CanvasMarker(
      position: position,
      painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        // Draw circle at marker position
        final double radius = 10.0;
        canvas.drawCircle(center, radius, circlePaint);

        // Draw line from center to previous marker position or London if first marker
        final Offset offsetPosition = latLngToPixelOffset(
          previousPosition ?? london,
        );
        // Draw background line for better visibility
        canvas.drawLine(center, offsetPosition, backgroundLinePaint);
        canvas.drawLine(center, offsetPosition, linePaint);

        // Draw arrowhead at the end of the line (at the target position)
        _drawArrowhead(
          canvas,
          center,
          offsetPosition,
          linePaint,
          backgroundLinePaint,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('LatLng to Offset')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(51.5074, -0.1278),
          initialZoom: 10,
          maxZoom: 18,
          minZoom: 1,
        ),
        children: [
          TileLayer(
            userAgentPackageName: 'com.flutter_map_markers.example',
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          CanvasMarkerLayer(
            markers: markers,
            drawHitMarkerLast: true,
            cullMarkers: false,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            markers = _generateMarkers(100);
          });
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
