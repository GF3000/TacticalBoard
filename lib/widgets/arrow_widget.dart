import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math';
import '../models/tactical_arrow.dart';
import 'arrow_painter.dart';

/// Widget that displays a curved arrow and handles interactions including dragging all 4 points.
class ArrowWidget extends StatefulWidget {
  final TacticalArrow arrow;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final ValueChanged<TacticalArrow> onUpdate;

  const ArrowWidget({
    super.key,
    required this.arrow,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<ArrowWidget> createState() => _ArrowWidgetState();
}

class _ArrowWidgetState extends State<ArrowWidget> {
  _DragTarget? _dragTarget;

  late Offset _startPoint;
  late Offset _controlPoint1;
  late Offset _controlPoint2;
  late Offset _endPoint;

  @override
  void initState() {
    super.initState();
    _initPoints();
  }

  void _initPoints() {
    _startPoint = widget.arrow.startPoint;
    _controlPoint1 = widget.arrow.controlPoint1;
    _controlPoint2 = widget.arrow.controlPoint2;
    _endPoint = widget.arrow.endPoint;
  }

  @override
  void didUpdateWidget(ArrowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.arrow.id != widget.arrow.id) {
      _initPoints();
    } else if (_dragTarget == null) {
      // Only update from parent if not currently dragging
      _initPoints();
    }
  }

  void _showEditDialog(BuildContext context) {
    // Selection is managed by parent
    showModalBottomSheet(
      context: context,
      builder: (context) => ArrowEditSheet(
        arrow: widget.arrow.copyWith(
          startPoint: _startPoint,
          controlPoint1: _controlPoint1,
          controlPoint2: _controlPoint2,
          endPoint: _endPoint,
        ),
        onDelete: () {
          Navigator.pop(context);
          widget.onDelete();
        },
        onUpdate: (updatedArrow) {
          Navigator.pop(context);
          widget.onUpdate(updatedArrow);
        },
      ),
    );
  }

  /// Calculates a point on the cubic bezier curve at parameter t (0-1).
  Offset _bezierPoint(double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    return Offset(
      uuu * _startPoint.dx + 3 * uu * t * _controlPoint1.dx + 3 * u * tt * _controlPoint2.dx + ttt * _endPoint.dx,
      uuu * _startPoint.dy + 3 * uu * t * _controlPoint1.dy + 3 * u * tt * _controlPoint2.dy + ttt * _endPoint.dy,
    );
  }

  /// Checks if a position is near the bezier curve.
  bool _isNearCurve(Offset position, double threshold) {
    // Sample points along the curve and check distance
    const samples = 20;
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final curvePoint = _bezierPoint(t);
      if ((position - curvePoint).distance < threshold) {
        return true;
      }
    }
    return false;
  }

  /// Checks if the position is within the arrow's interactive area.
  bool _isHit(Offset position) {
    const hitRadius = 25.0;
    const controlPointRadius = 30.0;

    // Always check endpoints
    if ((position - _startPoint).distance < hitRadius) return true;
    if ((position - _endPoint).distance < hitRadius) return true;

    // Check control points only when selected
    if (widget.isSelected) {
      if ((position - _controlPoint1).distance < controlPointRadius) return true;
      if ((position - _controlPoint2).distance < controlPointRadius) return true;
    }

    // Check if near the curve itself
    return _isNearCurve(position, hitRadius);
  }

  _DragTarget? _determineDragTarget(Offset position) {
    const hitRadius = 30.0;

    // Check control points first when selected (they're smaller and need priority)
    if (widget.isSelected) {
      if ((position - _controlPoint1).distance < hitRadius) {
        return _DragTarget.control1;
      }
      if ((position - _controlPoint2).distance < hitRadius) {
        return _DragTarget.control2;
      }
    }

    // Then check endpoints
    if ((position - _startPoint).distance < hitRadius) {
      return _DragTarget.start;
    }
    if ((position - _endPoint).distance < hitRadius) {
      return _DragTarget.end;
    }

    // Check if near the curve for whole arrow drag
    if (_isNearCurve(position, hitRadius)) {
      return _DragTarget.whole;
    }

    // Not a valid hit
    return null;
  }

