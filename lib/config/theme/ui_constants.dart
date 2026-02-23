import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Standardized UI constants for consistent styling across the app
class UIConstants {
  UIConstants._();

  // ==================== Spacing Scale ====================
  /// Extra small spacing: 4px
  static const double spacing4 = 4;
  /// Small spacing: 8px
  static const double spacing8 = 8;
  /// Medium-small spacing: 12px
  static const double spacing12 = 12;
  /// Medium spacing: 16px
  static const double spacing16 = 16;
  /// Medium-large spacing: 20px
  static const double spacing20 = 20;
  /// Large spacing: 24px
  static const double spacing24 = 24;
  /// Extra large spacing: 32px
  static const double spacing32 = 32;

  // ==================== Border Radius Scale ====================
  /// Small radius: 8px - chips, small buttons, badges
  static const double radiusSmall = 8;
  /// Medium radius: 12px - buttons, input fields, list items
  static const double radiusMedium = 12;
  /// Large radius: 16px - cards, containers, modals
  static const double radiusLarge = 16;
  /// Extra large radius: 24px - bottom sheets, hero elements
  static const double radiusXLarge = 24;

  /// Small border radius
  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  /// Medium border radius
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  /// Large border radius
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  /// Extra large border radius
  static final BorderRadius borderRadiusXLarge = BorderRadius.circular(radiusXLarge);

  // ==================== Icon Sizes ====================
  /// Small icon: 16px
  static const double iconSmall = 16;
  /// Medium icon: 20px
  static const double iconMedium = 20;
  /// Default icon: 24px
  static const double iconDefault = 24;
  /// Large icon: 32px
  static const double iconLarge = 32;
  /// Extra large icon: 48px
  static const double iconXLarge = 48;

  // ==================== Button Heights ====================
  /// Primary button height: 48px
  static const double buttonHeightPrimary = 48;
  /// Secondary/small button height: 40px
  static const double buttonHeightSecondary = 40;
  /// Mini button height: 32px
  static const double buttonHeightMini = 32;

  // ==================== AppBar Constants ====================
  /// AppBar title font size: 20px
  static const double appBarTitleSize = 20;
  /// AppBar title font weight: w600
  static const FontWeight appBarTitleWeight = FontWeight.w600;
  /// AppBar elevation: 0
  static const double appBarElevation = 0;

  // ==================== Card Constants ====================
  /// Standard card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(spacing16);
  /// Standard card margin
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(horizontal: spacing16);

  // ==================== Shadow Presets ====================

  /// Light mode card shadow - subtle elevation
  static final List<BoxShadow> shadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Dark mode card shadow - more pronounced for depth
  static final List<BoxShadow> shadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Light mode subtle shadow
  static final List<BoxShadow> shadowLightSubtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Dark mode subtle shadow
  static final List<BoxShadow> shadowDarkSubtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.20),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Light mode elevated shadow
  static final List<BoxShadow> shadowLightElevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  /// Dark mode elevated shadow
  static final List<BoxShadow> shadowDarkElevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  /// Get appropriate shadow based on theme
  static List<BoxShadow> getShadow(bool isDark) => isDark ? shadowDark : shadowLight;

  /// Get appropriate subtle shadow based on theme
  static List<BoxShadow> getShadowSubtle(bool isDark) => isDark ? shadowDarkSubtle : shadowLightSubtle;

  /// Get appropriate elevated shadow based on theme
  static List<BoxShadow> getShadowElevated(bool isDark) => isDark ? shadowDarkElevated : shadowLightElevated;

  // ==================== Typography Constants ====================

  /// Headline Large: 24px, w700 - Screen titles, hero text
  static const TextStyle headlineLargeBase = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Headline Medium: 20px, w600 - AppBar titles, section headers
  static const TextStyle headlineMediumBase = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Headline Small: 18px, w600 - Card titles, subsection headers
  static const TextStyle headlineSmallBase = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Body Large: 16px, w500 - Primary body text, habit names
  static const TextStyle bodyLargeBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// Body Medium: 14px, w400 - Secondary body text, descriptions
  static const TextStyle bodyMediumBase = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Body Small: 12px, w400 - Tertiary text, timestamps
  static const TextStyle bodySmallBase = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Label Large: 14px, w600 - Button text, action labels
  static const TextStyle labelLargeBase = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Label Medium: 12px, w500 - Chip labels, tags
  static const TextStyle labelMediumBase = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  /// Label Small: 11px, w500 - Badges, small labels
  static const TextStyle labelSmallBase = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  // ==================== Empty State Constants ====================
  /// Empty state icon size: 48px
  static const double emptyStateIconSize = 48;
  /// Empty state title size: 16px
  static const double emptyStateTitleSize = 16;
  /// Empty state subtitle size: 14px
  static const double emptyStateSubtitleSize = 14;

  // ==================== Standard Decorations ====================

  /// Get standard card decoration
  static BoxDecoration cardDecoration({
    required bool isDark,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: borderRadiusLarge,
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        width: 1,
      ),
      boxShadow: elevated ? getShadowElevated(isDark) : getShadow(isDark),
    );
  }

  /// Get button decoration
  static BoxDecoration buttonDecoration({
    required bool isDark,
    required bool isPrimary,
    bool isEnabled = true,
  }) {
    if (isPrimary) {
      return BoxDecoration(
        color: isEnabled
            ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: borderRadiusMedium,
      );
    }
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: borderRadiusMedium,
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        width: 1.5,
      ),
    );
  }
}
