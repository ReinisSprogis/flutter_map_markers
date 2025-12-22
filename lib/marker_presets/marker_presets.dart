import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_markers/canvas_marker_layer/canvas_marker.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// A collection of preset marker shapes and their corresponding CanvasMarker generators.
class MarkerPresets {
  ///Returns a ball shaped Path and the center of the ball.
  static (Path path, Offset arcCenter) ballMarkerPath(
    Offset center, {
    double ballRadius = 25,
    double knobHeight = 15,
    double knobAngle = pi / 4,
  }) {
    final double halfAngle = knobAngle / 2;

    // Bottom tip of the knob
    final Offset bottomTip = center;

    // Knob base points (left and right)
    final Offset leftKnob = Offset(
      bottomTip.dx - knobHeight * sin(halfAngle),
      bottomTip.dy - knobHeight * cos(halfAngle),
    );

    final Offset rightKnob = Offset(
      bottomTip.dx + knobHeight * sin(halfAngle),
      bottomTip.dy - knobHeight * cos(halfAngle),
    );

    // Midpoint of the chord
    final Offset mid = Offset(
      (leftKnob.dx + rightKnob.dx) / 2,
      (leftKnob.dy + rightKnob.dy) / 2,
    );

    final double chordLength = (rightKnob - leftKnob).distance;
    final double halfChord = chordLength / 2;

    // Clamp halfChord to avoid sqrt of negative
    final double safeHalfChord = min(halfChord, ballRadius);

    // Sagitta height (distance from midpoint to arc center)
    final double h = sqrt(
      ballRadius * ballRadius - safeHalfChord * safeHalfChord,
    );

    // Normalized perpendicular vector (90° CCW from chord)
    final Offset chordDir = (rightKnob - leftKnob) / chordLength;
    final Offset perp = Offset(-chordDir.dy, chordDir.dx);

    // Determine arc center based on Flutter arc sweep logic
    const bool clockwise = true;
    const bool largeArc = true;
    final bool flip = clockwise != largeArc;

    final Offset arcCenter = mid + perp * (h * (flip ? 1 : -1));

    // Construct the path
    final Path path = Path()
      ..moveTo(leftKnob.dx, leftKnob.dy)
      ..arcToPoint(
        rightKnob,
        radius: Radius.circular(ballRadius),
        largeArc: largeArc,
        clockwise: clockwise,
      )
      ..lineTo(bottomTip.dx, bottomTip.dy)
      ..close();

    return (path, arcCenter);
  }

  ///Returns a raindrop shaped Path and the center of the circular part of the raindrop.
  /// The bottom of the raindrop is at the provided [bottom] Offset.
  /// [radius] defines the radius of the circular part of the raindrop.
  /// The center of the circular part is located 2 * radius above the bottom point.
  static (Path path, Offset center) raindropMarkerPath(
    Offset bottom, {
    double radius = 20,
  }) {
    // Circle center is 2 radius above the final bottom anchor.
    final cx = bottom.dx;
    final cy = bottom.dy - radius * 2;

    const kappa = 0.5522847498307936;
    final k = kappa * radius;

    // Actual circle anchors before deformation
    final pTop = Offset(cx, cy - radius);
    final pRight = Offset(cx + radius, cy);
    final pLeft = Offset(cx - radius, cy);

    // Deformed bottom = provided bottom
    final pDropBottom = bottom;

    // Control points
    final cTR1 = Offset(cx + k, cy - radius);
    final cTR2 = Offset(cx + radius, cy - k);

    final cRB1 = Offset(cx + radius, cy + k);
    final cRB2 = Offset(cx + k, cy + radius - (radius / 2));
    // Moving control points inward by radius/3 for concave effect of the raindrop.
    // You can adjust this value for more or less pronounced effect.
    final cBL1 = Offset(cx - k, cy + radius - (radius / 2));
    final cBL2 = Offset(cx - radius, cy + k);

    final cLT1 = Offset(cx - radius, cy - k);
    final cLT2 = Offset(cx - k, cy - radius);

    final path = Path()..moveTo(pTop.dx, pTop.dy);

    // Top → Right
    path.cubicTo(cTR1.dx, cTR1.dy, cTR2.dx, cTR2.dy, pRight.dx, pRight.dy);

    // Right → Deformed Bottom
    path.cubicTo(
      cRB1.dx,
      cRB1.dy,
      cRB2.dx,
      cRB2.dy,
      pDropBottom.dx,
      pDropBottom.dy,
    );

    // Bottom → Left
    path.cubicTo(cBL1.dx, cBL1.dy, cBL2.dx, cBL2.dy, pLeft.dx, pLeft.dy);

    // Left → Top
    path.cubicTo(cLT1.dx, cLT1.dy, cLT2.dx, cLT2.dy, pTop.dx, pTop.dy);

    path.close();

    return (path, Offset(cx, cy));
  }

