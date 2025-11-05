import 'package:flutter/material.dart';

/// App color constants for light and dark themes
class AppColors {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFFAF9F6); // Warm beige
  static const Color lightSurface = Color(0xFFFFFFFF); // White
  static const Color lightTextPrimary = Color(0xFF2C3E50); // Dark gray
  static const Color lightTextSecondary = Color(0xFF7F8C8D); // Medium gray
  static const Color lightTextTertiary = Color(0xFFB0B0B0); // Lighter gray
  static const Color lightPrimaryText = Color(0xFF2C3E50); // Dark gray (alias)
  static const Color lightSecondaryText = Color(0xFF7F8C8D); // Medium gray (alias)
  static const Color lightBorder = Color(0xFFE8E8E8); // Light gray
  static const Color lightCoral = Color(0xFFFF6B6B); // Coral
  static const Color lightCoralDeep = Color(0xFFFF5252); // Deeper coral
  static const Color lightCoralLight = Color(0xFFFFBABA); // Lighter coral
  static const Color lightPink = Color(0xFFFFD3E1); // Pink
  static const Color lightOrange = Color(0xFFF39C12); // Orange
  static const Color lightGold = Color(0xFFFFD700); // Gold
  static const Color lightRed = Color(0xFFE74C3C); // Red

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212); // Very dark gray
  static const Color darkSurface = Color(0xFF1E1E1E); // Elevated dark
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C); // Surface variant
  static const Color darkNavBar = Color(0xFF2C2C2C); // Nav bar elevated
  static const Color darkTextPrimary = Color(0xFFE8E8E8); // Off-white
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // Light gray
  static const Color darkTextTertiary = Color(0xFF808080); // Dimmer gray
  static const Color darkPrimaryText = Color(0xFFE8E8E8); // Off-white (alias)
  static const Color darkSecondaryText = Color(0xFFB0B0B0); // Light gray (alias)
  static const Color darkBorder = Color(0xFF3A3A3A); // Dark gray
  static const Color darkCoral = Color(0xFFFF8A80); // Bright coral
  static const Color darkCoralDeep = Color(0xFFFF6B6B); // Coral
  static const Color darkPink = Color(0xFFFF80AB); // Bright pink
  static const Color darkGold = Color(0xFFFFD54F); // Gold
  static const Color darkRed = Color(0xFFFF5252); // Red

  // Shared Colors
  static const Color orange = Color(0xFFF39C12); // Streak orange
  static const Color darkOrange = Color(0xFFFFB74D); // Dark mode streak orange
  static const Color red = Color(0xFFE74C3C); // Delete red

  // Category Gradient Colors (Light Mode)
  static const List<Color> healthGradientLight = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD3E1),
  ];
  static const List<Color> learningGradientLight = [
    Color(0xFF5DADE2),
    Color(0xFF85C1E9),
  ];
  static const List<Color> productivityGradientLight = [
    Color(0xFF48C9B0),
    Color(0xFF76D7C4),
  ];
  static const List<Color> mindfulnessGradientLight = [
    Color(0xFF9B59B6),
    Color(0xFFBB8FCE),
  ];
  static const List<Color> fitnessGradientLight = [
    Color(0xFFEC7063),
    Color(0xFFF1948A),
  ];

  // Category Gradient Colors (Dark Mode)
  static const List<Color> healthGradientDark = [
    Color(0xFFFF8A80),
    Color(0xFFFF80AB),
  ];
  static const List<Color> learningGradientDark = [
    Color(0xFF73C2FB),
    Color(0xFF9FD4FB),
  ];
  static const List<Color> productivityGradientDark = [
    Color(0xFF5EDCC4),
    Color(0xFF8FE8D5),
  ];
  static const List<Color> mindfulnessGradientDark = [
    Color(0xFFB388FF),
    Color(0xFFD1B3FF),
  ];
  static const List<Color> fitnessGradientDark = [
    Color(0xFFFF8A80),
    Color(0xFFFFAB91),
  ];
}
