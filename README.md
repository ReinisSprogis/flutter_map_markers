<div align="center">
  <h1>Flutter Map Markers</h1>
  
  <img src="https://github.com/ReinisSprogis/flutter_map_markers/raw/main/screenshots/asset_one.png" alt="Flutter Map Markers example screenshot" width="100%"/>
  
  <img src="https://github.com/ReinisSprogis/flutter_map_markers/raw/main/screenshots/asset_two.png" alt="Flutter Map Markers example screenshot" width="100%"/>
  
  <p>Canvas based marker rendering for <a href="https://pub.dev/packages/flutter_map">flutter_map</a></p>
</div>

<hr>

<h2>Overview</h2>

<p>
  <code>flutter_map_markers</code> is a plugin for <a href="https://pub.dev/packages/flutter_map">flutter_map</a> package that provides a flexible canvas based marker layer. It enables you to render interactive markers directly on the map using Canvas.
</p>

<strong>This is the initial release. There might be bugs or missing features. Use with caution in production. Please report any issues or feature requests you have and give feedback on your experience.</strong>
<p>If you find this useful, consider supporting <a href="https://github.com/sponsors/ReinisSprogis">me</a>.</p>

<h2>Features</h2>

<ul>
  <li><strong>Interactive markers</strong> - Support for tap</li>
  <li><strong>Custom hit area</strong> - Define custom hit areas for complex marker shapes</li>
  <li><strong>Marker rotation</strong> - Counter-rotate markers to maintain orientation during map rotation</li>
  <li><strong>Culling</strong> - Automatically cull markers outside the visible viewport</li>
  <li><strong>Preset shapes and markers</strong> - Built in marker presets for common marker types</li>
  <li><strong>Flexible rendering</strong> - Full control over marker appearance using Canvas API</li>
  <li><strong>Zoom level Awareness</strong> - Change marker graphics based on current zoom level</li>
</ul>

<h2>Getting Started</h2>

<h3>Installation</h3>

<p>Add <code>flutter_map_markers</code> to your <code>pubspec.yaml</code>:</p>

```yaml
dependencies:
  flutter_map_markers: ^0.1.1
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
      userAgentPackageName: 'your.package.name',
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
          },
        ),
      ],
    ),
  ],
)
```

<h3>Using <code>MarkerPresets</code></h3>
<p>There are several built-in marker presets to help you get started quickly.</p>
<p>You can chose to either to use the full marker preset or just the path for more customization. Or you can use it as an example how to construct your own.</p>
<h4>Markers</h4>
<p>Marker presets are available in the <code>MarkerPresets</code> class for common marker shapes and parameters.</p>
<ul>
<li>
<p><code>MarkerPresets.raindropMarker()</code> a standard raindrop shaped marker. </p>
<p><code>MarkerPresets.textMarker()</code> places a text marker with customizable text.</p>
<p><code>MarkerPresets.iconMarker()</code> places an icon on the map. Defaults to Icons.location_pin as a marker pin.</p>
</li>
</ul>
To use a preset marker simply call a static method from the <code>MarkerPresets</code> class:

