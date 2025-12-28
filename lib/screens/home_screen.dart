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
import 'ai_coach_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

/// Home Screen - Primary Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Preload AI data when habits are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAIPreloading();
    });
  }

  void _setupAIPreloading() {
    _habitProvider = Provider.of<HabitProvider>(context, listen: false);
    _progressProvider = Provider.of<ProgressProvider>(context, listen: false);

    _habitListener = _checkAndLoadAI;
    _progressListener = _checkAndLoadAI;

    _habitProvider?.addListener(_habitListener!);
    _progressProvider?.addListener(_progressListener!);

    _checkAndLoadAI(); // Initial check
  }

  void _checkAndLoadAI() {
    if (_habitProvider == null) return;

    final coachProvider = Provider.of<AICoachProvider>(context, listen: false);

    // 1. Check if habits are loaded to fetch Suggestions & Tips
    if (!_habitProvider!.isLoadingHabits && _habitProvider!.habits.isNotEmpty) {
      // Load suggestions if empty
      if (coachProvider.suggestions.isEmpty &&
          !coachProvider.isLoadingSuggestions) {
        coachProvider.loadSuggestions(
          categories: _habitProvider!.habits
              .map((h) => h.category.name)
              .toSet()
              .toList(),
          currentHabits: _habitProvider!.habits.map((h) => h.name).toList(),
        );
      }

      // Load tips if empty
      if (coachProvider.tipsByCategory.isEmpty &&
          !coachProvider.isLoadingTips) {
        coachProvider.loadTips();
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

        coachProvider.loadInsights(weekData: weekData);
      }
    }
  }

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

/// Home Tab Widget
class _HomeTab extends StatelessWidget {
  const _HomeTab();

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
                // Header Section
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return HomeHeader(userName: settings.userProfile.firstName);
                  },
                ),

                // 1. Motivational Quote (Daily Wisdom)
                const MotivationalQuoteCard(),
                const SizedBox(height: 20),

                // 2. Summary Stats (Progress)
                const SummaryStatsCard(),
                const SizedBox(height: 24),

                // 3. Habit List (Core Action)
                const HabitList(),
                const SizedBox(height: 24),

                // 4. AI Suggestion Card (Discovery - Least frequent)
                const AISuggestionCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
