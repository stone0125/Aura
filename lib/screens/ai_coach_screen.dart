import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import '../models/ai_coach_models.dart';
import '../models/ai_scoring_models.dart';
import '../models/daily_review_models.dart';
import '../providers/ai_coach_provider.dart';
import '../providers/ai_scoring_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

import '../services/firestore_service.dart';
import '../services/subscription_service.dart';
import '../models/subscription_models.dart';
import '../config/theme/app_colors.dart';
import '../models/settings_models.dart';
import '../config/theme/ui_constants.dart';
import '../models/habit_category.dart';
import 'habit_creation_screen.dart';
import 'habit_detail_screen.dart';
import '../widgets/outdated_report_banner.dart';

/// AI Coach Screen with personalized suggestions and insights
/// AI教练屏幕，提供个性化建议和洞察
class AICoachScreen extends StatefulWidget {
  final AICoachTab? initialTab;

  /// Creates the AI Coach screen with an optional initial tab
  /// 创建AI教练屏幕，可选初始标签
  const AICoachScreen({super.key, this.initialTab});

  /// Creates the mutable state for the AI Coach screen
  /// 创建AI教练屏幕的可变状态
  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _skeletonController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final GlobalKey _refreshButtonKey = GlobalKey();
  OverlayEntry? _cooldownTooltip;
  final Set<String> _expandedHabits = {};

  /// Initializes animations, controllers, and loads initial tab data
  /// 初始化动画、控制器并加载初始标签数据
  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Skeleton pulse animation — started on demand when loading, not always
    _skeletonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Usage icon pulse animation — started on demand when limit reached
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AICoachProvider>(context, listen: false);

      // Set initial tab if provided
      if (widget.initialTab != null) {
        provider.setTab(widget.initialTab!);
      }

