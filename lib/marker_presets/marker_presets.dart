import 'dart:math';
import 'dart:ui';

class MarkerPresets {
  ///Returns a ball shaped Path and the center of the ball.
  static (Path path, Offset arcCenter) ballMarkerPath(Offset center, {double ballRadius = 25, double knobHeight = 15, double knobAngle = pi / 4}) {
    final double halfAngle = knobAngle / 2;

    // Bottom tip of the knob
    final Offset bottomTip = center;

    // Knob base points (left and right)
    final Offset leftKnob = Offset(bottomTip.dx - knobHeight * sin(halfAngle), bottomTip.dy - knobHeight * cos(halfAngle));

    final Offset rightKnob = Offset(bottomTip.dx + knobHeight * sin(halfAngle), bottomTip.dy - knobHeight * cos(halfAngle));

    // Midpoint of the chord
    final Offset mid = Offset((leftKnob.dx + rightKnob.dx) / 2, (leftKnob.dy + rightKnob.dy) / 2);

    final double chordLength = (rightKnob - leftKnob).distance;
    final double halfChord = chordLength / 2;

    // Clamp halfChord to avoid sqrt of negative
    final double safeHalfChord = min(halfChord, ballRadius);

    // Sagitta height (distance from midpoint to arc center)
    final double h = sqrt(ballRadius * ballRadius - safeHalfChord * safeHalfChord);

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
      ..arcToPoint(rightKnob, radius: Radius.circular(ballRadius), largeArc: largeArc, clockwise: clockwise)
      ..lineTo(bottomTip.dx, bottomTip.dy)
      ..close();

    return (path, arcCenter);
  }

  ///Returns a raindrop shaped Path and the center of the circular part of the raindrop.
  static (Path path, Offset center) raindropMarkerPath(Offset bottom, {double radius = 20}) {
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
    final cRB2 = Offset(cx + k, cy + radius - (radius / 3)); 
    // Moving control points inward by radius/3 for concave effect of the raindrop.
    // You can adjust this value for more or less pronounced effect.
    final cBL1 = Offset(cx - k, cy + radius - (radius / 3));
    final cBL2 = Offset(cx - radius, cy + k);

    final cLT1 = Offset(cx - radius, cy - k);
    final cLT2 = Offset(cx - k, cy - radius);

    final path = Path()..moveTo(pTop.dx, pTop.dy);

    // Top → Right
    path.cubicTo(cTR1.dx, cTR1.dy, cTR2.dx, cTR2.dy, pRight.dx, pRight.dy);

    // Right → Deformed Bottom
    path.cubicTo(cRB1.dx, cRB1.dy, cRB2.dx, cRB2.dy, pDropBottom.dx, pDropBottom.dy);

    // Bottom → Left
    path.cubicTo(cBL1.dx, cBL1.dy, cBL2.dx, cBL2.dy, pLeft.dx, pLeft.dy);

    // Left → Top
    path.cubicTo(cLT1.dx, cLT1.dy, cLT2.dx, cLT2.dy, pTop.dx, pTop.dy);

    path.close();

    return (path, Offset(cx, cy));
  }
}
