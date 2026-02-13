import 'dart:ui';

/// Enum for arrow colors.
enum ArrowColor {
  red,
  yellow,
  white,
}

/// Data model for arrows on the tactical board.
/// Uses 4 points for curved arrows (cubic Bezier curve):
/// - startPoint: where the arrow begins
/// - controlPoint1: first curve control point
/// - controlPoint2: second curve control point
/// - endPoint: where the arrow ends
class TacticalArrow {
  final String id;
  Offset startPoint;
  Offset controlPoint1;
  Offset controlPoint2;
  Offset endPoint;
  bool hasStartArrowhead;
  bool hasEndArrowhead;
  bool isDashed;
  ArrowColor color;

  TacticalArrow({
    required this.id,
    required this.startPoint,
    required this.endPoint,
    Offset? controlPoint1,
    Offset? controlPoint2,
    this.hasStartArrowhead = false,
    this.hasEndArrowhead = true,
    this.isDashed = false,
    this.color = ArrowColor.white,
  }) : controlPoint1 = controlPoint1 ?? _defaultControlPoint1(startPoint, endPoint),
       controlPoint2 = controlPoint2 ?? _defaultControlPoint2(startPoint, endPoint);

  /// Default control point 1: 1/3 of the way from start to end
  static Offset _defaultControlPoint1(Offset start, Offset end) {
    return Offset(
      start.dx + (end.dx - start.dx) / 3,
      start.dy + (end.dy - start.dy) / 3,
    );
  }

  /// Default control point 2: 2/3 of the way from start to end
  static Offset _defaultControlPoint2(Offset start, Offset end) {
    return Offset(
      start.dx + (end.dx - start.dx) * 2 / 3,
      start.dy + (end.dy - start.dy) * 2 / 3,
    );
  }

  /// Creates a copy of this arrow with optional new values.
  TacticalArrow copyWith({
    String? id,
    Offset? startPoint,
    Offset? controlPoint1,
    Offset? controlPoint2,
    Offset? endPoint,
    bool? hasStartArrowhead,
    bool? hasEndArrowhead,
    bool? isDashed,
    ArrowColor? color,
  }) {
    return TacticalArrow(
      id: id ?? this.id,
      startPoint: startPoint ?? this.startPoint,
      controlPoint1: controlPoint1 ?? this.controlPoint1,
      controlPoint2: controlPoint2 ?? this.controlPoint2,
      endPoint: endPoint ?? this.endPoint,
      hasStartArrowhead: hasStartArrowhead ?? this.hasStartArrowhead,
      hasEndArrowhead: hasEndArrowhead ?? this.hasEndArrowhead,
      isDashed: isDashed ?? this.isDashed,
      color: color ?? this.color,
    );
  }
}
