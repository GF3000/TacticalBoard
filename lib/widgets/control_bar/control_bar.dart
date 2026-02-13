import 'package:flutter/material.dart';
import '../../models/tactical_item.dart';
import '../../utils/constants.dart';
import '../player_token.dart';
import '../cone_widget.dart';
import '../ball_widget.dart';
import '../text_widget.dart';

/// Left side control bar with draggable item sources.
class ControlBar extends StatelessWidget {
  final int nextRedNumber;
  final int nextWhiteNumber;
  final bool isArrowMode;
  final bool isDrawingMode;
  final VoidCallback onArrowModePressed;
  final VoidCallback onDrawModePressed;
  final VoidCallback onClearAll;
  final VoidCallback onSetup6vs6;

  const ControlBar({
    super.key,
    required this.nextRedNumber,
    required this.nextWhiteNumber,
    required this.isArrowMode,
    required this.isDrawingMode,
    required this.onArrowModePressed,
    required this.onDrawModePressed,
    required this.onClearAll,
    required this.onSetup6vs6,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = ResponsiveSizes(context);

    return Container(
      width: sizes.controlBarWidth,
      color: kControlBarColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: sizes.isSmallPhone ? 4 : 8, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildDraggableSource(
              context: context,
              itemType: ItemType.redPlayer,
              label: 'Red',
              child: PlayerToken(label: nextRedNumber.toString(), isRed: true),
            ),
            SizedBox(height: sizes.itemSpacing),
            _buildDraggableSource(
              context: context,
              itemType: ItemType.whitePlayer,
              label: 'White',
              child: PlayerToken(label: nextWhiteNumber.toString(), isRed: false),
            ),
            SizedBox(height: sizes.itemSpacing),
            _buildDraggableSource(
              context: context,
              itemType: ItemType.cone,
              label: 'Cone',
              child: const ConeWidget(),
            ),
            SizedBox(height: sizes.itemSpacing),
            _buildDraggableSource(
              context: context,
              itemType: ItemType.ball,
              label: 'Ball',
              child: const BallWidget(),
            ),
            SizedBox(height: sizes.itemSpacing),
            _buildDraggableSource(
              context: context,
              itemType: ItemType.text,
              label: 'Text',
              child: const TextWidget(text: 'Abc'),
            ),
            SizedBox(height: sizes.itemSpacing),
            // Arrow button
            _buildArrowButton(context),
            SizedBox(height: sizes.itemSpacing),
            // Draw button
            _buildDrawButton(context),
            SizedBox(height: sizes.itemSpacing),
            // 6vs6 setup button
            _build6vs6Button(context),
            SizedBox(height: sizes.itemSpacing),
            // Clear all button
            _buildClearButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowButton(BuildContext context) {
    final sizes = ResponsiveSizes(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onArrowModePressed,
          child: Container(
            width: sizes.controlButtonSize,
            height: sizes.controlButtonSize,
            decoration: BoxDecoration(
              color: isArrowMode ? Colors.blue : Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isArrowMode ? Colors.white : Colors.grey,
                width: 2,
              ),
            ),
            child: Icon(
              isArrowMode ? Icons.close : Icons.arrow_forward,
              color: Colors.white,
              size: sizes.controlButtonSize * 0.58,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isArrowMode ? 'Cancel' : 'Arrow',
          style: TextStyle(
            color: Colors.white70,
            fontSize: sizes.fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawButton(BuildContext context) {
    final sizes = ResponsiveSizes(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDrawModePressed,
          child: Container(
            width: sizes.controlButtonSize,
            height: sizes.controlButtonSize,
            decoration: BoxDecoration(
              color: isDrawingMode ? Colors.blue : Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDrawingMode ? Colors.white : Colors.grey,
                width: 2,
              ),
            ),
            child: Icon(
              isDrawingMode ? Icons.close : Icons.draw,
              color: Colors.white,
              size: sizes.controlButtonSize * 0.58,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isDrawingMode ? 'Cancel' : 'Draw',
          style: TextStyle(
            color: Colors.white70,
            fontSize: sizes.fontSize,
          ),
        ),
      ],
    );
  }

  Widget _build6vs6Button(BuildContext context) {
    final sizes = ResponsiveSizes(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onSetup6vs6,
          child: Container(
            width: sizes.controlButtonSize,
            height: sizes.controlButtonSize,
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '6v6',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: sizes.controlButtonSize * 0.35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Setup',
          style: TextStyle(
            color: Colors.white70,
            fontSize: sizes.fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildClearButton(BuildContext context) {
    final sizes = ResponsiveSizes(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onClearAll,
          child: Container(
            width: sizes.controlButtonSize,
            height: sizes.controlButtonSize,
            decoration: BoxDecoration(
              color: Colors.red[700],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.delete_sweep,
              color: Colors.white,
              size: sizes.controlButtonSize * 0.58,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Clear',
          style: TextStyle(
            color: Colors.white70,
            fontSize: sizes.fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableSource({
    required BuildContext context,
    required ItemType itemType,
    required String label,
    required Widget child,
  }) {
    final sizes = ResponsiveSizes(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Draggable<ItemType>(
          data: itemType,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.8,
              child: child,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: child,
          ),
          child: child,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: sizes.fontSize,
          ),
        ),
      ],
    );
  }
}