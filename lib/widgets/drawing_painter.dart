import 'package:flutter/material.dart';
import '../models/tactical_drawing.dart';
import '../models/tactical_arrow.dart';

/// CustomPainter for rendering all drawing shape types.
class DrawingPainter extends CustomPainter {
  final DrawingType type;
  final Offset origin;
  final Offset size;
  final List<Offset> points;
  final ArrowColor drawingColor;
  final bool isSelected;
  final double strokeWidth;

  DrawingPainter({
    required this.type,
    required this.origin,
    required this.size,
    required this.points,
    required this.drawingColor,
    this.isSelected = false,
    this.strokeWidth = 3.0,
  });

  Color get _color {
    switch (drawingColor) {
      case ArrowColor.red:
        return Colors.red;
      case ArrowColor.yellow:
        return Colors.yellow;
      case ArrowColor.white:
        return Colors.white;
    }
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = _color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case DrawingType.circle:
        _paintCircle(canvas, paint);
        break;
      case DrawingType.rectangle:
        _paintRectangle(canvas, paint);
        break;
      case DrawingType.freehand:
        _paintFreehand(canvas, paint);
        break;
    }

    if (isSelected) {
      _paintSelectionIndicators(canvas);
    }
  }

  void _paintCircle(Canvas canvas, Paint paint) {
    final radius = size.dx;
    if (radius > 0) {
      // Draw filled area with alpha 0.2
      final fillPaint = Paint()
        ..color = _color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(origin, radius, fillPaint);
      // Draw stroke
      canvas.drawCircle(origin, radius, paint);
    }
  }

  void _paintRectangle(Canvas canvas, Paint paint) {
    if (size.dx != 0 && size.dy != 0) {
      final rect = Rect.fromLTWH(origin.dx, origin.dy, size.dx, size.dy);
      // Draw filled area with alpha 0.2
      final fillPaint = Paint()
        ..color = _color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);
      // Draw stroke
      canvas.drawRect(rect, paint);
    }
  }

  void _paintFreehand(Canvas canvas, Paint paint) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  void _paintSelectionIndicators(Canvas canvas) {
    final indicatorPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const handleRadius = 8.0;

    switch (type) {
      case DrawingType.circle:
        // Draw handles at cardinal points of the circle
        final radius = size.dx;
        final handles = [
          origin + Offset(radius, 0), // Right
          origin + Offset(-radius, 0), // Left
          origin + Offset(0, radius), // Bottom
          origin + Offset(0, -radius), // Top
        ];
        for (final handle in handles) {
          canvas.drawCircle(handle, handleRadius, indicatorPaint);
          canvas.drawCircle(handle, handleRadius, borderPaint);
        }
        break;

      case DrawingType.rectangle:
        // Draw handles at corners
        final handles = [
          origin, // Top-left
          origin + Offset(size.dx, 0), // Top-right
          origin + Offset(0, size.dy), // Bottom-left
          origin + size, // Bottom-right
        ];
        for (final handle in handles) {
          canvas.drawCircle(handle, handleRadius, indicatorPaint);
          canvas.drawCircle(handle, handleRadius, borderPaint);
        }
        break;

      case DrawingType.freehand:
        // Draw handle at start and end of path
        if (points.isNotEmpty) {
          canvas.drawCircle(points.first, handleRadius, indicatorPaint);
          canvas.drawCircle(points.first, handleRadius, borderPaint);
          if (points.length > 1) {
            canvas.drawCircle(points.last, handleRadius, indicatorPaint);
            canvas.drawCircle(points.last, handleRadius, borderPaint);
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.origin != origin ||
        oldDelegate.size != size ||
        oldDelegate.points != points ||
        oldDelegate.drawingColor != drawingColor ||
        oldDelegate.isSelected != isSelected;
  }
}

/// Painter for drawing preview while creating a shape.
class DrawingPreviewPainter extends CustomPainter {
  final DrawingType type;
  final Offset startPoint;
  final Offset currentPoint;
  final List<Offset> freehandPoints;
  final ArrowColor drawingColor;

  DrawingPreviewPainter({
    required this.type,
    required this.startPoint,
    required this.currentPoint,
    required this.freehandPoints,
    required this.drawingColor,
  });

  Color get _color {
    switch (drawingColor) {
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
      ..color = _color.withValues(alpha: 0.7)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Fill paint for circle and rectangle
    final fillPaint = Paint()
      ..color = _color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    switch (type) {
      case DrawingType.circle:
        // Start and current points define the diameter
        final center = (startPoint + currentPoint) / 2;
        final radius = (currentPoint - startPoint).distance / 2;
        canvas.drawCircle(center, radius, fillPaint);
        canvas.drawCircle(center, radius, paint);
        break;

      case DrawingType.rectangle:
        final rect = Rect.fromPoints(startPoint, currentPoint);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, paint);
        break;

      case DrawingType.freehand:
        if (freehandPoints.length < 2) return;
        final path = Path();
        path.moveTo(freehandPoints.first.dx, freehandPoints.first.dy);
        for (int i = 1; i < freehandPoints.length; i++) {
          path.lineTo(freehandPoints[i].dx, freehandPoints[i].dy);
        }
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPreviewPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.startPoint != startPoint ||
        oldDelegate.currentPoint != currentPoint ||
        oldDelegate.freehandPoints != freehandPoints ||
        oldDelegate.drawingColor != drawingColor;
  }
}
