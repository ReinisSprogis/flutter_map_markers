import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Utility {
  /// Generates a random point around a cluster center within a specified maximum distance.
  /// [clusterCenter]: The central point of the cluster.
  /// [random]: An instance of Random for generating random values.
  /// [maxDistance]: The maximum distance from the cluster center in degrees.
  /// Returns a LatLng representing the generated point.
  static LatLng clusterPoint(LatLng clusterCenter, Random random, {double maxDistance = 0.5}) {
    double angle = random.nextDouble() * 2 * pi;
    double distance = random.nextDouble() * maxDistance;
    double latOffset = distance * sin(angle) * (0.7 + random.nextDouble() * 0.6);
    double lonOffset = distance * cos(angle) * (0.7 + random.nextDouble() * 0.6);
    double lat = clusterCenter.latitude + latOffset;
    double lon = clusterCenter.longitude + lonOffset;
    lat = lat.clamp(-90.0, 90.0);
    lon = lon.clamp(-180.0, 180.0);
    return LatLng(lat, lon);
  }

  /// Generates a color from a gradient based on the index and total count.
  static Color getGradientColor(int i, int count, {bool grayScale = false}) {
    double hueStart = 0.0;
    double hueEnd = 300;
    double t = i / (count - 1);
    double hue = hueStart + t * (hueEnd - hueStart);
    // print('hue: $hue');
    //random from 100 to 1000
    //   double randomSize = 100 + random.nextDouble() * 900;
    final color = HSVColor.fromAHSV(1.0, hue, grayScale ? 0.0 : 1.0, 0.95).toColor();
    return color;
  }


  static LatLng randomWalk(LatLng position, int index) {
    final random = Random();
    double lat = 0;
    double lon = 0;
    
    
      // Random angle between 0 and 360 degrees
      double angle = random.nextDouble() * 360;
      const min = 1e-3; // 0.0001
      const max = 1e-1; // 0.01
      // Increase the step size range to walk farther
      double stepSize = min + random.nextDouble() * (max - min);

      // Convert angle to radians
      double angleRad = angle * pi / 180;

      // Calculate changes in lat/lon based on angle and step size
      double latChange = stepSize * cos(angleRad); // Latitude change (using cosine for north/south movement)
      double lonChange = stepSize * sin(angleRad); // Longitude change (using sine for east/west movement)

      lat += latChange;
      lon += lonChange;

      // Clamp latitude to [-90, 90]
      lat = lat.clamp(-89.0, 89.0);

      // Wrap longitude to [-180, 180]
      if (lon > 180.0) {
        lon = -180.0 + (lon - 180.0);
      } else if (lon < -180.0) {
        lon = 180.0 + (lon + 180.0);
      }
    return LatLng(position.latitude + lat, position.longitude + lon);
    }

  
}
