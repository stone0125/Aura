import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/ai_coach_models.dart';
import '../models/habit_category.dart';

/// Provider for managing AI Coach data and state
class AICoachProvider with ChangeNotifier {
  AICoachTab _currentTab = AICoachTab.suggestions;
  List<AICoachSuggestion> _suggestions = [];
  WeeklyAISummary? _weeklySummary;
  List<AIPattern> _patterns = [];
  Map<TipCategory, List<AITip>> _tipsByCategory = {};
  TipCategory? _expandedTipCategory;
  bool _isLoadingSuggestions = false;
  bool _isLoadingInsights = false;
  bool _isLoadingTips = false;

  // Getters
  AICoachTab get currentTab => _currentTab;
  List<AICoachSuggestion> get suggestions => _suggestions;
  WeeklyAISummary? get weeklySummary => _weeklySummary;
  List<AIPattern> get patterns => _patterns;
  Map<TipCategory, List<AITip>> get tipsByCategory => _tipsByCategory;
  TipCategory? get expandedTipCategory => _expandedTipCategory;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  bool get isLoadingInsights => _isLoadingInsights;
  bool get isLoadingTips => _isLoadingTips;

  /// Initialize AI coach data
  Future<void> initialize() async {
    await loadTips();
  }

  /// Change active tab
  void setTab(AICoachTab tab) {
    _currentTab = tab;
    notifyListeners();
  }

  /// Load AI suggestions
  Future<void> loadSuggestions({
    required List<String> categories,
    required List<String> currentHabits,
  }) async {
    _isLoadingSuggestions = true;
    notifyListeners();

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateHabitSuggestions');
      final result = await callable.call({
        'categories': categories,
        'currentHabits': currentHabits,
      });

      final List<dynamic> data = result.data;
      _suggestions = data.map((item) {
        return AICoachSuggestion(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate ID
          title: item['habitName'] ?? 'New Habit',
          description: item['explanation'] ?? '',
          whyThisHelps: item['reason'] ?? '',
          category: HabitCategory.values.firstWhere(
            (e) => e.name == item['category'],
            orElse: () => HabitCategory.health,
          ),
          icon: Icons.lightbulb_outline, // Default icon
          estimatedImpact: 'Medium', // Default
          estimatedMinutes: 15, // Default
          suggestedAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      // Fallback to empty or error state
      _suggestions = [];
    } finally {
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }

  /// Load insights (weekly summary and patterns)
  Future<void> loadInsights({required Map<String, dynamic> weekData}) async {
    _isLoadingInsights = true;
    notifyListeners();

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateWeeklyInsights');
      final result = await callable.call({'weekData': weekData});

      final data = result.data;
      _weeklySummary = WeeklyAISummary(
        weekRange: 'Current Week', // Should be dynamic
        totalCompletions: weekData['totalCompletions'] ?? 0,
        targetCompletions: 0, // Calculate or pass
        completionRate: 0.0, // Calculate
        currentStreak: weekData['currentStreak'] ?? 0,
        topCategory: 'General', // Calculate
        insight: data['summary'] ?? 'Keep going!',
        encouragement: data['improvement'] ?? 'You can do it!',
        highlights: [data['pattern'] ?? 'Consistent effort'],
      );

      // Patterns could also be parsed if the function returns them
      _patterns = [];
    } catch (e) {
      debugPrint('Error loading insights: $e');
    } finally {
      _isLoadingInsights = false;
      notifyListeners();
    }
  }

  /// Load tips by category
  Future<void> loadTips() async {
    _isLoadingTips = true;
    notifyListeners();

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateHabitTips');
      final result = await callable.call();

      final List<dynamic> data = result.data;

      // Initialize map with empty lists for all categories
      _tipsByCategory = {for (var category in TipCategory.values) category: []};

      for (var item in data) {
        final categoryStr = item['category'];
        // Map string to enum
        final category = TipCategory.values.firstWhere(
          (e) =>
              e.name == categoryStr ||
              e.toString().split('.').last == categoryStr,
          orElse: () => TipCategory.gettingStarted,
        );

        final tip = AITip(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              item['title'].hashCode.toString(),
          title: item['title'] ?? 'New Tip',
          content: item['content'] ?? '',
          category: category,
          keyPoints: List<String>.from(item['keyPoints'] ?? []),
          actionable: item['actionable'] ?? '',
          icon: _getCategoryIcon(category),
        );

        _tipsByCategory[category]?.add(tip);
      }
    } catch (e) {
      debugPrint('Error loading tips: $e');
      // Keep empty or show error
    } finally {
      _isLoadingTips = false;
      notifyListeners();
    }
  }

  IconData _getCategoryIcon(TipCategory category) {
    switch (category) {
      case TipCategory.gettingStarted:
        return Icons.rocket_launch_rounded;
      case TipCategory.stayingConsistent:
        return Icons.refresh_rounded;
      case TipCategory.overcomingChallenges:
        return Icons.warning_amber_rounded;
      case TipCategory.advancedStrategies:
        return Icons.swap_horiz_rounded;
      case TipCategory.mindsetAndMotivation:
        return Icons.lightbulb_outline_rounded;
    }
  }

  /// Dismiss a suggestion
  void dismissSuggestion(String suggestionId) {
    _suggestions.removeWhere((s) => s.id == suggestionId);
    notifyListeners();
  }

  /// Toggle tip category expansion
  void toggleTipCategory(TipCategory category) {
    if (_expandedTipCategory == category) {
      _expandedTipCategory = null;
    } else {
      _expandedTipCategory = category;
    }
    notifyListeners();
  }

  /// Toggle tip bookmark
  void toggleTipBookmark(String tipId) {
    for (var category in _tipsByCategory.keys) {
      final tips = _tipsByCategory[category]!;
      final index = tips.indexWhere((t) => t.id == tipId);
      if (index != -1) {
        final tip = tips[index];
        _tipsByCategory[category]![index] = tip.copyWith(
          isBookmarked: !tip.isBookmarked,
        );
        notifyListeners();
        return;
      }
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await loadTips();
  }
}
