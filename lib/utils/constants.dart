import 'package:flutter/material.dart';

// Asset paths
const String kCourtImage = 'assets/court.png';
const String kConeImage = 'assets/cone.png';
const String kBallImage = 'assets/ball.png';

// Colors
const Color kRedPlayerColor = Color(0xFFE53935);
const Color kWhitePlayerColor = Colors.white;
const Color kCourtFallbackColor = Color(0xFF1565C0);
const Color kControlBarColor = Color(0xFF263238);
const Color kBackgroundColor = Color(0xFF6e824e);

// Court dimensions (2040x1592)
const double kCourtAspectRatio = 2040 / 1592; // ~1.281

// Base sizes (for tablets/large screens)
const double kPlayerRadius = 24.0;
const double kPlayerBorderWidth = 3.0;
const double kConeSize = 40.0;
const double kBallSize = 36.0;
const double kControlBarHeight = 85.0;
const double kControlBarWidth = 80.0;

// Control bar button styles
const double kControlButtonHeight = 45.0;
const double kControlButtonSpacing = 12.0;

// Text sizes
const double kTextSizeSmall = 14.0;
const double kTextSizeMedium = 20.0;
const double kTextSizeLarge = 28.0;

/// Helper class to get responsive sizes based on screen dimensions.
class ResponsiveSizes {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;
  late final bool isPhone;
  late final bool isSmallPhone;
  late final bool isLandscapePhone;
  late final double scaleFactor;

  ResponsiveSizes(this.context) {
    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height;
    // Consider phone if shorter dimension is less than 600
    isPhone = size.shortestSide < 600;
    isSmallPhone = size.shortestSide < 400;
    // Landscape phone: phone with width > height (small height, big width)
    isLandscapePhone = isPhone && screenWidth > screenHeight;
    // Scale factor: 1.0 for tablets, 0.7 for phones (30% smaller), 0.5 for small phones
    scaleFactor = isSmallPhone ? 0.65 : (isPhone ? 0.75 : 1.0);
  }

  double get playerRadius => kPlayerRadius * scaleFactor;
  double get playerBorderWidth => kPlayerBorderWidth * scaleFactor;
  double get coneSize => kConeSize * scaleFactor;
  double get ballSize => kBallSize * scaleFactor;
  double get controlBarWidth {
    if (isLandscapePhone) {
      // Wider control bar for landscape phones to ease vertical scrolling
      return isSmallPhone ? 70.0 : 85.0;
    }
    return isSmallPhone ? 60.0 : (isPhone ? 70.0 : 80.0);
  }
  double get controlButtonSize => isSmallPhone ? 36.0 : (isPhone ? 42.0 : 48.0);
  double get fontSize => isSmallPhone ? 8.0 : (isPhone ? 9.0 : 10.0);
  double get itemSpacing => isSmallPhone ? 8.0 : (isPhone ? 10.0 : 12.0);
  double get textSizeSmall => kTextSizeSmall * scaleFactor;
  double get textSizeMedium => kTextSizeMedium * scaleFactor;
  double get textSizeLarge => kTextSizeLarge * scaleFactor;
}
