import 'dart:math';
import 'dart:ui';

class MarkerPresets {
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
}