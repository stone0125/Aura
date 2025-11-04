import 'package:flutter/material.dart';
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
    await Future.wait([
      loadSuggestions(),
      loadInsights(),
      loadTips(),
    ]);
  }

  /// Change active tab
  void setTab(AICoachTab tab) {
    _currentTab = tab;
    notifyListeners();
  }

  /// Load AI suggestions
  Future<void> loadSuggestions() async {
    _isLoadingSuggestions = true;
    notifyListeners();

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock data
    _suggestions = [
      AICoachSuggestion(
        id: '1',
        title: 'Morning Journaling',
        description: 'Write 3 things you\'re grateful for each morning',
        whyThisHelps: 'Starting your day with gratitude increases positivity and mental clarity. Studies show journaling reduces stress by 25% and improves focus.',
        category: HabitCategory.mindfulness,
        icon: Icons.edit_note_rounded,
        estimatedImpact: 'High',
        estimatedMinutes: 5,
        suggestedAt: DateTime.now(),
      ),
      AICoachSuggestion(
        id: '2',
        title: 'Afternoon Walk',
        description: 'Take a 15-minute walk after lunch',
        whyThisHelps: 'Afternoon walks boost energy, improve digestion, and break up sedentary time. This timing aligns with your natural energy dip and prevents afternoon slumps.',
        category: HabitCategory.fitness,
        icon: Icons.directions_walk_rounded,
        estimatedImpact: 'High',
        estimatedMinutes: 15,
        suggestedAt: DateTime.now(),
      ),
      AICoachSuggestion(
        id: '3',
        title: 'Tech-Free Evening',
        description: 'No screens 1 hour before bed',
        whyThisHelps: 'Blue light disrupts melatonin production, affecting sleep quality. Creating a tech-free wind-down routine can improve sleep by up to 40%.',
        category: HabitCategory.mindfulness,
        icon: Icons.nights_stay_rounded,
        estimatedImpact: 'Medium',
        estimatedMinutes: 60,
        suggestedAt: DateTime.now(),
      ),
      AICoachSuggestion(
        id: '4',
        title: 'Skill Practice',
        description: 'Dedicate 20 minutes to learning something new',
        whyThisHelps: 'Consistent daily practice is the key to mastery. Your completion patterns show you\'re most focused during evening hours.',
        category: HabitCategory.learning,
        icon: Icons.school_rounded,
        estimatedImpact: 'Medium',
        estimatedMinutes: 20,
        suggestedAt: DateTime.now(),
      ),
    ];

    _isLoadingSuggestions = false;
    notifyListeners();
  }

  /// Load insights (weekly summary and patterns)
  Future<void> loadInsights() async {
    _isLoadingInsights = true;
    notifyListeners();

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Mock weekly summary
    _weeklySummary = const WeeklyAISummary(
      weekRange: 'Oct 28 - Nov 3',
      totalCompletions: 32,
      targetCompletions: 35,
      completionRate: 0.91,
      currentStreak: 7,
      topCategory: 'Mindfulness',
      insight: 'You\'re crushing it this week! Your consistency has improved by 15% compared to last week.',
      encouragement: 'Keep up the amazing work! You\'re just 3 completions away from your weekly goal.',
      highlights: [
        'Perfect 7-day streak in progress',
        'Morning habits: 100% completion rate',
        'Best day: Tuesday (6/6 habits)',
        'Evening habits need attention',
      ],
    );

    // Mock patterns
    final now = DateTime.now();
    _patterns = [
      AIPattern(
        id: '1',
        title: 'You\'re a Morning Person',
        description: 'You complete 85% of your habits before noon',
        type: PatternType.timeOfDay,
        insight: 'Consider scheduling new habits in the morning when you\'re most consistent.',
        icon: Icons.wb_sunny_rounded,
        confidence: 0.89,
        discoveredAt: now.subtract(const Duration(days: 2)),
      ),
      AIPattern(
        id: '2',
        title: 'Meditation Triggers Success',
        description: 'You complete 60% more habits on days you meditate',
        type: PatternType.sequence,
        insight: 'Meditation seems to set a positive tone for your day. Try moving it earlier to maximize this effect.',
        icon: Icons.self_improvement_rounded,
        confidence: 0.76,
        discoveredAt: now.subtract(const Duration(days: 5)),
      ),
      AIPattern(
        id: '3',
        title: 'Weekend Warriors',
        description: 'Your Saturday completion rate is 95%',
        type: PatternType.dayOfWeek,
        insight: 'Weekends are your strong days. Use this momentum to prepare for the week ahead.',
        icon: Icons.weekend_rounded,
        confidence: 0.82,
        discoveredAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    _isLoadingInsights = false;
    notifyListeners();
  }

  /// Load tips by category
  Future<void> loadTips() async {
    _isLoadingTips = true;
    notifyListeners();

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Mock tips data
    _tipsByCategory = {
      TipCategory.gettingStarted: [
        const AITip(
          id: 'gs1',
          title: 'Start Small',
          content: 'Begin with habits that take less than 2 minutes. This reduces friction and builds momentum.',
          category: TipCategory.gettingStarted,
          keyPoints: [
            'Break down big habits into tiny steps',
            'Focus on showing up, not perfection',
            'Celebrate small wins',
          ],
          actionable: 'Choose one habit and reduce it to a 2-minute version today.',
          icon: Icons.rocket_launch_rounded,
        ),
        const AITip(
          id: 'gs2',
          title: 'Stack Your Habits',
          content: 'Link new habits to existing routines. "After I [existing habit], I will [new habit]."',
          category: TipCategory.gettingStarted,
          keyPoints: [
            'Use existing routines as triggers',
            'Create clear if-then plans',
            'Make the connection obvious',
          ],
          actionable: 'Write down: "After I brush my teeth, I will..."',
          icon: Icons.layers_rounded,
        ),
      ],
      TipCategory.stayingConsistent: [
        const AITip(
          id: 'sc1',
          title: 'Never Miss Twice',
          content: 'Missing once is an accident. Missing twice is the start of a new pattern. Get back on track immediately.',
          category: TipCategory.stayingConsistent,
          keyPoints: [
            'One slip doesn\'t break your streak mentally',
            'Focus on recovery, not perfection',
            'Have a comeback plan ready',
          ],
          actionable: 'Write down your comeback plan for when you miss a day.',
          icon: Icons.refresh_rounded,
        ),
        const AITip(
          id: 'sc2',
          title: 'Track Visually',
          content: 'Use a visual tracker to see your progress. The satisfaction of marking completion reinforces the behavior.',
          category: TipCategory.stayingConsistent,
          keyPoints: [
            'Visual progress is motivating',
            'Don\'t break the chain',
            'Celebrate milestones',
          ],
          icon: Icons.check_circle_outline_rounded,
        ),
      ],
      TipCategory.overcomingChallenges: [
        const AITip(
          id: 'oc1',
          title: 'Identify Your Obstacles',
          content: 'Most habit failures happen due to predictable obstacles. Identify yours and plan around them.',
          category: TipCategory.overcomingChallenges,
          keyPoints: [
            'Map out common obstacles',
            'Create if-then plans',
            'Reduce friction points',
          ],
          actionable: 'List your top 3 obstacles and write one solution for each.',
          icon: Icons.warning_amber_rounded,
        ),
        const AITip(
          id: 'oc2',
          title: 'Design Your Environment',
          content: 'Make good habits obvious and bad habits invisible. Your environment shapes your behavior.',
          category: TipCategory.overcomingChallenges,
          keyPoints: [
            'Visual cues trigger habits',
            'Remove friction from good habits',
            'Add friction to bad habits',
          ],
          actionable: 'Place one habit cue in a visible location today.',
          icon: Icons.home_rounded,
        ),
      ],
      TipCategory.advancedStrategies: [
        const AITip(
          id: 'as1',
          title: 'Temptation Bundling',
          content: 'Pair a habit you need to do with one you want to do. "I can only watch Netflix while on the treadmill."',
          category: TipCategory.advancedStrategies,
          keyPoints: [
            'Link wants with needs',
            'Make hard habits more attractive',
            'Create positive associations',
          ],
          actionable: 'Identify one want-need pairing you can implement.',
          icon: Icons.swap_horiz_rounded,
        ),
      ],
      TipCategory.mindsetAndMotivation: [
        const AITip(
          id: 'mm1',
          title: 'Focus on Identity',
          content: 'Don\'t just set goals. Decide who you want to become. "I\'m the type of person who..."',
          category: TipCategory.mindsetAndMotivation,
          keyPoints: [
            'Habits reinforce identity',
            'Every action is a vote for who you are',
            'Small wins build self-confidence',
          ],
          actionable: 'Complete this sentence: "I\'m the type of person who..."',
          icon: Icons.person_outline_rounded,
        ),
        const AITip(
          id: 'mm2',
          title: 'Reframe Your Mindset',
          content: 'Change "I have to" to "I get to." Shift from obligation to opportunity.',
          category: TipCategory.mindsetAndMotivation,
          keyPoints: [
            'Language shapes attitude',
            'Find meaning in the mundane',
            'Gratitude enhances motivation',
          ],
          icon: Icons.lightbulb_outline_rounded,
        ),
      ],
    };

    _isLoadingTips = false;
    notifyListeners();
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
    await Future.wait([
      loadSuggestions(),
      loadInsights(),
      loadTips(),
    ]);
  }
}
