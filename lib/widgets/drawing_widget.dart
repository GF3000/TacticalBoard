import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math';
import '../models/tactical_drawing.dart';
import '../models/tactical_arrow.dart';
import 'drawing_painter.dart';

/// Widget that displays a drawing and handles interactions.
class DrawingWidget extends StatefulWidget {
  final TacticalDrawing drawing;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final ValueChanged<TacticalDrawing> onUpdate;

  const DrawingWidget({
    super.key,
    required this.drawing,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<DrawingWidget> createState() => _DrawingWidgetState();
}

class _DrawingWidgetState extends State<DrawingWidget> {
  _DrawingDragTarget? _dragTarget;

  late Offset _origin;
  late Offset _size;
  late List<Offset> _points;

  @override
  void initState() {
    super.initState();
    _initFromDrawing();
  }

  void _initFromDrawing() {
    _origin = widget.drawing.origin;
    _size = widget.drawing.size;
    _points = List.from(widget.drawing.points);
  }

  @override
  void didUpdateWidget(DrawingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drawing.id != widget.drawing.id) {
      _initFromDrawing();
    } else if (_dragTarget == null) {
      _initFromDrawing();
    }
  }

  /// Checks if a position is within the drawing's interactive area.
  bool _isHit(Offset position) {
    const hitThreshold = 15.0;

    switch (widget.drawing.type) {
      case DrawingType.circle:
        final distance = (position - _origin).distance;
        final radius = _size.dx;
        // Hit if inside the circle (including filled area) or near the edge
        return distance <= radius + hitThreshold;

      case DrawingType.rectangle:
        final rect = Rect.fromLTWH(_origin.dx, _origin.dy, _size.dx, _size.dy);
        final expandedRect = rect.inflate(hitThreshold);
        // Hit if inside the rectangle (including filled area)
        return expandedRect.contains(position);

      case DrawingType.freehand:
        return _isNearPath(position, hitThreshold);
    }
  }

  bool _isNearPath(Offset position, double threshold) {
    if (_points.length < 2) return false;

    for (int i = 0; i < _points.length - 1; i++) {
      if (_distanceToSegment(position, _points[i], _points[i + 1]) < threshold) {
        return true;
      }
    }
    return false;
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) return (point - start).distance;

    final t = max(0, min(1, ((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) / lengthSquared));
    final projection = Offset(start.dx + t * dx, start.dy + t * dy);

    return (point - projection).distance;
  }

  _DrawingDragTarget? _determineDragTarget(Offset position) {
    const handleRadius = 20.0;

    if (widget.isSelected) {
      switch (widget.drawing.type) {
        case DrawingType.circle:
          // Check cardinal point handles
          final radius = _size.dx;
          if ((position - (_origin + Offset(radius, 0))).distance < handleRadius) {
            return _DrawingDragTarget.resizeRight;
          }
          if ((position - (_origin + Offset(-radius, 0))).distance < handleRadius) {
            return _DrawingDragTarget.resizeLeft;
          }
          if ((position - (_origin + Offset(0, radius))).distance < handleRadius) {
            return _DrawingDragTarget.resizeBottom;
          }
          if ((position - (_origin + Offset(0, -radius))).distance < handleRadius) {
            return _DrawingDragTarget.resizeTop;
          }
          break;

        case DrawingType.rectangle:
          // Check corner handles
          if ((position - _origin).distance < handleRadius) {
            return _DrawingDragTarget.resizeTopLeft;
          }
          if ((position - (_origin + Offset(_size.dx, 0))).distance < handleRadius) {
            return _DrawingDragTarget.resizeTopRight;
          }
          if ((position - (_origin + Offset(0, _size.dy))).distance < handleRadius) {
            return _DrawingDragTarget.resizeBottomLeft;
          }
          if ((position - (_origin + _size)).distance < handleRadius) {
            return _DrawingDragTarget.resizeBottomRight;
          }
          break;

        case DrawingType.freehand:
          // Freehand doesn't have resize handles
          break;
      }
    }

    // Check if near the shape for whole-shape drag
    if (_isHit(position)) {
      return _DrawingDragTarget.whole;
    }

    return null;
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DrawingEditSheet(
        drawing: widget.drawing.copyWith(
          origin: _origin,
          size: _size,
          points: _points,
        ),
        onDelete: () {
          Navigator.pop(context);
          widget.onDelete();
        },
        onUpdate: (updated) {
          Navigator.pop(context);
          widget.onUpdate(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rect = widget.drawing.boundingRect;
    const padding = 40.0;

    final offset = Offset(rect.left - padding, rect.top - padding);

    // Adjust drawing properties relative to widget position
    final adjustedOrigin = _origin - offset;
    final adjustedPoints = _points.map((p) => p - offset).toList();

    return Positioned(
      left: rect.left - padding,
      top: rect.top - padding,
      child: _DrawingHitTestWidget(
        hitTest: (localPos) => _isHit(localPos + offset),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSelect,
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
                case _DrawingDragTarget.whole:
                  _origin = _origin + details.delta;
                  _points = _points.map((p) => p + details.delta).toList();
                  break;

                // Circle resizing
                case _DrawingDragTarget.resizeRight:
                case _DrawingDragTarget.resizeLeft:
                case _DrawingDragTarget.resizeTop:
                case _DrawingDragTarget.resizeBottom:
                  if (widget.drawing.type == DrawingType.circle) {
                    final currentRadius = _size.dx;
                    double delta;
                    if (_dragTarget == _DrawingDragTarget.resizeRight) {
                      delta = details.delta.dx;
                    } else if (_dragTarget == _DrawingDragTarget.resizeLeft) {
                      delta = -details.delta.dx;
                    } else if (_dragTarget == _DrawingDragTarget.resizeBottom) {
                      delta = details.delta.dy;
                    } else {
                      delta = -details.delta.dy;
                    }
                    final newRadius = max(10.0, currentRadius + delta);
                    _size = Offset(newRadius, newRadius);
                  }
                  break;

                // Rectangle resizing
                case _DrawingDragTarget.resizeTopLeft:
                  _origin = _origin + details.delta;
                  _size = _size - details.delta;
                  break;
                case _DrawingDragTarget.resizeTopRight:
                  _origin = Offset(_origin.dx, _origin.dy + details.delta.dy);
                  _size = Offset(_size.dx + details.delta.dx, _size.dy - details.delta.dy);
                  break;
                case _DrawingDragTarget.resizeBottomLeft:
                  _origin = Offset(_origin.dx + details.delta.dx, _origin.dy);
                  _size = Offset(_size.dx - details.delta.dx, _size.dy + details.delta.dy);
                  break;
                case _DrawingDragTarget.resizeBottomRight:
                  _size = _size + details.delta;
                  break;

                case null:
                  break;
              }
            });
          },
          onPanEnd: (details) {
            if (_dragTarget != null) {
              widget.onUpdate(widget.drawing.copyWith(
                origin: _origin,
                size: _size,
                points: _points,
              ));
            }
            _dragTarget = null;
          },
          onLongPress: () => _showEditDialog(context),
          onDoubleTap: widget.onDelete,
          child: SizedBox(
            width: rect.width + padding * 2,
            height: rect.height + padding * 2,
            child: CustomPaint(
              painter: DrawingPainter(
                type: widget.drawing.type,
                origin: adjustedOrigin,
                size: _size,
                points: adjustedPoints,
                drawingColor: widget.drawing.color,
                isSelected: widget.isSelected,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _DrawingDragTarget {
  whole,
  resizeTopLeft,
  resizeTopRight,
  resizeBottomLeft,
  resizeBottomRight,
  resizeTop,
  resizeBottom,
  resizeLeft,
  resizeRight,
}

/// Custom widget for hit testing based on a callback.
class _DrawingHitTestWidget extends SingleChildRenderObjectWidget {
  final bool Function(Offset localPosition) hitTest;

  const _DrawingHitTestWidget({
    required this.hitTest,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _DrawingHitTestRenderBox(hitTest);
  }

  @override
  void updateRenderObject(BuildContext context, _DrawingHitTestRenderBox renderObject) {
    renderObject.hitTestCallback = hitTest;
  }
}

class _DrawingHitTestRenderBox extends RenderProxyBox {
  bool Function(Offset localPosition) hitTestCallback;

  _DrawingHitTestRenderBox(this.hitTestCallback);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!hitTestCallback(position)) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}

/// Bottom sheet for editing drawing properties.
class DrawingEditSheet extends StatefulWidget {
  final TacticalDrawing drawing;
  final VoidCallback onDelete;
  final ValueChanged<TacticalDrawing> onUpdate;

  const DrawingEditSheet({
    super.key,
    required this.drawing,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<DrawingEditSheet> createState() => _DrawingEditSheetState();
}

class _DrawingEditSheetState extends State<DrawingEditSheet> {
  late ArrowColor _color;

  @override
  void initState() {
    super.initState();
    _color = widget.drawing.color;
  }

  void _save() {
    widget.onUpdate(widget.drawing.copyWith(color: _color));
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
              'Edit Drawing',
              style: TextStyle(fontSize: compact ? 14 : 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: compact ? 8 : 16),
            if (compact)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _colorChip(ArrowColor.white, Colors.white),
                  _colorChip(ArrowColor.red, Colors.red),
                  _colorChip(ArrowColor.yellow, Colors.yellow),
                ],
              )
            else
              Row(
                children: [
                  const Text('Color: '),
                  const SizedBox(width: 8),
                  _colorChip(ArrowColor.white, Colors.white),
                  const SizedBox(width: 8),
                  _colorChip(ArrowColor.red, Colors.red),
                  const SizedBox(width: 8),
                  _colorChip(ArrowColor.yellow, Colors.yellow),
                ],
              ),
            SizedBox(height: compact ? 12 : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete, color: Colors.red, size: compact ? 18 : 24),
                  label: Text('Delete', style: TextStyle(color: Colors.red, fontSize: compact ? 12 : 14)),
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

  Widget _colorChip(ArrowColor colorValue, Color displayColor) {
    final isSelected = _color == colorValue;
    return GestureDetector(
      onTap: () => setState(() => _color = colorValue),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
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
        ),
      ),
    );
  }
}
