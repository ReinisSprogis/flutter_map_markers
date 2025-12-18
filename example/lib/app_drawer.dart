import 'package:example/demo_pages/animated_marker_demo_page.dart';
import 'package:example/demo_pages/ball_marker_demo_page.dart';
import 'package:example/demo_pages/lat_long_to_offset_demo_page.dart';
import 'package:example/demo_pages/marker_demo_page.dart';
import 'package:example/demo_pages/meters_to_pixels_demo_page.dart';
import 'package:example/demo_pages/simple_marker_demo_page.dart';
import 'package:example/demo_pages/pricetag_marker_demo.dart';
import 'package:flutter/material.dart';

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
            child: Text('Navigation', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Marker Demo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MarkerDemoPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.pin_drop),
            title: const Text('Simple Marker'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const SimpleMarkerDemoPage()));
            },
          ),
           ListTile(
            leading: const Icon(Icons.price_check),
            title: const Text('Price Tag Marker'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const PriceTagMarkerDemo()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.animation),
            title: const Text('Animated Marker'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AnimatedMarkerDemoPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Meters to pixels'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MetersToPixelsDemoPage()));
            },
          ),
           ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('LatLng to Offset'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LatLongToOffsetDemoPage()));
            },
          ),

           ListTile(
            leading: const Icon(Icons.bubble_chart),
            title: const Text('Ball Marker'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const BallMarkerDemoPage()));
            },
          ),
        ],
      ),
    );
  }
}
