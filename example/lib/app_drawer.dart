import 'package:flutter/material.dart';
import 'package:flutter_map_markers_example/demo_pages/canvas_marker_demos/animated_marker_demo_page.dart';
import 'package:flutter_map_markers_example/demo_pages/canvas_marker_demos/ball_marker_demo_page.dart';
import 'package:flutter_map_markers_example/demo_pages/canvas_marker_demos/circles_demo_page.dart';
import 'package:flutter_map_markers_example/demo_pages/canvas_marker_demos/icon_marker_demo_page.dart';
import 'package:flutter_map_markers_example/demo_pages/canvas_marker_demos/lat_long_to_offset_demo_page.dart';
import 'package:flutter_map_markers_example/demo_pages/canvas_marker_demos/marker_demo_page.dart';
import 'package:flutter_map_markers_example/demo_pages/canvas_marker_demos/meters_to_pixels_demo_page.dart';
import 'package:flutter_map_markers_example/demo_pages/canvas_marker_demos/pricetag_marker_demo.dart';
import 'package:flutter_map_markers_example/demo_pages/canvas_marker_demos/simple_marker_demo_page.dart';
import 'package:flutter_map_markers_example/demo_pages/sprites/aircraft_sprite_markers_demo_page.dart';
import 'package:flutter_map_markers_example/demo_pages/sprites/animation_player_demo.dart';
import 'package:flutter_map_markers_example/demo_pages/sprites/sprite_layer_demo.dart';
import 'package:flutter_map_markers_example/demo_pages/sprites/static_sprite_manager_demo.dart';
import 'package:flutter_map_markers_example/demo_pages/sprites/static_sprite_marker_layer.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Navigation',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Marker Demo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MarkerDemoPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.pin_drop),
            title: const Text('Simple Marker'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const SimpleMarkerDemoPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.price_check),
            title: const Text('Price Tag Marker'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const PriceTagMarkerDemo(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.animation),
            title: const Text('Animated Marker'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AnimatedMarkerDemoPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Meters to pixels'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MetersToPixelsDemoPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('LatLng to Offset'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LatLongToOffsetDemoPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.bubble_chart),
            title: const Text('Ball Marker'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const BallMarkerDemoPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_pin),
            title: const Text('Icon Marker'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const IconMarkerDemoPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.circle),
            title: const Text('Circles'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const CirclesDemoPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.circle),
            title: const Text('Aircraft demo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AircraftSpriteMarkerDemoPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.circle),
            title: const Text('Sprite layer'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const SpriteLayerDemo(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.circle),
            title: const Text('Static Sprite Manager Demo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const StaticSpriteManagerDemo(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.circle),
            title: const Text('Static Sprite Marker Layer'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const SpriteMarkerFrameLayerDemo(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.circle),
            title: const Text('Animation Player'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AnimationPlayerDemo(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
