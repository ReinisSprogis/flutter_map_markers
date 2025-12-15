import 'package:example/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_layer.dart';
import 'package:flutter_map_markers/marker_presets/marker_presets.dart';
import 'package:latlong2/latlong.dart';

class MarkerDemoSimple extends StatefulWidget {
  const MarkerDemoSimple({super.key});

  @override
  State<MarkerDemoSimple> createState() => _MarkerDemoSimpleState();
}

class _MarkerDemoSimpleState extends State<MarkerDemoSimple> {
  List<CanvasMarker> markers = [];

  @override
  void initState() {
    super.initState();
    final london = LatLng(51.5074, -0.1278);
    markers.add(_createMarker(london));
  }

  CanvasMarker _createMarker(LatLng position) {
    final Paint borderPaint = Paint()
      ..color = Color(0xff81342d)
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint circlePaint = Paint()
      ..color = Color(0xff81342d)
      ..style = PaintingStyle.fill;

    final Paint fillPaint = Paint()
      ..strokeJoin = StrokeJoin.round
      ..color = Color(0xfff1493c)
      ..style = PaintingStyle.fill;
    final double radius = 12;

    return CanvasMarker(
      rotate: false,
      position: position,
      hitArea: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        final (path, _) = MarkerPresets.raindropMarkerPath(center, radius: 12);
        return path;
      },
      painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        final (path, markerCenterPosition) = MarkerPresets.raindropMarkerPath(center, radius: radius);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
        canvas.drawCircle(markerCenterPosition, radius / 2, circlePaint);
        // final bounds = path.getBounds();
        // If bounds are known, then it might be more performant to return a known Rect area instead of calculating
        // from the Path using getBounds() each time.
        // In this case we know the bounds from how we constructed the path.
        // raindropMarkerPath creates a marker with a height-to-width ratio of 3:2.
        // Example: width = 2 radius units, height = 3 radius units.
        // the showDebugRect: true can be set on the CanvasMarkerLayer to visualize the bounds.
        final bounds = Rect.fromLTRB(center.dx - radius, center.dy - radius * 3, center.dx + radius, center.dy);
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
              TileLayer(userAgentPackageName: 'com.flutter_map_markers.example', urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
               CanvasMarkerLayer(markers: markers,drawHitMarkerLast: true,),
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
