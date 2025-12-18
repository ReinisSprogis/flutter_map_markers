import 'dart:math';

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
}