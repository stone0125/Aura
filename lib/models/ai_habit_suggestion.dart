// =============================================================================
// ai_habit_suggestion.dart — AI Habit Suggestion Model
// AI 习惯建议模型
//
// Lightweight model for AI-suggested habits. Contains habit name, category,
// explanation, and reason. Used when the AI recommends new habits for the user.
//
// AI 建议习惯的轻量级模型。包含习惯名称、类别、解释和原因。
// 当 AI 为用户推荐新习惯时使用。
// =============================================================================

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
