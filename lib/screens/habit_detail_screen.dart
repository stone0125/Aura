import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/habit_stats.dart';
import '../providers/habit_detail_provider.dart';

import '../providers/theme_provider.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/ui_constants.dart';
import 'habit_creation_screen.dart';

/// Habit Detail Screen - Comprehensive habit statistics and management
/// 习惯详情屏幕 - 全面的习惯统计和管理
class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  /// Creates the habit detail screen for a specific habit
  /// 为特定习惯创建习惯详情屏幕
  const HabitDetailScreen({super.key, required this.habit});

  /// Creates the mutable state for the habit detail screen
  /// 创建习惯详情屏幕的可变状态
  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final _scrollController = ScrollController();
  TimeRange _selectedTimeRange = TimeRange.month;
  bool _isInsightExpanded = false;

  /// Initializes state and loads habit details
  /// 初始化状态并加载习惯详情
  @override
  void initState() {
    super.initState();
    // Removed _scrollController.addListener(_onScroll) to avoid 60 rebuilds/second
    // Now using AnimatedBuilder with _scrollController as Listenable for opacity calculations

    // Load habit details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HabitDetailProvider>(context, listen: false);
      provider.loadHabitDetails(widget.habit);
    });
  }

  /// Disposes the scroll controller
  /// 释放滚动控制器
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Builds the habit detail screen with stats, charts, and actions
  /// 构建带有统计、图表和操作的习惯详情屏幕
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detailProvider = Provider.of<HabitDetailProvider>(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      extendBodyBehindAppBar: true,
      // Use AnimatedBuilder to rebuild only the AppBar on scroll, not the entire widget tree
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: _scrollController,
          builder: (context, child) {
            final scrollOffset = _scrollController.hasClients
                ? _scrollController.offset
                : 0.0;
            final appBarOpacity = (scrollOffset / 100).clamp(0.0, 1.0);
            final titleOpacity = ((scrollOffset - 80) / 20).clamp(0.0, 1.0);
            return _buildAppBar(isDark, appBarOpacity, titleOpacity);
          },
        ),
      ),
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
                    // Space between Hero and AI Insight Card
                    const SizedBox(height: 24),

                    // AI Insight Card
                    _buildAIInsightCard(isDark, detailProvider),
                    const SizedBox(height: 20),

                    // Reminder Info
                    _buildReminderRow(isDark),

                    // Statistics Grid
                    _buildStatisticsGrid(isDark, detailProvider),
                    const SizedBox(height: 24),

                    // Calendar Section
                    _buildCalendarSection(isDark, detailProvider),
                    const SizedBox(height: 24),

                    // Progress Chart
                    _buildProgressChart(isDark, detailProvider),

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

  /// Builds the app bar with dynamic opacity based on scroll position
  /// 构建根据滚动位置动态调整不透明度的应用栏
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
            fontSize: UIConstants.appBarTitleSize,
            fontWeight: UIConstants.appBarTitleWeight,
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    HabitCreationScreen(habitToEdit: widget.habit),
              ),
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

  /// Builds the hero header section with habit info and streak
  /// 构建带有习惯信息和连续天数的英雄标题区域
  Widget _buildHeroHeader(bool isDark) {
    final gradientColors = widget.habit.category.getGradient(
      isDark ? Brightness.dark : Brightness.light,
    );

    return SliverToBoxAdapter(
      child: Container(
        constraints: const BoxConstraints(minHeight: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
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
            if (widget.habit.reminderEnabled &&
                widget.habit.reminderTime != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alarm_rounded,
                    size: 14,
                    color: (isDark ? AppColors.darkPrimaryText : Colors.white)
                        .withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeOfDay(widget.habit.reminderTime!),
                    style: TextStyle(
                      color: (isDark ? AppColors.darkPrimaryText : Colors.white)
                          .withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Category & Goal Badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.3),
                    ),
                    borderRadius: UIConstants.borderRadiusMedium,
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
                if (widget.habit.goalType != 'none' &&
                    widget.habit.goalValue != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.15 : 0.2,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.2 : 0.3,
                        ),
                      ),
                      borderRadius: UIConstants.borderRadiusMedium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.habit.goalType == 'time'
                              ? Icons.timer_outlined
                              : Icons.flag_outlined,
                          size: 14,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.habit.goalValue} ${widget.habit.goalUnit ?? ''}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Builds the AI insight card with expandable content
  /// 构建带有可展开内容的AI洞察卡片
  Widget _buildAIInsightCard(bool isDark, HabitDetailProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isDark ? 12 : 8,
            offset: const Offset(0, 4),
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

  /// Builds the AI insight loading spinner
  /// 构建AI洞察加载旋转器
  Widget _buildAIInsightLoading(bool isDark) {
    final coral = isDark ? AppColors.darkCoral : AppColors.lightCoral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: coral),
            ),
            const SizedBox(width: 8),
            Text(
              'Analyzing your habit patterns...',
              style: TextStyle(
                color: coral,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: coral.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 16,
          decoration: BoxDecoration(
            color: coral.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  /// Builds the AI insight content with analysis and tips
  /// 构建带有分析和提示的AI洞察内容
  Widget _buildAIInsightContent(bool isDark, AIInsight insight) {
    final textStyle = TextStyle(
      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
      fontSize: 15,
      height: 1.5,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: insight.text, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Text(
                insight.text,
                style: textStyle,
                maxLines: _isInsightExpanded ? null : 3,
                overflow: _isInsightExpanded ? null : TextOverflow.ellipsis,
              ),
            ),
            if (isOverflowing) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () =>
                    setState(() => _isInsightExpanded = !_isInsightExpanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isInsightExpanded ? 'Show Less' : 'Show More',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkCoral
                            : AppColors.lightCoral,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isInsightExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.darkCoral
                          : AppColors.lightCoral,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Builds the empty state when no AI insight is available
  /// 构建无AI洞察可用时的空状态
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

  /// Builds the reminder information row
  /// 构建提醒信息行
  Widget _buildReminderRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: UIConstants.borderRadiusMedium,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.alarm_rounded,
              size: 20,
              color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
            ),
            const SizedBox(width: 10),
            Text(
              'Daily reminder',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Text(
              widget.habit.reminderEnabled && widget.habit.reminderTime != null
                  ? _formatTimeOfDay(widget.habit.reminderTime!)
                  : 'Not set',
              style: TextStyle(
                color:
                    widget.habit.reminderEnabled &&
                        widget.habit.reminderTime != null
                    ? (isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText)
                    : (isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the statistics grid showing key habit metrics
  /// 构建显示关键习惯指标的统计网格
  Widget _buildStatisticsGrid(bool isDark, HabitDetailProvider provider) {
    // Show loading indicator while data loads
    if (provider.isLoadingData) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
          ),
        ),
      );
    }

    // Show error message if loading failed
    if (provider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
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

    if (provider.stats == null) return const SizedBox.shrink();

    final stats = provider.stats!;

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 16) / 2; // horizontal padding + gap

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: cardWidth,
            child: _buildStatCard(
              isDark: isDark,
              icon: Icons.local_fire_department_rounded,
              gradientColors: isDark
                  ? [AppColors.darkOrange, const Color(0xFFFF6F00)]
                  : [AppColors.orange, const Color(0xFFE74C3C)],
              number: '${stats.currentStreak}',
              label: 'Day Streak',
              sublabel: stats.currentStreak == 0 ? 'Start today!' : null,
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _buildStatCard(
              isDark: isDark,
              icon: Icons.emoji_events_rounded,
              gradientColors: const [Color(0xFFFFD54F), Color(0xFFFFC107)],
              number: '${stats.longestStreak}',
              label: 'Best Streak',
              sublabel: stats.isRecord ? 'Record! ✨' : null,
              sublabelColor: isDark
                  ? AppColors.darkCoral
                  : AppColors.lightCoral,
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _buildStatCard(
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
          ),
          SizedBox(
            width: cardWidth,
            child: _buildStatCard(
              isDark: isDark,
              icon: Icons.insert_chart_rounded,
              gradientColors: isDark
                  ? [const Color(0xFF42A5F5), const Color(0xFFAB47BC)]
                  : [const Color(0xFF3498DB), const Color(0xFF9B59B6)],
              number: stats.completionRateFormatted,
              label: 'Success Rate',
              sublabel: 'Last 30 days',
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single stat card with icon, value, and label
  /// 构建带有图标、值和标签的单个统计卡片
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
        borderRadius: UIConstants.borderRadiusLarge,
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
          const SizedBox(height: 12),
          Text(
            number,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  /// Builds the calendar section showing monthly completion history
  /// 构建显示月度完成历史的日历部分
  Widget _buildCalendarSection(bool isDark, HabitDetailProvider provider) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun
    // Adjust for Sunday start if needed (Flutter uses Mon=1), let's stick to Mon-Sun

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMonthName(now.month)} ${now.year}',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Legend or minimal controls could go here
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: UIConstants.borderRadiusLarge,
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
                // Weekday Headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                    return SizedBox(
                      width: 32,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Days Grid
                GridView.builder(
                  shrinkWrap: true,
                  primary: false,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: daysInMonth + (firstWeekday - 1),
                  itemBuilder: (context, index) {
                    if (index < firstWeekday - 1) {
                      return const SizedBox.shrink();
                    }

                    final day = index - (firstWeekday - 1) + 1;
                    final date = DateTime(now.year, now.month, day);
                    final isToday = day == now.day;

                    final isCompleted = provider.completions.any(
                      (c) =>
                          c.date.year == date.year &&
                          c.date.month == date.month &&
                          c.date.day == date.day,
                    );

                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? (isDark
                                  ? AppColors.darkCoral
                                  : AppColors.lightCoral)
                            : isToday
                            ? (isDark
                                  ? AppColors.darkCoral.withValues(alpha: 0.2)
                                  : AppColors.lightCoral.withValues(alpha: 0.2))
                            : Colors.transparent,
                        border: isToday && !isCompleted
                            ? Border.all(
                                color: isDark
                                    ? AppColors.darkCoral
                                    : AppColors.lightCoral,
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: isCompleted
                                ? (isDark
                                      ? AppColors.darkBackground
                                      : Colors.white)
                                : isToday
                                ? (isDark
                                      ? AppColors.darkCoral
                                      : AppColors.lightCoral)
                                : (isDark
                                      ? AppColors.darkSecondaryText
                                      : AppColors.lightSecondaryText),
                            fontSize: 12,
                            fontWeight: isCompleted || isToday
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a TimeOfDay to a readable string
  /// 将TimeOfDay格式化为可读字符串
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Returns the full month name for a given month number
  /// 返回给定月份编号的完整月份名称
  String _getMonthName(int month) {
    const months = [
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
      'December',
    ];
    // Ensure month is within valid range (1-12)
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  /// Builds the progress line chart showing completion trend
  /// 构建显示完成趋势的进度折线图
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
                  borderRadius: UIConstants.borderRadiusSmall,
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

          const SizedBox(height: 24),
          Container(
            height: 240,
            padding: const EdgeInsets.only(
              right: 8,
              left: 8,
              top: 24,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: UIConstants.borderRadiusLarge,
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
            child: RepaintBoundary(
              child: LineChart(
                _buildChartData(
                  isDark,
                  provider.completions,
                  _selectedTimeRange,
                ),
                duration: const Duration(
                  milliseconds: 250,
                ), // Animation duration
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(
    bool isDark,
    List<HabitCompletion> completions,
    TimeRange range,
  ) {
    final spots = _getChartSpots(completions, range);
    final color = isDark ? AppColors.darkCoral : AppColors.lightCoral;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              // Custom labels based on range could be added here
              // For simplicity, showing generic labels or leaving sparse
              if (value % (range == TimeRange.quarter ? 2 : 1) != 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _getBottomLabel(value.toInt(), range),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
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
            interval: 25,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: -5,
      maxY: 105,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true, // Smooth curve
          curveSmoothness: 0.35,
          preventCurveOverShooting: true,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: isDark ? AppColors.darkBackground : Colors.white,
                strokeWidth: 2,
                strokeColor: color,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getChartSpots(
    List<HabitCompletion> completions,
    TimeRange range,
  ) {
    final now = DateTime.now();
    final List<FlSpot> spots = [];

    // Pre-calculate completed dates for O(1) lookup
    // Format: "YYYY-MM-DD"
    final completedDates = completions.map((c) {
      return '${c.date.year}-${c.date.month}-${c.date.day}';
    }).toSet();

    bool isCompleted(DateTime d) {
      return completedDates.contains('${d.year}-${d.month}-${d.day}');
    }

    if (range == TimeRange.week) {
      // Last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        spots.add(FlSpot((6 - i).toDouble(), isCompleted(date) ? 100 : 0));
      }
    } else if (range == TimeRange.month) {
      // Last 4 weeks
      for (int i = 3; i >= 0; i--) {
        int completedCount = 0;
        for (int d = 0; d < 7; d++) {
          final dayOffset = (i * 7) + d;
          final date = now.subtract(Duration(days: dayOffset));
          if (isCompleted(date)) {
            completedCount++;
          }
        }
        final percentage = (completedCount / 7) * 100;
        spots.add(FlSpot((3 - i).toDouble(), percentage));
      }
    } else {
      // Quarter: Last 12 weeks
      for (int i = 11; i >= 0; i--) {
        int completedCount = 0;
        for (int d = 0; d < 7; d++) {
          final dayOffset = (i * 7) + d;
          final date = now.subtract(Duration(days: dayOffset));
          if (isCompleted(date)) {
            completedCount++;
          }
        }
        final percentage = (completedCount / 7) * 100;
        spots.add(FlSpot((11 - i).toDouble(), percentage));
      }
    }

    return spots;
  }

  /// Returns the bottom axis label for a chart data point
  /// 返回图表数据点的底部轴标签
  String _getBottomLabel(int index, TimeRange range) {
    final now = DateTime.now();
    if (range == TimeRange.week) {
      // Index 0 = 6 days ago
      final date = now.subtract(Duration(days: 6 - index));
      // Return weekday initial
      const weekdays = ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S']; // 1-based
      return weekdays[date.weekday];
    } else if (range == TimeRange.month) {
      return 'W${index + 1}'; // W1..W4
    } else {
      // Quarter - show monthly labels roughly?
      // 12 data points = 12 weeks.
      // Let's show Month name for every ~4th week?
      final date = DateTime.now().subtract(Duration(days: (11 - index) * 7));
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return months[date.month];
    }
  }

  /// Builds the bottom action buttons (edit, delete, complete)
  /// 构建底部操作按钮（编辑、删除、完成）
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
                      borderRadius: UIConstants.borderRadiusLarge,
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkCoral
                      : AppColors.lightCoral,
                  foregroundColor: isDark
                      ? AppColors.darkBackground
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: UIConstants.borderRadiusLarge,
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
