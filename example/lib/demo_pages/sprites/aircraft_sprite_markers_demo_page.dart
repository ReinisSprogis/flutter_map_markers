import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/flutter_map_markers.dart';
import 'package:flutter_map_markers_example/app_drawer.dart';
import 'package:flutter_map_markers_example/demo_pages/heli_2.dart';
import 'package:flutter_map_markers_example/utility/utility.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

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
  List<SpriteMarkerFrame> _markers = [];
  final Map<String, double> _velocityByMarkerId = <String, double>{};
  final Map<String, double> _scaleByMarkerId = <String, double>{};
  final Distance _distance = Distance();
  DateTime? _lastFrameTime;
  int markerCount = 1;
  final double minSpeed = 0.00008;
  final double maxSpeed = 0.0008;
  LatLng? _previousHoverPosition;
  Timer? _periodicTimer;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadAssetImage();
      await fetchAircraftLocations();
      _periodicTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        fetchAircraftLocations();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    });

    //_generateSprites(1);
    _animationController =
        AnimationController(
            vsync: this,
            // 60 alternations per second = 30 complete cycles per second
            // 2 frames, each visible for 1/60 second = 16.67ms
            // Full cycle = 33.33ms
            duration: const Duration(milliseconds: 33),
          )
          ..addListener(() {
            setState(() {
              updateSpriteFrames();
            });
          })
          ..repeat();
  }

  ///Fetch locations from https://opensky-network.org/api/states/all
  Future<void> fetchAircraftLocations() async {
    const url = 'https://opensky-network.org/api/states/all';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint('Error fetching aircraft locations: ${response.statusCode}');
        return;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> states = (data['states'] as List<dynamic>?) ?? [];

      final Random random = Random();
      final Map<String, SpriteMarkerFrame> previousById =
          <String, SpriteMarkerFrame>{
            for (final marker in _markers) marker.id: marker,
          };

      final List<SpriteMarkerFrame> markers = <SpriteMarkerFrame>[];
      for (final state in states) {
        if (state is! List) continue;

        final String? icao24 = (state.isNotEmpty && state[0] is String)
            ? (state[0] as String).trim()
            : null;
        final String markerId = (icao24 != null && icao24.isNotEmpty)
            ? icao24
            : 'marker_${markers.length}';

        final dynamic latRaw = state.length > 6 ? state[6] : null;
        final dynamic lonRaw = state.length > 5 ? state[5] : null;
        final dynamic velocityRaw = state.length > 9 ? state[9] : null;
        final dynamic trueTrackRaw = state.length > 10 ? state[10] : null;

        final double? latitude = (latRaw is num) ? latRaw.toDouble() : null;
        final double? longitude = (lonRaw is num) ? lonRaw.toDouble() : null;
        if (latitude == null || longitude == null) continue;

        final position = LatLng(latitude, longitude);

        final double? velocityMps = (velocityRaw is num)
            ? velocityRaw.toDouble()
            : null;
        if (velocityMps != null) {
          _velocityByMarkerId[markerId] = velocityMps;
        }

        final double? trueTrackDegrees = (trueTrackRaw is num)
            ? trueTrackRaw.toDouble()
            : null;
        final double? previousRotation = previousById[markerId]?.rotation;
        final double rotation = trueTrackDegrees != null
            ? (trueTrackDegrees * pi / 180.0)
            : (previousRotation ?? (random.nextDouble() * 2 * pi));
        final double scale = _scaleByMarkerId.putIfAbsent(
          markerId,
          () => 0.5 + random.nextDouble() * 0.3,
        );
        markers.add(
          SpriteMarkerFrame(
            id: markerId,
            rotate: false,
            scale: scale,
            rotation: rotation,
            position: position,
            spriteIndex: markers.length % 2,
          ),
        );
      }

      final Set<String> markerIds = markers.map((m) => m.id).toSet();
      _velocityByMarkerId.removeWhere((key, _) => !markerIds.contains(key));
      _scaleByMarkerId.removeWhere((key, _) => !markerIds.contains(key));

      if (!mounted) return;
      setState(() {
        _markers = markers;
        markerCount = markers.length;
        _lastFrameTime = null;
      });
    } catch (e, st) {
      debugPrint('Error fetching aircraft locations: $e');
      debugPrintStack(stackTrace: st);
      if (kIsWeb) {
        debugPrint(
          'Note: on Flutter web this request can also fail due to CORS. '
          'If that happens, run on desktop/mobile or use a proxy that adds CORS headers.',
        );
      }
    }
  }

  void updateSpriteFrames() {
    // Use floor to ensure clean frame transitions
    final frameIndex = (_animationController.value * 2).floor().clamp(0, 1);

    final DateTime now = DateTime.now();
    final double dtSeconds = _lastFrameTime == null
        ? 0.033
        : (now.difference(_lastFrameTime!).inMicroseconds / 1000000.0).clamp(
            0.0,
            0.2,
          );
    _lastFrameTime = now;

    // Define map bounds (London area with some padding)
    const double minLat = -179.0;
    const double maxLat = 179.0;
    const double minLng = -90.0;
    const double maxLng = 90.0;

    // Movement speed (degrees per frame)
    // const double speed = 0.00002;

    for (int i = 0; i < _markers.length; i++) {
      final marker = _markers[i];

      final double speedMps = _velocityByMarkerId[marker.id] ?? 0.0;
      final double distanceMeters = speedMps * dtSeconds;

      final LatLng newPosition = distanceMeters > 0.0
          ? _distance.offset(
              marker.position,
              distanceMeters,
              marker.rotation * 180.0 / pi,
            )
          : marker.position;

      double newLat = newPosition.latitude;
      double newLng = newPosition.longitude;
      double newRotation = marker.rotation;

      // Check bounds and flip direction if needed
      // if (newLat < minLat || newLat > maxLat) {
      //   newRotation = -marker.rotation; // Flip vertical direction
      //   newLat = marker.position.latitude.clamp(minLat, maxLat);
      // }

      // if (newLng < minLng || newLng > maxLng) {
      //   newRotation = pi - marker.rotation; // Flip horizontal direction
      //   newLng = marker.position.longitude.clamp(minLng, maxLng);
      // }

      _markers[i] = SpriteMarkerFrame(
        id: marker.id,
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
    _periodicTimer?.cancel();

    super.dispose();
  }

  Future<void> _loadAssetImage() async {
    final ByteData data = await rootBundle.load('assets/heli_2.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    setState(() {
      _spriteAtlas = SpriteAtlas.custom(
        image: frameInfo.image,
        sprites: Heli2.sprites,
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
      _markers = List<SpriteMarkerFrame>.generate(count, (index) {
        //rotation in radians
        double rotation = random.nextDouble() * 2 * pi;
        double scale = 0.5; // + random.nextDouble() * 0.3;
        final position = Utility.clusterPoint(
          london,
          random,
          maxDistance: 10.0,
        );
        return SpriteMarkerFrame(
          id: 'marker_$index',
          scale: scale,
          rotate: true,
          rotation: rotation,
          position: position,
          spriteIndex: index % 2,
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
        SpriteMarkerFrame(
          id: 'marker_${_markers.length}',
          rotate: false,
          scale: scale,
          rotation: rotation,
          position: position,
          spriteIndex: _markers.length % 2,
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
