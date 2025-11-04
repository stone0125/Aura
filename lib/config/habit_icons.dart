import 'package:flutter/material.dart';

/// Available habit icons
class HabitIcons {
  static const List<HabitIconData> icons = [
    HabitIconData(icon: Icons.self_improvement_rounded, label: 'Meditation'),
    HabitIconData(icon: Icons.directions_run_rounded, label: 'Running'),
    HabitIconData(icon: Icons.menu_book_rounded, label: 'Reading'),
    HabitIconData(icon: Icons.edit_rounded, label: 'Writing'),
    HabitIconData(icon: Icons.water_drop_rounded, label: 'Water'),
    HabitIconData(icon: Icons.apple_rounded, label: 'Healthy eating'),
    HabitIconData(icon: Icons.fitness_center_rounded, label: 'Exercise'),
    HabitIconData(icon: Icons.track_changes_rounded, label: 'Goal'),
    HabitIconData(icon: Icons.alarm_rounded, label: 'Wake up'),
    HabitIconData(icon: Icons.nightlight_rounded, label: 'Sleep'),
    HabitIconData(icon: Icons.palette_rounded, label: 'Creative'),
    HabitIconData(icon: Icons.phone_android_rounded, label: 'Digital detox'),
    HabitIconData(icon: Icons.school_rounded, label: 'Learning'),
    HabitIconData(icon: Icons.work_rounded, label: 'Work'),
    HabitIconData(icon: Icons.music_note_rounded, label: 'Music'),
    HabitIconData(icon: Icons.energy_savings_leaf_rounded, label: 'Growth'),
    HabitIconData(icon: Icons.coffee_rounded, label: 'Coffee'),
    HabitIconData(icon: Icons.directions_bike_rounded, label: 'Cycling'),
    HabitIconData(icon: Icons.restaurant_rounded, label: 'Nutrition'),
    HabitIconData(icon: Icons.favorite_rounded, label: 'Health'),
    HabitIconData(icon: Icons.wb_sunny_rounded, label: 'Morning routine'),
    HabitIconData(icon: Icons.beach_access_rounded, label: 'Relaxation'),
    HabitIconData(icon: Icons.flash_on_rounded, label: 'Energy'),
    HabitIconData(icon: Icons.emoji_emotions_rounded, label: 'Mood'),
    HabitIconData(icon: Icons.bathtub_rounded, label: 'Self-care'),
    HabitIconData(icon: Icons.pets_rounded, label: 'Pet care'),
    HabitIconData(icon: Icons.cleaning_services_rounded, label: 'Cleaning'),
    HabitIconData(icon: Icons.calendar_today_rounded, label: 'Planning'),
    HabitIconData(icon: Icons.loyalty_rounded, label: 'Gratitude'),
    HabitIconData(icon: Icons.lightbulb_rounded, label: 'Ideas'),
  ];

  /// Get default icon for category
  static IconData getDefaultIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Icons.favorite_rounded;
      case 'learning':
        return Icons.school_rounded;
      case 'productivity':
        return Icons.work_rounded;
      case 'mindfulness':
        return Icons.self_improvement_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      default:
        return Icons.track_changes_rounded;
    }
  }
}

/// Habit icon data model
class HabitIconData {
  final IconData icon;
  final String label;

  const HabitIconData({
    required this.icon,
    required this.label,
  });
}
