import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A widget that displays a cone image with a fallback icon.
class ConeWidget extends StatelessWidget {
  const ConeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = ResponsiveSizes(context);
    return SizedBox(
      width: sizes.coneSize,
      height: sizes.coneSize,
      child: Image.asset(
        kConeImage,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Container(
            width: sizes.coneSize,
            height: sizes.coneSize,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.warning,
              color: Colors.white,
              size: 24 * sizes.scaleFactor,
            ),
          );
        },
      ),
    );
  }
}
