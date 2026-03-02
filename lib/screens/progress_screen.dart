import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/progress_models.dart';
import '../models/habit_category.dart';
import '../providers/progress_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings_models.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/ui_constants.dart';
import '../config/app_constants.dart';
import '../widgets/progress/progress_ring_painter.dart';
import '../services/share_service.dart';
import 'dart:math' as math;
import '../providers/ai_coach_provider.dart';
import '../widgets/outdated_report_banner.dart';
import '../models/ai_coach_models.dart';
import 'home_screen.dart';
import '../utils/date_utils.dart' as date_utils;

/// Progress/Analytics Screen with comprehensive data visualization
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  bool _insightsRequested = false;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _progressAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    // Load data and start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProgressProvider>(context, listen: false).initialize();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use context.watch for providers that need full rebuild on changes
    // For more selective rebuilds, use context.select() in specific widgets
    final progressProvider = context.watch<ProgressProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await progressProvider.refresh();
            // Reset and restart animation after refresh
            _animationController.reset();
            _animationController.forward();
          },
          color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
          child: CustomScrollView(
            slivers: [
              // App Bar
              _buildAppBar(isDark, progressProvider, themeProvider),

              // Hero Section
              _buildHeroSection(isDark, progressProvider),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // AI Weekly Summary
                    _buildAIWeeklySummary(isDark, progressProvider),

                    // Category Breakdown
                    _buildCategoryBreakdown(isDark, progressProvider),

                    // Weekly Heatmap
                    _buildWeeklyHeatmap(isDark, progressProvider),

                    // Trend Chart
                    _buildTrendChart(isDark, progressProvider),

                    // Best & Worst Performers
                    _buildPerformers(isDark, progressProvider),

                    // Achievement Gallery
                    _buildAchievementGallery(isDark, progressProvider),

                    // Quick Actions
                    _buildQuickActions(isDark, progressProvider),

                    // Bottom padding
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// App Bar
  Widget _buildAppBar(
    bool isDark,
    ProgressProvider progressProvider,
    ThemeProvider themeProvider,
  ) {
    return SliverAppBar(
      pinned: true,
      elevation: UIConstants.appBarElevation,
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      titleSpacing: UIConstants.spacing16,
      title: Text(
        'Your Progress',
        style: TextStyle(
          color: isDark
              ? AppColors.darkPrimaryText
              : AppColors.lightPrimaryText,
          fontSize: UIConstants.appBarTitleSize,
          fontWeight: UIConstants.appBarTitleWeight,
        ),
      ),
      actions: [
        // Theme Toggle
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            themeProvider.toggleTheme();
            // Sync with SettingsProvider
            final newIsDark = !isDark;
            context.read<SettingsProvider>().setThemePreference(
              newIsDark ? ThemePreference.dark : ThemePreference.light,
            );
          },
          icon: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
      ],
    );
  }

  /// Hero Section with Progress Ring
  Widget _buildHeroSection(bool isDark, ProgressProvider progressProvider) {
    // Use actual stats or default empty stats for new users
    final stats =
        progressProvider.stats ??
        const ProgressStats(
          completionRate: 0.0,
          daysTracked: 0,
          bestStreak: 0,
          totalHabits: 0,
          completedToday: 0,
          totalToday: 0,
        );

    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFFFF8A80),
                    const Color(0xFF69F0AE),
                    const Color(0xFF82B1FF),
                  ]
                : [
                    const Color(0xFFFF6B6B),
                    const Color(0xFFA8E6CF),
                    const Color(0xFFB8D4E8),
                  ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Date Range Selector
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: UIConstants.borderRadiusMedium,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: DateRange.values.map((range) {
                    final isSelected = progressProvider.selectedRange == range;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        progressProvider.setDateRange(range);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: UIConstants.borderRadiusSmall,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          range.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.lightCoral
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Progress Ring - wrapped in RepaintBoundary
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return SizedBox(
                    width: 160,
                    height: 160,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: ProgressRingPainter(
                        progress:
                            stats.completionRate * _progressAnimation.value,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        progressColor: Colors.white,
                        strokeWidth: 14,
                        showGlow: true,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(stats.completionRate * 100 * _progressAnimation.value).toInt()}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Success Rate',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Stats Row
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildHeroStat(
                      icon: Icons.calendar_today_rounded,
                      value: '${stats.daysTracked}',
                      label: 'Days Tracked',
                    ),
                    _buildHeroStat(
                      icon: Icons.local_fire_department_rounded,
                      value: '${stats.bestStreak}',
                      label: 'Best Streak',
                    ),
                    _buildHeroStat(
                      icon: Icons.check_circle_rounded,
                      value: '${stats.totalHabits}',
                      label: 'Active Habits',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// AI Weekly Summary Card - reads from AICoachProvider
  Widget _buildAIWeeklySummary(bool isDark, ProgressProvider progressProvider) {
    final coachProvider = context.watch<AICoachProvider>();
    final summary = coachProvider.weeklySummary;

    // Trigger load if null and not loading (only once per screen lifecycle)
    if (summary == null && !coachProvider.isLoadingInsights && !_insightsRequested) {
      _insightsRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final habitProvider = Provider.of<HabitProvider>(context, listen: false);
        final weekData = {
          'totalCompletions': habitProvider.totalCount,
          'currentStreak': habitProvider.bestStreak,
        };
        coachProvider.loadInsights(
          weekData: weekData,
          habits: habitProvider.habits,
        );
      });
    }

    final habitProvider2 = context.watch<HabitProvider>();
    final isOutdated = coachProvider.isWeeklySummaryOutdated(habitProvider2.habits);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: coachProvider.isLoadingInsights
          ? _buildAIInsightsLoadingSpinner(isDark)
          : summary == null
              ? (!coachProvider.canUseAIReport
                  ? _buildAIReportLimitReached(isDark)
                  : _buildAILoadingState(isDark))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFFFF8A80),
                                      const Color(0xFF69F0AE),
                                    ]
                                  : [
                                      const Color(0xFFFF6B6B),
                                      const Color(0xFFA8E6CF),
                                    ],
                            ),
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Analysis',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A237E)
                                : const Color(0xFFE3F2FD),
                            borderRadius: UIConstants.borderRadiusMedium,
                          ),
                          child: Text(
                            summary.weekRange,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF82B1FF)
                                  : const Color(0xFF2196F3),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Outdated banner
                    if (isOutdated)
                      OutdatedReportBanner(
                        isRefreshing: coachProvider.isLoadingInsights,
                        onRefresh: () {
                          final hp = Provider.of<HabitProvider>(context, listen: false);
                          final wd = {
                            'totalCompletions': hp.totalCount,
                            'currentStreak': hp.bestStreak,
                          };
                          coachProvider.loadInsights(
                            weekData: wd,
                            habits: hp.habits,
                            forceRefresh: true,
                          );
                        },
                      ),

                    // Stats row
                    Row(
                      children: [
                        _buildAIStat(
                          isDark,
                          '${(summary.completionRate * 100).toInt()}%',
                          'Success Rate',
                        ),
                        const SizedBox(width: 24),
                        _buildAIStat(
                          isDark,
                          '${summary.currentStreak}',
                          'Day Streak',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Insight Text
                    Text(
                      summary.insight,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                      ),
                    ),

                    // Encouragement
                    if (summary.encouragement.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: summary.getPerformanceColor(isDark)
                              .withValues(alpha: 0.1),
                          borderRadius: UIConstants.borderRadiusSmall,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              size: 16,
                              color: summary.getPerformanceColor(isDark),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                summary.encouragement,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.lightPrimaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Divider
                    Divider(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    const SizedBox(height: 12),

                    // View Full Insights Button
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final cp = Provider.of<AICoachProvider>(
                          context,
                          listen: false,
                        );
                        cp.setTab(AICoachTab.insights);

                        // Switch to AI Coach tab instead of pushing a new route
                        // so the bottom navigation bar stays visible
                        HomeScreen.homeKey.currentState?.switchToTab(2);
                      },
                      child: Text(
                        'View Full Insights →',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkCoral
                              : AppColors.lightCoral,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAIStat(bool isDark, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsightsLoadingSpinner(bool isDark) {
    final coral = isDark ? AppColors.darkCoral : AppColors.lightCoral;
    final pink = isDark ? AppColors.darkPink : AppColors.lightPink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [coral, pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'AI is analyzing your progress...',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: coral,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: coral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAILoadingState(bool isDark) {
    return Column(
      children: [
        Icon(
          Icons.psychology_outlined,
          size: 48,
          color: isDark
              ? AppColors.darkSecondaryText.withValues(alpha: 0.5)
              : AppColors.lightSecondaryText.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Start tracking habits to unlock AI insights',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Complete ${AppConstants.minDaysForAIInsights} days of tracking to see personalized analysis',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark
                ? AppColors.darkTertiaryText
                : AppColors.lightTertiaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAIReportLimitReached(bool isDark) {
    return Column(
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 48,
          color: Colors.orange.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 12),
        Text(
          'Monthly AI report limit reached',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upgrade your plan for more AI reports each month',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Category Breakdown Section
  Widget _buildCategoryBreakdown(
    bool isDark,
    ProgressProvider progressProvider,
  ) {
    final breakdown = progressProvider.categoryBreakdown;

    if (breakdown.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Performance by Category',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: UIConstants.borderRadiusLarge,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isDark ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Donut Chart - wrapped in RepaintBoundary
              SizedBox(
                height: 140,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      breakdown: breakdown,
                      isDark: isDark,
                    ),
                    child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${breakdown.fold<int>(0, (sum, item) => sum + item.habitCount)}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Habits',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ),
              const SizedBox(height: 20),

              // Legend
              ...breakdown.map(
                (item) => _buildCategoryLegendItem(isDark, item),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryLegendItem(bool isDark, CategoryBreakdown breakdown) {
    final colors = breakdown.category.getGradient(
      isDark ? Brightness.dark : Brightness.light,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colors),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            breakdown.category.displayName,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${breakdown.habitCount}',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            '${(breakdown.percentage * 100).toInt()}%',
            style: TextStyle(
              color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Weekly Heatmap Section
  Widget _buildWeeklyHeatmap(bool isDark, ProgressProvider progressProvider) {
    final heatmap = progressProvider.weeklyHeatmap;

    if (heatmap.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Your Week at a Glance',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: UIConstants.borderRadiusLarge,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isDark ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Day headers
              Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : const Color(0xFF7F8C8D),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Day cells
              Row(
                children: heatmap.map((day) {
                  return Expanded(
                    child: _buildHeatmapCell(isDark, day),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapCell(bool isDark, DayHeatmapData day) {
    Color cellColor;
    Color textColor;

    if (isDark) {
      if (day.completionRate >= 0.8) {
        cellColor = const Color(0xFFFF8A80);
        textColor = Colors.white;
      } else if (day.completionRate >= 0.6) {
        cellColor = const Color(0xFF5D3A3A);
        textColor = const Color(0xFFD0D0D0);
      } else if (day.completionRate >= 0.4) {
        cellColor = const Color(0xFF4D2C2C);
        textColor = const Color(0xFFB0B0B0);
      } else if (day.completionRate >= 0.2) {
        cellColor = const Color(0xFF3A2222);
        textColor = const Color(0xFFB0B0B0);
      } else {
        cellColor = const Color(0xFF2C2C2C);
        textColor = const Color(0xFFB0B0B0);
      }
    } else {
      if (day.completionRate >= 0.8) {
        cellColor = const Color(0xFFFF6B6B);
        textColor = Colors.white;
      } else if (day.completionRate >= 0.6) {
        cellColor = const Color(0xFFFFB0B0);
        textColor = const Color(0xFF2C3E50);
      } else if (day.completionRate >= 0.4) {
        cellColor = const Color(0xFFFFCBCB);
        textColor = const Color(0xFF2C3E50);
      } else if (day.completionRate >= 0.2) {
        cellColor = const Color(0xFFFFE8E8);
        textColor = const Color(0xFF2C3E50);
      } else {
        cellColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF2C3E50);
      }
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showDayDetailSheet(context, isDark, day);
      },
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: UIConstants.borderRadiusMedium,
          border: day.isToday
              ? Border.all(
                  color: isDark
                      ? const Color(0xFFFF8A80)
                      : const Color(0xFFFF5252),
                  width: 2,
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day.dayNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                day.completionText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetailSheet(
    BuildContext context,
    bool isDark,
    DayHeatmapData day,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (sheetContext, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: _buildDayDetailContent(sheetContext, isDark, day),
          );
        },
      ),
    );
  }

  /// Build day detail content with error boundary
  Widget _buildDayDetailContent(
    BuildContext context,
    bool isDark,
    DayHeatmapData day,
  ) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Date
          Text(
            _formatDate(day.date),
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Summary
          Text(
            '${day.completed} of ${day.total} habits completed (${(day.completionRate * 100).toInt()}%)',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),

          // Habit completion list for this day
          Expanded(
            child: SingleChildScrollView(
              child: _buildDayHabitList(context, day, isDark),
            ),
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error building day detail content: $e');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load day details',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again later',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return date_utils.formatDateFull(date);
  }

  /// Build habit list for a specific day
  Widget _buildDayHabitList(
    BuildContext context,
    DayHeatmapData day,
    bool isDark,
  ) {
    final habitProvider = context.read<HabitProvider>();
    final progressProvider = context.read<ProgressProvider>();
    final habits = habitProvider.habits;

    if (habits.isEmpty) {
      return Text(
        'No habits to track',
        style: TextStyle(
          color: isDark
              ? AppColors.darkSecondaryText
              : AppColors.lightSecondaryText,
          fontSize: 14,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: habits.map((habit) {
        // Check if THIS specific habit was completed on this day
        final isCompleted = progressProvider.wasHabitCompletedOnDate(
          habit.id,
          day.date,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                      : (isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: isCompleted
                    ? Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
              ),
              Icon(
                habit.category.icon,
                size: 16,
                color: isDark
                    ? habit.category.getDarkGradient().first
                    : habit.category.getLightGradient().first,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Trend Chart Section with fl_chart
  Widget _buildTrendChart(bool isDark, ProgressProvider progressProvider) {
    final trendData = progressProvider.trendData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Completion Trend',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 200,
          padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: UIConstants.borderRadiusLarge,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isDark ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: trendData.isEmpty
              ? Center(
                  child: Text(
                    'Complete habits to see trends',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                      fontSize: 14,
                    ),
                  ),
                )
              : RepaintBoundary(
                  child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 0.25,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.3)
                            : AppColors.lightBorder,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: (trendData.length / 5).ceilToDouble(),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= trendData.length) {
                              return const SizedBox.shrink();
                            }
                            final date = trendData[index].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTertiaryText
                                      : AppColors.lightTertiaryText,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 0.25,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${(value * 100).toInt()}%',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTertiaryText
                                    : AppColors.lightTertiaryText,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (trendData.length - 1).toDouble(),
                    minY: 0,
                    maxY: 1,
                    lineBarsData: [
                      LineChartBarData(
                        // Use List.generate instead of .asMap().entries.map() for efficiency
                        spots: List.generate(trendData.length, (index) {
                          return FlSpot(
                            index.toDouble(),
                            trendData[index].completionRate,
                          );
                        }),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: isDark
                            ? AppColors.darkCoral
                            : AppColors.lightCoral,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: isDark
                                  ? AppColors.darkCoral
                                  : AppColors.lightCoral,
                              strokeWidth: 2,
                              strokeColor: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color:
                              (isDark
                                      ? AppColors.darkCoral
                                      : AppColors.lightCoral)
                                  .withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => isDark
                            ? AppColors.darkSurfaceVariant
                            : Colors.white,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final index = spot.x.toInt();
                            // Bounds check for trendData access
                            if (index < 0 || index >= trendData.length) {
                              return LineTooltipItem(
                                '${(spot.y * 100).toInt()}%',
                                TextStyle(
                                  color: isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.lightPrimaryText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              );
                            }
                            final date = trendData[index].date;
                            return LineTooltipItem(
                              '${date.day}/${date.month}\n${(spot.y * 100).toInt()}%',
                              TextStyle(
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
                ),
        ),
      ],
    );
  }

  /// Best & Worst Performers Section (Continued in next part due to length)
  Widget _buildPerformers(bool isDark, ProgressProvider progressProvider) {
    final topPerformers = progressProvider.topPerformers;
    final bottomPerformers = progressProvider.bottomPerformers;

    if (topPerformers.isEmpty && bottomPerformers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Top & Bottom Habits',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: UIConstants.borderRadiusLarge,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isDark ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Performers
              Text(
                '⭐ Top Performers',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...topPerformers.take(3).map((performer) {
                final rank = topPerformers.indexOf(performer) + 1;
                return _buildPerformerItem(isDark, performer, rank, true);
              }),

              const SizedBox(height: 20),

              // Bottom Performers
              Text(
                '🎯 Needs Attention',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...bottomPerformers.take(2).map((performer) {
                return _buildPerformerItem(isDark, performer, 0, false);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformerItem(
    bool isDark,
    HabitPerformance performer,
    int rank,
    bool isTop,
  ) {
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFF1C40F);
    } else if (rank == 2) {
      rankColor = const Color(0xFF95A5A6);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = Colors.transparent;
    }

    final gradientColors = performer.habit.category.getGradient(
      isDark ? Brightness.dark : Brightness.light,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Rank badge (only for top performers)
          if (isTop && rank > 0) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rankColor,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Habit icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: gradientColors),
            ),
            child: Icon(
              performer.habit.category.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Habit name
          Expanded(
            child: Text(
              performer.habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Success rate
          Text(
            performer.successPercentage,
            style: TextStyle(
              color: isTop
                  ? (isDark ? const Color(0xFF69F0AE) : const Color(0xFF27AE60))
                  : (performer.successRate < 0.5
                        ? (isDark
                              ? const Color(0xFFFF5252)
                              : const Color(0xFFE74C3C))
                        : (isDark
                              ? const Color(0xFFFFB74D)
                              : const Color(0xFFF39C12))),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Achievement Gallery Section
  Widget _buildAchievementGallery(
    bool isDark,
    ProgressProvider progressProvider,
  ) {
    final achievements = progressProvider.achievements.take(6).toList();

    if (achievements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Achievements',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${progressProvider.unlockedAchievements.length} of ${progressProvider.achievements.length} unlocked',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: UIConstants.borderRadiusLarge,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isDark ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Achievement grid
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: achievements.map((achievement) {
                  return _buildAchievementBadge(isDark, achievement);
                }).toList(),
              ),

              const SizedBox(height: 16),
              Divider(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              const SizedBox(height: 12),

              // View All link
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showAllAchievements(context, isDark, progressProvider);
                },
                child: Text(
                  'View All Achievements →',
                  style: TextStyle(
                    color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge(bool isDark, Achievement achievement) {
    final badgeColor = achievement.category.getColor(isDark);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showAchievementDetail(context, isDark, achievement);
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: achievement.isUnlocked
              ? badgeColor.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5)),
          border: Border.all(
            color: achievement.isUnlocked
                ? badgeColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
          borderRadius: UIConstants.borderRadiusMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              achievement.icon,
              size: 32,
              color: achievement.isUnlocked
                  ? badgeColor
                  : (isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText),
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              achievement.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: achievement.isUnlocked
                    ? (isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText)
                    : (isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Progress or date
            if (!achievement.isUnlocked) ...[
              const SizedBox(height: 8),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A3A3A)
                      : const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: achievement.progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCoral
                          : AppColors.lightCoral,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(
    BuildContext context,
    bool isDark,
    Achievement achievement,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge icon
                      Icon(
                        achievement.icon,
                        size: 96,
                        color: achievement.category.getColor(isDark),
                      ),
                      const SizedBox(height: 20),

                      // Badge name
                      Text(
                        achievement.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            achievement.isUnlocked
                                ? Icons.check_circle_rounded
                                : Icons.lock_rounded,
                            size: 16,
                            color: achievement.isUnlocked
                                ? (isDark
                                      ? const Color(0xFF69F0AE)
                                      : const Color(0xFF27AE60))
                                : (isDark
                                      ? const Color(0xFFFFB74D)
                                      : const Color(0xFFF39C12)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            achievement.isUnlocked
                                ? 'Unlocked ${achievement.unlockedDateText}'
                                : 'Not yet unlocked',
                            style: TextStyle(
                              color: achievement.isUnlocked
                                  ? (isDark
                                        ? const Color(0xFF69F0AE)
                                        : const Color(0xFF27AE60))
                                  : (isDark
                                        ? const Color(0xFFFFB74D)
                                        : const Color(0xFFF39C12)),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        achievement.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ),

                      // Progress (if locked)
                      if (!achievement.isUnlocked) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Your progress',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3A3A3A)
                                : const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: achievement.progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCoral
                                    : AppColors.lightCoral,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          achievement.progressText,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],

                      // Share button
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _shareAchievement(achievement);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: Text(
                            achievement.isUnlocked
                                ? 'Share Achievement'
                                : 'Share Progress',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkCoral
                                : AppColors.lightCoral,
                            foregroundColor: isDark
                                ? AppColors.darkBackground
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: UIConstants.borderRadiusMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareAchievement(Achievement achievement) async {
    await ShareService().shareAchievement(achievement);
  }

  Future<void> _exportData() async {
    // Store scaffold messenger BEFORE any async operations to avoid context issues
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    try {
      final habits = habitProvider.habits;

      if (habits.isEmpty) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No data to export yet!')),
        );
        return;
      }

      final StringBuffer csv = StringBuffer();
      csv.writeln('Name,Category,Streak,Status,Last Completed');

      for (final habit in habits) {
        final lastCompleted = habit.lastCompletedDate != null
            ? '${habit.lastCompletedDate!.year}-${habit.lastCompletedDate!.month.toString().padLeft(2, '0')}-${habit.lastCompletedDate!.day.toString().padLeft(2, '0')}'
            : 'Never';

        // Quote fields that may contain commas and escape internal quotes
        final escapedName = habit.name.contains(',') || habit.name.contains('"')
            ? '"${habit.name.replaceAll('"', '""')}"'
            : habit.name;
        csv.writeln(
          '$escapedName,${habit.category.name},${habit.streak},${habit.isCompleted ? "Completed Today" : "Pending"},$lastCompleted',
        );
      }

      final directory = await getTemporaryDirectory();
      if (!mounted) return;

      final path =
          '${directory.path}/aura_habits_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv.toString());
      if (!mounted) return;

      await ShareService().shareFile(path, 'My Aura Habit Data');
    } catch (e) {
      debugPrint('Export failed: $e');
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  /// Quick Actions Section
  Widget _buildQuickActions(bool isDark, ProgressProvider progressProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        children: [
          // Share button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                final stats = progressProvider.stats;
                if (stats != null) {
                  ShareService().shareProgressSummary(
                    daysTracked: stats.daysTracked,
                    bestStreak: stats.bestStreak,
                    totalHabits: stats.totalHabits,
                    completionRate: stats.completionRate,
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: UIConstants.borderRadiusMedium,
                ),
              ),
              icon: Icon(
                Icons.share_rounded,
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                size: 20,
              ),
              label: Text(
                'Share',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Export button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _exportData();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: UIConstants.borderRadiusMedium,
                ),
              ),
              icon: Icon(
                Icons.download_rounded,
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                size: 20,
              ),
              label: Text(
                'Export',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllAchievements(
    BuildContext context,
    bool isDark,
    ProgressProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'All Achievements',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCoral.withValues(alpha: 0.1)
                              : AppColors.lightCoral.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
                        ),
                        child: Text(
                          '${provider.unlockedAchievements.length} / ${provider.achievements.length}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkCoral
                                : AppColors.lightCoral,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Grid
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.75, // Taller for badge + text
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: provider.achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = provider.achievements[index];
                      return _buildAchievementBadge(isDark, achievement);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for donut chart
class _DonutChartPainter extends CustomPainter {
  final List<CategoryBreakdown> breakdown;
  final bool isDark;

  _DonutChartPainter({required this.breakdown, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 24.0;

    double startAngle = -math.pi / 2;

    for (var item in breakdown) {
      final sweepAngle = 2 * math.pi * item.percentage;
      final colors = item.category.getGradient(
        isDark ? Brightness.dark : Brightness.light,
      );

      final paint = Paint()
        ..shader = LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(
        center: center,
        radius: radius - strokeWidth / 2,
      );
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.breakdown != breakdown || oldDelegate.isDark != isDark;
  }
}
