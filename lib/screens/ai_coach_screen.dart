import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ai_coach_models.dart';
import '../models/ai_habit_suggestion.dart';
import '../providers/ai_coach_provider.dart';
import '../config/theme/app_colors.dart';
import 'habit_creation_screen.dart';

/// AI Coach Screen with personalized suggestions and insights
class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AICoachProvider>(context, listen: false).initialize();
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
            Expanded(
              child: _buildTabContent(isDark, coachProvider),
            ),
          ],
        ),
      ),
    );
  }

  /// Hero section with gradient and AI avatar
  Widget _buildHeroSection(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 180,
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
                              color: (isDark
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
                          color:
                              isDark ? AppColors.darkBackground : Colors.white,
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
          ],
        ),
      ),
    );
  }

  /// Tab navigation
  Widget _buildTabNavigation(bool isDark, AICoachProvider coachProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBorder.withValues(alpha: 0.3)
            : AppColors.lightBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: AICoachTab.values.map((tab) {
          final isSelected = coachProvider.currentTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                coachProvider.setTab(tab);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
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
                  tab.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText)
                        : (isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Tab content
  Widget _buildTabContent(bool isDark, AICoachProvider coachProvider) {
    switch (coachProvider.currentTab) {
      case AICoachTab.suggestions:
        return _buildSuggestionsTab(isDark, coachProvider);
      case AICoachTab.insights:
        return _buildInsightsTab(isDark, coachProvider);
      case AICoachTab.tips:
        return _buildTipsTab(isDark, coachProvider);
    }
  }

  /// Suggestions Tab
  Widget _buildSuggestionsTab(bool isDark, AICoachProvider coachProvider) {
    if (coachProvider.isLoadingSuggestions) {
      return _buildLoadingState(isDark);
    }

    if (coachProvider.suggestions.isEmpty) {
      return _buildEmptyState(
        isDark,
        icon: Icons.lightbulb_outline_rounded,
        title: 'No suggestions yet',
        subtitle: 'Keep tracking your habits and we\'ll find patterns to suggest new ones',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: coachProvider.suggestions.length,
      itemBuilder: (context, index) {
        return _buildSuggestionCard(
          isDark,
          coachProvider.suggestions[index],
          coachProvider,
        );
      },
    );
  }

  /// Suggestion Card
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
        borderRadius: BorderRadius.circular(16),
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
                  child: Icon(
                    suggestion.icon,
                    color: Colors.white,
                    size: 24,
                  ),
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
                    borderRadius: BorderRadius.circular(8),
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
                      // Convert to AIHabitSuggestion for creation screen
                      final habitSuggestion = AIHabitSuggestion(
                        id: suggestion.id,
                        habitName: suggestion.title,
                        explanation: suggestion.description,
                        category: suggestion.category,
                        reason: suggestion.whyThisHelps,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HabitCreationScreen(
                            aiSuggestion: habitSuggestion,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.darkCoral : AppColors.lightCoral,
                      foregroundColor:
                          isDark ? AppColors.darkBackground : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

  /// Insights Tab
  Widget _buildInsightsTab(bool isDark, AICoachProvider coachProvider) {
    if (coachProvider.isLoadingInsights) {
      return _buildLoadingState(isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Summary
          if (coachProvider.weeklySummary != null)
            _buildWeeklySummaryCard(isDark, coachProvider.weeklySummary!),

          const SizedBox(height: 24),

          // Section Header
          Text(
            'Pattern Discovery',
            style: TextStyle(
              color:
                  isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Pattern Cards
          ...coachProvider.patterns.map(
            (pattern) => _buildPatternCard(isDark, pattern),
          ),
        ],
      ),
    );
  }

  /// Weekly Summary Card
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
        borderRadius: BorderRadius.circular(16),
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

          // Stats Row
          Row(
            children: [
              _buildWeeklyStat(
                isDark,
                '${summary.totalCompletions}/${summary.targetCompletions}',
                'Completions',
              ),
              const SizedBox(width: 24),
              _buildWeeklyStat(
                isDark,
                '${(summary.completionRate * 100).toInt()}%',
                'Success Rate',
              ),
              const SizedBox(width: 24),
              _buildWeeklyStat(
                isDark,
                '${summary.currentStreak}',
                'Day Streak',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Insight
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: summary.getPerformanceColor(isDark).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }

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
            color:
                isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Pattern Card
  Widget _buildPatternCard(bool isDark, AIPattern pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
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

  /// Tips Tab
  Widget _buildTipsTab(bool isDark, AICoachProvider coachProvider) {
    if (coachProvider.isLoadingTips) {
      return _buildLoadingState(isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: TipCategory.values.length,
      itemBuilder: (context, index) {
        final category = TipCategory.values[index];
        final tips = coachProvider.tipsByCategory[category] ?? [];
        final isExpanded = coachProvider.expandedTipCategory == category;

        return _buildTipCategoryCard(isDark, category, tips, isExpanded, coachProvider);
      },
    );
  }

  /// Tip Category Card
  Widget _buildTipCategoryCard(
    bool isDark,
    TipCategory category,
    List<AITip> tips,
    bool isExpanded,
    AICoachProvider coachProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Category Header
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              coachProvider.toggleTipCategory(category);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: category.getColor(isDark).withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.getColor(isDark),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.displayName,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tips.length} ${tips.length == 1 ? 'tip' : 'tips'}',
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
                  ),

                  // Expand icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Tips
          if (isExpanded)
            Column(
              children: tips.map((tip) => _buildTipCard(isDark, tip, coachProvider)).toList(),
            ),
        ],
      ),
    );
  }

  /// Individual Tip Card
  Widget _buildTipCard(bool isDark, AITip tip, AICoachProvider coachProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and bookmark
          Row(
            children: [
              Expanded(
                child: Text(
                  tip.title,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  coachProvider.toggleTipBookmark(tip.id);
                },
                icon: Icon(
                  tip.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  size: 20,
                  color: tip.isBookmarked
                      ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                      : (isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Content
          Text(
            tip.content,
            style: TextStyle(
              color:
                  isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Key Points
          ...tip.keyPoints.map(
            (point) => Padding(
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
                      color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actionable
          if (tip.actionable != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 14,
                    color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tip.actionable!,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Loading state
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading insights...',
            style: TextStyle(
              color:
                  isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state
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
                color:
                    isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
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
}
