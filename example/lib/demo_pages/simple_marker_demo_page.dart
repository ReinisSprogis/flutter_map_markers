import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_layer.dart';
import 'package:flutter_map_markers/marker_presets/marker_presets.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
import 'package:latlong2/latlong.dart';

/// Demonstration of simple markers that can be added by tapping on the map.
/// Tapping on a marker shows a SnackBar with its coordinates.
class SimpleMarkerDemoPage extends StatefulWidget {
  const SimpleMarkerDemoPage({super.key});

  @override
  State<SimpleMarkerDemoPage> createState() => _SimpleMarkerDemoPageState();
}

class _SimpleMarkerDemoPageState extends State<SimpleMarkerDemoPage> {
  List<CanvasMarker> markers = [];

  @override
  void initState() {
    super.initState();
    final london = LatLng(51.5074, -0.1278);
    markers.add(_createMarker(london));
  }

  CanvasMarker _createMarker(LatLng position) {
    return MarkerPresets.raindropMarker(
      position: position,
      radius: 12,
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
              TileLayer(
                userAgentPackageName: 'com.flutter_map_markers.example',
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              CanvasMarkerLayer(markers: markers),
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
