import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/flutter_map_markers.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/animation_mode.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
import 'package:flutter_map_markers_example/demo_pages/sprites/gemstone.dart';
import 'package:flutter_map_markers_example/demo_pages/sprites/puffy_gems.dart';
import 'package:flutter_map_markers_example/utility/utility.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

class SpriteLayerDemo extends StatefulWidget {
  const SpriteLayerDemo({super.key});

  @override
  State<SpriteLayerDemo> createState() => _SpriteLayerDemoState();
}

class _SpriteLayerDemoState extends State<SpriteLayerDemo>
    with SingleTickerProviderStateMixin {
  SpriteAtlas? _spriteAtlas;
  late final AnimationPlayer _animationPlayer;
  List<SpriteMarkerSequence> markers = [];
  int markerCount = 1000;
  int lastTime = 0;
  @override
  void initState() {
    super.initState();
    _animationPlayer = AnimationPlayer(vsync: this);

    Future.microtask(() async {
      await _loadAtlas();
    });
  }

  Future<SpriteAtlas> _getAtlas() async {
    final image = await SpriteUtil.loadAtlasImageFromAssets(
      'assets/puffy_gems.png',
    );
    final spriteAtlas = SpriteAtlas.custom(
      image: image,
      sprites: PuffyGems.sprites,
    );
    return spriteAtlas;
  }

  @override
  void dispose() {
    _animationPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAtlas() async {
    _spriteAtlas = await _getAtlas();
    _animationPlayer.markers = markers;
    _generateSprites(1);
  }

  void _generateSprites(int count) {
    final london = LatLng(51.5074, -0.1278);
    final Random random = Random(42);
    //random rotation and scale for each marker

    setState(() {
      markers = List<SpriteMarkerSequence>.generate(count, (index) {
        //rotation in radians

        final position = Utility.clusterPoint(
          london,
          random,
          maxDistance: 10.0,
        );
        final String id = Uuid().v4();
        return SpriteMarkerSequence(
          id: id,
          scale: 1.0,
          rotate: true,
          anchor: Alignment.bottomCenter,
          position: position,
          sequenceIndex: 1,
          animating: true,
          onTap: () {
            final marker = markers[index];
            if(marker.sequenceIndex != 0){
               markers[index].sequenceIndex = 0;
            markers[index].resetAnimation(animate: true);
            setState(() {});
            }
           
          },
          sequences: [
            Sequence(
              mode: AnimationMode.forwardOnce,
              fps: 30,
              frames: [
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7,
                8,
                9,
              ],
              onAnimationEnd: () {
                markers[index].isVisible = false;
                setState(() {});
              },
            ),
            Sequence(
              mode: AnimationMode.loopForward,
              fps: 24,
              frameIndex: random.nextInt(24),
              frames: [
                11,
                12,
                13,
                14,
                15,
                16,
                17,
                18,
                19,
                20,
                21,
                22,
                23,
                24,
                25,
                26,
                27,
                28,
                29,
                30,
                31,
                32,
                33,
                34,
              ],
            ),
          ],
        );
      });
      markerCount = count;
    });
    _animationPlayer.markers = markers;
    if (!_animationPlayer.isRunning) {
      _animationPlayer.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemstone Demo')),
      drawer: const AppDrawer(),
      body: _spriteAtlas == null
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
                      spriteAtlas: _spriteAtlas!,
                      markers: markers,
                      animationPlayer: _animationPlayer,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_animationPlayer.isRunning) {
            _animationPlayer.stop();
          } else {
            _animationPlayer.start();
          }
        },
        child: Icon(
          _animationPlayer.isRunning ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
