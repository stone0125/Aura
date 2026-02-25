import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/ai_coach_models.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import '../config/habit_icons.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing AI Coach data and state
class AICoachProvider with ChangeNotifier {
  final FirebaseFunctions? _firebaseFunctions;
  final SubscriptionService _subscriptionService = SubscriptionService();

  AICoachProvider({FirebaseFunctions? functions})
    : _firebaseFunctions = functions;

  AICoachTab _currentTab = AICoachTab.suggestions;
  List<AICoachSuggestion> _suggestions = [];
  WeeklyAISummary? _weeklySummary;
  List<AIPattern> _patterns = [];
  Map<TipCategory, List<AITip>> _tipsByCategory = {};
  TipCategory? _expandedTipCategory;
  List<AIActionItem> _actionItems = [];
  bool _isLoadingSuggestions = false;
  bool _isLoadingInsights = false;
  bool _isLoadingTips = false;
  bool _isLoadingActions = false;
  final Set<String> _inProgressOps = {};
  String? _suggestionsError;
  String? _actionsError;
  bool _usedFallback = false;
  DateTime? _lastSuggestionRefreshTime;
  static const Duration _refreshCooldown = Duration(minutes: 5);

  // Getters
  AICoachTab get currentTab => _currentTab;
  List<AICoachSuggestion> get suggestions => _suggestions;
  WeeklyAISummary? get weeklySummary => _weeklySummary;
  List<AIPattern> get patterns => _patterns;
  Map<TipCategory, List<AITip>> get tipsByCategory => _tipsByCategory;
  TipCategory? get expandedTipCategory => _expandedTipCategory;
  List<AIActionItem> get actionItems => _actionItems;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  bool get isLoadingInsights => _isLoadingInsights;
  bool get isLoadingTips => _isLoadingTips;
  bool get isLoadingActions => _isLoadingActions;
  String? get suggestionsError => _suggestionsError;
  String? get actionsError => _actionsError;
  bool get usedFallback => _usedFallback;

  /// Whether the refresh button should be enabled (not loading and not in cooldown)
  bool get canRefreshSuggestions {
    if (_isLoadingSuggestions) return false;
    if (_lastSuggestionRefreshTime == null) return true;
    return DateTime.now().difference(_lastSuggestionRefreshTime!) >= _refreshCooldown;
  }

  /// Seconds remaining in cooldown (0 if no cooldown active)
  int get refreshCooldownRemaining {
    if (_lastSuggestionRefreshTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastSuggestionRefreshTime!);
    final remaining = _refreshCooldown - elapsed;
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  /// Formatted cooldown remaining string (e.g. "4:32" or "0:05")
  String get refreshCooldownFormatted {
    final total = refreshCooldownRemaining;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if user can use AI suggestions (subscription limit)
  bool get canUseAISuggestion => _subscriptionService.canUseAISuggestion();

  /// Get remaining AI suggestions for today
  int get remainingAISuggestions =>
      _subscriptionService.getRemainingAISuggestions();

  /// Check if user can use AI reports this month
  bool get canUseAIReport => _subscriptionService.canUseAIReport();

  /// Get remaining AI reports for this month
  int get remainingAIReports => _subscriptionService.getRemainingAIReports();

  /// Build a sorted list of completed habit IDs for snapshot comparison
  static List<String> buildCompletionSnapshot(List<Habit> habits) {
    final ids = habits.where((h) => h.isCompleted).map((h) => h.id).toList()
      ..sort();
    return ids;
  }

  /// Check if the weekly summary is outdated compared to current habit state
  bool isWeeklySummaryOutdated(List<Habit> habits) {
    final summary = _weeklySummary;
    if (summary == null) return false;
    final current = buildCompletionSnapshot(habits);
    return !listEquals(current, summary.completionSnapshot);
  }

  void clearActionsError() {
    _actionsError = null;
  }

  // Cache Keys
  static const String _suggestionsCacheKey = 'ai_suggestions_cache';
  static const String _insightsCacheKey = 'ai_insights_cache';
  static const String _tipsCacheKey = 'ai_tips_cache';
  static const String _actionsCacheKey = 'ai_actions_cache';
  static const String _patternsCacheKey = 'ai_patterns_cache';
  /// Helper to get cached data if valid
  Future<dynamic> _getCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return null;

      final Map<String, dynamic> cache = jsonDecode(jsonStr);
      final DateTime timestamp = DateTime.parse(cache['timestamp']);

      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      if (timestamp.isBefore(todayMidnight)) {
        // Cache is from a previous day — expired
        await prefs.remove(key);
        return null;
      }
      return cache['data'];
    } catch (e) {
      debugPrint('Error reading cache for $key: $e');
      return null;
    }
  }

