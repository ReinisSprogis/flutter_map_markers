import 'package:example/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_layer.dart';
import 'package:latlong2/latlong.dart';

/// Demonstration of markers that visualize a radius in meters converted to pixels.
class MetersToPixelsDemoPage extends StatefulWidget {
  const MetersToPixelsDemoPage({super.key});

  @override
  State<MetersToPixelsDemoPage> createState() => _MetersToPixelsDemoPageState();
}

class _MetersToPixelsDemoPageState extends State<MetersToPixelsDemoPage> {
  List<CanvasMarker> markers = [];

  @override
  void initState() {
    super.initState();
    final london = LatLng(51.5074, -0.1278);
    markers.add(_createMarker(london, 10000)); // 10 km radius
  }

  CanvasMarker _createMarker(LatLng position, double radius) {

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '${(radius / 1000).toStringAsFixed(1)} km',
        style: TextStyle(color: Colors.black, fontSize: 14,fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    return CanvasMarker(
      rotate: true,
      position: position,
      painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        final paint = Paint()..color = Colors.blue.withAlpha(128);
        final strokePaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        final radiusInMeters = 10000.0;
        // Get radius in pixels based on current latitude
        final radiusInPixels = metersToPixels(radiusInMeters, position);
        // Draw circle
        canvas.drawCircle(center, radiusInPixels, paint);
        

        if (zoomLevel > 8) {
          // Draw text above the circle to indicate radius
          textPainter.paint(canvas, Offset(center.dx + (radiusInPixels / 2), center.dy - 25));
          // Draw stroke from the center to the edge of the circle.
          canvas.drawLine(center, Offset(center.dx + radiusInPixels, center.dy), strokePaint);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Meters to Pixels')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(51.5074, -0.1278),
              initialZoom: 12,
              maxZoom: 18,
              minZoom: 1,
              onTap: (tapPosition, point) {
                setState(() {
                  markers = [...markers, _createMarker(point, 10000)];
                });
              },
            ),
            children: [
              TileLayer(userAgentPackageName: 'com.flutter_map_markers.example', urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
              CanvasMarkerLayer(markers: markers, cullMarkers: false),
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
