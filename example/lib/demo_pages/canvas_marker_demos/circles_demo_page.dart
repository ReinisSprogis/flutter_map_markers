import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_layer.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
import 'package:latlong2/latlong.dart' hide Path;

class CirclesDemoPage extends StatefulWidget {
  const CirclesDemoPage({super.key});

  @override
  State<CirclesDemoPage> createState() => _CirclesDemoPageState();
}

class _CirclesDemoPageState extends State<CirclesDemoPage> {
  List<CanvasMarker> markers = [];
  int circleCount = 3000;
  double circleRadius = 5.0;
  bool radiusInMeters = false;
  bool drawBorder = false;
  Marker? selectedMarker;
  String? selectedMarkerKey;
  bool _isTransitioning = false;
  GlobalKey<_SelectedMarkerCardState>? _currentCardKey;

  @override
  void initState() {
    super.initState();
    _generateMarkers(circleCount);
  }

  void _generateMarkers(int count) {
    final randomGenerator = Random(100);
    for (int i = 0; i < count; i++) {
      Color color = HSLColor.fromAHSL(
        1,
        i % 360,
        1,
        doubleInRange(randomGenerator, 0.3, 0.7),
      ).toColor();
      final point = LatLng(
        doubleInRange(randomGenerator, 37, 55),
        doubleInRange(randomGenerator, -9, 30),
      );
      markers.add(_createMarker(point, color));
    }
  }

  static double doubleInRange(Random source, num start, num end) =>
      source.nextDouble() * (end - start) + start;

  void _selectMarker(LatLng position, Color color) {
    final newKey = '${position.latitude}_${position.longitude}';

    if (selectedMarkerKey == newKey) return; // Same marker clicked

    if (_isTransitioning) return; // Prevent rapid transitions

    if (selectedMarker != null && _currentCardKey?.currentState != null) {
      // Animate out current marker first
      setState(() {
        _isTransitioning = true;
      });

      // Animate out the current card
      _currentCardKey!.currentState!.animateOut().then((_) {
        if (mounted) {
          _showNewMarker(position, color, newKey);
        }
      });
    } else {
      _showNewMarker(position, color, newKey);
    }
  }

  void _showNewMarker(LatLng position, Color color, String key) {
    _currentCardKey = GlobalKey<_SelectedMarkerCardState>();

    setState(() {
      selectedMarkerKey = key;
      selectedMarker = Marker(
        rotate: true,
        point: position,
        width: 200,
        height: 120,
        child: SelectedMarkerCard(
          key: _currentCardKey!,
          title: 'Circle Marker',
          color: color,
          onClose: _closeMarker,
        ),
      );
      _isTransitioning = false;
    });
  }

  void _closeMarker() {
    if (selectedMarker == null ||
        _isTransitioning ||
        _currentCardKey?.currentState == null)
      return;

    setState(() {
      _isTransitioning = true;
    });

    _currentCardKey!.currentState!.animateOut().then((_) {
      if (mounted) {
        setState(() {
          selectedMarker = null;
          selectedMarkerKey = null;
          _currentCardKey = null;
          _isTransitioning = false;
        });
      }
    });
  }

  CanvasMarker _createMarker(LatLng position, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()..color = Colors.black;
    return CanvasMarker(
      size: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        double radiusInPixels = radiusInMeters
            ? metersToPixels(25000, position)
            : circleRadius;
        return Rect.fromCircle(center: center, radius: radiusInPixels);
      },
      position: position,
      hitArea: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        double radiusInPixels = radiusInMeters
            ? metersToPixels(25000, position)
            : circleRadius;
        final Path path = Path()
          ..addOval(Rect.fromCircle(center: center, radius: radiusInPixels));
        return path;
      },
      painter:
          (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
            double radiusInPixels = radiusInMeters
                ? metersToPixels(25000, position)
                : 5;
            canvas.drawCircle(center, radiusInPixels, paint);
            if (drawBorder) {
              canvas.drawCircle(
                center,
                radiusInPixels,
                borderPaint
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.0,
              );
            }
          },
      onTap: () {
        _selectMarker(position, color);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Icon Marker')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds(
                  const LatLng(55, -9),
                  const LatLng(37, 30),
                ),
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 88,
                  bottom: 192,
                ),
              ),
              onTap: (tapPosition, point) {
                _closeMarker();
              },
            ),

            children: [
              TileLayer(
                userAgentPackageName: 'com.flutter_map_markers.example',
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              CanvasMarkerLayer(markers: markers, drawHitMarkerLast: true),
              if (selectedMarker != null)
                MarkerLayer(markers: [selectedMarker!]),
            ],
          ),
          // if (!kIsWeb && true)
          //   Positioned(
          //     bottom: 16,
          //     left: 0,
          //     right: 0,
          //     child: PerformanceOverlay.allEnabled(),
          //   ),
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                Container(
                  color: Colors.white70,
                  child: Column(
                    children: [
                      Slider(
                        value: circleCount.toDouble(),
                        min: 0,
                        max: 30000,
                        divisions: 20,
                        label: circleCount.toString(),
                        onChanged: (double value) {
                          setState(() {
                            circleCount = value.toInt();
                            markers.clear();
                            _generateMarkers(circleCount);
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Tooltip(
                            message: 'Draw Border',

                            child: Switch(
                              value: drawBorder,
                              thumbIcon: drawBorder
                                  ? const WidgetStatePropertyAll(
                                      Icon(Icons.circle_outlined),
                                    )
                                  : const WidgetStatePropertyAll(
                                      Icon(Icons.circle),
                                    ),
                              onChanged: (v) {
                                setState(() {
                                  drawBorder = v;
                                  markers.clear();
                                  _generateMarkers(circleCount);
                                });
                              },
                            ),
                          ),
                          Tooltip(
                            message: 'Radius in Meters',
                            child: Switch(
                              value: radiusInMeters,
                              thumbIcon: radiusInMeters
                                  ? const WidgetStatePropertyAll(
                                      Icon(Icons.straighten),
                                    )
                                  : const WidgetStatePropertyAll(
                                      Icon(Icons.circle),
                                    ),
                              onChanged: (v) {
                                setState(() {
                                  radiusInMeters = v;
                                  markers.clear();
                                  _generateMarkers(circleCount);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white70,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Tap on marker to select it. Tap on the map or close button to close selected marker.',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SelectedMarkerCard extends StatefulWidget {
  final String title;
  final Color color;
  final VoidCallback onClose;

  const SelectedMarkerCard({
    super.key,
    required this.title,
    required this.color,
    required this.onClose,
  });

  @override
  State<SelectedMarkerCard> createState() => _SelectedMarkerCardState();
}

class _SelectedMarkerCardState extends State<SelectedMarkerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isAnimatingOut = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  Future<void> animateOut() async {
    if (_isAnimatingOut) return;

    _isAnimatingOut = true;

    // Create reverse animations for smoother exit
    final reverseScale = Tween<double>(begin: _scaleAnimation.value, end: 0.0)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
        );
    final reverseFade = Tween<double>(begin: _fadeAnimation.value, end: 0.0)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    setState(() {
      _scaleAnimation = reverseScale;
      _fadeAnimation = reverseFade;
    });

    _animationController.reset();
    await _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Card(
              elevation: 8,
              shadowColor: Colors.black26,
              color: widget.color.withAlpha(230),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (!_isAnimatingOut) {
                              widget.onClose();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(204),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.info_outline),
                          iconSize: 18,
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(51),
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_border),
                          iconSize: 18,
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(51),
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.navigation),
                          iconSize: 18,
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(51),
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