  ///Generates a raindrop marker at the given position.
  ///
  /// [position]: The geographical position of the marker.
  ///
  /// [radius]: The radius of the circular part of the raindrop.
  ///
  /// [fillColor]: The fill color of the raindrop.
  ///
  /// [borderColor]: The border color of the raindrop.
  ///
  /// [circleColor]: The color of the circle inside the raindrop.
  ///
  /// [onTap]: Optional callback function to be executed when the marker is tapped.
  ///
  /// [rotate]: Whether the marker should counter-rotate the map.
  static CanvasMarker raindropMarker({
    required LatLng position,
    double radius = 12.0,
    Color fillColor = const Color(0xfff1493c),
    Color borderColor = const Color(0xff81342d),
    Color circleColor = const Color(0xff81342d),
    VoidCallback? onTap,
    bool rotate = true,
  }) {
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint circlePaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.fill;

    final Paint fillPaint = Paint()
      ..strokeJoin = StrokeJoin.round
      ..color = fillColor
      ..style = PaintingStyle.fill;

    return CanvasMarker(
      rotate: rotate,
      position: position,
      size: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        // Ensure the size encompasses the entire raindrop
        final Rect bounds = Rect.fromLTRB(center.dx - radius, center.dy - radius * 3, center.dx + radius, center.dy);
        return bounds;
      },
      hitArea: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        final (path, _) = MarkerPresets.raindropMarkerPath(
          center,
          radius: radius,
        );
        return path;
      },
      painter:
          (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
            final (path, markerCenterPosition) =
                MarkerPresets.raindropMarkerPath(center, radius: radius);
            canvas.drawPath(path, fillPaint);
            canvas.drawPath(path, borderPaint);
            canvas.drawCircle(markerCenterPosition, radius / 2, circlePaint);
          },
      onTap: onTap,
    );
  }

  /// Generates a text marker at the given position.
  ///
  /// [position]: The geographical position of the marker.
  ///
  /// [text]: The text to display inside the marker.
  ///
  /// [fillColor]: The fill color of the marker.
  ///
  /// [borderColor]: The border color of the marker.
  ///
  /// [textColor]: The color of the text.
  ///
  /// [onTap]: Optional callback function to be executed when the marker is tapped.
  ///
  /// [rotate]: Whether the marker should counter-rotate the map.
  ///
  /// [zoomLevelTransition]: Optional zoom level threshold to switch to a simpler representation (circle) below the specified zoom level.
  static CanvasMarker textMarker({
    required LatLng position,
    required String text,
    Color fillColor = Colors.white,
    Color borderColor = Colors.deepPurple,
    Color textColor = Colors.black,
    VoidCallback? onTap,
    bool rotate = true,
    int? zoomLevelTransition,
  }) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
    textPainter.layout();

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final double width = textPainter.width + 8;
    final double height = textPainter.height + 8;
    final double cornerRadius = 4;

    Path createMarkerPath(
      Offset center,
      double width,
      double height,
      double cornerRadius,
    ) {
      Path markerPath = Path();
      markerPath.moveTo(center.dx, center.dy);
      markerPath.lineTo(center.dx - 2.5, center.dy - 5);
      markerPath.lineTo(center.dx - width / 2 + cornerRadius, center.dy - 5);
      markerPath.arcToPoint(
        Offset(center.dx - width / 2, center.dy - 5 - cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      );
      markerPath.lineTo(
        center.dx - width / 2,
        center.dy - height + cornerRadius,
      );
      markerPath.arcToPoint(
        Offset(center.dx - width / 2 + cornerRadius, center.dy - height),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      );
      markerPath.lineTo(
        center.dx + width / 2 - cornerRadius,
        center.dy - height,
      );
      markerPath.arcToPoint(
        Offset(center.dx + width / 2, center.dy - height + cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      );
      markerPath.lineTo(center.dx + width / 2, center.dy - 5 - cornerRadius);
      markerPath.arcToPoint(
        Offset(center.dx + width / 2 - cornerRadius, center.dy - 5),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      );
      markerPath.lineTo(center.dx + 2.5, center.dy - 5);
      markerPath.close();
      return markerPath;
    }

    return CanvasMarker(
      rotate: rotate,
      position: position,
      size: (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
        // Ensure the size encompasses the entire marker
        final Rect bounds = Rect.fromLTRB(
          center.dx - width / 2,
          center.dy - height,
          center.dx + width / 2,
          center.dy,
        );
        return bounds;
      },
      // hitArea: onTap != null
      //     ? (center, metersToPixels, latLngToPixelOffset, zoomLevel) {
      //         // Return a simple circle hit area below the zoom level transition
      //         if (zoomLevelTransition != null &&
      //             zoomLevel < zoomLevelTransition) {
      //           return Path()
      //             ..addOval(Rect.fromCircle(center: center, radius: 5));
      //         }
      //         // Return the full marker path otherwise
      //         Path markerPath = createMarkerPath(
      //           center,
      //           width,
      //           height,
      //           cornerRadius,
      //         );
      //         return markerPath;
      //       }
      //     : null,
      painter:
          (canvas, center, metersToPixels, latLngToPixelOffset, zoomLevel) {
            // Draw a simple circle below the zoom level transition
            if (zoomLevelTransition != null &&
                zoomLevel < zoomLevelTransition) {
              canvas.drawCircle(center, 5, fillPaint);
              canvas.drawCircle(center, 5, borderPaint);
            } else {
               // Draw the full marker otherwise
            Path markerPath = createMarkerPath(
              center,
              width,
              height,
              cornerRadius,
            );
            canvas.drawPath(markerPath, fillPaint);
            canvas.drawPath(markerPath, borderPaint);

            final textOffset =
                center -
                Offset(
                  textPainter.width / 2,
                  (height + 5) / 2 + textPainter.height / 2,
                );
            textPainter.paint(canvas, textOffset);
            }
           
          },
      onTap: onTap,
    );
  }

  /// Generates an icon marker at the given position.
  ///
  /// [position]: The geographical position of the marker.
  ///
  /// [iconData]: The icon data to display.
  ///
  /// [color]: The color of the icon.
  ///
  /// [size]: The size of the icon.
  ///
  /// [alignment]: The alignment of the icon relative to the marker position.
  ///
  /// [onTap]: Optional callback function to be executed when the marker is tapped.
  ///
  /// [rotate]: Whether the marker should counter-rotate the map.
  static CanvasMarker iconMarker({
    required LatLng position,
    IconData iconData = Icons.location_pin,
    required Color color,
    double size = 24.0,
    Alignment alignment = Alignment.center,
    VoidCallback? onTap,
    bool rotate = true,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: iconData.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double baseline = textPainter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );

    Offset topLeftFromAlignment(Offset center) {
      return Offset(
        center.dx - (alignment.x + 1) * textPainter.width / 2,
        center.dy - (alignment.y + 1) * textPainter.height / 2,
      );
    }

    Rect bounds(Offset center) {
      final topLeft = topLeftFromAlignment(center);
      return Rect.fromLTWH(
        topLeft.dx,
        topLeft.dy - baseline / 2,
        textPainter.width,
        textPainter.height,
      );
    }

    return CanvasMarker(
      rotate: rotate,
      position: position,

      size: (center, _, _, _) => bounds(center),

      hitArea: onTap != null
          ? (center, _, _, _) {
              final path = Path()..addRect(bounds(center));
              return path;
            }
          : null,

      painter: (canvas, center, _, _, _) {
        final topLeft = topLeftFromAlignment(center);

        final paintOffset = Offset(
          topLeft.dx,
          topLeft.dy + (textPainter.height / 2 - baseline),
        );

        textPainter.paint(canvas, paintOffset);
      },

      onTap: onTap,
    );
  }
}
