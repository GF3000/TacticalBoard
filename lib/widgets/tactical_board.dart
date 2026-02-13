import 'package:flutter/material.dart';
import 'dart:math';
import '../models/tactical_item.dart';
import '../models/tactical_arrow.dart';
import '../models/tactical_drawing.dart';
import '../utils/constants.dart';
import 'arrow_painter.dart';
import 'arrow_widget.dart';
import 'ball_widget.dart';
import 'cone_widget.dart';
import 'control_bar/control_bar.dart';
import 'control_bar/drawing_toolbar.dart';
import 'draggable_item.dart';
import 'drawing_painter.dart';
import 'drawing_widget.dart';
import 'player_token.dart';
import 'text_widget.dart';

/// Main tactical board widget that contains the court and all items.
class TacticalBoard extends StatefulWidget {
  const TacticalBoard({super.key});

  @override
  State<TacticalBoard> createState() => _TacticalBoardState();
}

class _TacticalBoardState extends State<TacticalBoard> {
  /// List of all items currently on the board.
  final List<TacticalItem> _items = [];

  /// List of all arrows on the board.
  final List<TacticalArrow> _arrows = [];

  /// Currently selected arrow ID (for showing control points).
  String? _selectedArrowId;

  /// Counter for auto-incrementing red player numbers.
  int _redPlayerCount = 0;

  /// Counter for auto-incrementing white player numbers.
  int _whitePlayerCount = 0;

  /// Key for the board stack to get its position.
  final GlobalKey _boardKey = GlobalKey();

  /// Current court dimensions (updated by LayoutBuilder).
  double _courtWidth = 0;
  double _courtHeight = 0;
  double _courtOffsetX = 0;

  /// Whether we're in arrow drawing mode.
  bool _isDrawingArrow = false;

  /// Start point of the arrow being drawn.
  Offset? _arrowStartPoint;

  /// Current end point while drawing.
  Offset? _arrowCurrentEnd;

  /// Counter for generating unique IDs.
  int _idCounter = 0;

  /// ID of the newly added text item that needs auto-edit.
  String? _autoEditTextId;

  // ========== Drawing State ==========

  /// List of all drawings on the board.
  final List<TacticalDrawing> _drawings = [];

  /// Currently selected drawing ID.
  String? _selectedDrawingId;

  /// Whether we're in drawing mode.
  bool _isDrawingMode = false;

  /// Active drawing type.
  DrawingType _activeDrawingType = DrawingType.freehand;

  /// Active drawing color.
  ArrowColor _activeDrawingColor = ArrowColor.white;

  /// Start point of the shape being drawn.
  Offset? _drawingStartPoint;

  /// Current point while drawing.
  Offset? _drawingCurrentPoint;

  /// Points for freehand drawing.
  List<Offset> _freehandPoints = [];

  /// Undo stack - stores drawing IDs in creation order.
  final List<String> _undoStack = [];

  /// Maximum undo history.
  static const int _maxUndoHistory = 20;

  /// Generates a unique ID for new items.
  String _generateId() => '${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