```dart
    final marker = MarkerPresets.raindropMarker(
      position: position,
      radius: 12,
    );
```
<p>Paths</p>
<p>You can use path from <code>MarkerPresets</code> if you want the shape but more customization.</p>
<ul>
<li>
<p><code>MarkerPresets.ballMarkerPath()</code> A path as a ball with knob pointing to location. Returns (path, center) where center is a center of the ball.</p>
<p><code>MarkerPresets.raindropMarkerPath()</code> More curved path for a raindrop shape. Returns (path, center) where center is the center of the circular part of the raindrop.</p>
</li>
</ul>
<p>To use a preset path simply call a static method from the <code>MarkerPresets</code> class inside your painter function:</p>
<p>You can then use centerPosition to draw additional content centered on the ball.</p>

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
    canvas.drawCircle(markerCenterPosition, 5, Paint()..color = Colors.white);
  },
)
```
<h3 id="size">Size</h3>
<p>The <code>size</code> function allows you to define the bounding rectangle of the marker for hit testing and culling purposes.</p>
<p>If not provided, then culling will happen based on the single point position of the marker and markers might disappear before fully leaving the screen.</p>
<p>It is recommended to provide accurate bounds for better performance and interaction.</p>
<p>It is used for <a href="#hit-testing">hit testing</a> if no custom hitArea is provided.</p>

```dart
CanvasMarker(
  position: LatLng(51.5074, -0.1278),
  size: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
    // Define a bounding box of 20x20 pixels around the center
    // If you use metersToPixels or latLngToPixelOffset when painting marker, then use the same here to get correct size.
    return Rect.fromCenter(center: center, width: 20, height: 20);
  },
  painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
    final paint = Paint()..color = Colors.green;
    canvas.drawCircle(center, 10, paint);
  },
)
```

<h3>Interactive Markers</h3>
<p> Currently only onTap is supported, but more gesture callbacks will be added in future releases. </p>
<p>Provide hitArea that returns Path to define precise hit areas for markers.</p>
<p>If no hitArea is provided, the bounding rectangle returned by size function will be used.</p>
<p>If both, hitArea and size are not provided, the marker will not be interactive.</p>
<p>See <a href="#size">size</a> for more details.</p>

<h3 id="hit-testing">Custom Hit Detection</h3>
<p>You can define precise hit areas for complex marker shapes.</p>
<p>Provide a hitArea function that returns a Path representing the clickable area of the marker.</p>
<p>

```dart
CanvasMarker(
  position: LatLng(51.5074, -0.1278),
  painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
    final (path, _) = MarkerPresets.ballMarkerPath(center, ballRadius: 15);
    final paint = Paint()..color = Colors.purple;
    canvas.drawPath(path, paint);
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
<p>You can use <code>TextPainter</code> to draw icons or text on your markers.</p>
<p>If using TextPainter, make sure to call <code>layout()</code> outside painting for better performance.</p>
<p>Overall don't create new objects unnecessarily inside the painter function to avoid unnecessary allocations during rendering.</p>

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

final bgPaint = Paint()..color = Colors.orange;
CanvasMarker(
  position: LatLng(51.5074, -0.1278),
  painter: (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
    // Draw marker background
    final (path, iconCenter) = MarkerPresets.ballMarkerPath(center, ballRadius: 15);
    canvas.drawPath(path, bgPaint);
    
    // Draw icon
    final iconOffset = iconCenter - Offset(
      textPainter.width / 2,
      textPainter.height / 2,
    );
    textPainter.paint(canvas, iconOffset);
  },
)
```

<h3>Layer Configuration</h3>
<p>Configure the <code>CanvasMarkerLayer</code> with various options:</p>
<p><strong>Showing debug rectangles and hit areas can help during development and troubleshooting size inconsistencies.</strong></p>

```dart
CanvasMarkerLayer(
  markers: myMarkers,
  showDebugRect: false,          // Show size debug rectangles around markers
  showDebugHitArea: false,       // Show debug hit areas
  drawHitMarkerLast: true,       // Draw tapped marker on top
  cullMarkers: true,             // Cull off-screen markers
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
    <td><code>size</code></td>
    <td><code>MarkerSize?</code></td>
    <td>Define the size of the marker</td>
  </tr>
  <tr>
    <td><code>painter</code></td>
    <td><code>CanvasPainter</code></td>
    <td>Function to draw the marker on canvas</td>
  </tr>
  <tr>
    <td><code>hitArea</code></td>
    <td><code>HitArea?</code></td>
    <td>Custom hit detection path</td>
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
</table>

<h3>Painter Function Signature</h3>

```dart
Rect Function(
  Canvas canvas,
  Offset center,
  double Function(double meters, LatLng? position) metersToPixels,
  Offset Function(LatLng latLng, {LatLng? referencePoint}) latLngToPixelOffset,
  int zoomLevel,
)
```

<p><strong>Parameters:</strong></p>

<ul>
  <li><code>canvas</code> - The canvas to draw on</li>
  <li><code>center</code> - The marker's center position in pixels</li>
  <li><code>metersToPixels</code> - Convert meters to pixels at current zoom and position</li>
  <li><code>latLngToPixelOffset</code> - Convert lat/lng coordinates to pixel offsets</li>
  <li><code>zoomLevel</code> - Current map zoom level</li>
</ul>

<h2>Example App</h2>

<p>
  Check out the complete example in the <code>example/</code> folder, which demonstrates:
</p>
