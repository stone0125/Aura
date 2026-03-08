import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/ui_constants.dart';
import '../../config/app_constants.dart';

// ==================== Public API ====================

/// Shows the FAQ bottom sheet with expandable question-answer items
/// 显示常见问题底部弹出窗口，包含可展开的问答项
void showFAQSheet(BuildContext context, bool isDark) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _buildSheetContainer(
      context,
      isDark,
      heightFactor: 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHeader(context, isDark, 'Frequently Asked Questions'),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._faqItems.map((item) => _buildFAQTile(isDark, item)),
                const SizedBox(height: 24),
                _buildStillNeedHelp(context, isDark),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Shows the tutorials bottom sheet with guided walkthroughs
/// 显示教程底部弹出窗口，包含引导式教学
void showTutorialsSheet(BuildContext context, bool isDark) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _buildSheetContainer(
      context,
      isDark,
      heightFactor: 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHeader(context, isDark, 'Tutorials'),
          const SizedBox(height: 8),
          Text(
            'Learn how to get the most out of Aura',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _tutorials.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tutorial = _tutorials[index];
                return _buildTutorialCard(context, isDark, tutorial);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Shows the contact support form bottom sheet
/// 显示联系支持表单底部弹出窗口
void showContactSupportSheet(BuildContext context, bool isDark) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _ContactSupportSheet(isDark: isDark),
  );
}

/// Shows the bug report form bottom sheet
/// 显示错误报告表单底部弹出窗口
void showReportBugSheet(BuildContext context, bool isDark) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _ReportBugSheet(isDark: isDark),
  );
}

/// Shows the feature request form bottom sheet
/// 显示功能请求表单底部弹出窗口
void showRequestFeatureSheet(BuildContext context, bool isDark) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _RequestFeatureSheet(isDark: isDark),
  );
}

/// Shows the AI transparency information bottom sheet
/// 显示 AI 透明度信息底部弹出窗口
void showAITransparencySheet(BuildContext context, bool isDark) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _buildSheetContainer(
      context,
      isDark,
      heightFactor: 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHeader(context, isDark, 'AI Transparency'),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAIHeroBanner(isDark),
                  const SizedBox(height: 24),
                  _buildSection(
                    isDark,
                    title: 'AI Technology',
                    content:
                        'Aura uses Google Gemini, a large language model by Google, accessed securely through Firebase Cloud Functions. All AI processing happens server-side — no AI model runs on your device.',
                  ),
                  _buildSection(
                    isDark,
                    title: 'What Data AI Processes',
                    content:
                        'When you use AI features, the following data may be sent for analysis:\n'
                        '• Habit names and categories\n'
                        '• Completion history and streaks\n'
                        '• Health data (only if you\'ve connected Health integration)\n\n'
                        'AI does NOT access your email address, password, or payment information.',
                  ),
                  _buildSection(
                    isDark,
                    title: 'What AI Generates',
                    content:
                        'AI powers the following features in Aura:\n'
                        '• Personalized habit suggestions\n'
                        '• Weekly insight summaries\n'
                        '• Motivational tips and encouragement\n'
                        '• Individual habit insights\n'
                        '• Actionable improvement items\n'
                        '• Pattern discovery across habits\n'
                        '• Habit scoring and analysis\n'
                        '• Daily review summaries\n'
                        '• Health data correlations',
                  ),
                  _buildSection(
                    isDark,
                    title: 'How Processing Works',
                    content:
                        '1. Your device sends anonymized habit data to our Firebase Cloud Functions\n'
                        '2. Cloud Functions format a prompt and send it to Google Gemini\n'
                        '3. Gemini generates insights based on the data\n'
                        '4. The response is sent back to your device\n\n'
                        'Your data is encrypted in transit and is not stored on Google\'s servers after processing.',
                  ),
                  _buildSection(
                    isDark,
                    title: 'Your Control',
                    content:
                        '• AI features are entirely optional — the app works fully without them\n'
                        '• You can disable AI features at any time in Settings\n'
                        '• AI insights require a minimum of 7 days of tracking data\n'
                        '• Some AI features are limited by subscription tier\n'
                        '• Deleting your account removes all data used for AI processing',
                  ),
                  _buildSection(
                    isDark,
                    title: 'Data Retention',
                    content:
                        'AI responses are cached locally on your device for performance. This cache is cleared when you sign out. Google does not retain your habit data after generating a response.',
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ==================== Shared Helpers ====================

/// Builds a styled bottom sheet container with rounded top corners
/// 构建带圆角顶部的样式化底部弹窗容器
Widget _buildSheetContainer(
  BuildContext context,
  bool isDark, {
  required Widget child,
  double heightFactor = 0.85,
}) {
  return Container(
    padding: const EdgeInsets.all(24),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * heightFactor,
    ),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(UIConstants.radiusXLarge),
      ),
    ),
    child: child,
  );
}