  /// Helper to save data to cache
  Future<void> _cacheData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      await prefs.setString(key, jsonEncode(cache));
    } catch (e) {
      debugPrint('Error saving cache for $key: $e');
    }
  }

  /// Clear suggestions cache when habits change
  /// Call this when user adds or removes habits
  Future<void> clearSuggestionsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_suggestionsCacheKey);
      _suggestions = [];
      debugPrint('🧹 AI suggestions cache cleared');
    } catch (e) {
      debugPrint('Error clearing suggestions cache: $e');
    }
  }

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
  /// Returns false if rate limited, true otherwise
  Future<bool> loadSuggestions({
    required List<String> categories,
    required List<String> currentHabits,
    double completionRate = 0,
    int bestStreak = 0,
    bool forceRefresh = false,
  }) async {
    if (_inProgressOps.contains('suggestions')) return false;
    _inProgressOps.add('suggestions');
    _isLoadingSuggestions = true;
    notifyListeners();

    try {
      // 1. Check Cache first (doesn't count against rate limit)
      if (!forceRefresh) {
        try {
          final cachedData = await _getCachedData(_suggestionsCacheKey);
          if (cachedData != null && cachedData is List) {
            final List<dynamic> list = cachedData;
            _suggestions = list
                .map((item) {
                  try {
                    return AICoachSuggestion.fromJson(item);
                  } catch (e) {
                    debugPrint('Error parsing cached suggestion: $e');
                    return null;
                  }
                })
                .whereType<AICoachSuggestion>()
                .toList();
            if (_suggestions.isNotEmpty) {
              _isLoadingSuggestions = false;
              notifyListeners(); // Early return needs notification
              return true;
            }
          }
        } catch (e) {
          debugPrint('Cache validation failed, fetching fresh data: $e');
          // Continue to fetch fresh data if cache is corrupted
        }
      }

      // 2. Check subscription limits before making API call
      if (!_subscriptionService.canUseAISuggestion()) {
        final tier = _subscriptionService.currentTier;
        _suggestionsError =
            'Daily AI suggestion limit reached (${tier.maxAISuggestionsPerDay} per day on ${tier.displayName}). '
            'Upgrade for more suggestions.';
        _suggestions = _getDefaultSuggestions();
        _usedFallback = true;
        _isLoadingSuggestions = false;
        notifyListeners(); // Early return needs notification
        return false;
      }

      // 3. Fetch from API with user stats for personalization
      final functions = _firebaseFunctions ?? FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateHabitSuggestions');
      final result = await callable.call({
        'categories': categories,
        'currentHabits': currentHabits,
        'userStats': {
          'completionRate': completionRate,
          'bestStreak': bestStreak,
          'totalHabits': currentHabits.length,
        },
      });

      // Validate response data structure
      final responseData = result.data;
      if (responseData == null || responseData is! List) {
        throw FormatException('Invalid response format: expected List');
      }
      final List<dynamic> data = responseData;

      _suggestions = data.asMap().entries.map((entry) {
        final item = entry.value;
        final index = entry.key;
        // Validate each item is a Map
        if (item == null || item is! Map) {
          return null;
        }
        final map = Map<String, dynamic>.from(item);
        final category = HabitCategory.values.firstWhere(
          (e) => e.name == map['category']?.toString().toLowerCase(),
          orElse: () {
            debugPrint('Unknown category "${map['category']}", defaulting to health');
            return HabitCategory.health;
          },
        );
        return AICoachSuggestion(
          id: '${DateTime.now().millisecondsSinceEpoch}_$index', // Unique ID per item
          title: map['habitName']?.toString() ?? 'New Habit',
          description: map['explanation']?.toString() ?? '',
          whyThisHelps: map['reason']?.toString() ?? '',
          category: category,
          icon: HabitIcons.getDefaultIconForCategory(category.name),
          estimatedImpact: map['estimatedImpact']?.toString() ?? 'Medium',
          estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 15,
          suggestedAt: DateTime.now(),
          frequencyType: map['frequencyType']?.toString() ?? 'daily',
          weeklyDays: map['weeklyDays'] is List
              ? List<int>.from((map['weeklyDays'] as List).map((e) => (e as num?)?.toInt() ?? 0))
              : null,
          goalType: map['goalType']?.toString() ?? 'none',
          goalValue: (map['goalValue'] as num?)?.toInt(),
          goalUnit: map['goalUnit']?.toString(),
          suggestedReminderHour: (map['suggestedReminderHour'] as num?)?.toInt(),
          suggestedReminderMinute: (map['suggestedReminderMinute'] as num?)?.toInt(),
        );
      }).whereType<AICoachSuggestion>().toList();

      // 4. Record usage and save to cache
      await _subscriptionService.recordAISuggestionUsage();
      final cacheData = _suggestions.map((s) => s.toJson()).toList();
      await _cacheData(_suggestionsCacheKey, cacheData);
      _suggestionsError = null;
      _usedFallback = false;
      return true;
    } catch (e) {
      debugPrint('Error loading suggestions (${e.runtimeType}): $e');
      // Fallback to default suggestions when Cloud Function fails
      _suggestions = _getDefaultSuggestions();
      _suggestionsError =
          'Unable to get personalized suggestions. Using defaults.';
      _usedFallback = true;
      debugPrint('Fallback: ${_suggestions.length} default suggestions');
      return false;
    } finally {
      _inProgressOps.remove('suggestions');
      _isLoadingSuggestions = false;
      if (forceRefresh) {
        _lastSuggestionRefreshTime = DateTime.now();
      }
      notifyListeners();
    }
  }

  /// Default suggestions when Cloud Functions fail
  List<AICoachSuggestion> _getDefaultSuggestions() {
    return [
      AICoachSuggestion(
        id: 'default_1',
        title: 'Morning Meditation',
        description:
            'Start your day with 5 minutes of mindfulness to improve focus and reduce stress.',
        whyThisHelps: 'Builds mental clarity and emotional resilience',
        category: HabitCategory.mindfulness,
        icon: Icons.self_improvement,
        estimatedImpact: 'High',
        estimatedMinutes: 5,
        suggestedAt: DateTime.now(),
        frequencyType: 'daily',
        goalType: 'time',
        goalValue: 5,
        goalUnit: 'minutes',
        suggestedReminderHour: 7,
        suggestedReminderMinute: 0,
      ),
      AICoachSuggestion(
        id: 'default_2',
        title: 'Daily Reading',
        description:
            'Read for 15 minutes daily to expand knowledge and improve cognitive function.',
        whyThisHelps: 'Enhances vocabulary and critical thinking',
        category: HabitCategory.learning,
        icon: Icons.menu_book,
        estimatedImpact: 'Medium',
        estimatedMinutes: 15,
        suggestedAt: DateTime.now(),
        frequencyType: 'daily',
        goalType: 'time',
        goalValue: 15,
        goalUnit: 'minutes',
        suggestedReminderHour: 21,
        suggestedReminderMinute: 0,
      ),
      AICoachSuggestion(
        id: 'default_3',
        title: 'Evening Walk',
        description:
            'Take a 20-minute walk after dinner to aid digestion and improve sleep quality.',
        whyThisHelps: 'Promotes physical health and better rest',
        category: HabitCategory.fitness,
        icon: Icons.directions_walk,
        estimatedImpact: 'High',
        estimatedMinutes: 20,
        suggestedAt: DateTime.now(),
        frequencyType: 'daily',
        goalType: 'time',
        goalValue: 20,
        goalUnit: 'minutes',
        suggestedReminderHour: 18,
        suggestedReminderMinute: 30,
      ),
    ];
  }

  /// Load insights (weekly summary and patterns)
  Future<void> loadInsights({
    required Map<String, dynamic> weekData,
    List<Habit> habits = const [],
    bool forceRefresh = false,
  }) async {
    if (_inProgressOps.contains('insights')) return;
    _inProgressOps.add('insights');
    _isLoadingInsights = true;
    notifyListeners();

    try {
      Map<String, dynamic>? data;

      // 1. Check Cache
      if (!forceRefresh) {
        final cached = await _getCachedData(_insightsCacheKey);
        if (cached != null) {
          data = Map<String, dynamic>.from(cached);
        }
      }

      // 2. Fetch from API if needed
      if (data == null) {
        // Check monthly AI report limit
        if (!_subscriptionService.canUseAIReport()) {
          _isLoadingInsights = false;
          notifyListeners();
          return;
        }

        final functions = _firebaseFunctions ?? FirebaseFunctions.instance;
        final callable = functions.httpsCallable('generateWeeklyInsights');
        final result = await callable.call({'weekData': weekData});
        final rawData = result.data;
        if (rawData == null || rawData is! Map) {
          throw FormatException('Invalid insights response');
        }
        data = Map<String, dynamic>.from(rawData);

        // Record usage after successful API call
        await _subscriptionService.recordAIReportUsage();

        // 3. Save Cache (AI text parts + completion snapshot)
        final snapshot = buildCompletionSnapshot(habits);
        data['completionSnapshot'] = snapshot;
        await _cacheData(_insightsCacheKey, data);
      }

      // 4. Construct Summary (Fresh stats + AI text)
      final snapshot = data['completionSnapshot'] is List
          ? List<String>.from(data['completionSnapshot'])
          : buildCompletionSnapshot(habits);
      // Parse nextSteps from AI response
      List<AINextStep> nextSteps = [];
      if (data['nextSteps'] is List) {
        nextSteps = (data['nextSteps'] as List)
            .whereType<Map>()
            .map((e) => AINextStep.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      _weeklySummary = WeeklyAISummary(
        weekRange: 'Current Week',
        totalCompletions: weekData['totalCompletions'] ?? 0,
        targetCompletions: 0, // Calculate or pass
        completionRate: 0.0, // Calculate
        currentStreak: weekData['currentStreak'] ?? 0,
        topCategory: 'General',
        insight: data['summary'] ?? 'Keep going!',
        encouragement: data['improvement'] ?? 'You can do it!',
        highlights: data['pattern'] != null
            ? [data['pattern']]
            : ['Consistent effort'],
        completionSnapshot: snapshot,
        nextSteps: nextSteps,
      );
    } catch (e) {
      debugPrint('Error loading insights: $e');
    } finally {
      _inProgressOps.remove('insights');
      _isLoadingInsights = false;
      notifyListeners();
    }
  }

  /// Load AI-discovered patterns from habit completion history
  Future<void> loadPatterns({
    required List<Map<String, dynamic>> habitsData,
    bool forceRefresh = false,
  }) async {
    if (_inProgressOps.contains('patterns')) return;
    _inProgressOps.add('patterns');
    // Don't set _isLoadingInsights — patterns load independently
    try {
      // 1. Check cache first
      if (!forceRefresh) {
        try {
          final cachedData = await _getCachedData(_patternsCacheKey);
          if (cachedData != null && cachedData is List) {
            final cached = cachedData
                .map((item) {
                  try {
                    return AIPattern.fromJson(Map<String, dynamic>.from(item));
                  } catch (e) {
                    debugPrint('Error parsing cached pattern: $e');
                    return null;
                  }
                })
                .whereType<AIPattern>()
                .toList();
            if (cached.isNotEmpty) {
              _patterns = cached;
              notifyListeners();
              return;
            }
          }
        } catch (e) {
          debugPrint('Patterns cache read failed: $e');
        }
      }

      // 2. Check monthly AI report limit
      if (!_subscriptionService.canUseAIReport()) {
        notifyListeners();
        return;
      }

      // 3. Call Cloud Function
      final functions = _firebaseFunctions ?? FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generatePatternDiscovery');
      final result = await callable.call({'habits': habitsData});

      final responseData = result.data;
      if (responseData == null || responseData is! Map) {
        throw FormatException('Invalid pattern discovery response');
      }
      final data = Map<String, dynamic>.from(responseData);

      // Check for insufficient data reason
      if (data['reason'] == 'insufficient_data') {
        _patterns = [];
        notifyListeners();
        return;
      }

      final rawPatterns = data['patterns'];
      if (rawPatterns == null || rawPatterns is! List) {
        _patterns = [];
        notifyListeners();
        return;
      }

      _patterns = rawPatterns.asMap().entries.map((entry) {
        final item = entry.value;
        if (item == null || item is! Map) return null;
        final map = Map<String, dynamic>.from(item);
        map['id'] = 'pattern_${DateTime.now().millisecondsSinceEpoch}_${entry.key}';
        map['discoveredAt'] = DateTime.now().toIso8601String();
        return AIPattern.fromJson(map);
      }).whereType<AIPattern>().toList();

      // Record usage after successful API call
      await _subscriptionService.recordAIReportUsage();

      // 4. Cache results
      final cacheData = _patterns.map((p) => p.toJson()).toList();
      await _cacheData(_patternsCacheKey, cacheData);
    } catch (e) {
      debugPrint('Error loading patterns (${e.runtimeType}): $e');
      _patterns = [];
    } finally {
      _inProgressOps.remove('patterns');
      notifyListeners();
    }
  }

  /// Load tips by category (personalized if user data provided)
  Future<void> loadTips({
    List<String> userHabits = const [],
    double completionRate = 0,
    int bestStreak = 0,
    int totalCompletions = 0,
    bool forceRefresh = false,
  }) async {
    if (_inProgressOps.contains('tips')) return;
    _inProgressOps.add('tips');
    _isLoadingTips = true;
    notifyListeners();

    try {
      // 1. Check Cache with validation
      if (!forceRefresh) {
        try {
          final cachedData = await _getCachedData(_tipsCacheKey);
          if (cachedData != null && cachedData is List) {
            final List<dynamic> list = cachedData;
            final allTips = list
                .map((item) {
                  try {
                    return AITip.fromJson(item);
                  } catch (e) {
                    debugPrint('Error parsing cached tip: $e');
                    return null;
                  }
                })
                .whereType<AITip>()
                .toList();
            if (allTips.isNotEmpty) {
              _bucketTips(allTips);
              _isLoadingTips = false;
              notifyListeners();
              return;
            }
          }
        } catch (e) {
          debugPrint('Tips cache validation failed, fetching fresh data: $e');
          // Continue to fetch fresh data if cache is corrupted
        }
      }

      // 2. Check monthly AI report limit
      if (!_subscriptionService.canUseAIReport()) {
        _isLoadingTips = false;
        notifyListeners();
        return;
      }

      // 3. Fetch from API with user data for personalization
      final functions = _firebaseFunctions ?? FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateHabitTips');
      final result = await callable.call({
        'userHabits': userHabits,
        'completionRate': completionRate,
        'bestStreak': bestStreak,
        'totalCompletions': totalCompletions,
      });

      // Validate response data structure
      final responseData = result.data;
      if (responseData == null || responseData is! List) {
        throw FormatException('Invalid tips response format: expected List');
      }
      final List<dynamic> data = responseData;
      final List<AITip> allTips = [];

      for (var item in data) {
        // Skip invalid items
        if (item == null || item is! Map) continue;
        final map = Map<String, dynamic>.from(item);

        final categoryStr = map['category']?.toString();
        final category = TipCategory.values.firstWhere(
          (e) =>
              e.name == categoryStr ||
              e.toString().split('.').last == categoryStr,
          orElse: () => TipCategory.gettingStarted,
        );

        // Safely parse keyPoints
        List<String> keyPoints = [];
        if (map['keyPoints'] is List) {
          keyPoints = (map['keyPoints'] as List)
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList();
        }

        final tip = AITip(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              (map['title']?.hashCode ?? 0).toString(),
          title: map['title']?.toString() ?? 'New Tip',
          content: map['content']?.toString() ?? '',
          category: category,
          keyPoints: keyPoints,
          actionable: map['actionable']?.toString() ?? '',
          icon: category.icon,
        );
        allTips.add(tip);
      }

      // 4. Record usage and bucket/save
      await _subscriptionService.recordAIReportUsage();
      _bucketTips(allTips);

      final cacheData = allTips.map((t) => t.toJson()).toList();
      await _cacheData(_tipsCacheKey, cacheData);
    } catch (e) {
      debugPrint('Error loading tips: $e');
    } finally {
      _inProgressOps.remove('tips');
      _isLoadingTips = false;
      notifyListeners();
    }
  }

  void _bucketTips(List<AITip> tips) {
    _tipsByCategory = {for (var category in TipCategory.values) category: []};
    for (var tip in tips) {
      _tipsByCategory[tip.category]?.add(tip);
    }
  }

  /// Load personalized action items
  Future<void> loadActionItems({
    List<Map<String, dynamic>> habits = const [],
    double completionRate = 0,
    int bestStreak = 0,
    bool forceRefresh = false,
  }) async {
    if (_inProgressOps.contains('actions')) return;
    _inProgressOps.add('actions');
    _isLoadingActions = true;
    _actionsError = null;
    notifyListeners();

    try {
      // 1. Check cache first
      if (!forceRefresh) {
        try {
          final cachedData = await _getCachedData(_actionsCacheKey);
          if (cachedData != null && cachedData is List) {
            final items = cachedData
                .map((item) {
                  try {
                    return AIActionItem.fromJson(
                        Map<String, dynamic>.from(item));
                  } catch (e) {
                    return null;
                  }
                })
                .whereType<AIActionItem>()
                .toList();
            // Check if cache is within 12-hour window
            if (items.isNotEmpty) {
              _actionItems = items;
              _isLoadingActions = false;
              notifyListeners();
              return;
            }
          }
        } catch (e) {
          debugPrint('Actions cache read failed: $e');
        }
      }

      // 2. Check monthly AI report limit
      if (!_subscriptionService.canUseAIReport()) {
        _actionsError = 'Monthly AI report limit reached. Upgrade for more reports.';
        _isLoadingActions = false;
        notifyListeners();
        return;
      }

      // 3. Call Cloud Function
      final functions = _firebaseFunctions ?? FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateActionItems');
      final result = await callable.call({
        'habits': habits,
        'completionRate': completionRate,
        'bestStreak': bestStreak,
      });

      final responseData = result.data;
      if (responseData == null || responseData is! List) {
        throw FormatException('Invalid action items response');
      }

      _actionItems = responseData.map((item) {
        if (item == null || item is! Map) return null;
        final map = Map<String, dynamic>.from(item);
        return AIActionItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              (map['title']?.hashCode ?? 0).toString(),
          title: map['title']?.toString() ?? 'Action Item',
          description: map['description']?.toString() ?? '',
          type: _parseActionType(map['type']?.toString()),
          priority: _parseActionPriority(map['priority']?.toString()),
          relatedHabit: map['relatedHabit']?.toString(),
          relatedHabitId: map['relatedHabitId']?.toString(),
          metric: map['metric']?.toString(),
          createdAt: DateTime.now(),
        );
      }).whereType<AIActionItem>().toList();

      // Record usage after successful API call
      await _subscriptionService.recordAIReportUsage();

      // 4. Cache
      final cacheData = _actionItems.map((a) => a.toJson()).toList();
      await _cacheData(_actionsCacheKey, cacheData);
    } catch (e) {
      debugPrint('Error loading action items (${e.runtimeType}): $e');
      if (_actionItems.isEmpty) {
        _actionItems = _getDefaultActionItems();
      }
      if (forceRefresh) {
        _actionsError = 'Failed to refresh actions. Showing previous results.';
      }
    } finally {
      _inProgressOps.remove('actions');
      _isLoadingActions = false;
      notifyListeners();
    }
  }

  ActionItemType _parseActionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'daily':
        return ActionItemType.daily;
      case 'weekly':
        return ActionItemType.weekly;
      case 'challenge':
        return ActionItemType.challenge;
      default:
        return ActionItemType.daily;
    }
  }

  ActionPriority _parseActionPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return ActionPriority.high;
      case 'medium':
        return ActionPriority.medium;
      case 'low':
        return ActionPriority.low;
      default:
        return ActionPriority.medium;
    }
  }

  /// Mark an action item as completed
  void completeActionItem(String actionId) {
    final index = _actionItems.indexWhere((a) => a.id == actionId);
    if (index != -1) {
      _actionItems[index] = _actionItems[index].copyWith(
        isCompleted: !_actionItems[index].isCompleted,
      );
      notifyListeners();
      // Update cache
      _cacheData(
        _actionsCacheKey,
        _actionItems.map((a) => a.toJson()).toList(),
      );
    }
  }

  List<AIActionItem> _getDefaultActionItems() {
    final now = DateTime.now();
    return [
      AIActionItem(
        id: 'default_action_1',
        title: 'Complete your morning routine first',
        description:
            'Research shows completing habits early in the day builds momentum for the rest of the day.',
        type: ActionItemType.daily,
        priority: ActionPriority.high,
        metric: 'Do it before 9am',
        createdAt: now,
      ),
      AIActionItem(
        id: 'default_action_2',
        title: 'Set a specific time for each habit',
        description:
            'Implementation intentions ("I will do X at Y time in Z location") increase follow-through by 2-3x.',
        type: ActionItemType.daily,
        priority: ActionPriority.medium,
        metric: 'Schedule all habits today',
        createdAt: now,
      ),
      AIActionItem(
        id: 'default_action_3',
        title: 'Review your weekly progress',
        description:
            'Take 5 minutes to look at your completion patterns and identify what worked.',
        type: ActionItemType.weekly,
        priority: ActionPriority.medium,
        metric: 'Spend 5 minutes on review',
        createdAt: now,
      ),
      AIActionItem(
        id: 'default_action_4',
        title: 'Try a 7-day streak challenge',
        description:
            'Pick your most important habit and commit to completing it every day this week.',
        type: ActionItemType.challenge,
        priority: ActionPriority.high,
        metric: 'Complete 7/7 days',
        createdAt: now,
      ),
    ];
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

  /// Clear all user-specific data on logout
  Future<void> clearUserData() async {
    _inProgressOps.clear();
    _suggestions = [];
    _weeklySummary = null;
    _patterns = [];
    _tipsByCategory = {};
    _expandedTipCategory = null;
    _actionItems = [];
    _isLoadingSuggestions = false;
    _isLoadingInsights = false;
    _isLoadingTips = false;
    _isLoadingActions = false;
    _suggestionsError = null;
    _usedFallback = false;
    _lastSuggestionRefreshTime = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_suggestionsCacheKey);
      await prefs.remove(_insightsCacheKey);
      await prefs.remove(_tipsCacheKey);
      await prefs.remove(_actionsCacheKey);
      await prefs.remove(_patternsCacheKey);
    } catch (e) {
      debugPrint('Error clearing AI coach caches: $e');
    }

    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await loadTips(forceRefresh: true);
  }
}
