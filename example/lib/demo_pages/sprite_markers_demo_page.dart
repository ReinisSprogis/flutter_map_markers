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
import 'package:flutter_map_markers_example/utility/utility.dart';
import 'package:latlong2/latlong.dart';

class SpriteMarkersDemoPage extends StatefulWidget {
  const SpriteMarkersDemoPage({super.key});

  @override
  State<SpriteMarkersDemoPage> createState() => _SpriteMarkersDemoPageState();
}

class _SpriteMarkersDemoPageState extends State<SpriteMarkersDemoPage> {
  SpriteAtlas? _spriteAtlas;
  List<SpriteMarker> _markers = [];
  int markerCount = 1;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadAssetImage();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    });
    _generateSprites(1000);
  }

  Future<void> _loadAssetImage() async {
    final ByteData data = await rootBundle.load('assets/circles_16x10.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    setState(() {
      // Create a horizontal sprite atlas with 2 sprites of 64x64 each
      _spriteAtlas = SpriteAtlas.horizontal(
        image: frameInfo.image,
        spriteCount: 10,
        spriteWidth: 16,
        spriteHeight: 16,
      );
    });
  }

  void _generateSprites(int count) {
    final london = LatLng(51.5074, -0.1278);
    final Random random = Random(42);
    setState(() {
      _markers = List<SpriteMarker>.generate(count, (index) {
        final position = Utility.clusterPoint(london, random,maxDistance: 10.0);
        return SpriteMarker(
          rotate: false,
          position: position,
          spriteIndex:
              index % 10,
        );
      });
      markerCount = count;
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
                      mainAxisSize: MainAxisSize.min  ,
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
