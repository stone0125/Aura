import 'package:flutter/material.dart';

/// App color constants for light and dark themes
///
/// NAMING CONVENTION:
/// - Primary naming: light/dark + semantic name (e.g., lightPrimaryText)
/// - Colors follow the pattern: [theme][Purpose]
/// - Text colors: PrimaryText, SecondaryText, TertiaryText
/// - Surface colors: Background, Surface, SurfaceVariant
/// - Accent colors: Coral, Pink, Gold, Red, Orange
class AppColors {
  AppColors._(); // Prevent instantiation

  // ==================== Light Mode Colors ====================

  /// Light mode background - Warm beige
  static const Color lightBackground = Color(0xFFFAF9F6);
  /// Light mode surface - White
  static const Color lightSurface = Color(0xFFFFFFFF);
  /// Light mode primary text - Dark gray
  static const Color lightPrimaryText = Color(0xFF2C3E50);
  /// Light mode secondary text - Medium gray
  static const Color lightSecondaryText = Color(0xFF7F8C8D);
  /// Light mode tertiary text - Lighter gray
  static const Color lightTertiaryText = Color(0xFFB0B0B0);
  /// Light mode border - Light gray
  static const Color lightBorder = Color(0xFFE8E8E8);
  /// Light mode coral accent
  static const Color lightCoral = Color(0xFFFF6B6B);
  /// Light mode deep coral
  static const Color lightCoralDeep = Color(0xFFFF5252);
  /// Light mode light coral
  static const Color lightCoralLight = Color(0xFFFFBABA);
  /// Light mode pink
  static const Color lightPink = Color(0xFFFFD3E1);
  /// Light mode orange
  static const Color lightOrange = Color(0xFFF39C12);
  /// Light mode gold
  static const Color lightGold = Color(0xFFFFD700);
  /// Light mode red (error/delete)
  static const Color lightRed = Color(0xFFE74C3C);

  // ==================== Dark Mode Colors ====================

  /// Dark mode background - Very dark gray
  static const Color darkBackground = Color(0xFF121212);
  /// Dark mode surface - Elevated dark
  static const Color darkSurface = Color(0xFF1E1E1E);
  /// Dark mode surface variant - Slightly lighter
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  /// Dark mode nav bar - Elevated surface
  static const Color darkNavBar = Color(0xFF2C2C2C);
  /// Dark mode primary text - Off-white
  static const Color darkPrimaryText = Color(0xFFE8E8E8);
  /// Dark mode secondary text - Light gray
  static const Color darkSecondaryText = Color(0xFFB0B0B0);
  /// Dark mode tertiary text - Dimmer gray
  static const Color darkTertiaryText = Color(0xFF808080);
  /// Dark mode border - Dark gray
  static const Color darkBorder = Color(0xFF3A3A3A);
  /// Dark mode coral accent
  static const Color darkCoral = Color(0xFFFF8A80);
  /// Dark mode deep coral
  static const Color darkCoralDeep = Color(0xFFFF6B6B);
  /// Dark mode pink
  static const Color darkPink = Color(0xFFFF80AB);
  /// Dark mode gold
  static const Color darkGold = Color(0xFFFFD54F);
  /// Dark mode red (error/delete)
  static const Color darkRed = Color(0xFFFF5252);

  // ==================== Deprecated Aliases ====================
  // TODO: Remove these in next major version - use consistent naming above

  /// @deprecated Use lightPrimaryText instead
  static const Color lightTextPrimary = lightPrimaryText;
  /// @deprecated Use lightSecondaryText instead
  static const Color lightTextSecondary = lightSecondaryText;
  /// @deprecated Use lightTertiaryText instead
  static const Color lightTextTertiary = lightTertiaryText;
  /// @deprecated Use darkPrimaryText instead
  static const Color darkTextPrimary = darkPrimaryText;
  /// @deprecated Use darkSecondaryText instead
  static const Color darkTextSecondary = darkSecondaryText;
  /// @deprecated Use darkTertiaryText instead
  static const Color darkTextTertiary = darkTertiaryText;

  // ==================== Splash Screen Colors ====================
  // Theme-independent — splash is a branding moment

  /// Splash background - Flat coral (matches native splash exactly)
  static const Color splashGradientStart = Color(0xFFFF6B6B);
  /// Splash background - Flat coral (same as start for seamless transition)
  static const Color splashGradientMiddle = Color(0xFFFF6B6B);
  /// Splash background - Flat coral (same as start for seamless transition)
  static const Color splashGradientEnd = Color(0xFFFF6B6B);
  /// Splash glow around logo
  static const Color splashGlow = Color(0xFFFF6B6B);

  // Splash Screen Colors — Dark
  /// Dark splash background - Flat dark (matches native dark splash exactly)
  static const Color splashDarkGradientStart = Color(0xFF1E1818);
  /// Dark splash background - Flat dark (same as start for seamless transition)
  static const Color splashDarkGradientMiddle = Color(0xFF1E1818);
  /// Dark splash background - Flat dark (same as start for seamless transition)
  static const Color splashDarkGradientEnd = Color(0xFF1E1818);
  /// Dark splash glow around logo - Dark coral
  static const Color splashDarkGlow = Color(0xFFFF8A80);

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
