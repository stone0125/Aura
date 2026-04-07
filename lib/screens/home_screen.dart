import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/ai_coach_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/ai_suggestion_card.dart';
import '../widgets/home/motivational_quote_card.dart';
import '../widgets/home/summary_stats_card.dart';
import '../widgets/home/habit_list.dart';
import '../config/theme/app_colors.dart';
import 'habit_creation_screen.dart';
import 'habit_detail_screen.dart';
import 'ai_coach_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

/// Home Screen - Primary Dashboard with tab navigation
/// 主屏幕 - 带有标签导航的主要仪表板
class HomeScreen extends StatefulWidget {
  static final GlobalKey<HomeScreenState> homeKey =
      GlobalKey<HomeScreenState>();

  /// Creates the home screen
  /// 创建主屏幕
  const HomeScreen({super.key});

  /// Creates the mutable state for the home screen
  /// 创建主屏幕的可变状态
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  HabitProvider? _habitProvider;
  ProgressProvider? _progressProvider;
  VoidCallback? _habitListener;
  VoidCallback? _progressListener;

  // Define screens for each tab
  final List<Widget> _screens = [
    const _HomeTab(),
    const ProgressScreen(),
    const AICoachScreen(),
    const SettingsScreen(),
  ];

  /// Switches to the specified bottom navigation tab
  /// 切换到指定的底部导航标签
  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// Initializes state and sets up AI data preloading
  /// 初始化状态并设置AI数据预加载
  @override
  void initState() {
    super.initState();
    // Preload AI data when habits are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAIPreloading();
    });
  }

  /// Sets up listeners to preload AI suggestions, tips, and insights
  /// 设置监听器以预加载AI建议、提示和洞察
  void _setupAIPreloading() {
    if (!mounted) {
      return; // Guard against post-frame callback after dispose / 防止销毁后的回调
    }
    _habitProvider = Provider.of<HabitProvider>(context, listen: false);
    _progressProvider = Provider.of<ProgressProvider>(context, listen: false);

    _habitListener = _checkAndLoadAI;
    _progressListener = _checkAndLoadAI;

    _habitProvider?.addListener(_habitListener!);
    _progressProvider?.addListener(_progressListener!);

    _checkAndLoadAI(); // Initial check
  }

  /// Checks if data is ready and loads AI suggestions, tips, and insights
  /// 检查数据是否就绪并加载AI建议、提示和洞察
  void _checkAndLoadAI() {
    if (_habitProvider == null || !mounted) return;

    final coachProvider = Provider.of<AICoachProvider>(context, listen: false);

    // 1. Check if habits are loaded to fetch Suggestions & Tips
    if (!_habitProvider!.isLoadingHabits && _habitProvider!.habits.isNotEmpty) {
      // Extract data in single iteration to avoid multiple .map() calls
      final habits = _habitProvider!.habits;
      final categories = <String>{};
      final habitNames = <String>[];
      int combinedStreaks = 0;

      for (final h in habits) {
        categories.add(h.category.name);
        habitNames.add(h.name);
        combinedStreaks += h.streak;
      }

      // Load suggestions if empty
      if (coachProvider.suggestions.isEmpty &&
          !coachProvider.isLoadingSuggestions) {
        coachProvider.loadSuggestions(
          categories: categories.toList(),
          currentHabits: habitNames,
          completionRate: _habitProvider!.completionRate * 100,
          bestStreak: _habitProvider!.bestStreak,
        );
      }

      // Load tips if empty (with user data for personalization)
      if (coachProvider.tipsByCategory.isEmpty &&
          !coachProvider.isLoadingTips) {
        coachProvider.loadTips(
          userHabits: habitNames,
          completionRate: _habitProvider!.completionRate * 100,
          bestStreak: _habitProvider!.bestStreak,
          totalCompletions:
              combinedStreaks, // approximation: sum of current streaks
        );
      }
    }

    // 2. Check if Progress stats are ready to fetch Insights
    if (_progressProvider != null &&
        !_progressProvider!.isLoading &&
        _progressProvider!.stats != null) {
      if (coachProvider.weeklySummary == null &&
          !coachProvider.isLoadingInsights) {
        // Calculate weekly data for AI
        final totalCompletions = _progressProvider!.weeklyHeatmap.isNotEmpty
            // sum up completed counts
            ? _progressProvider!.weeklyHeatmap.fold<int>(
                0,
                (sum, day) => sum + day.completed,
              )
            : 0;

        final currentStreak = _progressProvider!.stats!.bestStreak;

        final weekData = {
          'totalCompletions': totalCompletions,
          'currentStreak': currentStreak,
          'habits': _habitProvider!.habits.map((h) => h.name).toList(),
          'completionRate': _progressProvider!.stats!.completionRate,
        };

        coachProvider.loadInsights(
          weekData: weekData,
          habits: _habitProvider!.habits,
        );
      }
    }
  }

  /// Removes listeners and disposes resources
  /// 移除监听器并释放资源
  @override
  void dispose() {
    if (_habitProvider != null && _habitListener != null) {
      _habitProvider!.removeListener(_habitListener!);
    }
    if (_progressProvider != null && _progressListener != null) {
      _progressProvider!.removeListener(_progressListener!);
    }
    super.dispose();
  }

  /// Builds the home screen with tab content, FAB, and bottom navigation
  /// 构建带有标签内容、浮动按钮和底部导航的主屏幕
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HabitCreationScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_rounded),
              label: 'AI Coach',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// Home Tab Widget displaying dashboard content
/// 显示仪表板内容的主页标签组件
class _HomeTab extends StatelessWidget {
  /// Creates the home tab widget
  /// 创建主页标签组件
  const _HomeTab();

  /// Builds the home tab with quote, stats, habits, and AI suggestion cards
  /// 构建带有语录、统计、习惯和AI建议卡片的主页标签
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section - uses Selector to only rebuild when firstName changes
                Selector<SettingsProvider, String>(
                  selector: (context, settings) =>
                      settings.userProfile.firstName,
                  builder: (context, firstName, child) {
                    return HomeHeader(userName: firstName);
                  },
                ),

                // 1. Motivational Quote (Daily Wisdom)
                const MotivationalQuoteCard(),
                const SizedBox(height: 20),

                // 2. Summary Stats (Progress)
                const SummaryStatsCard(),
                const SizedBox(height: 24),

                // 3. Habit List (Core Action)
                HabitList(
                  onHabitTap: (habit) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HabitDetailScreen(habit: habit),
                      ),
                    );
                  },
                  onCreateHabit: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HabitCreationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 4. AI Suggestion Card (Discovery - Least frequent)
                AISuggestionCard(
                  onCreateHabitFromSuggestion: (suggestion) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            HabitCreationScreen(aiCoachSuggestion: suggestion),
                      ),
                    );
                  },
                  onViewAllSuggestions: () {
                    final homeState = context
                        .findAncestorStateOfType<HomeScreenState>();
                    homeState?.switchToTab(2);
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