  /// Converts global position to local position relative to the board.
  Offset? _globalToLocal(Offset globalPosition) {
    final RenderBox? boardBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null) return null;
    return boardBox.globalToLocal(globalPosition);
  }

  /// Adds a new item at the specified position.
  void _addItemAtPosition(ItemType type, Offset globalPosition) {
    final localPosition = _globalToLocal(globalPosition);
    if (localPosition == null) return;

    // Center the item on the drop position
    double offsetX = kPlayerRadius;
    double offsetY = kPlayerRadius;
    if (type == ItemType.cone) {
      offsetX = kConeSize / 2;
      offsetY = kConeSize / 2;
    } else if (type == ItemType.ball) {
      offsetX = kBallSize / 2;
      offsetY = kBallSize / 2;
    } else if (type == ItemType.text) {
      offsetX = 20;
      offsetY = 12;
    }

    final adjustedPosition = Offset(
      localPosition.dx - offsetX,
      localPosition.dy - offsetY,
    );

    setState(() {
      String label = '';
      if (type == ItemType.redPlayer) {
        _redPlayerCount++;
        label = _redPlayerCount.toString();
      } else if (type == ItemType.whitePlayer) {
        _whitePlayerCount++;
        label = _whitePlayerCount.toString();
      } else if (type == ItemType.text) {
        label = '';
      }

      final newId = _generateId();
      _items.add(TacticalItem(
        id: newId,
        type: type,
        position: adjustedPosition,
        label: label,
      ));

      // Auto-edit for new text items
      if (type == ItemType.text) {
        _autoEditTextId = newId;
      }
    });
  }

  /// Updates the position of an item.
  void _updateItemPosition(String id, Offset newPosition) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index].position = newPosition;
      }
    });
  }

  /// Deletes an item from the board.
  void _deleteItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
  }

  /// Updates the label of an item.
  void _updateItemLabel(String id, String newLabel) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index].label = newLabel;
      }
    });
  }

  /// Updates the text size of an item.
  void _updateItemTextSize(String id, TextSize newSize) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index].textSize = newSize;
      }
    });
  }

  /// Shows confirmation dialog (if board not empty) and sets up 6vs6 formation.
  void _setup6vs6(double courtWidth, double courtHeight, double offsetX) {
    // If board is empty, just do the setup directly
    if (_items.isEmpty && _arrows.isEmpty && _drawings.isEmpty) {
      _doSetup6vs6(courtWidth, courtHeight, offsetX);
      return;
    }

    // Show confirmation dialog if board has items
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup 6v6'),
        content: const Text('This will clear the board and place 12 players in a 6v6 formation. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _doSetup6vs6(courtWidth, courtHeight, offsetX);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  /// Actually performs the 6vs6 setup.
  /// Positions are defined in court coordinates (2040x1592) and scaled to rendered size.
  void _doSetup6vs6(double courtWidth, double courtHeight, double offsetX) {
    // Original court dimensions
    const originalWidth = 2040.0;
    const originalHeight = 1592.0;

    // Scale factors to convert court coordinates to rendered coordinates
    final scaleX = courtWidth / originalWidth;
    final scaleY = courtHeight / originalHeight;

    // Helper to convert court coordinates to rendered coordinates
    // Adds offsetX to account for centered court position
    Offset toRendered(double x, double y) => Offset(x * scaleX + offsetX, y * scaleY);

    setState(() {
      // Clear existing items
      _items.clear();
      _arrows.clear();
      _drawings.clear();
      _undoStack.clear();
      _redPlayerCount = 0;
      _whitePlayerCount = 0;
      _selectedArrowId = null;
      _selectedDrawingId = null;

      // Attack positions (red) - defined in court coordinates (2040x1592)
      final attackPositions = [
        toRendered(150, 1180),    // 1: Left wing
        toRendered(200, 280),     // 2: Left back
        toRendered(1000, 130),    // 3: Center back (playmaker)
        toRendered(1800, 280),    // 4: Right back
        toRendered(1380, 690),    // 5: Pivot
        toRendered(1850, 1180),   // 6: Right Wing
      ];

      // Defense positions (white) - 6:0 formation in court coordinates
      final defensePositions = [
        toRendered(205, 1016),   // 1: Left defender
        toRendered(510, 740),    // 2: Left-center defender
        toRendered(850, 640),    // 3: Center-left defender
        toRendered(1170, 640),   // 4: Center-right defender
        toRendered(1500, 740),   // 5: Right-center defender
        toRendered(1800, 1016),  // 6: Right defender
      ];

      // Add red (attack) players
      for (final pos in attackPositions) {
        _redPlayerCount++;
        _items.add(TacticalItem(
          id: _generateId(),
          type: ItemType.redPlayer,
          position: pos,
          label: _redPlayerCount.toString(),
        ));
      }

      // Add white (defense) players
      for (final pos in defensePositions) {
        _whitePlayerCount++;
        _items.add(TacticalItem(
          id: _generateId(),
          type: ItemType.whitePlayer,
          position: pos,
          label: _whitePlayerCount.toString(),
        ));
      }
    });
  }

  /// Clears all items, arrows, and drawings from the board.
  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All'),
        content: const Text('Are you sure you want to delete all items, arrows, and drawings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _items.clear();
                _arrows.clear();
                _drawings.clear();
                _undoStack.clear();
                _redPlayerCount = 0;
                _whitePlayerCount = 0;
                _selectedArrowId = null;
                _selectedDrawingId = null;
              });
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Enters arrow drawing mode.
  void _startArrowMode() {
    setState(() {
      _isDrawingArrow = true;
      _arrowStartPoint = null;
      _arrowCurrentEnd = null;
      // Cancel drawing mode if active
      _isDrawingMode = false;
      _drawingStartPoint = null;
      _drawingCurrentPoint = null;
      _freehandPoints = [];
    });
  }

  /// Cancels arrow drawing mode.
  void _cancelArrowMode() {
    setState(() {
      _isDrawingArrow = false;
      _arrowStartPoint = null;
      _arrowCurrentEnd = null;
    });
  }

  /// Handles tap on the board during arrow drawing.
  void _handleArrowTap(Offset localPosition) {
    if (!_isDrawingArrow) return;

    if (_arrowStartPoint == null) {
      // Set start point
      setState(() {
        _arrowStartPoint = localPosition;
      });
    } else {
      // Complete the arrow
      setState(() {
        _arrows.add(TacticalArrow(
          id: _generateId(),
          startPoint: _arrowStartPoint!,
          endPoint: localPosition,
        ));
        _isDrawingArrow = false;
        _arrowStartPoint = null;
        _arrowCurrentEnd = null;
      });
    }
  }

  /// Handles drag during arrow drawing to show preview.
  void _handleArrowDrag(Offset localPosition) {
    if (_isDrawingArrow && _arrowStartPoint != null) {
      setState(() {
        _arrowCurrentEnd = localPosition;
      });
    }
  }

  /// Deletes an arrow.
  void _deleteArrow(String id) {
    setState(() {
      _arrows.removeWhere((arrow) => arrow.id == id);
    });
  }

  /// Updates an arrow.
  void _updateArrow(TacticalArrow updatedArrow) {
    setState(() {
      final index = _arrows.indexWhere((a) => a.id == updatedArrow.id);
      if (index != -1) {
        _arrows[index] = updatedArrow;
      }
    });
  }

  /// Selects an arrow (or deselects if null).
  void _selectArrow(String? id) {
    setState(() {
      _selectedArrowId = id;
    });
  }

  /// Deselects any selected arrow.
  void _deselectArrow() {
    if (_selectedArrowId != null) {
      setState(() {
        _selectedArrowId = null;
      });
    }
  }

  // ========== Drawing Mode Methods ==========

  /// Enters drawing mode.
  void _startDrawingMode() {
    setState(() {
      _isDrawingMode = true;
      _isDrawingArrow = false;
      _drawingStartPoint = null;
      _drawingCurrentPoint = null;
      _freehandPoints = [];
    });
  }

  /// Cancels drawing mode.
  void _cancelDrawingMode() {
    setState(() {
      _isDrawingMode = false;
      _drawingStartPoint = null;
      _drawingCurrentPoint = null;
      _freehandPoints = [];
    });
  }

  /// Changes the active drawing type.
  void _setDrawingType(DrawingType type) {
    setState(() {
      _activeDrawingType = type;
    });
  }

  /// Changes the active drawing color.
  void _setDrawingColor(ArrowColor color) {
    setState(() {
      _activeDrawingColor = color;
    });
  }

  /// Handles pan start during drawing.
  void _handleDrawingStart(Offset localPosition) {
    if (!_isDrawingMode) return;

    setState(() {
      _drawingStartPoint = localPosition;
      if (_activeDrawingType == DrawingType.freehand) {
        _freehandPoints = [localPosition];
      }
    });
  }

  /// Handles pan update during drawing (preview).
  void _handleDrawingUpdate(Offset localPosition) {
    if (!_isDrawingMode || _drawingStartPoint == null) return;

    setState(() {
      _drawingCurrentPoint = localPosition;
      if (_activeDrawingType == DrawingType.freehand) {
        _freehandPoints.add(localPosition);
      }
    });
  }

  /// Completes the drawing.
  void _handleDrawingEnd() {
    if (!_isDrawingMode || _drawingStartPoint == null) return;
    if (_drawingCurrentPoint == null && _activeDrawingType != DrawingType.freehand) return;

    final id = _generateId();
    TacticalDrawing? newDrawing;

    switch (_activeDrawingType) {
      case DrawingType.circle:
        // Start and current points define the diameter
        final center = (_drawingStartPoint! + _drawingCurrentPoint!) / 2;
        final radius = (_drawingCurrentPoint! - _drawingStartPoint!).distance / 2;
        if (radius > 10) {
          newDrawing = TacticalDrawing.circle(
            id: id,
            center: center,
            radius: radius,
            color: _activeDrawingColor,
          );
        }
        break;

      case DrawingType.rectangle:
        final size = _drawingCurrentPoint! - _drawingStartPoint!;
        if (size.dx.abs() > 10 && size.dy.abs() > 10) {
          newDrawing = TacticalDrawing.rectangle(
            id: id,
            topLeft: Offset(
              min(_drawingStartPoint!.dx, _drawingCurrentPoint!.dx),
              min(_drawingStartPoint!.dy, _drawingCurrentPoint!.dy),
            ),
            bottomRight: Offset(
              max(_drawingStartPoint!.dx, _drawingCurrentPoint!.dx),
              max(_drawingStartPoint!.dy, _drawingCurrentPoint!.dy),
            ),
            color: _activeDrawingColor,
          );
        }
        break;

      case DrawingType.freehand:
        if (_freehandPoints.length > 3) {
          newDrawing = TacticalDrawing.freehand(
            id: id,
            points: List.from(_freehandPoints),
            color: _activeDrawingColor,
          );
        }
        break;
    }

    setState(() {
      if (newDrawing != null) {
        _drawings.add(newDrawing);
        _addToUndoStack(newDrawing.id);
      }
      _drawingStartPoint = null;
      _drawingCurrentPoint = null;
      _freehandPoints = [];
    });
  }

  /// Adds a drawing ID to the undo stack.
  void _addToUndoStack(String id) {
    _undoStack.add(id);
    if (_undoStack.length > _maxUndoHistory) {
      _undoStack.removeAt(0);
    }
  }

  /// Undoes the last drawing.
  void _undoLastDrawing() {
    if (_undoStack.isEmpty) return;

    setState(() {
      final lastId = _undoStack.removeLast();
      _drawings.removeWhere((d) => d.id == lastId);
      if (_selectedDrawingId == lastId) {
        _selectedDrawingId = null;
      }
    });
  }

  /// Deletes a drawing.
  void _deleteDrawing(String id) {
    setState(() {
      _drawings.removeWhere((d) => d.id == id);
      _undoStack.remove(id);
      if (_selectedDrawingId == id) {
        _selectedDrawingId = null;
      }
    });
  }

  /// Updates a drawing.
  void _updateDrawing(TacticalDrawing updated) {
    setState(() {
      final index = _drawings.indexWhere((d) => d.id == updated.id);
      if (index != -1) {
        _drawings[index] = updated;
      }
    });
  }

  /// Selects a drawing.
  void _selectDrawing(String? id) {
    setState(() {
      _selectedDrawingId = id;
      _selectedArrowId = null;
    });
  }

  /// Updates a player's name.
  void _updateItemName(String id, String newName) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index].name = newName;
      }
    });
  }

  /// Builds the widget for a tactical item based on its type.
  Widget _buildItemWidget(TacticalItem item) {
    switch (item.type) {
      case ItemType.redPlayer:
        return PlayerToken(label: item.label, isRed: true, name: item.name);
      case ItemType.whitePlayer:
        return PlayerToken(label: item.label, isRed: false, name: item.name);
      case ItemType.cone:
        return const ConeWidget();
      case ItemType.ball:
        return const BallWidget();
      case ItemType.text:
        return TextWidget(text: item.label, textSize: item.textSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: Row(
        children: [
          // Control bar on the left with draggable sources
          ControlBar(
            nextRedNumber: _redPlayerCount + 1,
            nextWhiteNumber: _whitePlayerCount + 1,
            isArrowMode: _isDrawingArrow,
            isDrawingMode: _isDrawingMode,
            onArrowModePressed: _isDrawingArrow ? _cancelArrowMode : _startArrowMode,
            onDrawModePressed: _isDrawingMode ? _cancelDrawingMode : _startDrawingMode,
            onClearAll: _clearAll,
            onSetup6vs6: () => _setup6vs6(_courtWidth, _courtHeight, _courtOffsetX-15),
          ),
        // Main board area with DragTarget
        Expanded(
          child: Stack(
            children: [
              DragTarget<ItemType>(
            onAcceptWithDetails: (details) {
              if (!_isDrawingArrow) {
                _addItemAtPosition(details.data, details.offset);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                color: kBackgroundColor,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Court image aspect ratio (2040x1914)
                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight;

                    // Calculate court size to fit within constraints
                    double courtWidth = availableWidth;
                    double courtHeight = courtWidth / kCourtAspectRatio;

                    // If court is too tall, constrain by height
                    if (courtHeight > availableHeight) {
                      courtHeight = availableHeight;
                      courtWidth = courtHeight * kCourtAspectRatio;
                    }

                    // Store court dimensions for 6vs6 setup
                    _courtWidth = courtWidth;
                    _courtHeight = courtHeight;
                    _courtOffsetX = (availableWidth - courtWidth) / 2;

                  return GestureDetector(
                    onTapUp: (details) {
                      final localPos = _globalToLocal(details.globalPosition);
                      if (localPos != null) {
                        if (_isDrawingArrow) {
                          _handleArrowTap(localPos);
                        } else if (!_isDrawingMode) {
                          // Deselect any selected arrow/drawing when tapping on the board
                          _deselectArrow();
                          _selectDrawing(null);
                        }
                      }
                    },
                    onPanStart: (details) {
                      final localPos = _globalToLocal(details.globalPosition);
                      if (localPos != null && _isDrawingMode) {
                        _handleDrawingStart(localPos);
                      }
                    },
                    onPanUpdate: (details) {
                      final localPos = _globalToLocal(details.globalPosition);
                      if (localPos != null) {
                        if (_isDrawingArrow) {
                          _handleArrowDrag(localPos);
                        } else if (_isDrawingMode) {
                          _handleDrawingUpdate(localPos);
                        }
                      }
                    },
                    onPanEnd: (details) {
                      if (_isDrawingArrow && _arrowStartPoint != null && _arrowCurrentEnd != null) {
                        setState(() {
                          _arrows.add(TacticalArrow(
                            id: _generateId(),
                            startPoint: _arrowStartPoint!,
                            endPoint: _arrowCurrentEnd!,
                          ));
                          _isDrawingArrow = false;
                          _arrowStartPoint = null;
                          _arrowCurrentEnd = null;
                        });
                      } else if (_isDrawingMode) {
                        _handleDrawingEnd();
                      }
                    },
                    child: Stack(
                      key: _boardKey,
                      children: [
                        // Court background positioned at bottom center
                        Positioned(
                          left: (availableWidth - courtWidth) / 2,
                          bottom: 0,
                          width: courtWidth,
                          height: courtHeight,
                          child: Image.asset(
                            kCourtImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: kCourtFallbackColor,
                                child: const Center(
                                  child: Text(
                                    'Handball Court',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    // Arrow mode indicator
                    if (_isDrawingArrow)
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _arrowStartPoint == null
                                  ? 'Tap to set start point'
                                  : 'Tap or drag to set end point',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    // Visual feedback when dragging over the board
                    if (candidateData.isNotEmpty)
                      Positioned.fill(
                        child: Container(
                          color: Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                    // Arrows (rendered first so they appear behind items)
                    ..._arrows.map((arrow) => ArrowWidget(
                          key: ValueKey(arrow.id),
                          arrow: arrow,
                          isSelected: _selectedArrowId == arrow.id,
                          onSelect: () => _selectArrow(arrow.id),
                          onDelete: () => _deleteArrow(arrow.id),
                          onUpdate: _updateArrow,
                        )),
                    // Preview arrow while drawing
                    if (_isDrawingArrow && _arrowStartPoint != null && _arrowCurrentEnd != null)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ArrowPainter(
                            start: _arrowStartPoint!,
                            end: _arrowCurrentEnd!,
                            hasEndArrowhead: true,
                            arrowColor: ArrowColor.white,
                          ),
                        ),
                      ),
                    // Start point indicator for arrows
                    if (_isDrawingArrow && _arrowStartPoint != null)
                      Positioned(
                        left: _arrowStartPoint!.dx - 8,
                        top: _arrowStartPoint!.dy - 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                        ),
                      ),
                    // Drawings
                    ..._drawings.map((drawing) => DrawingWidget(
                          key: ValueKey(drawing.id),
                          drawing: drawing,
                          isSelected: _selectedDrawingId == drawing.id,
                          onSelect: () => _selectDrawing(drawing.id),
                          onDelete: () => _deleteDrawing(drawing.id),
                          onUpdate: _updateDrawing,
                        )),
                    // Drawing preview while creating
                    if (_isDrawingMode && _drawingStartPoint != null && (_drawingCurrentPoint != null || _freehandPoints.length > 1))
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DrawingPreviewPainter(
                            type: _activeDrawingType,
                            startPoint: _drawingStartPoint!,
                            currentPoint: _drawingCurrentPoint ?? _drawingStartPoint!,
                            freehandPoints: _freehandPoints,
                            drawingColor: _activeDrawingColor,
                          ),
                        ),
                      ),
                    // Drawing mode indicator
                    if (_isDrawingMode)
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Draw ${_activeDrawingType.name}: tap and drag',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                            // Draggable items
                            ..._items.map((item) => DraggableItem(
                                  key: ValueKey(item.id),
                                  position: item.position,
                                  label: item.label,
                                  isTextItem: item.type == ItemType.text,
                                  textSize: item.textSize,
                                  autoEdit: _autoEditTextId == item.id,
                                  hasEditableLabel: item.type != ItemType.cone && item.type != ItemType.ball,
                                  isPlayer: item.type == ItemType.redPlayer || item.type == ItemType.whitePlayer,
                                  playerName: item.name,
                                  onNameChanged: (newName) => _updateItemName(item.id, newName),
                                  onAutoEditShown: () {
                                    setState(() {
                                      _autoEditTextId = null;
                                    });
                                  },
                                  onPositionChanged: (newPosition) =>
                                      _updateItemPosition(item.id, newPosition),
                                  onDelete: () => _deleteItem(item.id),
                                  onLabelChanged: (newLabel) =>
                                      _updateItemLabel(item.id, newLabel),
                                  onTextSizeChanged: (newSize) =>
                                      _updateItemTextSize(item.id, newSize),
                                  child: _buildItemWidget(item),
                                )),
                          ],
                        ),
                    );
                  },
                ),
              );
            },
          ),
              // Drawing toolbar overlay on the right (only visible in drawing mode)
              if (_isDrawingMode)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: DrawingToolbar(
                    selectedShape: _activeDrawingType,
                    selectedColor: _activeDrawingColor,
                    canUndo: _undoStack.isNotEmpty,
                    onShapeChanged: _setDrawingType,
                    onColorChanged: _setDrawingColor,
                    onUndo: _undoLastDrawing,
                    onCancel: _cancelDrawingMode,
                  ),
                ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}
