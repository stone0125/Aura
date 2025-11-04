import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/ai_habit_suggestion.dart';

/// Provider for managing habits data
class HabitProvider with ChangeNotifier {
  List<Habit> _habits = [];
  List<AIHabitSuggestion> _aiSuggestions = [];
  final bool _isLoadingHabits = false;
  bool _isLoadingSuggestions = false;

  HabitProvider() {
    _loadMockData();
  }

  // Getters
  List<Habit> get habits => _habits;
  List<Habit> get todaysHabits => _habits;
  List<AIHabitSuggestion> get aiSuggestions => _aiSuggestions;
  bool get isLoadingHabits => _isLoadingHabits;
  bool get isLoadingSuggestions => _isLoadingSuggestions;

  /// Get completed habits count for today
  int get completedCount => _habits.where((h) => h.isCompleted).length;

  /// Get total habits count
  int get totalCount => _habits.length;

  /// Get completion rate (0.0 to 1.0)
  double get completionRate =>
      totalCount > 0 ? completedCount / totalCount : 0.0;

  /// Get best streak across all habits
  int get bestStreak =>
      _habits.isEmpty ? 0 : _habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

  /// Load mock data for demonstration
  void _loadMockData() {
    _habits = [
      const Habit(
        id: '1',
        name: 'Morning Meditation',
        category: HabitCategory.mindfulness,
        streak: 14,
        isCompleted: false,
      ),
      const Habit(
        id: '2',
        name: 'Drink 8 Glasses of Water',
        category: HabitCategory.health,
        streak: 7,
        isCompleted: false,
      ),
      const Habit(
        id: '3',
        name: 'Read for 30 Minutes',
        category: HabitCategory.learning,
        streak: 21,
        isCompleted: true,
      ),
      const Habit(
        id: '4',
        name: 'Exercise',
        category: HabitCategory.fitness,
        streak: 5,
        isCompleted: false,
      ),
      const Habit(
        id: '5',
        name: 'Complete Daily Tasks',
        category: HabitCategory.productivity,
        streak: 10,
        isCompleted: true,
      ),
      const Habit(
        id: '6',
        name: 'Evening Walk',
        category: HabitCategory.fitness,
        streak: 8,
        isCompleted: false,
      ),
      const Habit(
        id: '7',
        name: 'Healthy Breakfast',
        category: HabitCategory.health,
        streak: 15,
        isCompleted: true,
      ),
      const Habit(
        id: '8',
        name: 'Journal Writing',
        category: HabitCategory.mindfulness,
        streak: 3,
        isCompleted: false,
      ),
    ];

    _aiSuggestions = [
      const AIHabitSuggestion(
        id: 'ai-1',
        habitName: 'Practice Gratitude',
        category: HabitCategory.mindfulness,
        explanation: 'Write 3 things you\'re grateful for',
        reason: 'Complements your meditation habit',
      ),
      const AIHabitSuggestion(
        id: 'ai-2',
        habitName: 'Learn a New Skill',
        category: HabitCategory.learning,
        explanation: 'Spend 20 minutes on skill development',
        reason: 'Builds on your reading habit',
      ),
    ];

    notifyListeners();
  }

  /// Toggle habit completion status
  void toggleHabitCompletion(String habitId) {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _habits[index] = _habits[index].toggleCompletion();
      notifyListeners();
    }
  }

  /// Add new habit
  void addHabit(Habit habit) {
    _habits.add(habit);
    notifyListeners();
  }

  /// Remove habit
  void removeHabit(String habitId) {
    _habits.removeWhere((h) => h.id == habitId);
    notifyListeners();
  }

  /// Add AI suggestion as a habit
  void addAISuggestionAsHabit(AIHabitSuggestion suggestion) {
    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: suggestion.habitName,
      category: suggestion.category,
      streak: 0,
      isCompleted: false,
    );
    addHabit(newHabit);
    // Remove from suggestions
    _aiSuggestions.removeWhere((s) => s.id == suggestion.id);
    notifyListeners();
  }

  /// Refresh AI suggestions (simulate API call)
  Future<void> refreshAISuggestions() async {
    _isLoadingSuggestions = true;
    notifyListeners();

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate new mock suggestions
    _aiSuggestions = [
      const AIHabitSuggestion(
        id: 'ai-new-1',
        habitName: 'Deep Breathing Exercise',
        category: HabitCategory.mindfulness,
        explanation: '5 minutes of focused breathing',
        reason: 'Enhances your meditation practice',
      ),
      const AIHabitSuggestion(
        id: 'ai-new-2',
        habitName: 'Stretching Routine',
        category: HabitCategory.fitness,
        explanation: '10-minute flexibility workout',
        reason: 'Complements your exercise habit',
      ),
    ];

    _isLoadingSuggestions = false;
    notifyListeners();
  }
}
