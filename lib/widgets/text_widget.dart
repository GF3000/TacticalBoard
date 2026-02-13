import 'package:flutter/material.dart';
import '../models/tactical_item.dart';
import '../utils/constants.dart';

/// Widget that displays text on the tactical board.
class TextWidget extends StatelessWidget {
  final String text;
  final TextSize textSize;

  const TextWidget({
    super.key,
    required this.text,
    this.textSize = TextSize.medium,
  });

  double _fontSize(ResponsiveSizes sizes) {
    switch (textSize) {
      case TextSize.small:
        return sizes.textSizeSmall;
      case TextSize.medium:
        return sizes.textSizeMedium;
      case TextSize.large:
        return sizes.textSizeLarge;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = ResponsiveSizes(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * sizes.scaleFactor,
        vertical: 4 * sizes.scaleFactor,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.isEmpty ? 'Text' : text,
        style: TextStyle(
          color: Colors.white,
          fontSize: _fontSize(sizes),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