/// Builds the sheet header row with title and close button
/// 构建弹窗头部行，包含标题和关闭按钮
Widget _buildSheetHeader(BuildContext context, bool isDark, String title) {
  return Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
          ),
        ),
      ),
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.close_rounded,
          color: isDark
              ? AppColors.darkSecondaryText
              : AppColors.lightSecondaryText,
        ),
      ),
    ],
  );
}

/// Builds a titled content section with heading and body text
/// 构建带标题和正文的内容区块
Widget _buildSection(
  bool isDark, {
  required String title,
  required String content,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
      ],
    ),
  );
}

/// Builds a labeled text form field with optional error and hint text
/// 构建带标签的文本表单字段，可选错误提示和占位文本
Widget _buildFormField(
  bool isDark, {
  required String label,
  required TextEditingController controller,
  int maxLines = 1,
  String? hintText,
  String? errorText,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.darkTertiaryText
                  : AppColors.lightTertiaryText,
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightBackground,
            border: OutlineInputBorder(
              borderRadius: UIConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: UIConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: UIConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: UIConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: isDark ? AppColors.darkRed : AppColors.lightRed,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Builds a labeled dropdown selection field
/// 构建带标签的下拉选择字段
Widget _buildDropdownField(
  bool isDark, {
  required String label,
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightBackground,
            borderRadius: UIConstants.borderRadiusMedium,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor:
                  isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Builds a full-width submit button with optional loading spinner
/// 构建全宽提交按钮，可选加载旋转指示器
Widget _buildSubmitButton(
  bool isDark, {
  required String label,
  required VoidCallback? onPressed,
  bool isLoading = false,
}) {
  return SizedBox(
    width: double.infinity,
    height: UIConstants.buttonHeightPrimary,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColors.darkCoral : AppColors.lightCoral,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: UIConstants.borderRadiusMedium,
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );
}

// ==================== FAQ Data & Widgets ====================

/// Data model for a single FAQ entry
/// 单个常见问题条目的数据模型
class _FAQItem {
  final String question;
  final String answer;

  /// Creates an FAQ item with a question and answer
  /// 创建包含问题和答案的常见问题条目
  const _FAQItem(this.question, this.answer);
}

const List<_FAQItem> _faqItems = [
  _FAQItem(
    'How do I create a new habit?',
    'Tap the "+" button on the home screen. Give your habit a name, choose a category and icon, set your frequency (daily or specific days), and optionally set a reminder time. Tap "Create" to start tracking.',
  ),
  _FAQItem(
    'How do streaks work?',
    'A streak counts consecutive days you\'ve completed a habit. Daily habits require completion every day. Weekly habits count streaks based on your chosen days. Missing a scheduled day resets your streak to zero.',
  ),
  _FAQItem(
    'What are categories and how do they help?',
    'Categories (Health, Learning, Productivity, Mindfulness, Fitness) help organize your habits and provide color-coded visual grouping. They also help the AI provide more relevant insights for each area of your life.',
  ),
  _FAQItem(
    'How does the AI Coach work?',
    'The AI Coach analyzes your habit completion patterns, streaks, and trends to provide personalized suggestions, weekly insights, and motivational tips. It requires at least 7 days of tracking data to generate meaningful insights.',
  ),
  _FAQItem(
    'What\'s the difference between Free and Pro?',
    'Free users can track up to 5 habits with basic AI insights. Pro subscribers get unlimited habits, advanced AI analytics, detailed progress reports, health data integration, and priority support.',
  ),
  _FAQItem(
    'How do reminders work?',
    'You can set a daily reminder time for each habit. The app sends a local notification at your chosen time. Make sure notifications are enabled in your device settings for reminders to work.',
  ),
  _FAQItem(
    'Can I export my data?',
    'Yes! Go to Settings > Export Data. You can export your habit data as a CSV file for your records or analysis in other tools.',
  ),
  _FAQItem(
    'How does Health integration work?',
    'Aura can connect to Apple Health (iOS) or Google Health Connect (Android) to correlate your health metrics with habit patterns. Go to Settings to enable this feature. The AI can then identify relationships between your habits and health data.',
  ),
  _FAQItem(
    'Is my data secure?',
    'Yes. Your data is stored securely using Firebase with encryption at rest and in transit. AI processing happens server-side through secure Cloud Functions, and Google does not retain your data after processing. You can delete your account and all data at any time.',
  ),
  _FAQItem(
    'How do I delete my account?',
    'Go to Settings > Account > Delete Account. This permanently removes your account and all associated data including habits, completion history, and AI insights. This action cannot be undone.',
  ),
  _FAQItem(
    'Why aren\'t my AI insights showing?',
    'AI insights require at least 7 days of tracking data. Make sure you\'ve been consistently logging habits. Also check that AI features are enabled in Settings and that you have an active internet connection.',
  ),
  _FAQItem(
    'Can I change a habit after creating it?',
    'Yes! Tap on any habit to open its detail screen, then tap the edit icon to modify the name, category, frequency, reminder time, or icon.',
  ),
  _FAQItem(
    'How do I switch between light and dark mode?',
    'Go to Settings > Appearance and choose your preferred theme. You can select Light, Dark, or System Default to automatically match your device\'s current appearance setting.',
  ),
  _FAQItem(
    'What are achievements and how do I unlock them?',
    'Aura tracks milestones like streak counts, total completions, and consistency to award badges and achievements. You can view all your earned and upcoming achievements on the Progress screen.',
  ),
  _FAQItem(
    'Can I share my progress with friends?',
    'Yes! You can share overall progress summaries, individual achievements, or streak milestones using the share button. You can send them directly to friends via any app or copy your stats to the clipboard.',
  ),
];

/// Builds an expandable FAQ tile with question as title and answer as content
/// 构建可展开的常见问题卡片，问题为标题，答案为内容
Widget _buildFAQTile(bool isDark, _FAQItem item) {
  return Theme(
    data: ThemeData(
      dividerColor: Colors.transparent,
      splashColor: Colors.transparent,
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: const EdgeInsets.only(left: 4, right: 4, bottom: 16),
      title: Text(
        item.question,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
        ),
      ),
      iconColor:
          isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
      collapsedIconColor:
          isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
      children: [
        Text(
          item.answer,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
      ],
    ),
  );
}

/// Builds the "Still need help?" section with a contact support button
/// 构建"仍需帮助？"区块，包含联系支持按钮
Widget _buildStillNeedHelp(BuildContext context, bool isDark) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightBackground,
      borderRadius: UIConstants.borderRadiusMedium,
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    ),
    child: Column(
      children: [
        Text(
          'Still need help?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Our support team is here to assist you.',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showContactSupportSheet(context, isDark);
            },
            icon: const Icon(Icons.support_agent_rounded, size: 18),
            label: const Text('Contact Support'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDark ? AppColors.darkCoral : AppColors.lightCoral,
              side: BorderSide(
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: UIConstants.borderRadiusMedium,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

// ==================== Tutorials Data & Widgets ====================

/// Data model for a tutorial with icon, title, subtitle, and steps
/// 教程数据模型，包含图标、标题、副标题和步骤
class _Tutorial {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_TutorialStep> steps;

  /// Creates a tutorial with the given icon, title, subtitle, and steps
  /// 使用给定的图标、标题、副标题和步骤创建教程
  const _Tutorial(this.icon, this.title, this.subtitle, this.steps);
}

/// Data model for a single step within a tutorial
/// 教程中单个步骤的数据模型
class _TutorialStep {
  final String title;
  final String description;

  /// Creates a tutorial step with a title and description
  /// 创建包含标题和描述的教程步骤
  const _TutorialStep(this.title, this.description);
}

const List<_Tutorial> _tutorials = [
  _Tutorial(
    Icons.add_circle_rounded,
    'Creating Habits',
    'Set up your first habit and customize it',
    [
      _TutorialStep(
        'Tap the + button',
        'On the home screen, tap the floating action button in the bottom right to open the habit creation screen.',
      ),
      _TutorialStep(
        'Name your habit',
        'Enter a clear, specific name for your habit. For example, "Read for 30 minutes" is better than just "Read".',
      ),
      _TutorialStep(
        'Choose a category',
        'Select from Health, Learning, Productivity, Mindfulness, or Fitness. This helps organize your habits and improves AI insights.',
      ),
      _TutorialStep(
        'Set your schedule',
        'Choose daily tracking or select specific days of the week. Pick what works best for your routine.',
      ),
      _TutorialStep(
        'Add a reminder (optional)',
        'Set a notification time to remind you. Consistent reminders help build lasting habits.',
      ),
    ],
  ),
  _Tutorial(
    Icons.check_circle_rounded,
    'Tracking & Completing',
    'Mark habits done and build streaks',
    [
      _TutorialStep(
        'Check off habits',
        'On the home screen, tap the circle next to any habit to mark it as completed for today.',
      ),
      _TutorialStep(
        'Build streaks',
        'Complete habits consistently to build streaks. Your current streak is shown next to each habit.',
      ),
      _TutorialStep(
        'View your calendar',
        'Tap on a habit to see its detail screen with a calendar view showing your completion history.',
      ),
      _TutorialStep(
        'Track your progress',
        'The home screen header shows your daily completion rate. Aim for 100% each day!',
      ),
    ],
  ),
  _Tutorial(
    Icons.smart_toy_rounded,
    'AI Coach',
    'Get personalized insights and suggestions',
    [
      _TutorialStep(
        'Track for 7 days',
        'The AI Coach needs at least 7 days of data to generate meaningful insights. Keep tracking consistently!',
      ),
      _TutorialStep(
        'View AI suggestions',
        'Check the home screen for AI-powered suggestion cards with personalized tips based on your patterns.',
      ),
      _TutorialStep(
        'Open AI Coach',
        'Navigate to the AI Coach screen for detailed weekly insights, pattern analysis, and actionable recommendations.',
      ),
      _TutorialStep(
        'Act on insights',
        'The AI identifies patterns in your habits and suggests specific improvements. Try implementing one suggestion at a time.',
      ),
    ],
  ),
  _Tutorial(
    Icons.bar_chart_rounded,
    'Progress & Analytics',
    'Understand your habit patterns',
    [
      _TutorialStep(
        'Open Progress screen',
        'Tap the Progress tab in the bottom navigation to see your overall analytics and trends.',
      ),
      _TutorialStep(
        'Review weekly stats',
        'See your completion rate, total completions, and active streaks for the current week.',
      ),
      _TutorialStep(
        'Analyze trends',
        'Charts show your consistency over time. Look for patterns — which days are strongest? Which habits need attention?',
      ),
      _TutorialStep(
        'Category breakdown',
        'View how your habits are distributed across categories and which areas you\'re most consistent in.',
      ),
    ],
  ),
  _Tutorial(
    Icons.notifications_rounded,
    'Reminders',
    'Never miss a habit with smart notifications',
    [
      _TutorialStep(
        'Enable notifications',
        'Make sure notifications are enabled for Aura in your device\'s system settings.',
      ),
      _TutorialStep(
        'Set reminder times',
        'When creating or editing a habit, toggle on reminders and choose your preferred notification time.',
      ),
      _TutorialStep(
        'Customize per habit',
        'Each habit can have its own reminder time. Set morning habits early and evening habits later.',
      ),
    ],
  ),
  _Tutorial(
    Icons.favorite_rounded,
    'Health Integration',
    'Connect health data for deeper insights',
    [
      _TutorialStep(
        'Enable Health access',
        'Go to Settings and enable Health Integration. Grant the requested permissions when prompted.',
      ),
      _TutorialStep(
        'Automatic syncing',
        'Aura reads health metrics like steps, sleep, and activity. This data is synced automatically.',
      ),
      _TutorialStep(
        'AI correlations',
        'The AI Coach can identify relationships between your health data and habit completion patterns.',
      ),
    ],
  ),
  _Tutorial(
    Icons.download_rounded,
    'Exporting Data',
    'Save your habit data for backup or analysis',
    [
      _TutorialStep(
        'Go to Settings',
        'Open the Settings screen from the bottom navigation or profile area.',
      ),
      _TutorialStep(
        'Tap Export Data',
        'Find the Export Data option in Settings. Choose your preferred format.',
      ),
      _TutorialStep(
        'Share or save',
        'The exported file can be shared via email, saved to Files, or opened in spreadsheet apps for analysis.',
      ),
    ],
  ),
];

/// Builds a tappable tutorial card with icon, title, and subtitle
/// 构建可点击的教程卡片，包含图标、标题和副标题
Widget _buildTutorialCard(
  BuildContext context,
  bool isDark,
  _Tutorial tutorial,
) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _showTutorialDetail(context, isDark, tutorial),
      borderRadius: UIConstants.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightBackground,
          borderRadius: UIConstants.borderRadiusMedium,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                    .withValues(alpha: 0.15),
                borderRadius: UIConstants.borderRadiusSmall,
              ),
              child: Icon(
                tutorial.icon,
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutorial.title,
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
                    tutorial.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shows a detailed tutorial bottom sheet with numbered steps
/// 显示带编号步骤的详细教程底部弹窗
void _showTutorialDetail(
  BuildContext context,
  bool isDark,
  _Tutorial tutorial,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _buildSheetContainer(
      context,
      isDark,
      heightFactor: 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHeader(context, isDark, tutorial.title),
          const SizedBox(height: 4),
          Text(
            tutorial.subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: tutorial.steps.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final step = tutorial.steps[index];
                return _buildTutorialStep(isDark, index + 1, step);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds a numbered tutorial step row with title and description
/// 构建带编号的教程步骤行，包含标题和描述
Widget _buildTutorialStep(bool isDark, int number, _TutorialStep step) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkCoral : AppColors.lightCoral)
              .withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
            ),
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step.description,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ==================== AI Transparency Widgets ====================

/// Builds the AI transparency hero banner with Gemini branding
/// 构建 AI 透明度横幅，展示 Gemini 品牌信息
Widget _buildAIHeroBanner(bool isDark) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [
                AppColors.darkCoral.withValues(alpha: 0.2),
                AppColors.darkSurfaceVariant,
              ]
            : [
                AppColors.lightCoral.withValues(alpha: 0.1),
                AppColors.lightBackground,
              ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: UIConstants.borderRadiusLarge,
    ),
    child: Column(
      children: [
        Icon(
          Icons.smart_toy_rounded,
          size: 48,
          color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
        ),
        const SizedBox(height: 12),
        Text(
          'Powered by Google Gemini',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Transparent AI you can trust',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
      ],
    ),
  );
}

// ==================== Contact Support Form ====================

/// Contact support form bottom sheet widget
/// 联系支持表单底部弹窗组件
class _ContactSupportSheet extends StatefulWidget {
  final bool isDark;

  /// Creates a contact support sheet with the given theme mode
  /// 使用给定主题模式创建联系支持弹窗
  const _ContactSupportSheet({required this.isDark});

  /// Creates the mutable state for the contact support sheet
  /// 创建联系支持弹窗的可变状态
  @override
  State<_ContactSupportSheet> createState() => _ContactSupportSheetState();
}

/// State for the contact support form sheet
/// 联系支持表单弹窗的状态
class _ContactSupportSheetState extends State<_ContactSupportSheet> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'General';
  bool _submitted = false;
  bool _isSubmitting = false;

  static const _categories = [
    'General',
    'Account',
    'Billing',
    'Performance',
    'Other',
  ];

  /// Disposes text editing controllers
  /// 销毁文本编辑控制器
  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Validates and submits the support message via Firebase Cloud Functions
  /// 验证并通过 Firebase Cloud Functions 提交支持消息
  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFunctions.instance
          .httpsCallable('submitSupportMessage')
          .call({
        'type': 'contact_support',
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'category': _category,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message. Please try again.')),
      );
    }
  }

  /// Builds the contact support form with category dropdown, subject, and message fields
  /// 构建联系支持表单，包含类别下拉框、主题和消息字段
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return _buildSheetContainer(
      context,
      isDark,
      heightFactor: 0.85,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSheetHeader(context, isDark, 'Contact Support'),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdownField(
                      isDark,
                      label: 'Category',
                      value: _category,
                      items: _categories,
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                    _buildFormField(
                      isDark,
                      label: 'Subject',
                      controller: _subjectController,
                      hintText: 'Brief description of your issue',
                      errorText: _submitted &&
                              _subjectController.text.trim().isEmpty
                          ? 'Subject is required'
                          : null,
                    ),
                    _buildFormField(
                      isDark,
                      label: 'Message',
                      controller: _messageController,
                      maxLines: 6,
                      hintText: 'Describe your issue in detail...',
                      errorText: _submitted &&
                              _messageController.text.trim().isEmpty
                          ? 'Message is required'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _buildSubmitButton(
                      isDark,
                      label: 'Send Message',
                      onPressed: _isSubmitting ? null : _submit,
                      isLoading: _isSubmitting,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Report Bug Form ====================

/// Bug report form bottom sheet widget
/// 错误报告表单底部弹窗组件
class _ReportBugSheet extends StatefulWidget {
  final bool isDark;

  /// Creates a bug report sheet with the given theme mode
  /// 使用给定主题模式创建错误报告弹窗
  const _ReportBugSheet({required this.isDark});

  /// Creates the mutable state for the bug report sheet
  /// 创建错误报告弹窗的可变状态
  @override
  State<_ReportBugSheet> createState() => _ReportBugSheetState();
}

/// State for the bug report form sheet
/// 错误报告表单弹窗的状态
class _ReportBugSheetState extends State<_ReportBugSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedController = TextEditingController();
  bool _submitted = false;
  bool _isSubmitting = false;
  String _deviceInfo = 'Loading device info...';

  /// Initializes state and loads device information
  /// 初始化状态并加载设备信息
  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  /// Disposes all text editing controllers
  /// 销毁所有文本编辑控制器
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    super.dispose();
  }

  /// Loads device model, OS version, and app version asynchronously
  /// 异步加载设备型号、操作系统版本和应用版本
  Future<void> _loadDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceModel;
      String osVersion;

      if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';
        osVersion = 'Android ${androidInfo.version.release}';
      } else if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceModel = iosInfo.utsname.machine;
        osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      } else {
        deviceModel = 'Unknown';
        osVersion = kIsWeb ? 'Web' : Platform.operatingSystem;
      }

      if (mounted) {
        setState(() {
          _deviceInfo =
              'App: ${packageInfo.appName} v${packageInfo.version} (${packageInfo.buildNumber})\n'
              'Device: $deviceModel\n'
              'OS: $osVersion';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _deviceInfo = 'App: ${AppConstants.appName} v${AppConstants.appVersion}\n'
              'Platform: ${Platform.operatingSystem}';
        });
      }
    }
  }

  /// Validates and submits the bug report via Firebase Cloud Functions
  /// 验证并通过 Firebase Cloud Functions 提交错误报告
  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    final messageBody = 'Bug Description:\n${_descriptionController.text.trim()}\n\n'
        'Steps to Reproduce:\n${_stepsController.text.trim().isNotEmpty ? _stepsController.text.trim() : "N/A"}\n\n'
        'Expected Behavior:\n${_expectedController.text.trim().isNotEmpty ? _expectedController.text.trim() : "N/A"}';

    try {
      await FirebaseFunctions.instance
          .httpsCallable('submitSupportMessage')
          .call({
        'type': 'bug_report',
        'subject': _titleController.text.trim(),
        'message': messageBody,
        'deviceInfo': _deviceInfo,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bug report submitted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit bug report. Please try again.')),
      );
    }
  }

  /// Builds the bug report form with title, description, steps, expected behavior, and device info
  /// 构建错误报告表单，包含标题、描述、重现步骤、预期行为和设备信息
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return _buildSheetContainer(
      context,
      isDark,
      heightFactor: 0.9,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSheetHeader(context, isDark, 'Report a Bug'),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormField(
                      isDark,
                      label: 'Bug Title',
                      controller: _titleController,
                      hintText: 'Short description of the bug',
                      errorText:
                          _submitted && _titleController.text.trim().isEmpty
                              ? 'Title is required'
                              : null,
                    ),
                    _buildFormField(
                      isDark,
                      label: 'Description',
                      controller: _descriptionController,
                      maxLines: 4,
                      hintText: 'What happened?',
                      errorText: _submitted &&
                              _descriptionController.text.trim().isEmpty
                          ? 'Description is required'
                          : null,
                    ),
                    _buildFormField(
                      isDark,
                      label: 'Steps to Reproduce (optional)',
                      controller: _stepsController,
                      maxLines: 4,
                      hintText: '1. Go to...\n2. Tap on...\n3. See error',
                    ),
                    _buildFormField(
                      isDark,
                      label: 'Expected Behavior (optional)',
                      controller: _expectedController,
                      maxLines: 2,
                      hintText: 'What should have happened instead?',
                    ),
                    _buildDeviceInfoBox(isDark),
                    const SizedBox(height: 16),
                    _buildSubmitButton(
                      isDark,
                      label: 'Submit Bug Report',
                      onPressed: _isSubmitting ? null : _submit,
                      isLoading: _isSubmitting,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a read-only box displaying auto-collected device information
  /// 构建只读框，显示自动采集的设备信息
  Widget _buildDeviceInfoBox(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Info (auto-collected)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightBackground,
              borderRadius: UIConstants.borderRadiusMedium,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Text(
              _deviceInfo,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Request Feature Form ====================

/// Feature request form bottom sheet widget
/// 功能请求表单底部弹窗组件
class _RequestFeatureSheet extends StatefulWidget {
  final bool isDark;

  /// Creates a feature request sheet with the given theme mode
  /// 使用给定主题模式创建功能请求弹窗
  const _RequestFeatureSheet({required this.isDark});

  /// Creates the mutable state for the feature request sheet
  /// 创建功能请求弹窗的可变状态
  @override
  State<_RequestFeatureSheet> createState() => _RequestFeatureSheetState();
}

/// State for the feature request form sheet
/// 功能请求表单弹窗的状态
class _RequestFeatureSheetState extends State<_RequestFeatureSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _useCaseController = TextEditingController();
  String _category = 'Habit Tracking';
  bool _submitted = false;
  bool _isSubmitting = false;

  static const _categories = [
    'Habit Tracking',
    'AI & Insights',
    'Progress & Analytics',
    'Notifications',
    'Social Features',
    'Other',
  ];

  /// Disposes all text editing controllers
  /// 销毁所有文本编辑控制器
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _useCaseController.dispose();
    super.dispose();
  }

  /// Validates and submits the feature request via Firebase Cloud Functions
  /// 验证并通过 Firebase Cloud Functions 提交功能请求
  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    final messageBody = 'Feature Description:\n${_descriptionController.text.trim()}\n\n'
        'Use Case:\n${_useCaseController.text.trim().isNotEmpty ? _useCaseController.text.trim() : "N/A"}';

    try {
      await FirebaseFunctions.instance
          .httpsCallable('submitSupportMessage')
          .call({
        'type': 'feature_request',
        'subject': _titleController.text.trim(),
        'message': messageBody,
        'category': _category,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feature request submitted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit feature request. Please try again.')),
      );
    }
  }

  /// Builds the feature request form with title, description, use case, and category
  /// 构建功能请求表单，包含标题、描述、使用场景和类别
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return _buildSheetContainer(
      context,
      isDark,
      heightFactor: 0.85,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSheetHeader(context, isDark, 'Request a Feature'),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormField(
                      isDark,
                      label: 'Feature Title',
                      controller: _titleController,
                      hintText: 'Short name for the feature',
                      errorText:
                          _submitted && _titleController.text.trim().isEmpty
                              ? 'Title is required'
                              : null,
                    ),
                    _buildFormField(
                      isDark,
                      label: 'Description',
                      controller: _descriptionController,
                      maxLines: 5,
                      hintText: 'Describe the feature you\'d like to see...',
                      errorText: _submitted &&
                              _descriptionController.text.trim().isEmpty
                          ? 'Description is required'
                          : null,
                    ),
                    _buildFormField(
                      isDark,
                      label: 'Use Case (optional)',
                      controller: _useCaseController,
                      maxLines: 3,
                      hintText: 'How would you use this feature?',
                    ),
                    _buildDropdownField(
                      isDark,
                      label: 'Category',
                      value: _category,
                      items: _categories,
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildSubmitButton(
                      isDark,
                      label: 'Submit Feature Request',
                      onPressed: _isSubmitting ? null : _submit,
                      isLoading: _isSubmitting,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
