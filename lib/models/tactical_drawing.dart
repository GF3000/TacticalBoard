import 'dart:ui';
import 'dart:math';
import 'tactical_arrow.dart'; // For ArrowColor enum

/// Enum for drawing shape types.
enum DrawingType {
  circle,
  rectangle,
  freehand,
}

/// Unified data model for drawings on the tactical board.
class TacticalDrawing {
  final String id;
  final DrawingType type;
  ArrowColor color;

  /// For circle: center point. For rectangle: top-left corner.
  Offset origin;

  /// For circle: Offset(radius, radius). For rectangle: Offset(width, height).
  Offset size;

  /// For freehand: list of points in the path.
  List<Offset> points;

  TacticalDrawing({
    required this.id,
    required this.type,
    this.color = ArrowColor.white,
    this.origin = Offset.zero,
    this.size = Offset.zero,
    List<Offset>? points,
  }) : points = points ?? [];

  /// Factory constructor for creating a circle.
  factory TacticalDrawing.circle({
    required String id,
    required Offset center,
    required double radius,
    ArrowColor color = ArrowColor.white,
  }) {
    return TacticalDrawing(
      id: id,
      type: DrawingType.circle,
      origin: center,
      size: Offset(radius, radius),
      color: color,
    );
  }

  /// Factory constructor for creating a rectangle.
  factory TacticalDrawing.rectangle({
    required String id,
    required Offset topLeft,
    required Offset bottomRight,
    ArrowColor color = ArrowColor.white,
  }) {
    return TacticalDrawing(
      id: id,
      type: DrawingType.rectangle,
      origin: topLeft,
      size: Offset(bottomRight.dx - topLeft.dx, bottomRight.dy - topLeft.dy),
      color: color,
    );
  }

  /// Factory constructor for creating a freehand drawing.
  factory TacticalDrawing.freehand({
    required String id,
    required List<Offset> points,
    ArrowColor color = ArrowColor.white,
  }) {
    return TacticalDrawing(
      id: id,
      type: DrawingType.freehand,
      points: points,
      color: color,
    );
  }

  /// Creates a copy of this drawing with optional modifications.
  TacticalDrawing copyWith({
    String? id,
    DrawingType? type,
    ArrowColor? color,
    Offset? origin,
    Offset? size,
    List<Offset>? points,
  }) {
    return TacticalDrawing(
      id: id ?? this.id,
      type: type ?? this.type,
      color: color ?? this.color,
      origin: origin ?? this.origin,
      size: size ?? this.size,
      points: points ?? List.from(this.points),
    );
  }

  /// Returns the center point of the drawing.
  Offset get center {
    switch (type) {
      case DrawingType.circle:
        return origin;
      case DrawingType.rectangle:
        return Offset(origin.dx + size.dx / 2, origin.dy + size.dy / 2);
      case DrawingType.freehand:
        if (points.isEmpty) return Offset.zero;
        final rect = boundingRect;
        return rect.center;
    }
  }

  /// Returns the radius (for circles).
  double get radius => size.dx;

  /// Returns the bounding rectangle of the drawing.
  Rect get boundingRect {
    switch (type) {
      case DrawingType.circle:
        return Rect.fromCircle(center: origin, radius: size.dx);
      case DrawingType.rectangle:
        return Rect.fromLTWH(origin.dx, origin.dy, size.dx, size.dy);
      case DrawingType.freehand:
        if (points.isEmpty) return Rect.zero;
        double minX = points.first.dx, maxX = points.first.dx;
        double minY = points.first.dy, maxY = points.first.dy;
        for (final p in points) {
          minX = min(minX, p.dx);
          maxX = max(maxX, p.dx);
          minY = min(minY, p.dy);
          maxY = max(maxY, p.dy);
        }
        return Rect.fromLTRB(minX, minY, maxX, maxY);
    }
  }
}
