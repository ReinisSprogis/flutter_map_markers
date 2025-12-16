<div align="center">
  <h1>Flutter Map Markers</h1>
  <p>Canvas based marker rendering for <a href="https://pub.dev/packages/flutter_map">flutter_map</a></p>
</div>

<hr>

<h2>Overview</h2>

<p>
  <code>flutter_map_markers</code> is a powerful Flutter plugin for flutter_maps package that provides a flexible canvas based marker layer. It enables you to render thousands of interactive markers directly on the map canvas with excellent performance and minimal overhead.
</p>

<h2>Features</h2>

<ul>
  <li><strong>Interactive Markers</strong> - Support for tap</li>
  <li><strong>Custom Hit Detection</strong> - Define custom hit areas for complex marker shapes</li>
  <li><strong>Marker Rotation</strong> - Counter-rotate markers to maintain orientation during map rotation</li>
  <li><strong>Culling</strong> - Automatically cull markers outside the visible viewport</li>
  <li><strong>Preset Shapes</strong> - Built in marker presets</li>
  <li><strong>Flexible Rendering</strong> - Full control over marker appearance using Canvas API</li>
  <li><strong>Zoom Level Awareness</strong> - Change marker graphics based on current zoom level</li>
</ul>

<h2>Getting Started</h2>

<h3>Installation</h3>

<p>Add <code>flutter_map_markers</code> to your <code>pubspec.yaml</code>:</p>

```yaml
dependencies:
  flutter_map_markers: ^0.0.1
  flutter_map: add latest version
  latlong2: add latest version
```

<p>Then run:</p>

```bash
flutter pub get
```

<h3>Import</h3>

```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_markers/flutter_map_markers.dart';
import 'package:latlong2/latlong.dart';
```

<h2>Usage</h2>

<h3>Basic Example</h3>

<p>Create a simple map with canvas markers:</p>

```dart
FlutterMap(
  options: MapOptions(
    initialCenter: LatLng(51.5074, -0.1278),
    initialZoom: 10,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    CanvasMarkerLayer(
      markers: [
        CanvasMarker(
          position: LatLng(51.5074, -0.1278),
          painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
            final paint = Paint()
              ..color = Colors.blue
              ..style = PaintingStyle.fill;
            
            canvas.drawCircle(center, 10, paint);
            
            return Rect.fromCircle(center: center, radius: 10);
          },
        ),
      ],
    ),
  ],
)
```

<h3>Using Marker Presets</h3>

<p>The package includes preset marker shapes like balloon markers:</p>

```dart
CanvasMarker(
  position: LatLng(51.5074, -0.1278),
  painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
    final (path, markerCenterPosition) = MarkerPresets.ballMarkerPath(
      center,
      ballRadius: 15,
    );
    
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, paint);
    
    return path.getBounds();
  },
)
```

<h3>Interactive Markers</h3>

<p>Add gesture callbacks to markers for interactivity:</p>

```dart
CanvasMarker(
  position: LatLng(51.5074, -0.1278),
  painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
    // Your drawing code
    final paint = Paint()..color = Colors.green;
    canvas.drawCircle(center, 12, paint);
    return Rect.fromCircle(center: center, radius: 12);
  },
  onTap: () {
    print('Marker tapped!');
  },
)
```

<h3>Custom Hit Detection</h3>

<p>Define precise hit areas for complex marker shapes:</p>

```dart
CanvasMarker(
  position: LatLng(51.5074, -0.1278),
  painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
    final (path, _) = MarkerPresets.ballMarkerPath(center, ballRadius: 15);
    final paint = Paint()..color = Colors.purple;
    canvas.drawPath(path, paint);
    return path.getBounds();
  },
  hitArea: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
    final (path, _) = MarkerPresets.ballMarkerPath(center, ballRadius: 15);
    return path;
  },
  onTap: () {
    print('Accurate hit detection!');
  },
)
```

<h3>Advanced: Drawing with Icons and Text</h3>

```dart
final textPainter = TextPainter(
  textAlign: TextAlign.center,
  textDirection: TextDirection.ltr,
);

final icon = Icons.place;
textPainter.text = TextSpan(
  text: String.fromCharCode(icon.codePoint),
  style: TextStyle(
    fontSize: 20,
    fontFamily: icon.fontFamily,
    color: Colors.white,
  ),
);

textPainter.layout();

CanvasMarker(
  position: LatLng(51.5074, -0.1278),
  painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
    // Draw marker background
    final (path, iconCenter) = MarkerPresets.ballMarkerPath(center, ballRadius: 15);
    final bgPaint = Paint()..color = Colors.orange;
    canvas.drawPath(path, bgPaint);
    
    // Draw icon
    final iconOffset = iconCenter - Offset(
      textPainter.width / 2,
      textPainter.height / 2,
    );
    textPainter.paint(canvas, iconOffset);
    return path.getBounds();
  },
)
```

<h3>Layer Configuration</h3>

