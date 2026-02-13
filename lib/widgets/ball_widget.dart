import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A widget that displays a ball image with a fallback icon.
class BallWidget extends StatelessWidget {
  const BallWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = ResponsiveSizes(context);
    return SizedBox(
      width: sizes.ballSize,
      height: sizes.ballSize,
      child: Image.asset(
        kBallImage,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Container(
            width: sizes.ballSize,
            height: sizes.ballSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2 * sizes.scaleFactor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.sports_handball,
              color: Colors.black87,
              size: 20 * sizes.scaleFactor,
            ),
          );
        },
      ),
    );
  }
}
