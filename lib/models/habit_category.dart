import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';

/// Habit category enumeration
enum HabitCategory {
  health,
  learning,
  productivity,
  mindfulness,
  fitness,
}

/// Extension to provide category-specific properties
extension HabitCategoryExtension on HabitCategory {
  /// Get category display name
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
  List<Color> getGradient(Brightness brightness) {
    return brightness == Brightness.light ? getLightGradient() : getDarkGradient();
  }
}
