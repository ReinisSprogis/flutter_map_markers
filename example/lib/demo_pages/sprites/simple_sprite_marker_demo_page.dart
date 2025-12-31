import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/flutter_map_markers.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animated_sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animation_mode.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_atlas.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_marker_manager.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
import 'package:flutter_map_markers_example/demo_pages/heli_2.dart';
import 'package:flutter_map_markers_example/utility/utility.dart';
import 'package:latlong2/latlong.dart';

class SimpleSpriteMarkerDemoPage extends StatefulWidget {
  const SimpleSpriteMarkerDemoPage({super.key});

  @override
  State<SimpleSpriteMarkerDemoPage> createState() =>
      _SimpleSpriteMarkerDemoPageState();
}

class _SimpleSpriteMarkerDemoPageState extends State<SimpleSpriteMarkerDemoPage>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  SpriteMarkerManager? _markerManager;
  List<AnimatedSpriteMarker> _markers = [];
  int markerCount = 1000;
  int lastTime = 0;
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await _loadAtlas();
    });
    _animationController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1000),
          )
          ..addListener(() {
            final int nowMs =
                _animationController.lastElapsedDuration?.inMilliseconds ?? 0;
            final int deltaTime = nowMs - lastTime;
            lastTime = nowMs;

            // Mutate markers in place (positions/rotations/etc).
            updateSpriteFrames();

            // Single-pass buffered update: transforms + animation.
            _markerManager?.tick(deltaTime, markersMoved: true);
          })
          ..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  LatLng? _previousHoverPosition;
  final double minSpeed = 0.00008;
  final double maxSpeed = 0.0008;
  void _addSingleSprite(LatLng position) {
    final Random random = Random();
    double rotation;

    // Calculate rotation from previous position if available
    if (_previousHoverPosition != null) {
      final dx = position.longitude - _previousHoverPosition!.longitude;
      final dy = position.latitude - _previousHoverPosition!.latitude;
      rotation = atan2(dx, dy);
      // Add random variance to rotation (±15 degrees)
      final variance = (random.nextDouble() - 0.5) * (pi / 6);
      rotation += variance;
    } else {
      rotation = random.nextDouble() * 2 * pi;
    }

    double scale = 0.5 + random.nextDouble() * 0.3;
    //double speed = minSpeed + random.nextDouble() * (maxSpeed - minSpeed);

    final marker = AnimatedSpriteMarker(
      id: 'marker_${_markers.length}',
      rotate: false,
      scale: scale,
      rotation: rotation,
      position: position,
      fps: 60,
      animationCycles: const [
        [0, 1],
      ],
    );

    _markers.add(marker);
    _previousHoverPosition = position;

    // Incremental add: avoids O(n) diff + rebuild per hover.
    _markerManager?.addMarker(marker);

    // Throttle label updates to avoid rebuild storms while hovering.
    if (_markers.length % 200 == 0) {
      setState(() {
        markerCount = _markers.length;
      });
    }
  }

  Future<SpriteAtlas> _getAtlas() async {
    final image = await SpriteUtil.loadAtlasImageFromAssets(
      'assets/heli_2.png',
    );
    final spriteAtlas = SpriteAtlas.custom(
      image: image,
      sprites: Heli2.sprites,
    );
    return spriteAtlas;
  }
  //   final spriteAtlas = SpriteAtlas.horizontal(
  //     image: image,
  //     spriteCount: 10,
  //     spriteWidth: 48,
  //     spriteHeight: 48,
  //   );
  //   return spriteAtlas;
  // }

  Future<void> _loadAtlas() async {
    final spriteAtlas = await _getAtlas();
    _markerManager = SpriteMarkerManager(spriteAtlas: spriteAtlas);
    _generateSprites(1);
  }

  void updateSpriteFrames() {
    // Movement speed (degrees per frame)
    // const double speed = 0.00002;

    for (int i = 0; i < _markers.length; i++) {
      final marker = _markers[i];

      // Calculate new position based on rotation direction
      // When rotation is 0, helicopter faces north (aligned with longitude)
      final double dx = sin(marker.rotation) * 0.00002;
      final double dy = cos(marker.rotation) * 0.00002;

      double newLat = marker.position.latitude + dy;
      double newLng = marker.position.longitude + dx;

      _markers[i].position = LatLng(newLat, newLng);
    }
  }

  void _generateSprites(int count) {
    final london = LatLng(51.5074, -0.1278);
    final Random random = Random(42);
    //random rotation and scale for each marker

    setState(() {
      _markers = List<AnimatedSpriteMarker>.generate(count, (index) {
        //rotation in radians
        double rotation = random.nextDouble() * 2 * pi;
        double scale = 0.5 + random.nextDouble() * 0.3;

        final position = Utility.clusterPoint(
          london,
          random,
          maxDistance: 10.0,
        );
        return AnimatedSpriteMarker(
          cycleIndex: 0,
          id: 'marker_$index',
          scale: scale,
          rotate: false,
          fps: 60,
          animationCycles: [
            [0, 1],
          ],
          // rotation: rotation,
          position: position,
          mode: AnimationMode.pingPong,
          anchor: Alignment.center,
        );
      });
      markerCount = count;
      _markerManager!.updateMarkers(_markers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sprite Markers manager Demo')),
      drawer: const AppDrawer(),
      body: _markerManager == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(51.5074, -0.1278),
                    initialZoom: 5,
                    maxZoom: 18,
                    minZoom: 1,
                    onPointerHover: (event, point) {
                      _addSingleSprite(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      userAgentPackageName: 'com.flutter_map_markers.example',
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    SpriteMarkerManagerLayer(markerManager: _markerManager!),
                  ],
                ),
                Positioned(
                  top: 10,
                  child: Container(
                    width: MediaQuery.sizeOf(context).width,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _generateSprites(1000);
                                  },
                                  child: const Text('1000'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _generateSprites(5000);
                                  },
                                  child: const Text('5000'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _generateSprites(10000);
                                  },
                                  child: const Text('10000'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _generateSprites(20000);
                                  },
                                  child: const Text('20000'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _generateSprites(50000);
                                  },
                                  child: const Text('50000'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _generateSprites(100000);
                                  },
                                  child: const Text('100000'),
                                ),
                              ],
                            ),
                            Center(
                              child: Text(
                                'Marker Count: $markerCount',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                        Expanded(
                          child: Slider(
                            label: 'Marker Count: $markerCount',
                            min: 1,
                            max: 200000,
                            value: markerCount.toDouble(),
                            onChanged: (v) {
                              markerCount = v.toInt();
                              _generateSprites(markerCount);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!kIsWeb && true)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: PerformanceOverlay.allEnabled(),
                  ),
              ],
            ),
    );
  }
}
