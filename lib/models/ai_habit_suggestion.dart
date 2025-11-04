import 'habit_category.dart';

/// AI-generated habit suggestion model
class AIHabitSuggestion {
  final String id;
  final String habitName;
  final HabitCategory category;
  final String explanation;
  final String reason;

  const AIHabitSuggestion({
    required this.id,
    required this.habitName,
    required this.category,
    required this.explanation,
    required this.reason,
  });

  @override
  String toString() {
    return 'AIHabitSuggestion(id: $id, habitName: $habitName, category: $category, explanation: $explanation)';
  }
}
