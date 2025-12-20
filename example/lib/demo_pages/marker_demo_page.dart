import 'dart:async';
import 'dart:math';

import 'package:example/app_drawer.dart';
import 'package:example/utility/utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/flutter_map_markers.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// Demonstration of a large number of markers with random icons and clustering around London.
class MarkerDemoPage extends StatefulWidget {
  const MarkerDemoPage({super.key});

  @override
  State<MarkerDemoPage> createState() => _MarkerDemoPageState();
}

class _MarkerDemoPageState extends State<MarkerDemoPage> {
  List<CanvasMarker> markers = [];
  double markerCount = 2000;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Generate random markers around London
    markers = randomCityClusters(markerCount.toInt());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Generate random clusters of markers around a London city center with given count.
  List<CanvasMarker> randomCityClusters(int count) {
    final random = Random(100);
    final randomGenerator = Random(10);
    List<CanvasMarker> generatedMarkers = [];

    // Paints
    // Avoid creating objects that don't change in the loop or markers painter function and reuse them for better performance.
    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke;

    final Paint circlePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final london = LatLng(51.5074, -0.1278);

      // This generates a random icon for the marker
      final iconPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      // Random position around London with clustering
      final LatLng pos = Utility.clusterPoint(london, random);
      // Get a random icon for the marker
      final markerIcon = Icon(getRandomMarkerIcon(random));
      iconPainter.text = TextSpan(
        text: String.fromCharCode(markerIcon.icon!.codePoint),
        style: TextStyle(fontSize: 15, fontFamily: markerIcon.icon!.fontFamily, color: Colors.white),
      );
      // Avoid layout call in the markers painter function for better performance.
      // Otherwise it would be called every frame during repaint.
      iconPainter.layout();

      // Random color for the marker fill
      final Color color = Color.fromARGB(255, randomGenerator.nextInt(256), randomGenerator.nextInt(256), randomGenerator.nextInt(256));
      final Paint taskPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      /// Generates a marker at the given position with the specified styles and behaviors.
      final marker = _generateMarker(pos, london, markerIcon, taskPaint, borderPaint, circlePaint, iconPainter, i);
      generatedMarkers.add(marker);
    }

    return generatedMarkers;
  }

  /// Generate a CanvasMarker at the given position with the specified styles and behaviors.
  /// Separated into its own method for clarity.
  CanvasMarker _generateMarker(LatLng pos, LatLng clusterLocation, Icon markerIcon, Paint taskPaint, Paint borderPaint, Paint circlePaint, TextPainter textPainter, int index) {
    final radius = 12.0;
    return CanvasMarker(
      rotate: true,
      position: pos,
      size: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        // Optional: Your size can be reactively changed based on zoom level too.
        // If you change your marker shape in the painter based on zoom level,
        // you probably want to change the size too.
        if (zoomLevel < 13) {
          return Rect.fromCircle(center: center, radius: 5);
        }
        // Return the size of the marker as used for culling.
        // If not provided, the marker will be culled based on point position only.
        // In this case Marker size ratio is 2:3 (width:height).
        // And Rect constructed here to cover the whole marker area.
        final bounds = Rect.fromLTRB(center.dx - radius, center.dy - radius * 3, center.dx + radius, center.dy);
        return bounds;
      },
      hitArea: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        // Optional: Your hit area can be reactively changed based on zoom level too.
        // If you change your marker shape in the painter based on zoom level,
        // you probably want to change the hit area too.
        if (zoomLevel < 13) {
          final circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: 5));
          return circlePath;
        }
        // Return the hit area Path for the marker.
        // This is used for hit testing taps and hovers. It uses path.contains to determine if a point is inside the hit area.
        // It allows for non-rectangular hit areas.
        // If it is not provided, a rectangular hit area based on the painter's returned Rect will be used.
        final (path, _) = MarkerPresets.raindropMarkerPath(center, radius: radius);
        return path;
      },
      painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        // Optional: Your canvas drawing can be reactively changed based on zoom level.
        // For example, only draw icon details when zoomed in enough.
        // You could draw different shapes, colors, or sizes or anything else based on zoom level.
        if (zoomLevel < 13) {
          canvas.drawCircle(center, 5, taskPaint);
          canvas.drawCircle(center, 5, borderPaint);
        } else {
          // The [center] is provided LatLng position converted to offset.
        // In other words [center] is the pixel position of the marker on the canvas.
        // For this example raindrop marker preset is used.
        // The circular part of the raindrop is centered above the provided position.
        // And the bottom tip of the raindrop is at the provided [center] position that points to the location.
        final (path, markerCenterPosition) = MarkerPresets.raindropMarkerPath(center, radius: 12); // Create the raindrop marker path from preset.
        canvas.drawPath(path, taskPaint); // Draws the filled part of the marker
        canvas.drawPath(path, borderPaint); // Draws the border of the marker

        // Draw the icon at the center of the circular part of the raindrop.
        canvas.drawCircle(markerCenterPosition, 10, circlePaint);
        final iconOffset = markerCenterPosition - Offset(textPainter.width / 2, textPainter.height / 2);
        textPainter.paint(canvas, iconOffset);
        }
       
        
      },
      onTap: () {
        //Show toast or dialog with info
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              constraints: const BoxConstraints(maxWidth: 220, maxHeight: 300),
              child: Stack(
                children: [
                  InfoCard(title: 'Marker $index', content: markerIcon, index: index),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Debounced version for slider changes
  void _debouncedRegenerateMarkers(double newCount) {
    // Cancel the previous timer if it exists
    _debounceTimer?.cancel();

    // Update the marker count immediately for UI responsiveness
    setState(() {
      markerCount = newCount;
    });

    // Set a new timer to regenerate markers after delay
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        markers = randomCityClusters(markerCount.toInt());
      });
    });
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
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Marker Demo')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: LatLng(51.5074, -0.1278), initialZoom: 10, maxZoom: 18, minZoom: 3),
            children: [
              TileLayer(userAgentPackageName: 'com.flutter_map_markers.example', urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
              CanvasMarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white.withAlpha(230),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Markers: ${markerCount.toInt()}', style: Theme.of(context).textTheme.titleMedium),
                    Slider(value: markerCount, min: 100, max: 20000, divisions: 199, label: markerCount.toInt().toString(), onChanged: _debouncedRegenerateMarkers),
                  ],
                ),
              ),
            ),
          ),
           if (!kIsWeb && true) Positioned(bottom: 16, left: 0, right: 0, child: PerformanceOverlay.allEnabled()),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final Icon content;
  final int index;

  const InfoCard({super.key, required this.title, required this.content, required this.index});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 250,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.network('https://picsum.photos/seed/${index}/200', fit: BoxFit.cover, height: 200),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                content,
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
