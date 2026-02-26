import 'package:flutter/material.dart';
import 'package:flutter_map_markers_example/demo_pages/canvas_marker_demos/marker_demo_page.dart';

void main() {
  runApp(const MarkerDemoApp());
}

class MarkerDemoApp extends StatelessWidget {
  const MarkerDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Marker Demo', home: const MarkerDemoPage());
  }
}
