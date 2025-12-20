import 'package:example/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_layer.dart';
import 'package:flutter_map_markers/marker_presets/marker_presets.dart';
import 'package:latlong2/latlong.dart';

/// A demo page showcasing ball-shaped markers on a Flutter map.
class BallMarkerDemoPage extends StatefulWidget {
  const BallMarkerDemoPage({super.key});

  @override
  State<BallMarkerDemoPage> createState() => _BallMarkerDemoPageState();
}

class _BallMarkerDemoPageState extends State<BallMarkerDemoPage> {
  List<CanvasMarker> markers = [];

  @override
  void initState() {
    super.initState();
    final london = LatLng(51.5074, -0.1278);
    markers.add(_createMarker(london));
  }

  CanvasMarker _createMarker(LatLng position) {
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blueAccent;
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white
      ..strokeWidth = 2.0;
    final Paint centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red;
    final Paint rectPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    return CanvasMarker(
      rotate: true,
      position: position,
      hitArea: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        final (markerPath, _) = MarkerPresets.ballMarkerPath(
          center,
          ballRadius: 15,
          knobHeight: 10,
        );
        return markerPath;
      },
      painter:
          (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
            final (markerPath, ballCenter) = MarkerPresets.ballMarkerPath(
              center,
              ballRadius: 15,
              knobHeight: 10,
            );
            canvas.drawPath(markerPath, fillPaint);
            canvas.drawPath(markerPath, strokePaint);
            canvas.drawCircle(ballCenter, 12, centerPaint);
            canvas.drawRect(
              Rect.fromCenter(center: ballCenter, width: 20, height: 8),
              rectPaint,
            );
          },
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Road closed at (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Ball Marker')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(51.5074, -0.1278),
              initialZoom: 5,
              maxZoom: 18,
              minZoom: 1,
              onTap: (tapPosition, point) {
                setState(() {
                  markers = [...markers, _createMarker(point)];
                });
              },
            ),
            children: [
              TileLayer(
                userAgentPackageName: 'com.flutter_map_markers.example',
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              CanvasMarkerLayer(markers: markers, drawHitMarkerLast: true),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(204),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tap anywhere to add a marker',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
