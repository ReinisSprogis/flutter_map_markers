import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/flutter_map_markers.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animated_sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animation_mode.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
import 'package:flutter_map_markers_example/demo_pages/diamond_marker_anim.dart';
import 'package:flutter_map_markers_example/utility/utility.dart';
import 'package:latlong2/latlong.dart';

class SpriteLayerDemo extends StatefulWidget {
  const SpriteLayerDemo({super.key});

  @override
  State<SpriteLayerDemo> createState() => _SpriteLayerDemoState();
}

class _SpriteLayerDemoState extends State<SpriteLayerDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  SpriteAtlas? _spriteAtlas;
  SpriteMarkerManager? _markerManager;
  List<AnimatedSpriteMarker> markers = [];
  int markerCount = 1000;
  int lastTime = 0;
  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          vsync: this,
          // 60 alternations per second = 30 complete cycles per second
          // 2 frames, each visible for 1/60 second = 16.67ms
          // Full cycle = 33.33ms
          duration: const Duration(milliseconds: 33),
        )..addListener(() {
          final int nowMs =
              _animationController.lastElapsedDuration?.inMilliseconds ?? 0;
          final int deltaTime = nowMs - lastTime;
          lastTime = nowMs;

          _markerManager?.tick(deltaTime, markersMoved: true);
        });

    Future.microtask(() async {
      await _loadAtlas();
    });
  }

  Future<SpriteAtlas> _getAtlas() async {
    final image = await SpriteUtil.loadAtlasImageFromAssets(
      'assets/diamond_marker_anim.png',
    );
    final spriteAtlas = SpriteAtlas.custom(
      image: image,
      sprites: DiamondMarkerAnim.sprites,
    );
    return spriteAtlas;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAtlas() async {
    _spriteAtlas = await _getAtlas();
    _markerManager = SpriteMarkerManager(spriteAtlas: _spriteAtlas!);
    _generateSprites(1);
  }

  void _generateSprites(int count) {
    final london = LatLng(51.5074, -0.1278);
    final Random random = Random(42);
    //random rotation and scale for each marker

    setState(() {
      markers = List<AnimatedSpriteMarker>.generate(count, (index) {
        //rotation in radians

        final position = Utility.clusterPoint(
          london,
          random,
          maxDistance: 10.0,
        );
        return AnimatedSpriteMarker(
          id: 'marker_$index',
          scale: 1.0,
          rotate: true,
          fps: 10,
          // rotation: rotation,
          mode: AnimationMode.loop,
          anchor: Alignment.bottomCenter,
          position: position,
          cycleIndex: 0,
          // Example: pin the first marker to a specific frame.
          cycleFrameIndex: random.nextInt(10),
          animating: true,
          animationCycles: [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
          ],
        );
      });
      markerCount = count;
    });
    _markerManager?.updateMarkers(markers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sprite Markers Demo')),
      drawer: const AppDrawer(),
      body: _spriteAtlas == null && _markerManager == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(51.5074, -0.1278),
                    initialZoom: 5,
                    maxZoom: 18,
                    minZoom: 1,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_animationController.isAnimating) {
            _animationController.stop();
          } else {
            _animationController.repeat();
          }
        },
        child: Icon(
          _animationController.isAnimating ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