<p>Configure the <code>CanvasMarkerLayer</code> with various options:</p>

```dart
CanvasMarkerLayer(
  markers: myMarkers,
  showDebugRect: false,          // Show debug rectangles around markers
  showDebugHitArea: false,       // Show debug hit areas
  drawHitMarkerLast: true,       // Draw tapped marker on top
  cullMarkers: true,             // Cull off-screen markers
  hoverDebounceDuration: Duration(milliseconds: 50),  // Hover debounce
)
```

<h2>API Reference</h2>

<h3>CanvasMarker</h3>

<table>
  <tr>
    <th>Property</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>position</code></td>
    <td><code>LatLng</code></td>
    <td>Geographic position of the marker</td>
  </tr>
  <tr>
    <td><code>painter</code></td>
    <td><code>CanvasPainter</code></td>
    <td>Function to draw the marker on canvas (required)</td>
  </tr>
  <tr>
    <td><code>hitArea</code></td>
    <td><code>HitArea?</code></td>
    <td>Custom hit detection path (optional)</td>
  </tr>
  <tr>
    <td><code>rotate</code></td>
    <td><code>bool</code></td>
    <td>Counter-rotate marker with map rotation</td>
  </tr>
  <tr>
    <td><code>onTap</code></td>
    <td><code>Function?</code></td>
    <td>Callback for tap events</td>
  </tr>
  <tr>
    <td><code>onDoubleTap</code></td>
    <td><code>Function?</code></td>
    <td>Callback for double-tap events</td>
  </tr>
  <tr>
    <td><code>onLongPress</code></td>
    <td><code>Function?</code></td>
    <td>Callback for long-press events</td>
  </tr>
  <tr>
    <td><code>onHover</code></td>
    <td><code>Function(bool)?</code></td>
    <td>Callback for hover events (true = hover in, false = hover out)</td>
  </tr>
</table>

<h3>CanvasMarkerLayer</h3>

<table>
  <tr>
    <th>Property</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>markers</code></td>
    <td><code>List&lt;CanvasMarker&gt;</code></td>
    <td>List of markers to render</td>
  </tr>
  <tr>
    <td><code>showDebugRect</code></td>
    <td><code>bool</code></td>
    <td>Display debug rectangles (default: false)</td>
  </tr>
  <tr>
    <td><code>showDebugHitArea</code></td>
    <td><code>bool</code></td>
    <td>Display debug hit areas (default: false)</td>
  </tr>
  <tr>
    <td><code>drawHitMarkerLast</code></td>
    <td><code>bool</code></td>
    <td>Draw hit marker on top (default: false)</td>
  </tr>
  <tr>
    <td><code>cullMarkers</code></td>
    <td><code>bool</code></td>
    <td>Enable marker culling (default: true)</td>
  </tr>
  <tr>
    <td><code>hoverDebounceDuration</code></td>
    <td><code>Duration</code></td>
    <td>Debounce duration for hover events (default: 50ms)</td>
  </tr>
</table>

<h3>Painter Function Signature</h3>

```dart
Rect Function(
  Canvas canvas,
  Offset center,
  double Function(double meters, double latitude) metersToPixels,
  Offset Function(LatLng latLng, {LatLng? referencePoint}) latLngToPixelOffset,
  int zoomLevel,
)
```

<p><strong>Parameters:</strong></p>

<ul>
  <li><code>canvas</code> - The canvas to draw on</li>
  <li><code>center</code> - The marker's center position in pixels</li>
  <li><code>metersToPixels</code> - Convert meters to pixels at current zoom and latitude</li>
  <li><code>latLngToPixelOffset</code> - Convert lat/lng coordinates to pixel offsets</li>
  <li><code>zoomLevel</code> - Current map zoom level</li>
</ul>

<p><strong>Returns:</strong> A <code>Rect</code> representing the marker's bounds for hit testing and culling</p>

<h2>Performance Tips</h2>

<ul>
  <li>Enable <code>cullMarkers</code> to avoid rendering off-screen markers</li>
  <li>Use <code>drawHitMarkerLast</code> to bring interacted markers to the front</li>
  <li>Adjust <code>hoverDebounceDuration</code> to balance responsiveness and performance</li>
  <li>Return accurate <code>Rect</code> bounds from your painter for optimal culling</li>
  <li>Consider using simpler marker shapes at lower zoom levels</li>
</ul>

<h2>Example App</h2>

<p>
  Check out the complete example in the <code>example/</code> folder, which demonstrates:
</p>

<ul>
  <li>Rendering 2000+ markers efficiently</li>
  <li>Interactive markers with tap and hover handlers</li>
  <li>Custom balloon-style markers with icons</li>
  <li>Lines connecting markers to cluster centers</li>
  <li>Dialog popups on marker tap</li>
</ul>

<h2>License</h2>

<p>This project is licensed under the MIT License - see the LICENSE file for details.</p>

<h2>Contributing</h2>

<p>Contributions are welcome! Please feel free to submit issues and pull requests.</p>
