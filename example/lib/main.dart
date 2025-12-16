import 'package:example/demo_pages/marker_demo_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MarkerDemoApp());
}


class MarkerDemoApp extends StatelessWidget {
  const MarkerDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marker Demo',
      home: const MarkerDemoPage(),
    );
  }
}