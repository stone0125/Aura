// =============================================================================
// habit_category.dart — Habit Category Enum
// 习惯类别枚举
//
// Defines the 5 habit categories: Health, Learning, Productivity, Mindfulness,
// and Fitness. Each category has a display name, icon, and gradient colors
// for both light and dark themes.
//
// 定义 5 个习惯类别：健康、学习、生产力、正念和健身。每个类别都有显示名称、
// 图标以及亮色和暗色主题的渐变颜色。
// =============================================================================

import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';

/// Habit category enumeration
/// 习惯类别枚举
enum HabitCategory {
  health,
  learning,
  productivity,
  mindfulness,
  fitness,
}

/// Extension to provide category-specific properties
/// 提供类别特定属性的扩展
extension HabitCategoryExtension on HabitCategory {
  /// Get category display name
  /// 获取类别显示名称
  String get displayName {
    switch (this) {
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.learning:
        return 'Learning';
      case HabitCategory.productivity:
        return 'Productivity';
      case HabitCategory.mindfulness:
        return 'Mindfulness';
      case HabitCategory.fitness:
        return 'Fitness';
    }
  }

  /// Get category icon
  /// 获取类别图标
  IconData get icon {
    switch (this) {
      case HabitCategory.health:
        return Icons.favorite_rounded;
      case HabitCategory.learning:
        return Icons.school_rounded;
      case HabitCategory.productivity:
        return Icons.work_rounded;
      case HabitCategory.mindfulness:
        return Icons.spa_rounded;
      case HabitCategory.fitness:
        return Icons.fitness_center_rounded;
    }
  }

  /// Get light mode gradient colors
  /// 获取浅色模式渐变颜色
  List<Color> getLightGradient() {
    switch (this) {
      case HabitCategory.health:
        return AppColors.healthGradientLight;
      case HabitCategory.learning:
        return AppColors.learningGradientLight;
      case HabitCategory.productivity:
        return AppColors.productivityGradientLight;
      case HabitCategory.mindfulness:
        return AppColors.mindfulnessGradientLight;
      case HabitCategory.fitness:
        return AppColors.fitnessGradientLight;
    }
  }

  /// Get dark mode gradient colors
  /// 获取深色模式渐变颜色
  List<Color> getDarkGradient() {
    switch (this) {
      case HabitCategory.health:
        return AppColors.healthGradientDark;
      case HabitCategory.learning:
        return AppColors.learningGradientDark;
      case HabitCategory.productivity:
        return AppColors.productivityGradientDark;
      case HabitCategory.mindfulness:
        return AppColors.mindfulnessGradientDark;
      case HabitCategory.fitness:
        return AppColors.fitnessGradientDark;
    }
  }

  /// Get gradient colors based on theme brightness
  /// 根据主题亮度获取渐变颜色
  List<Color> getGradient(Brightness brightness) {
    return brightness == Brightness.light ? getLightGradient() : getDarkGradient();
  }
}
