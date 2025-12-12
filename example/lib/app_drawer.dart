import 'package:example/marker_demo_page.dart';
import 'package:example/marker_demo_simple.dart';
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
            title: const Text('Marker Demo Page'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MarkerDemoPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.pin_drop),
            title: const Text('Marker Demo Simple'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MarkerDemoSimple()));
            },
          ),
        ],
      ),
    );
  }
}
