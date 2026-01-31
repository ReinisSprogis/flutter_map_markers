import 'package:flutter/rendering.dart';
import 'package:flutter_map_markers/sprite_marker_layer/sprite_marker_layer_raw/sprite_marker_manager.dart';

class SpriteMarkerLayerRawRenderBox extends RenderBox {
  SpriteMarkerManager _markerManager;
  bool _isListening = false;

  SpriteMarkerLayerRawRenderBox({required SpriteMarkerManager markerManager})
    : _markerManager = markerManager {
    _startListening();
  }

  void _onManagerChanged() {
    // Animations/camera updates mutate internal render buffers; repaint.
    markNeedsPaint();
  }

  void _startListening() {
    if (_isListening) return;
    _markerManager.addListener(_onManagerChanged);
    _isListening = true;
  }

  void _stopListening() {
    if (!_isListening) return;
    _markerManager.removeListener(_onManagerChanged);
    _isListening = false;
  }

  SpriteMarkerManager get markerManager => _markerManager;
  set markerManager(SpriteMarkerManager value) {
    if (identical(value, _markerManager)) return;
    _stopListening();
    _markerManager = value;
    _startListening();
    markNeedsPaint();
  }

  @override
  void detach() {
    _stopListening();
    super.detach();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    // Re-attach listener in case this RenderObject was detached/reattached.
    _startListening();
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    _markerManager.updateViewportSize(size);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_markerManager.markerCount == 0) return;
    _markerManager.draw(context.canvas, offset);
  }
}
