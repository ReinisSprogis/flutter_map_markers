import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/flutter_map_markers.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
import 'package:flutter_map_markers_example/utility/utility.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// Demonstration of simple markers with price tags clustered around London.
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
    markers = _generateMarkers(500);
  }

  List<CanvasMarker> _generateMarkers(int count) {
    final random = Random(100);
    List<CanvasMarker> generatedMarkers = [];

    final london = LatLng(51.5074, -0.1278);
    for (int i = 0; i < count; i++) {
      // Random radial spread from city center
      final LatLng markerPosition = Utility.clusterPoint(london, random);

      /// Generates a marker at the given position with the specified styles and behaviors.
      final marker = _generateMarker(markerPosition, random.nextInt(5000) + 500);
      generatedMarkers.add(marker);
    }

    return generatedMarkers;
  }

  CanvasMarker _generateMarker(LatLng position, int price) {
    /// Marker created from preset text marker with price tag.
    /// You can check the implementation by ctrl+clicking on the method name and create your own custom version based on it.
    return MarkerPresets.textMarker(
      position: position,
      zoomLevelTransition: 11,
      text: '£${price.toString()}',
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marker at (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}) with price £$price tapped!'),
            duration: Duration(seconds: 1),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Price tag Marker')),
      body: FlutterMap(
        options: MapOptions(initialCenter: LatLng(51.5074, -0.1278), initialZoom: 10, maxZoom: 18, minZoom: 1),
        children: [
          TileLayer(userAgentPackageName: 'com.flutter_map_markers.example', urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
          CanvasMarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
