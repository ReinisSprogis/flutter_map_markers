import 'dart:math';

import 'package:example/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_layer.dart';
import 'package:latlong2/latlong.dart' hide Path;

class PriceTagMarkerDemo extends StatefulWidget {
  const PriceTagMarkerDemo({super.key});

  @override
  State<PriceTagMarkerDemo> createState() => _PriceTagMarkerDemoState();
}

class _PriceTagMarkerDemoState extends State<PriceTagMarkerDemo> {
  List<CanvasMarker> markers = [];
  @override
  void initState() {
    super.initState();
    markers = _generateMarkers(1000);
  }

  List<CanvasMarker> _generateMarkers(int count) {
    final random = Random(100);
    List<CanvasMarker> generatedMarkers = [];

    // Paints
    final Paint borderPaint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final Paint markerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final london = LatLng(51.5074, -0.1278);
    for (int i = 0; i < count; i++) {
      // Random radial spread from city center
      double angle = random.nextDouble() * 2 * pi;
      double distance = random.nextDouble() * 0.5; // Max 2° away
      double latOffset = distance * sin(angle) * (0.7 + random.nextDouble() * 0.6);
      double lonOffset = distance * cos(angle) * (0.7 + random.nextDouble() * 0.6);
      double lat = london.latitude + latOffset;
      double lon = london.longitude + lonOffset;
      lat = lat.clamp(-90.0, 90.0);
      lon = lon.clamp(-180.0, 180.0);

      final LatLng markerPosition = LatLng(lat, lon);
    
      /// Generates a marker at the given position with the specified styles and behaviors.
      final marker = _generateMarker(markerPosition, markerPaint, borderPaint, random.nextInt(5000) + 500);
      generatedMarkers.add(marker);
    }

    return generatedMarkers;
  }

  CanvasMarker _generateMarker(LatLng position, Paint markerPaint, Paint borderPaint, int price) {
    final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: '\£$price',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
    );
    textPainter.layout();

    return CanvasMarker(
      rotate: true,
      position: position,

      painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        final double width = textPainter.width + 16;
        final double height = textPainter.height + 16;
        final double cornerRadius = 4;
        Path markerPath = Path();
        markerPath.moveTo(center.dx, center.dy);
        markerPath.lineTo(center.dx - 2.5, center.dy - 5);
        markerPath.lineTo(center.dx - width / 2 + cornerRadius, center.dy - 5);
        markerPath.arcToPoint(Offset(center.dx - width / 2, center.dy - 5 - cornerRadius), radius: Radius.circular(cornerRadius), clockwise: true);
        markerPath.lineTo(center.dx - width / 2, center.dy - height + cornerRadius);
        markerPath.arcToPoint(Offset(center.dx - width / 2 + cornerRadius, center.dy - height), radius: Radius.circular(cornerRadius), clockwise: true);
        markerPath.lineTo(center.dx + width / 2 - cornerRadius, center.dy - height);
        markerPath.arcToPoint(Offset(center.dx + width / 2, center.dy - height + cornerRadius), radius: Radius.circular(cornerRadius), clockwise: true);
        markerPath.lineTo(center.dx + width / 2, center.dy - 5 - cornerRadius);
        markerPath.arcToPoint(Offset(center.dx + width / 2 - cornerRadius, center.dy - 5), radius: Radius.circular(cornerRadius), clockwise: true);
        markerPath.lineTo(center.dx + 2.5, center.dy - 5);
        markerPath.close();
        canvas.drawPath(markerPath, markerPaint);
        canvas.drawPath(markerPath, borderPaint);
        // Draw price text

        final textOffset = center - Offset(textPainter.width / 2, (height + 5) / 2 + textPainter.height / 2);
        textPainter.paint(canvas, textOffset);
        final bounds = Rect.fromLTRB(center.dx - width / 2, center.dy - height, center.dx + width / 2, center.dy);
        return bounds;
      },
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marker at (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}) tapped!'), duration: Duration(seconds: 2)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Simple Marker Demo')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: LatLng(51.5074, -0.1278), initialZoom: 5, maxZoom: 18, minZoom: 1),
            children: [
              TileLayer(userAgentPackageName: 'com.flutter_map_markers.example', urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
              CanvasMarkerLayer(markers: markers, drawHitMarkerLast: true),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withAlpha(204), borderRadius: BorderRadius.circular(8)),
              child: const Text('Tap anywhere to add a marker', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
