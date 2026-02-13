import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A circular player token widget that displays a player number.
/// Optionally shows a name above the token.
class PlayerToken extends StatelessWidget {
  final String label;
  final bool isRed;
  final String? name;

  const PlayerToken({
    super.key,
    required this.label,
    required this.isRed,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = ResponsiveSizes(context);
    final backgroundColor = isRed ? kRedPlayerColor : kWhitePlayerColor;
    final borderColor = isRed ? Colors.white : Colors.black;
    final textColor = isRed ? Colors.white : Colors.black;

    final token = Container(
      width: sizes.playerRadius * 2,
      height: sizes.playerRadius * 2,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: sizes.playerBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 18 * sizes.scaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    // If no name, just return the token
    if (name == null || name!.isEmpty) {
      return token;
    }

    // Return token with name above it
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            name!,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14 * sizes.scaleFactor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        token,
      ],
    );
  }
}
