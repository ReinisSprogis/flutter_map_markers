import 'dart:math';

import 'package:example/app_drawer.dart';
import 'package:example/utility/utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_layer.dart';
import 'package:flutter_map_markers/marker_presets/marker_presets.dart';
import 'package:latlong2/latlong.dart' hide Path;

class IconMarkerDemoPage extends StatefulWidget {
  const IconMarkerDemoPage({super.key});

  @override
  State<IconMarkerDemoPage> createState() => _IconMarkerDemoPageState();
}

class _IconMarkerDemoPageState extends State<IconMarkerDemoPage> {
  List<CanvasMarker> markers = [];
  int sliderValue = 100;

  @override
  void initState() {
    super.initState();
    _generateMarkers(sliderValue);
  }

  void _generateMarkers(int count) {
    final Random random = Random(10);
    final london = LatLng(51.5074, -0.1278);

    for (int i = 0; i < count; i++) {
      Color color = Color.fromARGB(255, random.nextInt(256), random.nextInt(256), random.nextInt(256));
      final point = Utility.clusterPoint(london, random);
      markers.add(_createMarker(point, color));
    }
  }

  CanvasMarker _createMarker(LatLng position, Color color) {
    return MarkerPresets.iconMarker(position: position, color: color,alignment: Alignment.topCenter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Icon Marker')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: LatLng(51.5074, -0.1278), initialZoom: 5, maxZoom: 18, minZoom: 1),
            children: [
              TileLayer(userAgentPackageName: 'com.flutter_map_markers.example', urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
              CanvasMarkerLayer(markers: markers, drawHitMarkerLast: true),
            ],
          ),
          if (!kIsWeb && true) Positioned(bottom: 16, left: 0, right: 0, child: PerformanceOverlay.allEnabled()),
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                Container(
                  color: Colors.white70,
                  child: Slider(
                    value: sliderValue.toDouble(),
                    min: 0,
                    max: 20000,
                    divisions: 20,
                    label: sliderValue.toString(),
                    onChanged: (double value) {
                      setState(() {
                        sliderValue = value.toInt();
                        markers.clear();
                        _generateMarkers(sliderValue);
                      });
                    },
                  ),
                ),
                Container(color: Colors.white70, padding: const EdgeInsets.all(8.0), child: Text('Tap on the map to add more markers. Total markers: ${markers.length}')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
