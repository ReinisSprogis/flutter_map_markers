import 'dart:math';
/// Utility class providing common functions.
class Utility {
  /// Converts a size in meters to pixels based on the current zoom level and latitude.
  static double metersToPixels(double meters, double latitude, double zoom) {
    double tileSize = 255.0;
    const earthCircumference = 40075016.686;
    const maxLat = 85.05112878;

    final clampedLat = latitude.clamp(-maxLat, maxLat);
    final latitudeRadians = clampedLat * pi / 180.0;
    final scale = tileSize * pow(2.0, zoom);

    final metersPerPixel = earthCircumference * cos(latitudeRadians) / scale;
    return meters / metersPerPixel;
  }
}