import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ai_coach_models.dart';
import '../../models/habit_category.dart';
import '../../providers/habit_provider.dart';
import '../../providers/ai_coach_provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/ui_constants.dart';
import '../../screens/habit_creation_screen.dart';
import '../../screens/home_screen.dart';

/// AI Suggestion Card widget (Live Version)
/// AI 建议卡片组件（实时版本）
class AISuggestionCard extends StatefulWidget {
  /// Creates an AI suggestion card widget
  /// 创建 AI 建议卡片组件
  const AISuggestionCard({super.key});

  /// Creates the mutable state for this widget
  /// 创建此组件的可变状态
  @override
  State<AISuggestionCard> createState() => _AISuggestionCardState();
}

/// State for the AI suggestion card, manages loading and refresh logic
/// AI 建议卡片的状态，管理加载和刷新逻辑
class _AISuggestionCardState extends State<AISuggestionCard> {
  final GlobalKey _refreshButtonKey = GlobalKey();
  OverlayEntry? _cooldownTooltip;

  /// Initializes state and defers suggestion loading to the next frame
  /// 初始化状态并将建议加载延迟到下一帧
  @override
  void initState() {
    super.initState();
    // Defer loading to next frame to access context/providers safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSuggestionsIfNeeded();
    });
  }

  /// Loads AI suggestions if none are loaded yet
  /// 如果尚未加载 AI 建议则加载
  void _loadSuggestionsIfNeeded() {
    if (!mounted) return;

    final aiCoachProvider = Provider.of<AICoachProvider>(
      context,
      listen: false,
    );
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    // If no suggestions yet, load them
    if (aiCoachProvider.suggestions.isEmpty &&
        !aiCoachProvider.isLoadingSuggestions) {
      // Get current context for AI
      final currentHabitNames = habitProvider.habits
          .map((h) => h.name)
          .toList();
      // Simple categories list, or could be smarter
      final categories = HabitCategory.values.map((c) => c.name).toList();

      aiCoachProvider.loadSuggestions(
        categories: categories,
        currentHabits: currentHabitNames,
        completionRate: habitProvider.completionRate * 100,
        bestStreak: habitProvider.bestStreak,
      );
    }
  }

  /// Shows a tooltip indicating the cooldown time before next refresh
  /// 显示冷却时间提示，告知下次可刷新的时间
  void _showCooldownTooltip() {
    // Prevent duplicates
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
      if (mounted && _cooldownTooltip == entry) {
        entry.remove();
        _cooldownTooltip = null;
      }
    });
  }

  /// Disposes the cooldown tooltip overlay entry
  /// 销毁冷却提示的浮层入口
  @override
  void dispose() {
    _cooldownTooltip?.remove();
    _cooldownTooltip = null;
    super.dispose();
  }

  /// Forces a refresh of AI suggestions from the provider
  /// 强制从提供者刷新 AI 建议
  void _refreshSuggestions() {
    final aiCoachProvider = Provider.of<AICoachProvider>(
      context,
      listen: false,
    );
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    final currentHabitNames = habitProvider.habits.map((h) => h.name).toList();
    final categories = HabitCategory.values.map((c) => c.name).toList();

    aiCoachProvider.loadSuggestions(
      categories: categories,
      currentHabits: currentHabitNames,
      completionRate: habitProvider.completionRate * 100,
      bestStreak: habitProvider.bestStreak,
      forceRefresh: true,
    );
  }

  /// Builds the AI suggestion card UI with header, subtitle, and suggestion list
  /// 构建 AI 建议卡片界面，包含头部、副标题和建议列表
  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when specific fields change
    final suggestions = context.select<AICoachProvider, List<AICoachSuggestion>>(
      (provider) => provider.suggestions,
    );
    final isLoading = context.select<AICoachProvider, bool>(
      (provider) => provider.isLoadingSuggestions,
    );
    final usedFallback = context.select<AICoachProvider, bool>(
      (provider) => provider.usedFallback,
    );
    final canRefresh = context.select<AICoachProvider, bool>(
      (provider) => provider.canRefreshSuggestions,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
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
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isDark ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // AI Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkCoral, AppColors.darkPink]
                        : [AppColors.lightCoral, AppColors.lightPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  'AI Suggestions for You',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Refresh Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading
                      ? null
                      : canRefresh
                          ? _refreshSuggestions
                          : _showCooldownTooltip,
                  borderRadius: UIConstants.borderRadiusLarge,
                  child: Container(
                    key: _refreshButtonKey,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder.withValues(alpha: 0.5),
                      borderRadius: UIConstants.borderRadiusLarge,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark
                                      ? AppColors.darkCoral
                                      : AppColors.lightCoral,
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            color: canRefresh
                                ? (isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText)
                                : (isDark
                                    ? AppColors.darkSecondaryText.withValues(alpha: 0.3)
                                    : AppColors.lightSecondaryText.withValues(alpha: 0.3)),
                            size: 18,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle (with fallback warning if applicable)
          if (usedFallback)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: isDark ? Colors.orange[300] : Colors.orange[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Using default suggestions',
                    style: TextStyle(
                      color: isDark ? Colors.orange[300] : Colors.orange[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _refreshSuggestions,
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkCoral
                            : AppColors.lightCoral,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'Personalized using advanced AI',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          const SizedBox(height: 16),

          // Suggestions Preview
          if (isLoading)
            _buildLoadingState(isDark)
          else if (suggestions.isEmpty)
            _buildEmptyState(isDark)
          else
            _buildSuggestionsList(suggestions, isDark),
        ],
      ),
    );
  }

  /// Builds a shimmer-like loading placeholder while suggestions are being fetched
  /// 在获取建议时构建类似闪烁效果的加载占位符
  Widget _buildLoadingState(bool isDark) {
    final coral = isDark ? AppColors.darkCoral : AppColors.lightCoral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: coral,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Generating suggestions...',
              style: TextStyle(
                color: coral,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            itemBuilder: (context, index) {
              return Container(
                width: 240,
                margin: EdgeInsets.only(right: index == 0 ? 12 : 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCoral.withValues(alpha: 0.08)
                      : AppColors.lightCoral.withValues(alpha: 0.06),
                  borderRadius: UIConstants.borderRadiusMedium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: coral.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                        color: coral.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 12,
                      decoration: BoxDecoration(
                        color: coral.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds the empty state shown when no suggestions are available
  /// 构建无建议可用时显示的空状态
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
            ),
            const SizedBox(height: 12),
            Text(
              'Complete more habits to get AI suggestions',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the horizontal scrollable list of AI suggestion cards
  /// 构建 AI 建议卡片的水平滚动列表
  Widget _buildSuggestionsList(
    List<AICoachSuggestion> suggestions,
    bool isDark,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 130, // Slightly taller for better layout
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              // Bounds check to prevent race condition if list is modified during build
              if (index >= suggestions.length) {
                return const SizedBox.shrink();
              }
              final suggestion = suggestions[index];
              final gradientColors = suggestion.category.getGradient(
                isDark ? Brightness.dark : Brightness.light,
              );

              return Container(
                width: 240,
                margin: EdgeInsets.only(
                  right: index < suggestions.length - 1 ? 12 : 0,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightBorder.withValues(alpha: 0.15),
                  borderRadius: UIConstants.borderRadiusMedium,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Icon & Impact Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            suggestion.category.icon,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        // Mini Add Button
                        SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to habit creation screen with Live AI Suggestion
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
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: UIConstants.borderRadiusMedium,
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '+ Add',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Habit Name
                    Text(
                      suggestion.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Explanation
                    Expanded(
                      child: Text(
                        suggestion.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // View All Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // 1. Set the initial tab on the provider
              Provider.of<AICoachProvider>(
                context,
                listen: false,
              ).setTab(AICoachTab.suggestions);

              // 2. Switch to AI Coach tab (index 2)
              // We find the ancestor HomeScreenState and call switchToTab
              final homeState = context
                  .findAncestorStateOfType<HomeScreenState>();
              if (homeState != null) {
                homeState.switchToTab(2);
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View All Suggestions →',
              style: TextStyle(
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
