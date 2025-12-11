import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/flutter_map_markers.dart';
import 'package:latlong2/latlong.dart' hide Path;

class MarkerDemoPage extends StatefulWidget {
  const MarkerDemoPage({super.key});

  @override
  State<MarkerDemoPage> createState() => _MarkerDemoPageState();
}

class _MarkerDemoPageState extends State<MarkerDemoPage> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  List<CanvasMarker> markers = [];
  Marker? hoverCard;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..addListener((){
      setState(() {});
    });
    markers = randomCityClusters(2000);
  }

  @override
  void dispose() { 
    _animationController.dispose();
    super.dispose();
  }

  /// Generate random clusters of markers around a London city center.with given count.
  List<CanvasMarker> randomCityClusters(int count) {
    final random = Random(100);
    List<CanvasMarker> positions = [];
    final randomGenerator = Random(10);

    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < count; i++) {
      final cluster = [51.5074, -0.1278];
      final Color color = Color.fromARGB(255, randomGenerator.nextInt(256), randomGenerator.nextInt(256), randomGenerator.nextInt(256));
      final Paint taskPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      // Radial spread from city center
      double angle = random.nextDouble() * 2 * pi;
      double distance = random.nextDouble() * 0.5; // Max 2° away

      // Optional: skew toward elliptical pattern (more natural)
      double latOffset = distance * sin(angle) * (0.7 + random.nextDouble() * 0.6);
      double lonOffset = distance * cos(angle) * (0.7 + random.nextDouble() * 0.6);

      double lat = cluster[0] + latOffset;
      double lon = cluster[1] + lonOffset;

      // Clamp to valid range
      lat = lat.clamp(-90.0, 90.0);
      lon = lon.clamp(-180.0, 180.0);
      final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);

      final LatLng pos = LatLng(lat, lon);
      final markerIcon = Icon(getRandomMarkerIcon(random));
      textPainter.text = TextSpan(
        text: String.fromCharCode(markerIcon.icon!.codePoint),
        style: TextStyle(fontSize: 23, fontFamily: markerIcon.icon!.fontFamily, color: Colors.white),
      );

      textPainter.layout();

      final rasterMarker = _generateMarker(pos, cluster, markerIcon, taskPaint, borderPaint, textPainter, i);
      positions.add(rasterMarker);
    }

    return positions;
  }

  /// Generate a CanvasMarker at the given position with the specified styles and behaviors.
  CanvasMarker _generateMarker(LatLng pos, List<double> cluster, Icon markerIcon, Paint taskPaint, Paint borderPaint, TextPainter textPainter,int index) {
    return CanvasMarker(
      rotate: true,
      position: pos,
      hitArea: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        final (path, _) = MarkerPresets.ballMarkerPath(center, ballRadius: 15);
        return path;
      },
      painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) { 
        final (path, markerCenterPosition) = MarkerPresets.ballMarkerPath(center, ballRadius: 15);
        final bounds = path.getBounds();
        canvas.drawPath(path, taskPaint);

        canvas.drawPath(path, borderPaint);
        final Offset clusterOffset = latLngToPixelOffset(LatLng(cluster[0], cluster[1]));
        canvas.drawLine(center, clusterOffset, borderPaint);
        if (zoomLevel < 10) {
          return bounds;
        }
        final iconOffset = markerCenterPosition - Offset(textPainter.width / 2, textPainter.height / 2);
        textPainter.paint(canvas, iconOffset);

        return bounds;
      },
      onHover: (isHovered) {
        
      },
      onTap: () {
        //Show toast or dialog with info
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              icon: markerIcon,
              title: Text('Marker Tapped $index'),
              content: Text('You tapped the marker at (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Get a random icon for the marker
  IconData getRandomMarkerIcon(Random random) {
    List<IconData> icons = [
      Icons.wifi,
      Icons.place,
      Icons.star,
      Icons.home,
      Icons.business,
      Icons.school,
      Icons.local_hospital,
      Icons.local_gas_station,
      Icons.local_pharmacy,
      Icons.local_library,
      Icons.restaurant,
      Icons.local_cafe,
      Icons.directions_car,
      Icons.directions_bike,
      Icons.directions_boat,
      Icons.directions_bus,
      Icons.directions_subway,
    ];
    return icons[random.nextInt(icons.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marker Demo Page')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: LatLng(51.5074, -0.1278), initialZoom: 5, maxZoom: 18, minZoom: 3),
            children: [
              TileLayer(userAgentPackageName: 'com.flutter_map_markers.example', urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
              CanvasMarkerLayer(markers: markers, showDebugHitArea: false, showDebugRect: false, drawHitMarkerLast: true),
              MarkerLayer(markers: hoverCard != null ? [hoverCard!] : []),
            ],
          ),
          if (!kIsWeb && true) Positioned(bottom: 16, left: 0, right: 0, child: PerformanceOverlay.allEnabled()),
        ],
      ),
    );
  }
}

class HoverCard extends StatelessWidget {
  final String title;
  final Icon content;

  const HoverCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 50,
      child: Card(
        color: Colors.white70,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              content,
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
