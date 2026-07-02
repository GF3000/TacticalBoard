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
    showDialog(
      context: context,
      builder: (context) => _TextInputDialog(
        title: 'Edit Player Name',
        initialValue: widget.playerName ?? '',
        hintText: 'Enter player name',
        maxLength: 20,
        textCapitalization: TextCapitalization.words,
        onSubmit: (value) => widget.onNameChanged?.call(value),
      ),
    );
  }

  void _showEditDialog() {
    final isText = widget.isTextItem;
    showDialog(
      context: context,
      builder: (context) => _TextInputDialog(
        title: isText ? 'Edit Text' : 'Edit Label',
        initialValue: widget.label,
        hintText: isText ? 'Enter text' : 'Enter label',
        maxLength: isText ? 50 : 2,
        textAlign: isText ? TextAlign.start : TextAlign.center,
        style: TextStyle(fontSize: isText ? 16 : 24),
        counterText: isText ? '' : 'Max 2 characters',
        onSubmit: (value) => widget.onLabelChanged(value),
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

/// A reusable stateful dialog with a single text field that owns and disposes
/// its [TextEditingController].
class _TextInputDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final String hintText;
  final int maxLength;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final TextStyle? style;
  final String? counterText;
  final ValueChanged<String> onSubmit;

  const _TextInputDialog({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.maxLength,
    required this.onSubmit,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.style,
    this.counterText,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    Navigator.pop(context);
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLength: widget.maxLength,
        autofocus: true,
        textCapitalization: widget.textCapitalization,
        textAlign: widget.textAlign,
        style: widget.style,
        decoration: InputDecoration(
          hintText: widget.hintText,
          counterText: widget.counterText,
        ),
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _submit(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
