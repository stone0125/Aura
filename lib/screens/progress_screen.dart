import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/progress_models.dart';
import '../models/habit_category.dart';
import '../providers/progress_provider.dart';
import '../providers/theme_provider.dart';
import '../config/theme/app_colors.dart';
import '../widgets/progress/progress_ring_painter.dart';
import 'dart:math' as math;

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
    final progressProvider = Provider.of<ProgressProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await progressProvider.refresh();
            _animationController.forward(from: 0);
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
                    _buildQuickActions(isDark),

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
      elevation: 2,
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      title: Text(
        'Your Progress',
        style: TextStyle(
          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        // Date Range Selector
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.3)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
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
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppColors.darkSurface
                            : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
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
                          ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                          : (isDark
                              ? AppColors.darkSecondaryText
                              : const Color(0xFF7F8C8D)),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),

        // Theme Toggle
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            themeProvider.toggleTheme();
          },
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
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
    final stats = progressProvider.stats;

    if (stats == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

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
              // Progress Ring
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: ProgressRingPainter(
                        progress: stats.completionRate * _progressAnimation.value,
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
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: 32,
        ),
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

  /// AI Weekly Summary Card
  Widget _buildAIWeeklySummary(bool isDark, ProgressProvider progressProvider) {
    final summary = progressProvider.weeklySummary;

    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.12),
              blurRadius: isDark ? 24 : 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: summary == null
            ? _buildAILoadingState(isDark)
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
                        child: Icon(
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          summary.periodLabel,
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

                  // Summary Text
                  Text(
                    summary.summary,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Divider(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  const SizedBox(height: 12),

                  // View Full Insights Button
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Navigate to AI Coach screen
                    },
                    child: Text(
                      'View Full Insights →',
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
    );
  }

  Widget _buildAILoadingState(bool isDark) {
    return Column(
      children: [
        CircularProgressIndicator(
          color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
        ),
        const SizedBox(height: 16),
        Text(
          'AI is analyzing your progress...',
          style: TextStyle(
            color:
                isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Category Breakdown Section
  Widget _buildCategoryBreakdown(
      bool isDark, ProgressProvider progressProvider) {
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
              color:
                  isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
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
            borderRadius: BorderRadius.circular(16),
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
              // Donut Chart
              SizedBox(
                height: 140,
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
              const SizedBox(height: 20),

              // Legend
              ...breakdown.map((item) => _buildCategoryLegendItem(isDark, item)),
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
              color:
                  isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
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
              color:
                  isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
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
            borderRadius: BorderRadius.circular(16),
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return SizedBox(
                    width: 40,
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: heatmap.map((day) {
                  return _buildHeatmapCell(isDark, day);
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
        cellColor = const Color(0xFF4D2C2C);
        textColor = const Color(0xFFB0B0B0);
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
        width: 40,
        height: 80,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(12),
          border: day.isToday
              ? Border.all(
                  color: isDark
                      ? const Color(0xFFFF8A80)
                      : const Color(0xFFFF5252),
                  width: 2,
                )
              : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day.dayNumber,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              day.completionText,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetailSheet(BuildContext context, bool isDark, DayHeatmapData day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
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

                // Placeholder for habit list
                Text(
                  'Habit details coming soon...',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  /// Trend Chart Section (Placeholder)
  Widget _buildTrendChart(bool isDark, ProgressProvider progressProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Completion Trend',
            style: TextStyle(
              color:
                  isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
          child: Center(
            child: Text(
              'Chart visualization coming soon...',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                fontSize: 14,
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
              color:
                  isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
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
            borderRadius: BorderRadius.circular(16),
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
  Widget _buildAchievementGallery(bool isDark, ProgressProvider progressProvider) {
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
            borderRadius: BorderRadius.circular(16),
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
                  // Navigate to all achievements
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
              : (isDark
                  ? const Color(0xFF2C2C2C)
                  : const Color(0xFFF5F5F5)),
          border: Border.all(
            color: achievement.isUnlocked
                ? badgeColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
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
                      color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
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
      BuildContext context, bool isDark, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
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
                        color:
                            isDark ? AppColors.darkCoral : AppColors.lightCoral,
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
            ],
          ),
        ),
      ),
    );
  }

  /// Quick Actions
  Widget _buildQuickActions(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        children: [
          // Share button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Share functionality
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                // Export functionality
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
}

/// Custom painter for donut chart
class _DonutChartPainter extends CustomPainter {
  final List<CategoryBreakdown> breakdown;
  final bool isDark;

  _DonutChartPainter({
    required this.breakdown,
    required this.isDark,
  });

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

      final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.breakdown != breakdown || oldDelegate.isDark != isDark;
  }
}
