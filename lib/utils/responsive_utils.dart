import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  static double pixelDensity(BuildContext context) => MediaQuery.of(context).devicePixelRatio;
  static bool isSmallScreen(BuildContext context) => screenWidth(context) < 600;
  static bool isMediumScreen(BuildContext context) => screenWidth(context) >= 600 && screenWidth(context) < 1200;
  static bool isLargeScreen(BuildContext context) => screenWidth(context) >= 1200;
  static bool isTablet(BuildContext context) => screenWidth(context) >= 600;
  static bool isPhone(BuildContext context) => screenWidth(context) < 600;
  
  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context, {
    double horizontal = 16.0,
    double vertical = 16.0,
    double horizontalTablet = 24.0,
    double verticalTablet = 24.0,
    double horizontalLarge = 32.0,
    double verticalLarge = 32.0,
  }) {
    if (isLargeScreen(context)) {
      return EdgeInsets.symmetric(horizontal: horizontalLarge, vertical: verticalLarge);
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(horizontal: horizontalTablet, vertical: verticalTablet);
    } else {
      return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
    }
  }
  
  // Responsive margin
  static EdgeInsets responsiveMargin(BuildContext context, {
    double horizontal = 16.0,
    double vertical = 16.0,
    double horizontalTablet = 24.0,
    double verticalTablet = 24.0,
    double horizontalLarge = 32.0,
    double verticalLarge = 32.0,
  }) {
    if (isLargeScreen(context)) {
      return EdgeInsets.symmetric(horizontal: horizontalLarge, vertical: verticalLarge);
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(horizontal: horizontalTablet, vertical: verticalTablet);
    } else {
      return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
    }
  }
  
  // Responsive font size
  static double responsiveFontSize(BuildContext context, {
    double baseSize = 16.0,
    double tabletMultiplier = 1.2,
    double largeMultiplier = 1.4,
  }) {
    if (isLargeScreen(context)) {
      return baseSize * largeMultiplier;
    } else if (isTablet(context)) {
      return baseSize * tabletMultiplier;
    } else {
      return baseSize;
    }
  }
  
  // Responsive icon size
  static double responsiveIconSize(BuildContext context, {
    double baseSize = 24.0,
    double tabletMultiplier = 1.3,
    double largeMultiplier = 1.6,
  }) {
    if (isLargeScreen(context)) {
      return baseSize * largeMultiplier;
    } else if (isTablet(context)) {
      return baseSize * tabletMultiplier;
    } else {
      return baseSize;
    }
  }
  
  // Responsive spacing
  static double responsiveSpacing(BuildContext context, {
    double baseSpacing = 16.0,
    double tabletMultiplier = 1.25,
    double largeMultiplier = 1.5,
  }) {
    if (isLargeScreen(context)) {
      return baseSpacing * largeMultiplier;
    } else if (isTablet(context)) {
      return baseSpacing * tabletMultiplier;
    } else {
      return baseSpacing;
    }
  }
  
  // Responsive grid cross axis count
  static int responsiveGridCrossAxisCount(BuildContext context, {
    int phoneCount = 2,
    int tabletCount = 3,
    int largeCount = 4,
  }) {
    if (isLargeScreen(context)) {
      return largeCount;
    } else if (isTablet(context)) {
      return tabletCount;
    } else {
      return phoneCount;
    }
  }
  
  // Responsive card width
  static double responsiveCardWidth(BuildContext context, {
    double phoneWidth = 150.0,
    double tabletWidth = 200.0,
    double largeWidth = 250.0,
  }) {
    if (isLargeScreen(context)) {
      return largeWidth;
    } else if (isTablet(context)) {
      return tabletWidth;
    } else {
      return phoneWidth;
    }
  }
  
  // Responsive aspect ratio
  static double responsiveAspectRatio(BuildContext context, {
    double phoneRatio = 0.75,
    double tabletRatio = 0.8,
    double largeRatio = 0.85,
  }) {
    if (isLargeScreen(context)) {
      return largeRatio;
    } else if (isTablet(context)) {
      return tabletRatio;
    } else {
      return phoneRatio;
    }
  }
  
  // Responsive border radius
  static double responsiveBorderRadius(BuildContext context, {
    double baseRadius = 16.0,
    double tabletMultiplier = 1.2,
    double largeMultiplier = 1.4,
  }) {
    if (isLargeScreen(context)) {
      return baseRadius * largeMultiplier;
    } else if (isTablet(context)) {
      return baseRadius * tabletMultiplier;
    } else {
      return baseRadius;
    }
  }
  
  // Responsive height
  static double responsiveHeight(BuildContext context, {
    double baseHeight = 200.0,
    double tabletMultiplier = 1.3,
    double largeMultiplier = 1.6,
  }) {
    if (isLargeScreen(context)) {
      return baseHeight * largeMultiplier;
    } else if (isTablet(context)) {
      return baseHeight * tabletMultiplier;
    } else {
      return baseHeight;
    }
  }
  
  // Responsive width percentage
  static double responsiveWidthPercentage(BuildContext context, {
    double phonePercentage = 0.9,
    double tabletPercentage = 0.8,
    double largePercentage = 0.7,
  }) {
    if (isLargeScreen(context)) {
      return largePercentage;
    } else if (isTablet(context)) {
      return tabletPercentage;
    } else {
      return phonePercentage;
    }
  }
  
  // Responsive max width
  static double responsiveMaxWidth(BuildContext context, {
    double phoneMaxWidth = 400.0,
    double tabletMaxWidth = 600.0,
    double largeMaxWidth = 800.0,
  }) {
    if (isLargeScreen(context)) {
      return largeMaxWidth;
    } else if (isTablet(context)) {
      return tabletMaxWidth;
    } else {
      return phoneMaxWidth;
    }
  }

  // Responsive button height
  static double responsiveButtonHeight(BuildContext context, {
    double baseHeight = 48.0,
    double tabletMultiplier = 1.1,
    double largeMultiplier = 1.2,
  }) {
    if (isLargeScreen(context)) {
      return baseHeight * largeMultiplier;
    } else if (isTablet(context)) {
      return baseHeight * tabletMultiplier;
    } else {
      return baseHeight;
    }
  }
}
