import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/flutter_map_markers.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_ref.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
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
  SpriteAtlasSet? _spriteAtlasSet;
  late final AnimationPlayer _animationPlayer;
  List<SpriteSequenceMarker> markers = [];
  int markerCount = 1000;
  List<Marker> flutterMarkers = [];
  bool showFlutterMarkers = false;

  @override
  void initState() {
    super.initState();

    _animationPlayer = AnimationPlayer(vsync: this)
      ..onPlayerStop = () {
        print('Animation Player Stopped');
      };

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
    final atlas = await _getAtlas();
    _spriteAtlasSet = SpriteAtlasSet([atlas]);
    _generateSprites(1);
    _animationPlayer.markers = markers;
  }

  void _generateSprites(int count) {
    final london = LatLng(51.5074, -0.1278);
    final Random randomgen = Random(42);
    //random rotation and scale for each marker
    flutterMarkers = [];
    setState(() {
      markers = List<SpriteSequenceMarker>.generate(count, (index) {
        final position = Utility.clusterPoint(
          london,
          randomgen,
          maxDistance: 0.05,
        );
        if (showFlutterMarkers) {
          flutterMarkers.add(
            Marker(
              point: position,
              width: 24,
              height: 24,
              child: FlutterLogo(),
            ),
          );
        }
        final String id = Uuid().v4();
        int elapsed = 0;
        final Random random = Random();
        return SpriteSequenceMarker(
          id: id,
          position: position,
          sequenceIndex: 1,
          animating: true,
          onTap: () {
            final marker = markers[index];
            if (marker.sequenceIndex != 0) {
              markers[index].sequenceIndex = 0;
              markers[index].resetAnimation(animate: true);
              _animationPlayer.start();
              setState(() {});
            }
          },
          sequences: [
            Sequence(
              counterRotate: true,
              mode: AnimationMode.forwardOnce,
              fps: 20,
              frames: [
                SpriteRef(0, 0),
                SpriteRef(0, 1),
                SpriteRef(0, 2),
                SpriteRef(0, 3),
                SpriteRef(0, 4),
                SpriteRef(0, 5),
                SpriteRef(0, 6),
                SpriteRef(0, 7),
                SpriteRef(0, 8),
                SpriteRef(0, 9),
               ],
              onAnimationEnd: () {
                markers[index].isVisible = false;
              
              },
            ),
            Sequence(
              scale: 0.5,
              counterRotate: true,
              mode: AnimationMode.loopForward,
              fps: 25,
              frameIndex: random.nextInt(24),
              transform: Offset(0, 0),
              frames: [
                SpriteRef(0, 11),
                SpriteRef(0, 12),
                SpriteRef(0, 13),
                SpriteRef(0, 14),
                SpriteRef(0, 15),
                SpriteRef(0, 16),
                SpriteRef(0, 17),
                SpriteRef(0, 18),
                SpriteRef(0, 19),
                SpriteRef(0, 20),
                SpriteRef(0, 21),
                SpriteRef(0, 22),
                SpriteRef(0, 23),
                SpriteRef(0, 24),
                SpriteRef(0, 25),
                SpriteRef(0, 26),
                SpriteRef(0, 27),
                SpriteRef(0, 28),
                SpriteRef(0, 29),
                SpriteRef(0, 30),
                SpriteRef(0, 31),
                SpriteRef(0, 32),
                SpriteRef(0, 33),
                SpriteRef(0, 34),
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
      body: _spriteAtlasSet == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(51.5074, -0.1278),
                    initialZoom: 5,
                    maxZoom: 18,
                    minZoom: 0,
                  ),
                  children: [
                    TileLayer(
                      userAgentPackageName: 'com.flutter_map_markers.example',
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    if (showFlutterMarkers)
                      MarkerLayer(markers: flutterMarkers),
                    if (!showFlutterMarkers)
                      SpriteMarkerLayer(
                        atlases: _spriteAtlasSet!,
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
                                Switch(
                                  value: showFlutterMarkers,
                                  onChanged: (v) {
                                    showFlutterMarkers = !showFlutterMarkers;
                                    _generateSprites(markerCount);
                                    setState(() {});
                                  },
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
                            max: 50000,
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
          setState(() {});
        },
        child: Icon(
          _animationPlayer.isRunning ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
