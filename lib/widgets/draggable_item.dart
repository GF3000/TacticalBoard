import 'package:flutter/material.dart';
import '../models/tactical_item.dart';

/// A wrapper widget that makes its child draggable using GestureDetector.
/// Supports drag-to-move, double-tap-to-delete, and long-press menu functionality.
class DraggableItem extends StatefulWidget {
  final Widget child;
  final Offset position;
  final String label;
  final ValueChanged<Offset> onPositionChanged;
  final VoidCallback onDelete;
  final ValueChanged<String> onLabelChanged;
  final bool isTextItem;
  final TextSize? textSize;
  final ValueChanged<TextSize>? onTextSizeChanged;
  final bool autoEdit;
  final VoidCallback? onAutoEditShown;
  final bool hasEditableLabel;
  final bool isPlayer;
  final String? playerName;
  final ValueChanged<String>? onNameChanged;

  const DraggableItem({
    super.key,
    required this.child,
    required this.position,
    required this.label,
    required this.onPositionChanged,
    required this.onDelete,
    required this.onLabelChanged,
    this.isTextItem = false,
    this.textSize,
    this.onTextSizeChanged,
    this.autoEdit = false,
    this.onAutoEditShown,
    this.hasEditableLabel = true,
    this.isPlayer = false,
    this.playerName,
    this.onNameChanged,
  });

  @override
  State<DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<DraggableItem> {
  late Offset _currentPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;
    // Auto-show edit dialog for new text items
    if (widget.autoEdit && widget.isTextItem) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEditDialog();
        widget.onAutoEditShown?.call();
      });
    }
  }

  @override
  void didUpdateWidget(DraggableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update position from parent if not currently dragging
    if (!_isDragging && widget.position != oldWidget.position) {
      _currentPosition = widget.position;
    }
  }

  void _showContextMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isPlayer && widget.onNameChanged != null)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Edit Name'),
                onTap: () {
                  Navigator.pop(context);
                  _showNameDialog();
                },
              ),
            if (widget.hasEditableLabel)
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(widget.isTextItem ? 'Edit Text' : 'Edit Number'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog();
                },
              ),
            if (widget.isTextItem && widget.onTextSizeChanged != null)
              ListTile(
                leading: const Icon(Icons.format_size),
                title: const Text('Change Size'),
                onTap: () {
                  Navigator.pop(context);
                  _showSizeDialog();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSizeOption(TextSize.small, 'Small (S)'),
            _buildSizeOption(TextSize.medium, 'Medium (M)'),
            _buildSizeOption(TextSize.large, 'Large (L)'),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeOption(TextSize size, String label) {
    final isSelected = widget.textSize == size;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Colors.blue : null,
      ),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        widget.onTextSizeChanged?.call(size);
      },
    );
  }

  void _showNameDialog() {
    final controller = TextEditingController(text: widget.playerName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Player Name'),
        content: TextField(
          controller: controller,
          maxLength: 20,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Enter player name',
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            widget.onNameChanged?.call(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onNameChanged?.call(controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: widget.label);
    final isText = widget.isTextItem;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isText ? 'Edit Text' : 'Edit Label'),
        content: TextField(
          controller: controller,
          maxLength: isText ? 50 : 2,
          autofocus: true,
          textAlign: isText ? TextAlign.start : TextAlign.center,
          style: TextStyle(fontSize: isText ? 16 : 24),
          decoration: InputDecoration(
            hintText: isText ? 'Enter text' : 'Enter label',
            counterText: isText ? '' : 'Max 2 characters',
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            widget.onLabelChanged(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLabelChanged(controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _currentPosition.dx,
      top: _currentPosition.dy,
      child: GestureDetector(
        onPanStart: (_) {
          _isDragging = true;
        },
        onPanUpdate: (details) {
          setState(() {
            _currentPosition = Offset(
              _currentPosition.dx + details.delta.dx,
              _currentPosition.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (_) {
          _isDragging = false;
          widget.onPositionChanged(_currentPosition);
        },
        onDoubleTap: widget.onDelete,
        onLongPress: _showContextMenu,
        child: widget.child,
      ),
    );
  }
}
