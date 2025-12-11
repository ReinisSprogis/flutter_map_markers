import 'dart:ui';
import 'package:latlong2/latlong.dart' as coord;

typedef CanvasPainter =
    Rect Function(
      Canvas canvas,
      Offset center,
      double Function(double meters, double latitude) metersToPixels,
      Offset Function(coord.LatLng latLng, {coord.LatLng? referencePoint}) latLngToPixelOffset,
      int zoomLevel,
    );

typedef HitArea =
    Path Function(
      Offset center,
      double Function(double meters, double latitude) metersToPixels,
      Offset Function(coord.LatLng latLng, {coord.LatLng? referencePoint}) latLngToPixelOffset,
      int zoomLevel,
    );

///TileMarker is a class used to draw markers on a tile.
///[painter] must be provided to draw the marker.
/// Provide markers to the [MarkerTileManager] and set the [MarkerTileManager] to the [MarkerTileLayer] to display them on the map.
class CanvasMarker {
  ///This is a LatLng object that represents the position of the marker on the map.
  coord.LatLng position;

  /// If provided, this function is used to detect hits on the marker.
  /// It should return a [Path] that represents the area that will be hit tested.
  /// This is an optional parameter, if not provided, the Rect returned by the [painter] will be used for hit testing.
  ///
  /// This is useful for markers that have complex shapes or require custom hit detection logic.
  ///
  /// For example: You want to detect tap on the circle, but Rect returned by [painter] is a square,
  /// this would detect tap on the circle even if the tap is outside the circle, but within the square.
  /// By returning a [Path] that represents the circle, you can ensure that only taps within the circle are detected.
  ///
  /// If any of the parameters [metersToPixels],[latLngToPixelOffset],[zoomLevel] are used to draw the marker,
  /// they must also be used in the hit detection logic to ensure consistency.
  ///
  /// The [hitArea] function provides several parameters:
  /// /// - [center]: The central pixel position of the marker. This is typically the anchor point for rendering shapes (e.g., the center of a circle).
  /// - [metersToPixels]: A function that converts a size in meters to pixels, based
  ///  on the current zoom level and latitude of the [position]. This must also be used when computing the returned [Rect].
  /// - [latLngToPixelOffset]: A function that converts geographic coordinates (LatLng)
  /// to pixel offsets. Useful for drawing lines or shapes between coordinates.
  /// - [zoomLevel]: The current zoom level, which can be used to scale graphics based on the zoom level.
  HitArea? hitArea;

  /// A painter function that draws on a Canvas.
  ///
  /// This is a regular painter that uses the Canvas API to draw markers.
  /// Generally it is performant enough for most use cases. But it can suffer from overdraw issues when rendering many markers.
  /// However, it draws once per tile-per zoom level, so it is still efficient and caches the result as an image.
  /// First paint is slower but because it is cached, subsequent loads of the same tile are significantly faster.
  ///
  /// The painter must return a [Rect] that represents the area covered by the drawn marker. This [Rect] is used to determine which tiles the marker should appear on.
  /// - If the returned [Rect] spans multiple tiles, the marker will be drawn on all intersecting tiles, forming a complete visual.
  /// - If the marker appears cut off at tile edges, it is likely due to an incorrectly calculated [Rect].
  /// - Tile inclusion is currently determined by checking whether the [Rect] intersects the tile bounds.
  /// - As a result, even if the visible part of the marker isn't on a tile, it may still be indexed and drawn if the [Rect] overlaps it.
  /// - The returned [Rect] is also used for hit testing, so it must be precise.
  ///
  /// The [painter] function provides several parameters:
  ///
  /// - [canvas]: The [Canvas] instance used to draw the marker.
  /// - [center]: The central pixel position of the marker. This is typically the anchor point for rendering shapes (e.g., the center of a circle).
  /// - [metersToPixels]: A function that converts a size in meters to pixels, based on the current zoom level and latitude of the [position]. This must also be used when computing the returned [Rect].
  /// - [latLngToPixelOffset]: A function that converts geographic coordinates (LatLng) to pixel offsets. Useful for drawing lines or shapes between coordinates.
  /// - [zoomLevel]: The current zoom level, which can be used to scale graphics based on the zoom level.
  ///
  /// There is a parameter for the [MarkerTileManager] [int? drawWithCanvasZoom].
  /// When zooming closer it might be more performant to draw markers directly on the canvas instead of using the cached image.
  /// If this is provided, canvas will be drawn directly using Canvas API, without caching the result as an image at zoom level >= drawWithCanvasZoom.
  CanvasPainter painter;

  /// If true then counter rotates the marker to camera rotation.
  /// Only works in direct painter mode (when [drawWithCanvasZoom] is set in [MarkerManager]).
  bool rotate;

  /// Callback function that is called when the marker is tapped.
  final Function? onTap;

  /// Callback function that is called when the marker is double tapped.
  final Function? onDoubleTap;

  /// Callback function that is called when the marker is long pressed.
  final Function? onLongPress;

  /// Callback function that is called when the mouse hovers over the marker.
  /// The boolean parameter indicates whether the mouse is hovering (true) or not (false).
  final Function(bool)? onHover;

  CanvasMarker({required this.position, required this.painter, this.hitArea, this.rotate = false, this.onTap, this.onDoubleTap, this.onLongPress, this.onHover});

  Map<String, dynamic> toJson() => {'lat': position.latitude, 'lng': position.longitude};

  /// Copy the marker with new properties.
  CanvasMarker copyWith({
    coord.LatLng? position,
    CanvasPainter? painter,
    HitArea? hitArea,
    bool? rotate,
    Function? onTap,
    Function? onDoubleTap,
    Function? onLongPress,
    Function(bool)? onHover,
  }) {
    return CanvasMarker(
      position: position ?? this.position,
      painter: painter ?? this.painter,
      hitArea: hitArea ?? this.hitArea,
      rotate: rotate ?? this.rotate,
      onTap: onTap ?? this.onTap,
      onDoubleTap: onDoubleTap ?? this.onDoubleTap,
      onLongPress: onLongPress ?? this.onLongPress,
      onHover: onHover ?? this.onHover,
    );
  }

  @override
  String toString() {
    return 'TileMarker(position: $position, painter: $painter, hitArea: $hitArea, rotateToCamera: $rotate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final CanvasMarker otherMarker = other as CanvasMarker;
    return position == otherMarker.position &&
        painter == otherMarker.painter &&
        hitArea == otherMarker.hitArea &&
        rotate == otherMarker.rotate &&
        onTap == otherMarker.onTap &&
        onDoubleTap == otherMarker.onDoubleTap &&
        onLongPress == otherMarker.onLongPress &&
        onHover == otherMarker.onHover;
  }

  @override
  int get hashCode {
    return position.hashCode ^ painter.hashCode ^ hitArea.hashCode ^ rotate.hashCode ^ onTap.hashCode ^ onDoubleTap.hashCode ^ onLongPress.hashCode ^ onHover.hashCode;
  }
}
