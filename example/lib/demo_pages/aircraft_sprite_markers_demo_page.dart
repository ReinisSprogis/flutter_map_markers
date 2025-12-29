import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/sprite_marker_layer/model/sprite_marker.dart';
import 'package:flutter_map_markers/sprite_marker_layer/sprite_atlas.dart';
import 'package:flutter_map_markers/sprite_marker_layer/sprite_marker_layer.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
import 'package:flutter_map_markers_example/demo_pages/heli_8.dart';
import 'package:flutter_map_markers_example/utility/utility.dart';
import 'package:latlong2/latlong.dart';

class AircraftSpriteMarker extends SpriteMarker {
  double speed;
  AircraftSpriteMarker({
    this.speed = 0.0001,
    required super.position,
    required super.spriteIndex,
    required super.scale,
    required super.rotation,
    required super.rotate,
  });
}

class AircraftSpriteMarkerDemoPage extends StatefulWidget {
  const AircraftSpriteMarkerDemoPage({super.key});

  @override
  State<AircraftSpriteMarkerDemoPage> createState() =>
      _AircraftSpriteMarkerDemoPageState();
}

class _AircraftSpriteMarkerDemoPageState
    extends State<AircraftSpriteMarkerDemoPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  SpriteAtlas? _spriteAtlas;
  List<AircraftSpriteMarker> _markers = [];
  int markerCount = 1;
  final double minSpeed = 0.00008;
  final double maxSpeed = 0.0008;
  LatLng? _previousHoverPosition;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadAssetImage();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    });
    _generateSprites(1);
    // 8 frames at ~7.5 FPS animation = ~133ms per loop (1000ms / 7.5fps)
    // This ensures smooth animation where each frame is visible for ~16.67ms
    _animationController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1067), // 8 frames * 133.33ms
          )
          ..addListener(() {
            setState(() {
              updateSpriteFrames();
            });
          })
          ..repeat();
  }

  void updateSpriteFrames() {
    // Map animation value (0.0 to 1.0) to sprite index (0 to 7)
    // Use floor to ensure clean frame transitions
    final frameIndex = (_animationController.value * 8).floor().clamp(0, 7);

    // Define map bounds (London area with some padding)
    const double minLat = -179.0;
    const double maxLat = 179.0;
    const double minLng = -90.0;
    const double maxLng = 90.0;

    // Movement speed (degrees per frame)
    // const double speed = 0.00002;

    for (int i = 0; i < _markers.length; i++) {
      final marker = _markers[i];

      // Calculate new position based on rotation direction
      // When rotation is 0, helicopter faces north (aligned with longitude)
      final double dx = sin(marker.rotation) * marker.speed;
      final double dy = cos(marker.rotation) * marker.speed;

      double newLat = marker.position.latitude + dy;
      double newLng = marker.position.longitude + dx;
      double newRotation = marker.rotation;

      // Check bounds and flip direction if needed
      if (newLat < minLat || newLat > maxLat) {
        newRotation = -marker.rotation; // Flip vertical direction
        newLat = marker.position.latitude.clamp(minLat, maxLat);
      }

      if (newLng < minLng || newLng > maxLng) {
        newRotation = pi - marker.rotation; // Flip horizontal direction
        newLng = marker.position.longitude.clamp(minLng, maxLng);
      }

      _markers[i] = AircraftSpriteMarker(
        speed: marker.speed,
        position: LatLng(newLat, newLng),
        spriteIndex: frameIndex,
        scale: marker.scale,
        rotation: newRotation,
        rotate: marker.rotate,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAssetImage() async {
    final ByteData data = await rootBundle.load('assets/heli_8.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    setState(() {
      _spriteAtlas = SpriteAtlas.custom(
        image: frameInfo.image,
        sprites: Heli8.sprites,
      );
      // Create a horizontal sprite atlas with 2 sprites of 64x64 each
      // _spriteAtlas = SpriteAtlas.horizontal(
      //   image: frameInfo.image,

      //   spriteCount: 8,
      //   spriteWidth: 109,
      //   spriteHeight: 141,
      // );
    });
  }

  void _generateSprites(int count) {
    final london = LatLng(51.5074, -0.1278);
    final Random random = Random(42);
    //random rotation and scale for each marker

    setState(() {
      _markers = List<AircraftSpriteMarker>.generate(count, (index) {
        //rotation in radians
        double rotation = random.nextDouble() * 2 * pi;
        double scale = 0.5 + random.nextDouble() * 0.3;
        double speed = minSpeed + random.nextDouble() * (maxSpeed - minSpeed);
        final position = Utility.clusterPoint(
          london,
          random,
          maxDistance: 10.0,
        );
        return AircraftSpriteMarker(
          speed: speed,
          scale: scale,
          rotate: false,
          rotation: rotation,
          position: position,
          spriteIndex: index % 8,
        );
      });
      markerCount = count;
    });
  }

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
    double speed = minSpeed + random.nextDouble() * (maxSpeed - minSpeed);

    setState(() {
      _markers.add(
        AircraftSpriteMarker(
          rotate: false,
          speed: speed,
          scale: scale,
          rotation: rotation,
          position: position,
          spriteIndex: _markers.length % 8,
        ),
      );
      markerCount = _markers.length;
      _previousHoverPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sprite Markers Demo')),
      drawer: const AppDrawer(),
      body: _spriteAtlas == null
          ? const CircularProgressIndicator()
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
                    SpriteMarkerLayer(
                      spriteAtlas: _spriteAtlas!,
                      markers: _markers,
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
                              _generateSprites(v.toInt());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