  void _handleTap() {
    widget.onSelect();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate bounding box including all 4 points
    const padding = 40.0;
    final allPoints = [_startPoint, _controlPoint1, _controlPoint2, _endPoint];

    final minX = allPoints.map((p) => p.dx).reduce(min);
    final minY = allPoints.map((p) => p.dy).reduce(min);
    final maxX = allPoints.map((p) => p.dx).reduce(max);
    final maxY = allPoints.map((p) => p.dy).reduce(max);

    final width = (maxX - minX) + padding * 2;
    final height = (maxY - minY) + padding * 2;

    // Adjust all points relative to the widget's position
    final offset = Offset(minX - padding, minY - padding);
    final adjustedStart = _startPoint - offset;
    final adjustedCP1 = _controlPoint1 - offset;
    final adjustedCP2 = _controlPoint2 - offset;
    final adjustedEnd = _endPoint - offset;

    return Positioned(
      left: minX - padding,
      top: minY - padding,
      child: _ArrowHitTestWidget(
        hitTest: (localPos) => _isHit(localPos + offset),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          onPanStart: (details) {
            final globalPos = details.localPosition + offset;
            _dragTarget = _determineDragTarget(globalPos);
            if (_dragTarget != null) {
              widget.onSelect();
            }
          },
          onPanUpdate: (details) {
            if (_dragTarget == null) return;
            setState(() {
              switch (_dragTarget) {
                case _DragTarget.start:
                  _startPoint = _startPoint + details.delta;
                  break;
                case _DragTarget.control1:
                  _controlPoint1 = _controlPoint1 + details.delta;
                  break;
                case _DragTarget.control2:
                  _controlPoint2 = _controlPoint2 + details.delta;
                  break;
                case _DragTarget.end:
                  _endPoint = _endPoint + details.delta;
                  break;
                case _DragTarget.whole:
                  _startPoint = _startPoint + details.delta;
                  _controlPoint1 = _controlPoint1 + details.delta;
                  _controlPoint2 = _controlPoint2 + details.delta;
                  _endPoint = _endPoint + details.delta;
                  break;
                case null:
                  break;
              }
            });
          },
          onPanEnd: (details) {
            if (_dragTarget != null) {
              widget.onUpdate(widget.arrow.copyWith(
                startPoint: _startPoint,
                controlPoint1: _controlPoint1,
                controlPoint2: _controlPoint2,
                endPoint: _endPoint,
              ));
            }
            _dragTarget = null;
          },
          onLongPress: () => _showEditDialog(context),
          onDoubleTap: widget.onDelete,
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: ArrowPainter(
                start: adjustedStart,
                controlPoint1: adjustedCP1,
                controlPoint2: adjustedCP2,
                end: adjustedEnd,
                hasStartArrowhead: widget.arrow.hasStartArrowhead,
                hasEndArrowhead: widget.arrow.hasEndArrowhead,
                isDashed: widget.arrow.isDashed,
                arrowColor: widget.arrow.color,
                showControlPoints: widget.isSelected,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _DragTarget { start, control1, control2, end, whole }

/// Custom widget that performs hit testing based on a callback.
class _ArrowHitTestWidget extends SingleChildRenderObjectWidget {
  final bool Function(Offset localPosition) hitTest;

  const _ArrowHitTestWidget({
    required this.hitTest,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _ArrowHitTestRenderBox(hitTest);
  }

  @override
  void updateRenderObject(BuildContext context, _ArrowHitTestRenderBox renderObject) {
    renderObject.hitTestCallback = hitTest;
  }
}

class _ArrowHitTestRenderBox extends RenderProxyBox {
  bool Function(Offset localPosition) hitTestCallback;

  _ArrowHitTestRenderBox(this.hitTestCallback);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!hitTestCallback(position)) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}

/// Bottom sheet for editing arrow properties.
class ArrowEditSheet extends StatefulWidget {
  final TacticalArrow arrow;
  final VoidCallback onDelete;
  final ValueChanged<TacticalArrow> onUpdate;

  const ArrowEditSheet({
    super.key,
    required this.arrow,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<ArrowEditSheet> createState() => _ArrowEditSheetState();
}

class _ArrowEditSheetState extends State<ArrowEditSheet> {
  late bool _hasStartArrowhead;
  late bool _hasEndArrowhead;
  late bool _isDashed;
  late ArrowColor _color;

  @override
  void initState() {
    super.initState();
    _hasStartArrowhead = widget.arrow.hasStartArrowhead;
    _hasEndArrowhead = widget.arrow.hasEndArrowhead;
    _isDashed = widget.arrow.isDashed;
    _color = widget.arrow.color;
  }

  void _save() {
    widget.onUpdate(widget.arrow.copyWith(
      hasStartArrowhead: _hasStartArrowhead,
      hasEndArrowhead: _hasEndArrowhead,
      isDashed: _isDashed,
      color: _color,
    ));
  }

  void _resetCurve() {
    // Reset control points to make arrow straight
    final start = widget.arrow.startPoint;
    final end = widget.arrow.endPoint;
    widget.onUpdate(widget.arrow.copyWith(
      controlPoint1: Offset(
        start.dx + (end.dx - start.dx) / 3,
        start.dy + (end.dy - start.dy) / 3,
      ),
      controlPoint2: Offset(
        start.dx + (end.dx - start.dx) * 2 / 3,
        start.dy + (end.dy - start.dy) * 2 / 3,
      ),
      hasStartArrowhead: _hasStartArrowhead,
      hasEndArrowhead: _hasEndArrowhead,
      isDashed: _isDashed,
      color: _color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final isPhone = MediaQuery.of(context).size.shortestSide < 600;
    final compact = isLandscape && isPhone;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 8.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Arrow',
              style: TextStyle(fontSize: compact ? 14 : 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: compact ? 8 : 16),
            // Arrowheads and Line style in one row for compact mode
            if (compact)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Start ◄'),
                    selected: _hasStartArrowhead,
                    onSelected: (value) => setState(() => _hasStartArrowhead = value),
                    visualDensity: VisualDensity.compact,
                  ),
                  FilterChip(
                    label: const Text('End ►'),
                    selected: _hasEndArrowhead,
                    onSelected: (value) => setState(() => _hasEndArrowhead = value),
                    visualDensity: VisualDensity.compact,
                  ),
                  ChoiceChip(
                    label: const Text('Solid'),
                    selected: !_isDashed,
                    onSelected: (value) => setState(() => _isDashed = false),
                    visualDensity: VisualDensity.compact,
                  ),
                  ChoiceChip(
                    label: const Text('Dashed'),
                    selected: _isDashed,
                    onSelected: (value) => setState(() => _isDashed = true),
                    visualDensity: VisualDensity.compact,
                  ),
                  _colorChip(ArrowColor.white, Colors.white, 'White'),
                  _colorChip(ArrowColor.red, Colors.red, 'Red'),
                  _colorChip(ArrowColor.yellow, Colors.yellow, 'Yellow'),
                ],
              )
            else ...[
              // Arrowheads
              Row(
                children: [
                  const Text('Arrowheads: '),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Start'),
                    selected: _hasStartArrowhead,
                    onSelected: (value) => setState(() => _hasStartArrowhead = value),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('End'),
                    selected: _hasEndArrowhead,
                    onSelected: (value) => setState(() => _hasEndArrowhead = value),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Line style
              Row(
                children: [
                  const Text('Line Style: '),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Solid'),
                    selected: !_isDashed,
                    onSelected: (value) => setState(() => _isDashed = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Dashed'),
                    selected: _isDashed,
                    onSelected: (value) => setState(() => _isDashed = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Color
              Row(
                children: [
                  const Text('Color: '),
                  const SizedBox(width: 8),
                  _colorChip(ArrowColor.white, Colors.white, 'White'),
                  const SizedBox(width: 8),
                  _colorChip(ArrowColor.red, Colors.red, 'Red'),
                  const SizedBox(width: 8),
                  _colorChip(ArrowColor.yellow, Colors.yellow, 'Yellow'),
                ],
              ),
            ],
            SizedBox(height: compact ? 12 : 20),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete, color: Colors.red, size: compact ? 18 : 24),
                  label: Text('Delete', style: TextStyle(color: Colors.red, fontSize: compact ? 12 : 14)),
                ),
                TextButton.icon(
                  onPressed: _resetCurve,
                  icon: Icon(Icons.straighten, size: compact ? 18 : 24),
                  label: Text('Straighten', style: TextStyle(fontSize: compact ? 12 : 14)),
                ),
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: Icon(Icons.check, size: compact ? 18 : 24),
                  label: Text('Save', style: TextStyle(fontSize: compact ? 12 : 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorChip(ArrowColor colorValue, Color displayColor, String label) {
    final isSelected = _color == colorValue;
    return GestureDetector(
      onTap: () => setState(() => _color = colorValue),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
