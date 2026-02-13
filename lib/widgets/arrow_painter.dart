import 'dart:math';
import 'package:flutter/material.dart';
import '../models/tactical_arrow.dart';

/// CustomPainter that draws a curved arrow using cubic Bezier curve.
class ArrowPainter extends CustomPainter {
  final Offset start;
  final Offset controlPoint1;
  final Offset controlPoint2;
  final Offset end;
  final bool hasStartArrowhead;
  final bool hasEndArrowhead;
  final bool isDashed;
  final ArrowColor arrowColor;
  final double strokeWidth;
  final double arrowHeadSize;
  final bool showControlPoints;

  ArrowPainter({
    required this.start,
    required this.end,
    Offset? controlPoint1,
    Offset? controlPoint2,
    this.hasStartArrowhead = false,
    this.hasEndArrowhead = true,
    this.isDashed = false,
    this.arrowColor = ArrowColor.white,
    this.strokeWidth = 3.0,
    this.arrowHeadSize = 15.0,
    this.showControlPoints = false,
  }) : controlPoint1 = controlPoint1 ?? _defaultCP1(start, end),
       controlPoint2 = controlPoint2 ?? _defaultCP2(start, end);

  static Offset _defaultCP1(Offset start, Offset end) {
    return Offset(
      start.dx + (end.dx - start.dx) / 3,
      start.dy + (end.dy - start.dy) / 3,
    );
  }

  static Offset _defaultCP2(Offset start, Offset end) {
    return Offset(
      start.dx + (end.dx - start.dx) * 2 / 3,
      start.dy + (end.dy - start.dy) * 2 / 3,
    );
  }

  Color get _color {
    switch (arrowColor) {
      case ArrowColor.red:
        return Colors.red;
      case ArrowColor.yellow:
        return Colors.yellow;
      case ArrowColor.white:
        return Colors.white;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Calculate tangent angles at start and end for arrowheads
    // For cubic Bezier, the tangent at start is from start to controlPoint1
    // and at end is from controlPoint2 to end
    final startAngle = atan2(controlPoint1.dy - start.dy, controlPoint1.dx - start.dx);
    final endAngle = atan2(end.dy - controlPoint2.dy, end.dx - controlPoint2.dx);

    // Calculate adjusted endpoints for the curve
    final arrowBaseOffset = arrowHeadSize * cos(pi / 6);

    Offset curveStart = start;
    Offset curveEnd = end;

    if (hasStartArrowhead) {
      curveStart = Offset(
        start.dx + arrowBaseOffset * cos(startAngle),
        start.dy + arrowBaseOffset * sin(startAngle),
      );
    }

    if (hasEndArrowhead) {
      curveEnd = Offset(
        end.dx - arrowBaseOffset * cos(endAngle),
        end.dy - arrowBaseOffset * sin(endAngle),
      );
    }

    // Draw the curve
    if (isDashed) {
      _drawDashedCurve(canvas, curveStart, controlPoint1, controlPoint2, curveEnd, paint);
    } else {
      final path = Path();
      path.moveTo(curveStart.dx, curveStart.dy);
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        curveEnd.dx, curveEnd.dy,
      );
      canvas.drawPath(path, paint);
    }

    // Draw arrowheads
    if (hasEndArrowhead) {
      _drawArrowhead(canvas, end, endAngle);
    }
    if (hasStartArrowhead) {
      _drawArrowhead(canvas, start, startAngle + pi);
    }

    // Draw control points and lines (for debugging/editing visualization)
    if (showControlPoints) {
      _drawControlPoints(canvas);
    }
  }

  void _drawDashedCurve(Canvas canvas, Offset start, Offset cp1, Offset cp2, Offset end, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    const steps = 100;

    var drawing = true;
    var currentDashLength = 0.0;
    Offset? lastPoint;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final point = _cubicBezierPoint(t, start, cp1, cp2, end);

      if (lastPoint != null) {
        final segmentLength = (point - lastPoint).distance;
        currentDashLength += segmentLength;

        if (drawing) {
          canvas.drawLine(lastPoint, point, paint);
        }

        if (currentDashLength >= (drawing ? dashWidth : dashSpace)) {
          drawing = !drawing;
          currentDashLength = 0;
        }
      }

      lastPoint = point;
    }
  }

  Offset _cubicBezierPoint(double t, Offset p0, Offset p1, Offset p2, Offset p3) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    return Offset(
      uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx,
      uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy,
    );
  }

  void _drawArrowhead(Canvas canvas, Offset tip, double angle) {
    final arrowPaint = Paint()
      ..color = _color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.fill;

    final path = Path();

    final p1 = Offset(
      tip.dx - arrowHeadSize * cos(angle - pi / 6),
      tip.dy - arrowHeadSize * sin(angle - pi / 6),
    );
    final p2 = Offset(
      tip.dx - arrowHeadSize * cos(angle + pi / 6),
      tip.dy - arrowHeadSize * sin(angle + pi / 6),
    );

    path.moveTo(tip.dx, tip.dy);
    path.lineTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.close();

    canvas.drawPath(path, arrowPaint);
  }

  void _drawControlPoints(Canvas canvas) {
    final cpPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final cpFillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Draw lines from endpoints to control points
    canvas.drawLine(start, controlPoint1, cpPaint);
    canvas.drawLine(end, controlPoint2, cpPaint);

    // Draw control point circles
    canvas.drawCircle(controlPoint1, 8, cpFillPaint);
    canvas.drawCircle(controlPoint1, 8, cpPaint);
    canvas.drawCircle(controlPoint2, 8, cpFillPaint);
    canvas.drawCircle(controlPoint2, 8, cpPaint);
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.controlPoint1 != controlPoint1 ||
        oldDelegate.controlPoint2 != controlPoint2 ||
        oldDelegate.end != end ||
        oldDelegate.hasStartArrowhead != hasStartArrowhead ||
        oldDelegate.hasEndArrowhead != hasEndArrowhead ||
        oldDelegate.isDashed != isDashed ||
        oldDelegate.arrowColor != arrowColor ||
        oldDelegate.showControlPoints != showControlPoints;
  }
}
