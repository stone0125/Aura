// =============================================================================
// app_theme.dart — App Theme Configuration
// 应用主题配置
//
// Defines the complete Material 3 theme for both light and dark modes:
// - Color scheme (coral primary, semantic colors)
// - Typography system (display, headline, body, label styles)
// - Component themes (cards, buttons, inputs, navigation bar, app bar)
// All UI components inherit from these theme definitions, ensuring
// consistent look and feel across the entire app.
//
// 定义亮色和暗色模式的完整 Material 3 主题：
// - 色彩方案（珊瑚色主色、语义化颜色）
// - 排版系统（展示、标题、正文、标签样式）
// - 组件主题（卡片、按钮、输入框、导航栏、应用栏）
// 所有 UI 组件继承这些主题定义，确保整个应用的外观和风格一致。
// =============================================================================

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'ui_constants.dart';

/// App theme configuration
class AppTheme {
  AppTheme._(); // Prevent instantiation

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightCoral,
      secondary: AppColors.lightCoralLight,
      surface: AppColors.lightSurface,
      error: AppColors.red,
      onPrimary: Colors.white,
      onSecondary: AppColors.lightPrimaryText,
      onSurface: AppColors.lightPrimaryText,
    ),

    // AppBar Theme - Standardized: 20px, w600, elevation 0
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      elevation: UIConstants.appBarElevation,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.lightPrimaryText),
      titleTextStyle: TextStyle(
        color: AppColors.lightPrimaryText,
        fontSize: UIConstants.appBarTitleSize,
        fontWeight: UIConstants.appBarTitleWeight,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: UIConstants.borderRadiusLarge,
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.05),
    ),

    // Elevated Button Theme - Standardized
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightCoral,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size(0, UIConstants.buttonHeightPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: UIConstants.borderRadiusMedium,
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightCoral,
        minimumSize: Size(0, UIConstants.buttonHeightSecondary),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: UIConstants.borderRadiusMedium,
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.lightCoral,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.lightCoral,
      unselectedItemColor: AppColors.lightSecondaryText,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Text Theme - Standardized typography system
    textTheme: const TextTheme(
      // Headlines
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.lightPrimaryText,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.lightPrimaryText,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.lightPrimaryText,
      ),

      // Body text
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.lightPrimaryText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.lightSecondaryText,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.lightSecondaryText,
      ),

      // Labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.lightPrimaryText,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.lightSecondaryText,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.lightSecondaryText,
      ),

      // Display (for large hero text)
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.lightPrimaryText,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.lightPrimaryText,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.lightPrimaryText,
      ),

      // Title (for medium emphasis)
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.lightPrimaryText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.lightPrimaryText,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.lightPrimaryText,
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.lightPrimaryText,
      size: UIConstants.iconDefault,
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: UIConstants.borderRadiusMedium,
        borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: UIConstants.borderRadiusMedium,
        borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: UIConstants.borderRadiusMedium,
        borderSide: const BorderSide(color: AppColors.lightCoral, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing16,
        vertical: UIConstants.spacing12,
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkCoral,
      secondary: AppColors.darkPink,
      surface: AppColors.darkSurface,
      error: AppColors.darkRed,
      onPrimary: AppColors.darkBackground,
      onSecondary: AppColors.darkPrimaryText,
      onSurface: AppColors.darkPrimaryText,
    ),

    // AppBar Theme - Standardized: 20px, w600, elevation 0
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      elevation: UIConstants.appBarElevation,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.darkPrimaryText),
      titleTextStyle: TextStyle(
        color: AppColors.darkPrimaryText,
        fontSize: UIConstants.appBarTitleSize,
        fontWeight: UIConstants.appBarTitleWeight,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: UIConstants.borderRadiusLarge,
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.25),
    ),

    // Elevated Button Theme - Standardized
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkCoral,
        foregroundColor: AppColors.darkBackground,
        elevation: 0,
        minimumSize: Size(0, UIConstants.buttonHeightPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: UIConstants.borderRadiusMedium,
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkCoral,
        minimumSize: Size(0, UIConstants.buttonHeightSecondary),
        side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: UIConstants.borderRadiusMedium,
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.darkCoral,
      foregroundColor: AppColors.darkBackground,
      elevation: 4,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkNavBar,
      selectedItemColor: AppColors.darkCoral,
      unselectedItemColor: AppColors.darkSecondaryText,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Text Theme - Standardized typography system
    textTheme: const TextTheme(
      // Headlines
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.darkPrimaryText,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.darkPrimaryText,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.darkPrimaryText,
      ),

      // Body text
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.darkPrimaryText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.darkSecondaryText,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.darkSecondaryText,
      ),

      // Labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.darkPrimaryText,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.darkSecondaryText,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.darkSecondaryText,
      ),

      // Display (for large hero text)
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.darkPrimaryText,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.darkPrimaryText,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.darkPrimaryText,
      ),

      // Title (for medium emphasis)
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.darkPrimaryText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.darkPrimaryText,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.darkPrimaryText,
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.darkPrimaryText,
      size: UIConstants.iconDefault,
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: UIConstants.borderRadiusMedium,
        borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: UIConstants.borderRadiusMedium,
        borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: UIConstants.borderRadiusMedium,
        borderSide: const BorderSide(color: AppColors.darkCoral, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing16,
        vertical: UIConstants.spacing12,
      ),
    ),
  );
}
