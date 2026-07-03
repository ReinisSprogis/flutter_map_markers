import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  test('RenderSpriteMarkerLayer file exists in lib', () {
    // The file is in lib/sprite_marker_layer/sprite_marker_layer/
    final file = File('lib/sprite_marker_layer/sprite_marker_layer/sprite_marker_layer_render_box.dart');
    expect(file.existsSync(), isTrue);
    // Check that the file is not empty
    final content = file.readAsStringSync();
    expect(content.length, greaterThan(0));
  });
}