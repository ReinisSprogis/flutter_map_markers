import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/flutter_map_markers.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_ref.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
import 'package:flutter_map_markers_example/demo_pages/sprites/diamond_marker_anim.dart';
import 'package:flutter_map_markers_example/utility/utility.dart';
import 'package:latlong2/latlong.dart';

class StaticSpriteManagerDemo extends StatefulWidget {
  const StaticSpriteManagerDemo({super.key});

  @override
  State<StaticSpriteManagerDemo> createState() =>
      _StaticSpriteManagerDemoState();
}

class _StaticSpriteManagerDemoState extends State<StaticSpriteManagerDemo> {
  SpriteAtlasSet? _spriteAtlasSet;
  List<SpriteFrameMarker> markers = [];
  int markerCount = 1000;
  int lastTime = 0;
  @override
  void initState() {
    super.initState();
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

  Future<void> _loadAtlas() async {
    final atlas = await _getAtlas();
    _spriteAtlasSet = SpriteAtlasSet([atlas]);
    _generateSprites(1);
  }

  void _generateSprites(int count) {
    final london = LatLng(51.5074, -0.1278);
    final Random random = Random(42);
    //random rotation and scale for each marker

    setState(() {
      markers = List<SpriteFrameMarker>.generate(count, (index) {
        //rotation in radians

        final position = Utility.clusterPoint(
          london,
          random,
          maxDistance: 10.0,
        );
        return SpriteFrameMarker(
          id: 'marker_$index',
          scale: 1.0,
          counterRotate: true,
          anchor: Alignment.bottomCenter,
          position: position,
          currentSpriteRef: SpriteRef(0, 0),
        );
      });
      markerCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Static Sprite Manager Demo')),
      drawer: const AppDrawer(),
      body: _spriteAtlasSet == null
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
                    SpriteMarkerLayer(
                      atlases: _spriteAtlasSet!,
                      markers: markers,
                    ),
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