      provider.initialize();
      // Load initial tab data
      _loadTabData(provider.currentTab, context);
    });
  }

  /// Disposes animation controllers and removes overlay entries
  /// 释放动画控制器并移除覆盖层条目
  @override
  void dispose() {
    _cooldownTooltip?.remove();
    _cooldownTooltip = null;
    _animationController.dispose();
    _skeletonController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Builds the AI Coach screen with hero section, tabs, and content
  /// 构建带有英雄区域、标签和内容的AI教练屏幕
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coachProvider = Provider.of<AICoachProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(isDark),

            // Tab Navigation
            _buildTabNavigation(isDark, coachProvider),

            // Tab Content
            Expanded(child: _buildTabContent(isDark, coachProvider)),
          ],
        ),
      ),
    );
  }

  /// Hero section with gradient and AI avatar
  /// 带有渐变和AI头像的英雄区域
  Widget _buildHeroSection(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E1E2E),
                    const Color(0xFF2D2D44),
                    const Color(0xFF3A3A5C),
                  ]
                : [
                    const Color(0xFFFFE8E8),
                    const Color(0xFFFFD6E8),
                    const Color(0xFFF5E8FF),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Animated gradient overlay
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(
                          -1.0 + (_animationController.value * 2),
                          -1.0,
                        ),
                        end: Alignment(
                          1.0 + (_animationController.value * 2),
                          1.0,
                        ),
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // AI Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppColors.darkCoral
                              : AppColors.lightCoral,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isDark
                                          ? AppColors.darkCoral
                                          : AppColors.lightCoral)
                                      .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.psychology_rounded,
                          color: isDark
                              ? AppColors.darkBackground
                              : Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your AI Coach',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Personalized insights to help you succeed',
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
                    ],
                  ),
                ],
              ),
            ),

            // Dark mode toggle - top right
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<ThemeProvider>().toggleTheme();
                    final newIsDark = !isDark;
                    context.read<SettingsProvider>().setThemePreference(
                      newIsDark ? ThemePreference.dark : ThemePreference.light,
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab navigation with usage indicator
  /// 带有使用量指示器的标签导航
  Widget _buildTabNavigation(bool isDark, AICoachProvider coachProvider) {
    final tier = SubscriptionService().currentTier;
    final isUnlimited = tier == SubscriptionTier.mastery;
    final isAtLimit =
        !isUnlimited &&
        (!coachProvider.canUseAISuggestion || !coachProvider.canUseAIReport);
    final coralColor = isDark ? AppColors.darkCoral : AppColors.lightCoral;

    // Start/stop pulse animation based on limit state
    if (isAtLimit && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isAtLimit && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    final usageIcon = GestureDetector(
      onTap: () => _showUsageBottomSheet(context, isDark, coachProvider),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isAtLimit
              ? Colors.red.withValues(alpha: isDark ? 0.15 : 0.08)
              : coralColor.withValues(alpha: isDark ? 0.15 : 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isAtLimit ? Icons.warning_amber_rounded : Icons.data_usage_rounded,
          color: isAtLimit ? Colors.red : coralColor,
          size: 20,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 12),
      child: Row(
        children: [
          // Spacer to balance the icon on the right
          const SizedBox(width: 36),
          // Tab bar (centered)
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.3)
                        : AppColors.lightBorder.withValues(alpha: 0.5),
                    borderRadius: UIConstants.borderRadiusMedium,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: AICoachTab.values.map((tab) {
                      final isSelected = coachProvider.currentTab == tab;
                      final tabColor = isSelected
                          ? (isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText)
                          : (isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          coachProvider.setTab(tab);
                          _loadTabData(tab, context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 14 : 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightSurface)
                                : Colors.transparent,
                            borderRadius: UIConstants.borderRadiusSmall,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tab.icon, size: 20, color: tabColor),
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text(
                                    tab.displayName,
                                    style: TextStyle(
                                      color: tabColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          // Usage icon (pulses when at limit)
          if (isAtLimit)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: usageIcon,
            )
          else
            usageIcon,
        ],
      ),
    );
  }

  /// Show bottom sheet with AI usage breakdown
  /// 显示AI使用量详情的底部弹出面板
  void _showUsageBottomSheet(
    BuildContext context,
    bool isDark,
    AICoachProvider coachProvider,
  ) {
    final tier = SubscriptionService().currentTier;
    final isUnlimited = tier == SubscriptionTier.mastery;
    final coralColor = isDark ? AppColors.darkCoral : AppColors.lightCoral;

    final maxSuggestions = tier.maxAISuggestionsPerDay;
    final remainingSuggestions = coachProvider.remainingAISuggestions;
    final usedSuggestions = isUnlimited
        ? 0
        : maxSuggestions - remainingSuggestions;

    final maxReports = tier.maxAIReportsPerMonth;
    final remainingReports = coachProvider.remainingAIReports;
    final usedReports = isUnlimited ? 0 : maxReports - remainingReports;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'AI Usage',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 20),

              // Suggestions row
              _buildUsageRow(
                isDark: isDark,
                icon: Icons.bolt_rounded,
                label: 'AI Suggestions',
                sublabel: isUnlimited
                    ? 'Unlimited'
                    : '$usedSuggestions of $maxSuggestions used today',
                used: usedSuggestions,
                max: maxSuggestions,
                isUnlimited: isUnlimited,
                coralColor: coralColor,
              ),
              const SizedBox(height: 16),

              // Reports row
              _buildUsageRow(
                isDark: isDark,
                icon: Icons.bar_chart_rounded,
                label: 'AI Reports',
                sublabel: isUnlimited
                    ? 'Unlimited'
                    : '$usedReports of $maxReports used this month',
                used: usedReports,
                max: maxReports,
                isUnlimited: isUnlimited,
                coralColor: coralColor,
              ),

              // Upgrade button
              if (!isUnlimited) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      SubscriptionService().presentPaywall();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: coralColor.withValues(alpha: 0.1),
                      foregroundColor: coralColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Upgrade for more',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Build a single usage row for the bottom sheet
  /// 为底部弹出面板构建单个使用量行
  Widget _buildUsageRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String sublabel,
    required int used,
    required int max,
    required bool isUnlimited,
    required Color coralColor,
  }) {
    final isAtLimit = !isUnlimited && used >= max;
    final color = isAtLimit ? Colors.red : coralColor;
    final progress = isUnlimited
        ? 0.0
        : (max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 13,
                  color: isAtLimit
                      ? Colors.red
                      : (isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText),
                ),
              ),
              if (!isUnlimited) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.3)
                        : AppColors.lightBorder.withValues(alpha: 0.5),
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Tab content switcher based on current tab selection
  /// 根据当前标签选择切换标签内容
  Widget _buildTabContent(bool isDark, AICoachProvider coachProvider) {
    switch (coachProvider.currentTab) {
      case AICoachTab.suggestions:
        return _buildSuggestionsTab(isDark, coachProvider);
      case AICoachTab.insights:
        return _buildInsightsTab(isDark, coachProvider);
      case AICoachTab.scores:
        return _buildScoresTab(isDark);
      case AICoachTab.actions:
        return _buildActionsTab(isDark, coachProvider);
    }
  }

  /// Suggestions Tab with pull-to-refresh and suggestion cards
  /// 带有下拉刷新和建议卡片的建议标签
  Widget _buildSuggestionsTab(bool isDark, AICoachProvider coachProvider) {
    if (coachProvider.isLoadingSuggestions) {
      // Start skeleton animation on demand
      if (!_skeletonController.isAnimating) {
        _skeletonController.repeat(reverse: true);
      }
      return _buildSuggestionsLoadingSkeleton(isDark);
    } else {
      // Stop skeleton animation when not loading
      if (_skeletonController.isAnimating) {
        _skeletonController.stop();
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (!coachProvider.canRefreshSuggestions) return;
        await _refreshSuggestions(context);
      },
      color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
      child: coachProvider.suggestions.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _buildEmptyState(
                  isDark,
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'No suggestions yet',
                  subtitle:
                      'Keep tracking your habits and we\'ll find patterns to suggest new ones',
                ),
              ),
            )
          : _buildSuggestionsList(isDark, coachProvider),
    );
  }

  /// Builds the suggestions list using ListView.builder for lazy rendering
  /// 使用 ListView.builder 构建建议列表以实现懒加载渲染
  Widget _buildSuggestionsList(bool isDark, AICoachProvider coachProvider) {
    final suggestions = coachProvider.suggestions;
    final hasFallback = coachProvider.usedFallback;
    // Header + optional fallback banner + suggestion cards
    final headerCount = hasFallback ? 2 : 1;
    final totalItems = headerCount + suggestions.length;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              _buildSuggestionsHeader(isDark, coachProvider),
              const SizedBox(height: 8),
            ],
          );
        }
        if (hasFallback && index == 1) {
          return _buildFallbackBanner(isDark, coachProvider);
        }
        final suggestionIndex = index - headerCount;
        return _buildSuggestionCard(
          isDark,
          suggestions[suggestionIndex],
          coachProvider,
        );
      },
    );
  }

  /// Header row for suggestions tab with refresh button and rate limit
  /// 建议标签的标题行，包含刷新按钮和速率限制
  Widget _buildSuggestionsHeader(bool isDark, AICoachProvider coachProvider) {
    return Row(
      children: [
        Text(
          'Suggestions',
          style: TextStyle(
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        // Refresh button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: coachProvider.isLoadingSuggestions
                ? null
                : coachProvider.canRefreshSuggestions
                ? () => _refreshSuggestions(context)
                : () => _showCooldownTooltip(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              key: _refreshButtonKey,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.5)
                    : AppColors.lightBorder.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: coachProvider.isLoadingSuggestions
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark
                            ? AppColors.darkCoral
                            : AppColors.lightCoral,
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      color: coachProvider.canRefreshSuggestions
                          ? (isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText)
                          : (isDark
                                ? AppColors.darkSecondaryText.withValues(
                                    alpha: 0.3,
                                  )
                                : AppColors.lightSecondaryText.withValues(
                                    alpha: 0.3,
                                  )),
                      size: 20,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// Fallback/error banner for suggestions when AI fails
  /// 当AI失败时显示的建议回退/错误横幅
  Widget _buildFallbackBanner(bool isDark, AICoachProvider coachProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.08),
        borderRadius: UIConstants.borderRadiusSmall,
        border: Border.all(
          color: isDark
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: isDark ? Colors.red[300] : Colors.red[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              coachProvider.suggestionsError ?? 'Using default suggestions',
              style: TextStyle(
                color: isDark ? Colors.red[300] : Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: coachProvider.canRefreshSuggestions
                ? () => _refreshSuggestions(context)
                : () => _showCooldownTooltip(context),
            child: Text(
              'Retry',
              style: TextStyle(
                color: coachProvider.canRefreshSuggestions
                    ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                    : (isDark
                          ? AppColors.darkCoral.withValues(alpha: 0.3)
                          : AppColors.lightCoral.withValues(alpha: 0.3)),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Suggestion Card displaying AI-generated habit suggestion
  /// 显示AI生成的习惯建议的建议卡片
  Widget _buildSuggestionCard(
    bool isDark,
    AICoachSuggestion suggestion,
    AICoachProvider coachProvider,
  ) {
    final gradientColors = suggestion.category.getGradient(
      isDark ? Brightness.dark : Brightness.light,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: UIConstants.borderRadiusLarge,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isDark ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(suggestion.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),

                // Title and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Impact badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: suggestion
                                  .getImpactColor(isDark)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${suggestion.estimatedImpact} Impact',
                              style: TextStyle(
                                color: suggestion.getImpactColor(isDark),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Time
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${suggestion.estimatedMinutes} min',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Frequency/goal badge
                          Flexible(
                            child: Text(
                              _buildSuggestionBadgeText(suggestion),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.description,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Why This Helps section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.3)
                        : AppColors.lightBorder.withValues(alpha: 0.3),
                    borderRadius: UIConstants.borderRadiusSmall,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Why This Helps',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              suggestion.whyThisHelps,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Dismiss button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      coachProvider.dismissSuggestion(suggestion.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Suggestion dismissed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Add button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HabitCreationScreen(
                            aiCoachSuggestion: suggestion,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkCoral
                          : AppColors.lightCoral,
                      foregroundColor: isDark
                          ? AppColors.darkBackground
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: UIConstants.borderRadiusSmall,
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Add Habit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Insights Tab with weekly summary and pattern discovery
  /// 带有每周总结和模式发现的洞察标签
  Widget _buildInsightsTab(bool isDark, AICoachProvider coachProvider) {
    if (coachProvider.isLoadingInsights) {
      return _buildInsightsLoadingSkeleton(isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outdated banner for weekly summary
          if (coachProvider.weeklySummary != null)
            Builder(
              builder: (context) {
                final habitProvider = context.watch<HabitProvider>();
                if (!coachProvider.isWeeklySummaryOutdated(
                  habitProvider.habits,
                )) {
                  return const SizedBox.shrink();
                }
                return OutdatedReportBanner(
                  isRefreshing: coachProvider.isLoadingInsights,
                  onRefresh: () {
                    final hp = Provider.of<HabitProvider>(
                      context,
                      listen: false,
                    );
                    final weekData = {
                      'totalCompletions': hp.totalCount,
                      'currentStreak': hp.bestStreak,
                    };
                    coachProvider.loadInsights(
                      weekData: weekData,
                      habits: hp.habits,
                      forceRefresh: true,
                    );
                  },
                );
              },
            ),

          // Weekly Summary
          if (coachProvider.weeklySummary != null)
            _buildWeeklySummaryCard(isDark, coachProvider.weeklySummary!),

          const SizedBox(height: 24),

          // Section Header
          Text(
            'Pattern Discovery',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Pattern Cards or Empty Hint
          if (coachProvider.patterns.isNotEmpty)
            ...coachProvider.patterns.map(
              (pattern) => _buildPatternCard(isDark, pattern),
            )
          else if (!coachProvider.isLoadingInsights)
            _buildPatternsEmptyHint(isDark),
        ],
      ),
    );
  }

  /// Empty state hint when no patterns are available yet
  /// 尚无可用模式时的空状态提示
  Widget _buildPatternsEmptyHint(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.5)
            : AppColors.lightSurface.withValues(alpha: 0.5),
        borderRadius: UIConstants.borderRadiusMedium,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights_rounded,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete more habits over the next few days and we\'ll discover your behavioral patterns.',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Weekly Summary Card with stats, insight, and next steps
  /// 带有统计、洞察和下一步建议的每周总结卡片
  Widget _buildWeeklySummaryCard(bool isDark, WeeklyAISummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.darkCoral.withValues(alpha: 0.15),
                  AppColors.darkCoral.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.lightCoral.withValues(alpha: 0.15),
                  AppColors.lightCoral.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: UIConstants.borderRadiusLarge,
        border: Border.all(
          color: (isDark ? AppColors.darkCoral : AppColors.lightCoral)
              .withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Weekly Summary',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                summary.weekRange,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats Row — use live data from providers, not cached summary
          Builder(
            builder: (context) {
              final progressProvider = context.watch<ProgressProvider>();
              final habitProvider = context.watch<HabitProvider>();
              final liveRate =
                  progressProvider.stats?.completionRate ??
                  summary.completionRate;
              final liveStreak =
                  progressProvider.stats?.bestStreak ?? summary.currentStreak;
              final liveCompleted = habitProvider.habits
                  .where((h) => h.isCompleted)
                  .length;
              final liveTotal = habitProvider.habits.length;
              return Row(
                children: [
                  Expanded(
                    child: _buildWeeklyStat(
                      isDark,
                      '$liveCompleted/$liveTotal',
                      'Today',
                    ),
                  ),
                  Expanded(
                    child: _buildWeeklyStat(
                      isDark,
                      '${(liveRate * 100).toInt()}%',
                      'Success Rate',
                    ),
                  ),
                  Expanded(
                    child: _buildWeeklyStat(
                      isDark,
                      '$liveStreak',
                      'Day Streak',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Insight
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: summary.getPerformanceColor(isDark).withValues(alpha: 0.1),
              borderRadius: UIConstants.borderRadiusSmall,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  size: 16,
                  color: summary.getPerformanceColor(isDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.insight,
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
          const SizedBox(height: 12),

          // Highlights
          ...summary.highlights.map(
            (highlight) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      highlight,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Next Steps
          if (summary.nextSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                ),
                const SizedBox(width: 6),
                Text(
                  'Next Steps',
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
            const SizedBox(height: 8),
            ...summary.nextSteps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.getPriorityColor(isDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.action,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${step.timeframe} · ${step.priority} priority',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a single weekly statistic column (value + label)
  /// 构建单个每周统计列（值 + 标签）
  Widget _buildWeeklyStat(bool isDark, String value, String label) {
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

  /// Scores Tab - Daily Review and Habit Scores
  /// 评分标签 - 每日回顾和习惯评分
  Widget _buildScoresTab(bool isDark) {
    final scoringProvider = Provider.of<AIScoringProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);

    // Initialize scoring provider if needed
    if (!scoringProvider.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scoringProvider.initialize();
      });
    }

    if (scoringProvider.isLoadingReview) {
      return _buildScoresLoadingSkeleton(isDark);
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await scoringProvider.generateDailyReview(habitProvider.habits);
      },
      color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outdated banner for daily review
            if (scoringProvider.todaysReview != null &&
                scoringProvider.isDailyReviewOutdated(habitProvider.habits))
              OutdatedReportBanner(
                isRefreshing: scoringProvider.isLoadingReview,
                onRefresh: () {
                  HapticFeedback.mediumImpact();
                  scoringProvider.generateDailyReview(habitProvider.habits);
                },
              ),

            // Daily Review Card
            if (scoringProvider.todaysReview != null)
              _buildDailyReviewCard(isDark, scoringProvider.todaysReview!)
            else
              _buildGenerateReviewCard(isDark, scoringProvider, habitProvider),

            const SizedBox(height: 24),

            // Overall Score Summary
            if (scoringProvider.habitScores.isNotEmpty) ...[
              Text(
                'Habit Scores',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildOverallScoreSummary(isDark, scoringProvider),
              const SizedBox(height: 16),
            ],

            // Health Insights (if available)
            if (scoringProvider.healthIntegrationEnabled &&
                scoringProvider.healthCorrelations != null) ...[
              const SizedBox(height: 8),
              Text(
                'Health Insights',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildHealthInsightsCard(isDark, scoringProvider),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Generate Review Call-to-Action Card
  /// 生成回顾的行动号召卡片
  Widget _buildGenerateReviewCard(
    bool isDark,
    AIScoringProvider scoringProvider,
    HabitProvider habitProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: UIConstants.borderRadiusLarge,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
          ),
          const SizedBox(height: 16),
          Text(
            'Get Your Daily Review',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Receive personalized AI coaching based on your habit performance today',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  habitProvider.habits.isEmpty ||
                      scoringProvider.isLoadingReview
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      scoringProvider.generateDailyReview(habitProvider.habits);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkCoral
                    : AppColors.lightCoral,
                foregroundColor: isDark
                    ? AppColors.darkBackground
                    : Colors.white,
                disabledBackgroundColor: isDark
                    ? AppColors.darkCoral.withValues(alpha: 0.5)
                    : AppColors.lightCoral.withValues(alpha: 0.5),
                disabledForegroundColor: isDark
                    ? AppColors.darkBackground.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: UIConstants.borderRadiusMedium,
                ),
                elevation: 0,
              ),
              child: scoringProvider.isLoadingReview
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? AppColors.darkBackground.withValues(
                                    alpha: 0.7,
                                  )
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Generating...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Generate Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Daily Review Card with score, coach comments, and breakdown
  /// 带有评分、教练评论和详情的每日回顾卡片
  Widget _buildDailyReviewCard(bool isDark, DailyReview review) {
    final scoreColor = review.overallScore >= 80
        ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50))
        : review.overallScore >= 60
        ? (isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800))
        : (isDark ? const Color(0xFFEF5350) : const Color(0xFFF44336));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  scoreColor.withValues(alpha: 0.15),
                  scoreColor.withValues(alpha: 0.05),
                ]
              : [
                  scoreColor.withValues(alpha: 0.15),
                  scoreColor.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: UIConstants.borderRadiusLarge,
        border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with score
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Score circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withValues(alpha: 0.2),
                    border: Border.all(color: scoreColor, width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${review.overallScore}',
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        review.grade,
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Review",
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            review.scoreChange >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 16,
                            color: review.scoreChange >= 0
                                ? (isDark
                                      ? const Color(0xFF66BB6A)
                                      : const Color(0xFF4CAF50))
                                : (isDark
                                      ? const Color(0xFFEF5350)
                                      : const Color(0xFFF44336)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${review.scoreChange >= 0 ? '+' : ''}${review.scoreChange} from yesterday',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (ctx) {
                          final hp = ctx.watch<HabitProvider>();
                          final done = hp.habits
                              .where((h) => h.isCompleted)
                              .length;
                          final total = hp.habits.length;
                          return Text(
                            '$done/$total habits completed',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Coach Comments
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: UIConstants.borderRadiusMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.darkCoral
                            : AppColors.lightCoral,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Coach Analysis',
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
                  Text(
                    review.coachComments.summary,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  if (review.coachComments.highlight.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildCoachCommentItem(
                      isDark,
                      Icons.star_rounded,
                      'Highlight',
                      review.coachComments.highlight,
                      const Color(0xFFFFB74D),
                    ),
                  ],
                  if (review.coachComments.concern != null) ...[
                    const SizedBox(height: 8),
                    _buildCoachCommentItem(
                      isDark,
                      Icons.info_outline_rounded,
                      'Attention',
                      review.coachComments.concern!,
                      const Color(0xFFEF5350),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildCoachCommentItem(
                    isDark,
                    Icons.play_arrow_rounded,
                    'Action Item',
                    review.coachComments.actionItem,
                    isDark ? AppColors.darkCoral : AppColors.lightCoral,
                  ),
                ],
              ),
            ),
          ),

          // Per-Habit Score Breakdown
          if (review.habitScores.isNotEmpty)
            _buildHabitScoreBreakdown(isDark, review),

          // Score Trend (7-day history)
          _buildScoreTrendDots(isDark),

          // Health Insights
          if (review.healthInsights.hasData)
            _buildReviewHealthInsights(isDark, review),

          // Tomorrow's Focus
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                    .withValues(alpha: 0.1),
                borderRadius: UIConstants.borderRadiusSmall,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wb_sunny_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tomorrow\'s Focus',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          review.tomorrowFocus,
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
            ),
          ),

          // Motivational Message
          if (review.motivationalMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.3)
                      : AppColors.lightBorder.withValues(alpha: 0.3),
                  borderRadius: UIConstants.borderRadiusMedium,
                  border: Border(
                    left: BorderSide(
                      color: isDark
                          ? AppColors.darkCoral
                          : AppColors.lightCoral,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkCoral
                          : AppColors.lightCoral,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        review.motivationalMessage,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
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

  /// Per-habit score breakdown section with expandable details
  /// 每个习惯的评分细分区域，支持展开查看详情
  Widget _buildHabitScoreBreakdown(bool isDark, DailyReview review) {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final scoringProvider = Provider.of<AIScoringProvider>(
      context,
      listen: false,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: UIConstants.borderRadiusMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit Breakdown',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...review.habitScores.map((habitScore) {
              final habit = habitProvider.habits
                  .where(
                    (h) =>
                        h.id == habitScore.habitId ||
                        h.name == habitScore.habitId,
                  )
                  .firstOrNull;
              final habitName = habit?.name ?? habitScore.habitId;
              final habitId = habit?.id ?? habitScore.habitId;
              final isExpanded = _expandedHabits.contains(habitId);

              final statusIcon = _getStatusIcon(habitScore.status);
              final statusColor = _getStatusColor(habitScore.status, isDark);
              final scoreColor = habitScore.score >= 80
                  ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50))
                  : habitScore.score >= 60
                  ? (isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800))
                  : (isDark
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFF44336));

              // Look up detailed HabitScore from AIScoringProvider
              final detailedScore = scoringProvider.getScoreForHabit(habitId);

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Collapsed header row — always visible
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedHabits.remove(habitId);
                          } else {
                            _expandedHabits.add(habitId);
                          }
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                habitName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.lightPrimaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scoreColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${habitScore.score}',
                                style: TextStyle(
                                  color: scoreColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.expand_more_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expanded detail area
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: isExpanded
                          ? _buildExpandedHabitDetail(
                              isDark,
                              habitScore,
                              detailedScore,
                            )
                          : const SizedBox.shrink(),
                    ),
                    // Divider between items
                    Divider(
                      height: 1,
                      color:
                          (isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText)
                              .withValues(alpha: 0.15),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Expanded detail for a single habit in the breakdown
  /// 习惯细分中单个习惯的展开详情
  Widget _buildExpandedHabitDetail(
    bool isDark,
    HabitDayScore habitScore,
    HabitScore? detailedScore,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI comment
          if (habitScore.comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                habitScore.comment,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          // 4-dimension breakdown bars (only if detailed score exists)
          if (detailedScore != null) ...[
            _buildDimensionBar(
              isDark,
              'Consistency',
              detailedScore.breakdown.consistency.score,
            ),
            _buildDimensionBar(
              isDark,
              'Momentum',
              detailedScore.breakdown.momentum.score,
            ),
            _buildDimensionBar(
              isDark,
              'Resilience',
              detailedScore.breakdown.resilience.score,
            ),
            _buildDimensionBar(
              isDark,
              'Engagement',
              detailedScore.breakdown.engagement.score,
            ),
            const SizedBox(height: 6),
            // Primary strength
            if (detailedScore.primaryStrength.isNotEmpty)
              _buildInsightRow(
                isDark,
                Icons.star_rounded,
                const Color(0xFFFFB74D),
                detailedScore.primaryStrength,
              ),
            // Primary weakness
            if (detailedScore.primaryWeakness.isNotEmpty)
              _buildInsightRow(
                isDark,
                Icons.flag_rounded,
                const Color(0xFFEF5350),
                detailedScore.primaryWeakness,
              ),
            // Recommendation
            if (detailedScore.recommendation.isNotEmpty)
              _buildInsightRow(
                isDark,
                Icons.lightbulb_outline_rounded,
                const Color(0xFF66BB6A),
                detailedScore.recommendation,
              ),
          ],
        ],
      ),
    );
  }

  /// Single dimension progress bar (e.g. Consistency: 72)
  /// 单个维度进度条（如一致性：72）
  Widget _buildDimensionBar(bool isDark, String label, int score) {
    final barColor = score >= 70
        ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50))
        : score >= 50
        ? (isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800))
        : (isDark ? const Color(0xFFEF5350) : const Color(0xFFF44336));

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                fontSize: 10.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (score / 100.0).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor:
                    (isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText)
                        .withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 22,
            child: Text(
              '$score',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: barColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Small insight row with icon + text
  /// 带有图标和文本的小型洞察行
  Widget _buildInsightRow(
    bool isDark,
    IconData icon,
    Color iconColor,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the icon for a given habit day status
  /// 返回给定习惯日状态的图标
  IconData _getStatusIcon(HabitDayStatus status) {
    switch (status) {
      case HabitDayStatus.completed:
        return Icons.check_circle_rounded;
      case HabitDayStatus.missed:
        return Icons.cancel_rounded;
      case HabitDayStatus.streakMilestone:
        return Icons.local_fire_department_rounded;
      case HabitDayStatus.streakBroken:
        return Icons.link_off_rounded;
    }
  }

  /// Returns the color for a given habit day status
  /// 返回给定习惯日状态的颜色
  Color _getStatusColor(HabitDayStatus status, bool isDark) {
    switch (status) {
      case HabitDayStatus.completed:
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);
      case HabitDayStatus.missed:
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFF44336);
      case HabitDayStatus.streakMilestone:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
      case HabitDayStatus.streakBroken:
        return isDark ? const Color(0xFF90A4AE) : const Color(0xFF607D8B);
    }
  }

  /// 7-day score trend line chart
  /// 7天评分趋势折线图
  Widget _buildScoreTrendDots(bool isDark) {
    final scoringProvider = Provider.of<AIScoringProvider>(
      context,
      listen: false,
    );
    final history = scoringProvider.reviewHistory;

    if (history.length < 2) return const SizedBox.shrink();

    // Deduplicate by date (keep the most recent entry per day), then take up to 7
    final seenDates = <String>{};
    final deduplicated = <DailyReview>[];
    for (final r in history) {
      if (seenDates.add(r.date)) deduplicated.add(r);
    }
    final recentReviews = deduplicated.take(7).toList().reversed.toList();
    final scores = recentReviews.map((r) => r.overallScore).toList();
    final dayLabels = recentReviews.map((r) {
      try {
        final date = DateTime.parse(r.date);
        return DateFormat('E').format(date); // Mon, Tue, etc.
      } catch (_) {
        return '';
      }
    }).toList();

    final lineColor = isDark ? AppColors.darkCoral : AppColors.lightCoral;
    final labelStyle = TextStyle(
      color: isDark
          ? AppColors.darkSecondaryText
          : AppColors.lightSecondaryText,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: UIConstants.borderRadiusMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7-Day Score Trend',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: CustomPaint(
                size: Size.infinite,
                painter: ScoreTrendChartPainter(
                  scores: scores,
                  dayLabels: dayLabels,
                  lineColor: lineColor,
                  isDark: isDark,
                  labelStyle: labelStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Health insights from daily review
  /// 来自每日回顾的健康洞察
  Widget _buildReviewHealthInsights(bool isDark, DailyReview review) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2636) : const Color(0xFFE8F5E9),
          borderRadius: UIConstants.borderRadiusSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: isDark
                      ? const Color(0xFFEF5350)
                      : const Color(0xFFF44336),
                ),
                const SizedBox(width: 6),
                Text(
                  'Health Insights',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (review.healthInsights.correlation != null) ...[
              const SizedBox(height: 8),
              Text(
                review.healthInsights.correlation!,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            if (review.healthInsights.recommendation != null) ...[
              const SizedBox(height: 6),
              Text(
                review.healthInsights.recommendation!,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a single coach comment item with icon, label, and content
  /// 构建带有图标、标签和内容的单个教练评论项
  Widget _buildCoachCommentItem(
    bool isDark,
    IconData icon,
    String label,
    String content,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                content,
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
    );
  }

  /// Overall Score Summary with average score and progress bar
  /// 带有平均分和进度条的总体评分摘要
  Widget _buildOverallScoreSummary(bool isDark, AIScoringProvider provider) {
    final avgScore = provider.overallAverageScore;
    final scoreColor = avgScore >= 80
        ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50))
        : avgScore >= 60
        ? (isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800))
        : (isDark ? const Color(0xFFEF5350) : const Color(0xFFF44336));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: UIConstants.borderRadiusMedium,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average Score',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Text(
                    avgScore.toStringAsFixed(0),
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/100',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: avgScore / 100,
              backgroundColor: scoreColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${provider.habitScores.length} habits scored',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Health Insights Card showing health-habit correlations
  /// 显示健康与习惯关联的健康洞察卡片
  Widget _buildHealthInsightsCard(bool isDark, AIScoringProvider provider) {
    final correlations = provider.healthCorrelations;
    if (correlations == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: UIConstants.borderRadiusMedium,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 20,
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
              ),
              const SizedBox(width: 8),
              Text(
                'Health-Habit Correlations',
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
          const SizedBox(height: 16),
          ...correlations.keyFindings
              .take(3)
              .map(
                (finding) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppColors.darkCoral
                              : AppColors.lightCoral,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          finding,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                            fontSize: 13,
                          ),
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

  /// Pattern Card showing a discovered behavioral pattern
  /// 显示发现的行为模式的模式卡片
  Widget _buildPatternCard(bool isDark, AIPattern pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: UIConstants.borderRadiusMedium,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pattern.getPatternColor(isDark).withValues(alpha: 0.15),
            ),
            child: Icon(
              pattern.icon,
              color: pattern.getPatternColor(isDark),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: pattern
                        .getPatternColor(isDark)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pattern.type.displayName,
                    style: TextStyle(
                      color: pattern.getPatternColor(isDark),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  pattern.title,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  pattern.description,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Insight
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.3)
                        : AppColors.lightBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pattern.insight,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Actions Tab with daily, weekly, and challenge action items
  /// 带有每日、每周和挑战行动项的操作标签
  Widget _buildActionsTab(bool isDark, AICoachProvider coachProvider) {
    if (coachProvider.isLoadingActions) {
      return _buildActionsLoadingSkeleton(isDark);
    }

    if (coachProvider.actionItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEmptyState(
              isDark,
              icon: Icons.task_alt_rounded,
              title: 'No action items yet',
              subtitle:
                  'Track habits for a few days and we\'ll generate personalized actions',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: coachProvider.canUseAIReport
                  ? () {
                      HapticFeedback.mediumImpact();
                      _loadActionItems(context);
                    }
                  : null,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Generate Actions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkCoral
                    : AppColors.lightCoral,
                foregroundColor: isDark
                    ? AppColors.darkBackground
                    : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: UIConstants.borderRadiusMedium,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Group by type
    final dailyActions = coachProvider.actionItems
        .where((a) => a.type == ActionItemType.daily)
        .toList();
    final weeklyActions = coachProvider.actionItems
        .where((a) => a.type == ActionItemType.weekly)
        .toList();
    final challenges = coachProvider.actionItems
        .where((a) => a.type == ActionItemType.challenge)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await _loadActionItems(context, forceRefresh: true);
      },
      color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Header with refresh
          Row(
            children: [
              Text(
                'Your Action Items',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: coachProvider.isLoadingActions
                      ? null
                      : () => _loadActionItems(context, forceRefresh: true),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.5)
                          : AppColors.lightBorder.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily actions
          if (dailyActions.isNotEmpty) ...[
            _buildActionGroupHeader(
              isDark,
              "Today's Actions",
              Icons.today_rounded,
            ),
            const SizedBox(height: 8),
            ...dailyActions.map(
              (action) => _buildActionItemCard(isDark, action, coachProvider),
            ),
            const SizedBox(height: 20),
          ],

          // Weekly actions
          if (weeklyActions.isNotEmpty) ...[
            _buildActionGroupHeader(
              isDark,
              'This Week',
              Icons.date_range_rounded,
            ),
            const SizedBox(height: 8),
            ...weeklyActions.map(
              (action) => _buildActionItemCard(isDark, action, coachProvider),
            ),
            const SizedBox(height: 20),
          ],

          // Challenges
          if (challenges.isNotEmpty) ...[
            _buildActionGroupHeader(
              isDark,
              'Challenges',
              Icons.emoji_events_rounded,
            ),
            const SizedBox(height: 8),
            ...challenges.map(
              (action) => _buildActionItemCard(isDark, action, coachProvider),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Builds an action group header with icon and title
  /// 构建带有图标和标题的操作分组标题
  Widget _buildActionGroupHeader(bool isDark, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Builds a single action item card with checkbox and details
  /// 构建带有复选框和详情的单个行动项卡片
  Widget _buildActionItemCard(
    bool isDark,
    AIActionItem action,
    AICoachProvider coachProvider,
  ) {
    final priorityColor = action.priority.getColor(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: UIConstants.borderRadiusMedium,
        border: Border.all(
          color: action.isCompleted
              ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50))
                    .withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              coachProvider.completeActionItem(action.id);
            },
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: action.isCompleted
                    ? (isDark
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFF4CAF50))
                    : Colors.transparent,
                border: Border.all(
                  color: action.isCompleted
                      ? (isDark
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFF4CAF50))
                      : (isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText),
                  width: 2,
                ),
              ),
              child: action.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with priority
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        action.title,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: action.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: priorityColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  action.description,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 8),

                // Tags row
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    // Related habit badge (tappable if linked to a habit ID)
                    if (action.relatedHabit != null &&
                        action.relatedHabit!.isNotEmpty)
                      GestureDetector(
                        onTap: action.relatedHabitId != null
                            ? () {
                                final habitProvider =
                                    Provider.of<HabitProvider>(
                                      context,
                                      listen: false,
                                    );
                                final habit = habitProvider.habits
                                    .where((h) => h.id == action.relatedHabitId)
                                    .firstOrNull;
                                if (habit != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          HabitDetailScreen(habit: habit),
                                    ),
                                  );
                                }
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppColors.darkCoral
                                        : AppColors.lightCoral)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                action.relatedHabit!,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkCoral
                                      : AppColors.lightCoral,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (action.relatedHabitId != null) ...[
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 10,
                                  color: isDark
                                      ? AppColors.darkCoral
                                      : AppColors.lightCoral,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    // Metric badge
                    if (action.metric != null && action.metric!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder.withValues(alpha: 0.4)
                              : AppColors.lightBorder.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          action.metric!,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton building block - rounded rectangle placeholder
  /// 骨架屏构建块 - 圆角矩形占位符
  Widget _buildSkeletonBox(bool isDark, double width, double height) {
    return AnimatedBuilder(
      animation: _skeletonController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_skeletonController.value * 0.4),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCoral.withValues(alpha: 0.12)
                  : AppColors.lightCoral.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      },
    );
  }

  /// Skeleton building block - circle placeholder
  /// 骨架屏构建块 - 圆形占位符
  Widget _buildSkeletonCircle(bool isDark, double size) {
    return AnimatedBuilder(
      animation: _skeletonController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_skeletonController.value * 0.4),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCoral.withValues(alpha: 0.12)
                  : AppColors.lightCoral.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  /// Branded AI generating header for loading skeletons
  /// 加载骨架屏的品牌化AI生成标题
  Widget _buildAIGeneratingHeader(bool isDark, String message) {
    final coral = isDark ? AppColors.darkCoral : AppColors.lightCoral;
    final pink = isDark ? AppColors.darkPink : AppColors.lightPink;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [coral.withValues(alpha: 0.08), pink.withValues(alpha: 0.06)],
        ),
        borderRadius: UIConstants.borderRadiusMedium,
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _skeletonController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.5 + (_skeletonController.value * 0.5),
                child: Container(
                  width: 32,
                  height: 32,
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
                    size: 18,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: coral,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Powered by AI',
                  style: TextStyle(
                    color: coral.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: coral),
          ),
        ],
      ),
    );
  }

  /// Suggestions skeleton loading placeholder
  /// 建议骨架屏加载占位符
  Widget _buildSuggestionsLoadingSkeleton(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildAIGeneratingHeader(
          isDark,
          'Generating personalized suggestions...',
        ),
        ...List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: UIConstants.borderRadiusLarge,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSkeletonCircle(isDark, 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonBox(isDark, 160, 16),
                          const SizedBox(height: 8),
                          _buildSkeletonBox(isDark, 100, 12),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSkeletonBox(isDark, double.infinity, 1),
                const SizedBox(height: 16),
                _buildSkeletonBox(isDark, double.infinity, 14),
                const SizedBox(height: 8),
                _buildSkeletonBox(isDark, 200, 14),
                const SizedBox(height: 12),
                _buildSkeletonBox(isDark, double.infinity, 60),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Insights skeleton loading placeholder
  /// 洞察骨架屏加载占位符
  Widget _buildInsightsLoadingSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIGeneratingHeader(isDark, 'Analyzing your weekly patterns...'),
          // Weekly summary card skeleton
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCoral.withValues(alpha: 0.08)
                  : AppColors.lightCoral.withValues(alpha: 0.08),
              borderRadius: UIConstants.borderRadiusLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSkeletonCircle(isDark, 20),
                    const SizedBox(width: 8),
                    _buildSkeletonBox(isDark, 120, 16),
                    const Spacer(),
                    _buildSkeletonBox(isDark, 80, 12),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildSkeletonBox(isDark, 60, 28),
                    const SizedBox(width: 24),
                    _buildSkeletonBox(isDark, 60, 28),
                    const SizedBox(width: 24),
                    _buildSkeletonBox(isDark, 60, 28),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSkeletonBox(isDark, double.infinity, 50),
                const SizedBox(height: 12),
                _buildSkeletonBox(isDark, double.infinity, 14),
                const SizedBox(height: 6),
                _buildSkeletonBox(isDark, 240, 14),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSkeletonBox(isDark, 140, 18),
          const SizedBox(height: 12),
          // Pattern card skeletons
          ...List.generate(
            2,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: UIConstants.borderRadiusMedium,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonCircle(isDark, 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonBox(isDark, 80, 12),
                          const SizedBox(height: 8),
                          _buildSkeletonBox(isDark, 180, 15),
                          const SizedBox(height: 6),
                          _buildSkeletonBox(isDark, double.infinity, 13),
                          const SizedBox(height: 4),
                          _buildSkeletonBox(isDark, 160, 13),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Scores skeleton loading placeholder
  /// 评分骨架屏加载占位符
  Widget _buildScoresLoadingSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIGeneratingHeader(isDark, 'Generating your daily review...'),
          // Daily review card skeleton
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: UIConstants.borderRadiusLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSkeletonCircle(isDark, 72),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonBox(isDark, 140, 18),
                          const SizedBox(height: 8),
                          _buildSkeletonBox(isDark, 180, 13),
                          const SizedBox(height: 4),
                          _buildSkeletonBox(isDark, 160, 13),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSkeletonBox(isDark, double.infinity, 120),
                const SizedBox(height: 16),
                _buildSkeletonBox(isDark, double.infinity, 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Actions skeleton loading placeholder
  /// 操作骨架屏加载占位符
  Widget _buildActionsLoadingSkeleton(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildAIGeneratingHeader(isDark, 'Creating your action plan...'),
        _buildSkeletonBox(isDark, 120, 16),
        const SizedBox(height: 12),
        ...List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: UIConstants.borderRadiusMedium,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonBox(isDark, 24, 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonBox(isDark, 200, 15),
                      const SizedBox(height: 6),
                      _buildSkeletonBox(isDark, double.infinity, 13),
                      const SizedBox(height: 4),
                      _buildSkeletonBox(isDark, 160, 13),
                      const SizedBox(height: 8),
                      _buildSkeletonBox(isDark, 100, 12),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        _buildSkeletonBox(isDark, 100, 16),
        const SizedBox(height: 12),
        ...List.generate(2, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: UIConstants.borderRadiusMedium,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonBox(isDark, 24, 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonBox(isDark, 180, 15),
                      const SizedBox(height: 6),
                      _buildSkeletonBox(isDark, double.infinity, 13),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Empty state placeholder with icon, title, and subtitle
  /// 带有图标、标题和副标题的空状态占位符
  Widget _buildEmptyState(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.3)
                    : AppColors.lightBorder.withValues(alpha: 0.3),
              ),
              child: Icon(
                icon,
                size: 40,
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
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
    );
  }

  /// Refreshes AI suggestions by force-loading with current habit data
  /// 通过强制加载当前习惯数据来刷新AI建议
  Future<void> _refreshSuggestions(BuildContext context) async {
    final coachProvider = Provider.of<AICoachProvider>(context, listen: false);
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    HapticFeedback.mediumImpact();

    await coachProvider.loadSuggestions(
      categories: habitProvider.habits
          .map((h) => h.category.name)
          .toSet()
          .toList(),
      currentHabits: habitProvider.habits.map((h) => h.name).toList(),
      completionRate: habitProvider.completionRate * 100,
      bestStreak: habitProvider.bestStreak,
      forceRefresh: true,
    );
  }

  /// Builds badge text showing frequency and goal for a suggestion
  /// 为建议构建显示频率和目标的徽章文本
  String _buildSuggestionBadgeText(AICoachSuggestion suggestion) {
    final parts = <String>[];
    // Frequency
    if (suggestion.frequencyType == 'weekly') {
      final dayCount = suggestion.weeklyDays?.length ?? 0;
      parts.add('${dayCount}x weekly');
    } else {
      parts.add('Daily');
    }
    // Goal
    if (suggestion.goalType != 'none' && suggestion.goalValue != null) {
      parts.add('${suggestion.goalValue} ${suggestion.goalUnit ?? ''}');
    }
    return parts.join(' | ');
  }

  /// Shows a tooltip indicating the refresh cooldown time remaining
  /// 显示刷新冷却剩余时间的工具提示
  void _showCooldownTooltip(BuildContext context) {
    _cooldownTooltip?.remove();
    _cooldownTooltip = null;

    final provider = Provider.of<AICoachProvider>(context, listen: false);
    final remaining = provider.refreshCooldownFormatted;

    final renderBox =
        _refreshButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final buttonPos = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: buttonPos.dy - 36,
        left: buttonPos.dx + buttonSize.width / 2 - 60,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Try again in $remaining',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );

    _cooldownTooltip = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      if (_cooldownTooltip == entry) {
        entry.remove();
        _cooldownTooltip = null;
      }
    });
  }

  /// Loads AI-generated action items based on current habits
  /// 根据当前习惯加载AI生成的行动项
  Future<void> _loadActionItems(
    BuildContext context, {
    bool forceRefresh = false,
  }) async {
    final coachProvider = Provider.of<AICoachProvider>(context, listen: false);
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    final habitsData = habitProvider.habits
        .map(
          (h) => {
            'id': h.id,
            'name': h.name,
            'category': h.category.name,
            'streak': h.streak,
            'completed': h.isCompleted,
          },
        )
        .toList();

    await coachProvider.loadActionItems(
      habits: habitsData,
      completionRate: habitProvider.completionRate * 100,
      bestStreak: habitProvider.bestStreak,
      forceRefresh: forceRefresh,
    );

    if (forceRefresh && coachProvider.actionsError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(coachProvider.actionsError!)));
        coachProvider.clearActionsError();
      }
    }
  }

  /// Loads data for the selected tab if not already loaded
  /// 如果尚未加载，则加载所选标签的数据
  void _loadTabData(AICoachTab tab, BuildContext context) {
    final coachProvider = Provider.of<AICoachProvider>(context, listen: false);
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    if (tab == AICoachTab.suggestions &&
        coachProvider.suggestions.isEmpty &&
        !coachProvider.isLoadingSuggestions) {
      coachProvider.loadSuggestions(
        categories: habitProvider.habits
            .map((h) => h.category.name)
            .toSet()
            .toList(),
        currentHabits: habitProvider.habits.map((h) => h.name).toList(),
        completionRate: habitProvider.completionRate * 100,
        bestStreak: habitProvider.bestStreak,
      );
    } else if (tab == AICoachTab.insights &&
        coachProvider.weeklySummary == null &&
        !coachProvider.isLoadingInsights) {
      final weekData = {
        'totalCompletions': habitProvider.totalCount,
        'currentStreak': habitProvider.bestStreak,
      };
      coachProvider.loadInsights(
        weekData: weekData,
        habits: habitProvider.habits,
      );
      // Also load patterns if not already populated
      if (coachProvider.patterns.isEmpty) {
        _loadPatterns(context);
      }
    } else if (tab == AICoachTab.actions &&
        coachProvider.actionItems.isEmpty &&
        !coachProvider.isLoadingActions) {
      _loadActionItems(context);
    }
  }

  /// Loads behavioral patterns from habit completion history
  /// 从习惯完成历史中加载行为模式
  Future<void> _loadPatterns(BuildContext context) async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final coachProvider = Provider.of<AICoachProvider>(context, listen: false);
    final habits = habitProvider.habits;

    // Need at least 2 habits for meaningful patterns
    if (habits.length < 2) return;

    final List<Map<String, dynamic>> habitsData = [];
    int totalCompletions = 0;

    for (final habit in habits) {
      List<String> completionDates = [];
      try {
        final history = await FirestoreService().getHabitHistory(
          habit.id,
          limitDays: 30,
        );
        completionDates = history.map((d) => d.toIso8601String()).toList();
      } catch (e) {
        debugPrint('Failed to fetch history for ${habit.name}: $e');
        // Continue with empty dates for this habit
      }
      totalCompletions += completionDates.length;

      final reminderStr = habit.reminderTime != null
          ? '${habit.reminderTime!.hour.toString().padLeft(2, '0')}:${habit.reminderTime!.minute.toString().padLeft(2, '0')}'
          : '';

      habitsData.add({
        'name': habit.name,
        'category': habit.category.name,
        'streak': habit.streak,
        'reminderTime': reminderStr,
        'completionDates': completionDates,
      });
    }

    // Need at least 5 total completions for meaningful analysis
    if (totalCompletions < 5) return;

    if (!mounted) return;
    await coachProvider.loadPatterns(habitsData: habitsData);
  }
}

/// Custom painter for the 7-day score trend line chart
/// 7天评分趋势折线图的自定义绘制器
class ScoreTrendChartPainter extends CustomPainter {
  final List<int> scores;
  final List<String> dayLabels;
  final Color lineColor;
  final bool isDark;
  final TextStyle labelStyle;

  /// Creates the score trend chart painter with data and styling
  /// 使用数据和样式创建评分趋势图绘制器
  ScoreTrendChartPainter({
    required this.scores,
    required this.dayLabels,
    required this.lineColor,
    required this.isDark,
    required this.labelStyle,
  });

  /// Paints the score trend chart with line, dots, and labels
  /// 绘制带有折线、点和标签的评分趋势图
  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    // Layout constants
    const double topPadding = 18; // room for score labels above dots
    const double bottomPadding = 18; // room for day labels below
    const double leftPadding = 24; // room for Y-axis min/max labels
    const double rightPadding = 12;

    const chartLeft = leftPadding;
    final chartRight = size.width - rightPadding;
    const chartTop = topPadding;
    final chartBottom = size.height - bottomPadding;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    // Determine Y range with some padding
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final yMin = (minScore - 5).clamp(0, 100);
    final yMax = (maxScore + 5).clamp(0, 100);
    final yRange = (yMax - yMin).clamp(1, 100); // avoid division by zero

    // Calculate data points
    final points = <Offset>[];
    for (int i = 0; i < scores.length; i++) {
      final x = scores.length == 1
          ? chartLeft + chartWidth / 2
          : chartLeft + (i / (scores.length - 1)) * chartWidth;
      final y = chartBottom - ((scores[i] - yMin) / yRange) * chartHeight;
      points.add(Offset(x, y));
    }

    // Draw axis lines
    final axisPaint = Paint()
      ..color = (isDark ? const Color(0xFFB0BEC5) : const Color(0xFF90A4AE))
          .withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Y-axis (left edge)
    canvas.drawLine(
      const Offset(chartLeft, chartTop),
      Offset(chartLeft, chartBottom),
      axisPaint,
    );
    // X-axis (bottom edge)
    canvas.drawLine(
      Offset(chartLeft, chartBottom),
      Offset(chartRight, chartBottom),
      axisPaint,
    );

    // Horizontal grid lines (light dashes at midpoint)
    final midY = (chartTop + chartBottom) / 2;
    final gridPaint = Paint()
      ..color = (isDark ? const Color(0xFFB0BEC5) : const Color(0xFF90A4AE))
          .withValues(alpha: 0.12)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(chartLeft, midY),
      Offset(chartRight, midY),
      gridPaint,
    );

    // Draw gradient fill below the curve
    if (points.length >= 2) {
      final fillPath = Path()..moveTo(points.first.dx, chartBottom);
      // Build smooth curve for fill
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final cx = (p0.dx + p1.dx) / 2;
        fillPath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
      }
      fillPath
        ..lineTo(points.last.dx, chartBottom)
        ..close();

      final fillPaint = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                lineColor.withValues(alpha: 0.18),
                lineColor.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom),
            );

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    if (points.length >= 2) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final cx = (p0.dx + p1.dx) / 2;
        linePath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
      }
      final linePaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, linePaint);
    }

    // Draw dots and labels
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final score = scores[i];

      // Dot color based on score
      final dotColor = score >= 80
          ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50))
          : score >= 60
          ? (isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800))
          : (isDark ? const Color(0xFFEF5350) : const Color(0xFFF44336));

      // Outer ring
      canvas.drawCircle(
        pt,
        5,
        Paint()..color = dotColor.withValues(alpha: 0.25),
      );
      // Inner dot
      canvas.drawCircle(pt, 3.5, Paint()..color = dotColor);

      // Score label above dot
      final scoreTp = TextPainter(
        text: TextSpan(
          text: '$score',
          style: labelStyle.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: dotColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      scoreTp.paint(canvas, Offset(pt.dx - scoreTp.width / 2, pt.dy - 16));

      // Day label below chart
      if (i < dayLabels.length && dayLabels[i].isNotEmpty) {
        final dayTp = TextPainter(
          text: TextSpan(text: dayLabels[i], style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        dayTp.paint(canvas, Offset(pt.dx - dayTp.width / 2, chartBottom + 4));
      }
    }

    // Y-axis min / max labels
    final yAxisStyle = labelStyle.copyWith(fontSize: 9);
    final maxTp = TextPainter(
      text: TextSpan(text: '$yMax', style: yAxisStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    maxTp.paint(
      canvas,
      Offset(chartLeft - maxTp.width - 4, chartTop - maxTp.height / 2),
    );

    final minTp = TextPainter(
      text: TextSpan(text: '$yMin', style: yAxisStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    minTp.paint(
      canvas,
      Offset(chartLeft - minTp.width - 4, chartBottom - minTp.height / 2),
    );
  }

  /// Determines whether the chart should repaint when data changes
  /// 确定数据变化时图表是否应重新绘制
  @override
  bool shouldRepaint(ScoreTrendChartPainter oldDelegate) =>
      scores != oldDelegate.scores ||
      dayLabels != oldDelegate.dayLabels ||
      lineColor != oldDelegate.lineColor ||
      isDark != oldDelegate.isDark;
}
