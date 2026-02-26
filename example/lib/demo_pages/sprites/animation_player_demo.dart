import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/flutter_map_markers.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_ref.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
import 'package:flutter_map_markers_example/demo_pages/sprites/heli_fire.dart';
import 'package:flutter_map_markers_example/utility/utility.dart';
import 'package:latlong2/latlong.dart';

class AnimationPlayerDemo extends StatefulWidget {
  const AnimationPlayerDemo({super.key});

  @override
  State<AnimationPlayerDemo> createState() => _AnimationPlayerDemoState();
}

class _AnimationPlayerDemoState extends State<AnimationPlayerDemo>
    with SingleTickerProviderStateMixin {
  SpriteAtlasSet? _spriteAtlasSet;
  List<SpriteMarker> markers = [];
  int markerCount = 1000;
  late final AnimationPlayer _animationPlayer;

  Future<SpriteAtlas> _getAtlas() async {
    final image = await SpriteUtil.loadAtlasImageFromAssets(
      'assets/heli_fire.png',
    );
    final spriteAtlas = SpriteAtlas.custom(
      image: image,
      sprites: HeliFire.sprites,
    );
    return spriteAtlas;
  }

  @override
  void initState() {
    super.initState();
    _animationPlayer = AnimationPlayer(vsync: this);
    Future.microtask(() {
      _getAtlas().then((atlas) {
        setState(() {
          _spriteAtlasSet = SpriteAtlasSet([atlas]);
        });
      });

      _generateSprites(markerCount);
      _animationPlayer.markers = markers;
      _animationPlayer.start();
    });
  }

  @override
  void dispose() {
    _animationPlayer.dispose();
    super.dispose();
  }

  void _generateSprites(int count) {
    final london = LatLng(51.5074, -0.1278);
    final Random random = Random(42);
    //random rotation and scale for each marker

    setState(() {
      markers = List<SpriteSequenceMarker>.generate(count, (index) {
        //rotation in radians
        double rotation = random.nextDouble() * 2 * pi;
        double scale = 0.50; // + random.nextDouble() * 0.3;

        final position = Utility.clusterPoint(
          london,
          random,
          maxDistance: 10.0,
        );
        return SpriteSequenceMarker(
          sequenceIndex: index % 2,
          id: 'marker_$index',
          animating: true,

          sequences: [
            Sequence(
              counterRotate: true,
              anchor: Alignment.center,
              frames: [
                SpriteRef(0, 6),
                SpriteRef(0, 7)],
              fps: 30,
            ),
            Sequence(
              anchor: Alignment.center,
              frames: [SpriteRef(0, 0), SpriteRef(0, 1), SpriteRef(0, 2), SpriteRef(0, 3), SpriteRef(0, 4), SpriteRef(0, 5)],
              fps: 60,
              mode: AnimationMode.loopForward,
            ),
          ],
          position: position,
        );
      });
    });
    _animationPlayer.markers = markers;
    if (!_animationPlayer.isRunning) {
      _animationPlayer.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sprite Marker Animation Player Demo')),
      drawer: const AppDrawer(),
      body: _spriteAtlasSet == null
          ? const CircularProgressIndicator()
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(51.5074, -0.1278),
                    initialZoom: 5,
                    maxZoom: 18,
                    minZoom: 1,
                    // onPointerHover: (event, point) {
                    //   _addSingleSprite(point);
                    // },
                  ),
                  children: [
                    TileLayer(
                      userAgentPackageName: 'com.flutter_map_markers.example',
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    if (_spriteAtlasSet != null)
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
                        Center(
                          child: Text(
                            'Marker Count: $markerCount',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            label: 'Marker Count: $markerCount',
                            min: 1,
                            max: 200000,
                            value: markerCount.toDouble(),
                            onChanged: (v) {
                              setState(() {
                                markerCount = v.toInt();
                                _generateSprites(v.toInt());
                              });
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
