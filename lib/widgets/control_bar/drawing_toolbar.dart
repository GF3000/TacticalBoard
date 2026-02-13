import 'package:flutter/material.dart';
import '../../models/tactical_drawing.dart';
import '../../models/tactical_arrow.dart';
import '../../utils/constants.dart';

/// Right-side toolbar for drawing options.
/// Appears when user enters drawing mode.
class DrawingToolbar extends StatelessWidget {
  final DrawingType selectedShape;
  final ArrowColor selectedColor;
  final bool canUndo;
  final ValueChanged<DrawingType> onShapeChanged;
  final ValueChanged<ArrowColor> onColorChanged;
  final VoidCallback onUndo;
  final VoidCallback onCancel;

  const DrawingToolbar({
    super.key,
    required this.selectedShape,
    required this.selectedColor,
    required this.canUndo,
    required this.onShapeChanged,
    required this.onColorChanged,
    required this.onUndo,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = ResponsiveSizes(context);
    final buttonSize = sizes.controlButtonSize;
    final spacing = sizes.itemSpacing;
    final fontSize = sizes.fontSize;

    return Container(
      width: sizes.controlBarWidth,
      color: kControlBarColor,
      child: SafeArea(
        left: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: spacing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cancel button
              _buildButton(
                icon: Icons.close,
                label: 'Cancel',
                isActive: false,
                color: Colors.red[400]!,
                buttonSize: buttonSize,
                fontSize: fontSize,
                onTap: onCancel,
              ),
              SizedBox(height: spacing * 1.5),

              // Color section label
              Text(
                'Color',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: spacing / 2),

              // Color buttons
              _buildColorButton(ArrowColor.white, Colors.white, buttonSize),
              SizedBox(height: spacing / 2),
              _buildColorButton(ArrowColor.red, Colors.red, buttonSize),
              SizedBox(height: spacing / 2),
              _buildColorButton(ArrowColor.yellow, Colors.yellow, buttonSize),
              SizedBox(height: spacing * 1.5),

              // Shape section label
              Text(
                'Shape',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: spacing / 2),

              // Shape buttons
              _buildButton(
                icon: Icons.circle_outlined,
                label: 'Circle',
                isActive: selectedShape == DrawingType.circle,
                buttonSize: buttonSize,
                fontSize: fontSize,
                onTap: () => onShapeChanged(DrawingType.circle),
              ),
              SizedBox(height: spacing / 2),
              _buildButton(
                icon: Icons.rectangle_outlined,
                label: 'Rect',
                isActive: selectedShape == DrawingType.rectangle,
                buttonSize: buttonSize,
                fontSize: fontSize,
                onTap: () => onShapeChanged(DrawingType.rectangle),
              ),
              SizedBox(height: spacing / 2),
              _buildButton(
                icon: Icons.gesture,
                label: 'Free',
                isActive: selectedShape == DrawingType.freehand,
                buttonSize: buttonSize,
                fontSize: fontSize,
                onTap: () => onShapeChanged(DrawingType.freehand),
              ),
              SizedBox(height: spacing * 1.5),

              // Undo button
              _buildButton(
                icon: Icons.undo,
                label: 'Undo',
                isActive: false,
                color: canUndo ? Colors.orange[400]! : Colors.grey[700]!,
                enabled: canUndo,
                buttonSize: buttonSize,
                fontSize: fontSize,
                onTap: canUndo ? onUndo : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required double buttonSize,
    required double fontSize,
    Color? color,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    final bgColor = isActive
        ? Colors.blue
        : (color ?? Colors.grey[700]!);
    final iconColor = enabled ? Colors.white : Colors.grey[500]!;
    final textColor = enabled ? Colors.white : Colors.grey[500]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Icon(icon, color: iconColor, size: buttonSize * 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildColorButton(ArrowColor colorValue, Color displayColor, double buttonSize) {
    final isSelected = selectedColor == colorValue;
    final size = buttonSize * 0.6;

    return GestureDetector(
      onTap: () => onColorChanged(colorValue),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
