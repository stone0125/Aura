import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/habit_stats.dart';
import '../providers/habit_detail_provider.dart';

import '../providers/theme_provider.dart';
import '../config/theme/app_colors.dart';

/// Habit Detail Screen - Comprehensive habit statistics and management
class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  TimeRange _selectedTimeRange = TimeRange.month;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load habit details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HabitDetailProvider>(context, listen: false);
      provider.loadHabitDetails(widget.habit);
    });
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detailProvider = Provider.of<HabitDetailProvider>(context);

    // Calculate app bar opacity based on scroll
    final appBarOpacity = (_scrollOffset / 100).clamp(0.0, 1.0);
    final titleOpacity = ((_scrollOffset - 80) / 20).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isDark, appBarOpacity, titleOpacity),
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero Header
              _buildHeroHeader(isDark),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // AI Insight Card (overlapping hero)
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: _buildAIInsightCard(isDark, detailProvider),
                    ),

                    // Statistics Grid
                    _buildStatisticsGrid(isDark, detailProvider),
                    const SizedBox(height: 24),

                    // Calendar Section
                    _buildCalendarSection(isDark, detailProvider),
                    const SizedBox(height: 24),

                    // Progress Chart
                    _buildProgressChart(isDark, detailProvider),
                    const SizedBox(height: 24),

                    // Completion History
                    _buildCompletionHistory(isDark, detailProvider),

                    // Bottom spacing for FAB
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),

          // Bottom Action Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionButton(isDark, detailProvider),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    bool isDark,
    double opacity,
    double titleOpacity,
  ) {
    return AppBar(
      backgroundColor: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
          .withValues(alpha: opacity * 0.95),
      elevation: opacity > 0.5 ? 2 : 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark
              ? AppColors.darkPrimaryText
              : AppColors.lightPrimaryText,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Opacity(
        opacity: titleOpacity,
        child: Text(
          widget.habit.name,
          style: TextStyle(
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.edit_rounded,
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit habit coming soon!')),
            );
          },
        ),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Opacity(
          opacity: opacity,
          child: Container(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(bool isDark) {
    final gradientColors = widget.habit.category.getGradient(
      isDark ? Brightness.dark : Brightness.light,
    );

    return SliverToBoxAdapter(
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientColors.map((c) {
                      return Color.lerp(c, Colors.white, 0.2)!;
                    }).toList(),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  widget.habit.category.icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Habit Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.habit.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.darkPrimaryText : Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Frequency Label
              Text(
                'Daily',
                style: TextStyle(
                  color: (isDark ? AppColors.darkPrimaryText : Colors.white)
                      .withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),

              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.habit.category.displayName,
                  style: TextStyle(
                    color: isDark ? AppColors.darkPrimaryText : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIInsightCard(bool isDark, HabitDetailProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: isDark ? 24 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkCoral, AppColors.darkPink]
                        : [AppColors.lightCoral, AppColors.lightPink],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Insight',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          if (provider.isLoadingInsight)
            _buildAIInsightLoading(isDark)
          else if (provider.aiInsight != null)
            _buildAIInsightContent(isDark, provider.aiInsight!)
          else
            _buildAIInsightEmpty(isDark),
        ],
      ),
    );
  }

  Widget _buildAIInsightLoading(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 16,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'AI is analyzing your patterns...',
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

  Widget _buildAIInsightContent(bool isDark, AIInsight insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          insight.text,
          style: TextStyle(
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
            fontSize: 15,
            height: 1.5,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('AI Coach screen coming soon!')),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Get More Insights',
                style: TextStyle(
                  color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsightEmpty(bool isDark) {
    return Column(
      children: [
        Icon(
          Icons.auto_awesome_rounded,
          size: 32,
          color: isDark
              ? AppColors.darkSecondaryText
              : AppColors.lightSecondaryText,
        ),
        const SizedBox(height: 12),
        Text(
          'Complete this habit 5 more times to unlock AI insights',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid(bool isDark, HabitDetailProvider provider) {
    if (provider.stats == null) return const SizedBox.shrink();

    final stats = provider.stats!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _buildStatCard(
            isDark: isDark,
            icon: Icons.local_fire_department_rounded,
            gradientColors: isDark
                ? [AppColors.darkOrange, const Color(0xFFFF6F00)]
                : [AppColors.orange, const Color(0xFFE74C3C)],
            number: '${stats.currentStreak}',
            label: 'Day Streak',
            sublabel: stats.currentStreak == 0 ? 'Start today!' : null,
          ),
          _buildStatCard(
            isDark: isDark,
            icon: Icons.emoji_events_rounded,
            gradientColors: const [Color(0xFFFFD54F), Color(0xFFFFC107)],
            number: '${stats.longestStreak}',
            label: 'Best Streak',
            sublabel: stats.isRecord ? 'Record! ✨' : null,
            sublabelColor: isDark ? AppColors.darkCoral : AppColors.lightCoral,
          ),
          _buildStatCard(
            isDark: isDark,
            icon: Icons.check_circle_rounded,
            gradientColors: isDark
                ? [const Color(0xFF69F0AE), const Color(0xFF4CAF50)]
                : [const Color(0xFFA8E6CF), const Color(0xFF27AE60)],
            number: '${stats.totalCompletions}',
            label: 'Completions',
            sublabel: stats.totalCompletions < 100
                ? '${100 - stats.totalCompletions} to Century'
                : null,
          ),
          _buildStatCard(
            isDark: isDark,
            icon: Icons.insert_chart_rounded,
            gradientColors: isDark
                ? [const Color(0xFF42A5F5), const Color(0xFFAB47BC)]
                : [const Color(0xFF3498DB), const Color(0xFF9B59B6)],
            number: stats.completionRateFormatted,
            label: 'Success Rate',
            sublabel: 'Last 30 days',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required IconData icon,
    required List<Color> gradientColors,
    required String number,
    required String label,
    String? sublabel,
    Color? sublabelColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: gradientColors),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const Spacer(),
          Text(
            number,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
              fontSize: 13,
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                color:
                    sublabelColor ??
                    (isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText),
                fontSize: 11,
                fontWeight: sublabelColor != null
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarSection(bool isDark, HabitDetailProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendar',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Calendar view coming soon!',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Will show completion patterns',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(bool isDark, HabitDetailProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Trend',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Time range selector
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: TimeRange.values.map((range) {
                    final isSelected = _selectedTimeRange == range;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedTimeRange = range);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightSurface)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            range.displayName,
                            style: TextStyle(
                              color: isSelected
                                  ? (isDark
                                        ? AppColors.darkCoral
                                        : AppColors.lightCoral)
                                  : (isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.lightSecondaryText),
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 240,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Chart coming soon!',
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
      ),
    );
  }

  Widget _buildCompletionHistory(bool isDark, HabitDetailProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'History',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: provider.completions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 48,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No history yet',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.completions.length > 5
                        ? 5
                        : provider.completions.length,
                    separatorBuilder: (context, index) => Divider(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      height: 24,
                    ),
                    itemBuilder: (context, index) {
                      final completion = provider.completions[index];
                      return _buildHistoryEntry(isDark, completion);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryEntry(bool isDark, HabitCompletion completion) {
    return Row(
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
          ),
          child: Icon(
            Icons.check_rounded,
            color: isDark ? AppColors.darkBackground : Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Date
        Expanded(
          child: Text(
            completion.formattedDate,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(
              0xFFE8F5E9,
            ).withValues(alpha: isDark ? 0.2 : 1.0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Completed',
            style: TextStyle(
              color: isDark ? const Color(0xFF69F0AE) : const Color(0xFF27AE60),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Arrow
        Icon(
          Icons.chevron_right_rounded,
          color: isDark
              ? AppColors.darkSecondaryText
              : AppColors.lightSecondaryText,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildBottomActionButton(bool isDark, HabitDetailProvider provider) {
    final isCompleted = provider.isCompletedToday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.darkBackground : AppColors.lightBackground)
                .withValues(alpha: 0),
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
          ],
          stops: const [0.0, 0.3],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCompleted)
            // Completed state with undo
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFE8F5E9,
                      ).withValues(alpha: isDark ? 0.3 : 1.0),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF69F0AE)
                            : const Color(0xFF27AE60),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: isDark
                                ? const Color(0xFF69F0AE)
                                : const Color(0xFF27AE60),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Completed Today',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF69F0AE)
                                  : const Color(0xFF27AE60),
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () async {
                    await provider.undoCompletion();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Completion removed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Undo',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF69F0AE)
                          : const Color(0xFF27AE60),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            // Complete button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await provider.completeHabit();

                  if (mounted) {
                    // Update main habit provider (optional, stream handles it)
                    // final habitProvider = Provider.of<HabitProvider>(
                    //   context,
                    //   listen: false,
                    // );
                    // habitProvider.toggleHabitCompletion(widget.habit.id);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '+1 day streak! 🔥 Now ${provider.stats?.currentStreak ?? 0} days',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkCoral
                      : AppColors.lightCoral,
                  foregroundColor: isDark
                      ? AppColors.darkBackground
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_rounded, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Mark as Complete',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
