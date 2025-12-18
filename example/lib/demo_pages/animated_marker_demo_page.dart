import 'package:example/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker_layer.dart';
import 'package:flutter_map_markers/marker_presets/marker_presets.dart';
import 'package:latlong2/latlong.dart';

class AnimatedMarkerDemoPage extends StatefulWidget {
  const AnimatedMarkerDemoPage({super.key});

  @override
  State<AnimatedMarkerDemoPage> createState() => _AnimatedMarkerDemoPageState();
}

class _AnimatedMarkerDemoPageState extends State<AnimatedMarkerDemoPage> with SingleTickerProviderStateMixin {
  List<CanvasMarker> markers = [];
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  final double initialMarkerRadius = 2.0;
  final double expandedMarkerRadius = 12.0;

  int? _currentlyAnimatingIndex;
  final List<int> _pendingAnimations = [];

  @override
  void initState() {
    super.initState();
    final london = LatLng(51.5074, -0.1278);
    markers.add(_createMarker(london, radius: 12));
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.bounceOut);
  }

  void animateMarkerSize(int index) {
    // If an animation is already running, queue this one for later
    if (_currentlyAnimatingIndex != null) {
      if (!_pendingAnimations.contains(index)) {
        _pendingAnimations.add(index);
      }
      return;
    }

    _currentlyAnimatingIndex = index;
    _animationController.forward(from: 0.0);

    void animationListener() {
      if (_currentlyAnimatingIndex != index) return; // Safety check

      setState(() {
        final radius = initialMarkerRadius + (expandedMarkerRadius - initialMarkerRadius) * _animation.value;
        markers[index] = MarkerPresets.raindropMarker(radius: radius, position: markers[index].position);
      });
    }

    void animationStatusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        // Set marker to fixed size after animation completes
        setState(() {
          markers[index] = MarkerPresets.raindropMarker(radius: expandedMarkerRadius, position: markers[index].position);
        });

        // Remove listeners
        _animationController.removeListener(animationListener);
        _animationController.removeStatusListener(animationStatusListener);

        // Clear current animation
        _currentlyAnimatingIndex = null;

        // Start next pending animation if any
        if (_pendingAnimations.isNotEmpty) {
          final nextIndex = _pendingAnimations.removeAt(0);
          animateMarkerSize(nextIndex);
        }
      }
    }

    _animationController.addListener(animationListener);
    _animationController.addStatusListener(animationStatusListener);
  }

  CanvasMarker _createMarker(LatLng position, {double? radius}) {
    return MarkerPresets.raindropMarker(radius: radius ?? initialMarkerRadius, position: position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Simple Marker Demo')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(51.5074, -0.1278),
              initialZoom: 5,
              maxZoom: 18,
              minZoom: 1,
              onTap: (tapPosition, point) {
                setState(() {
                  markers = [...markers, _createMarker(point)];
                  animateMarkerSize(markers.length - 1);
                });
              },
            ),
            children: [
              TileLayer(userAgentPackageName: 'com.flutter_map_markers.example', urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
              CanvasMarkerLayer(markers: markers, drawHitMarkerLast: true),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withAlpha(204), borderRadius: BorderRadius.circular(8)),
              child: const Text('Tap anywhere to add a marker', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}