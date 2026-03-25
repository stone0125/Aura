import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../config/app_constants.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/ui_constants.dart';
import '../models/settings_models.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/ai_scoring_provider.dart';
// Future work — subscription/payment features, not included in the dissertation report.
import '../services/subscription_service.dart';
import '../models/subscription_models.dart';
import '../services/export_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/settings/help_support_sheets.dart';

/// Comprehensive settings and profile management screen
/// 综合设置和个人资料管理屏幕
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen
  /// 创建设置屏幕
  const SettingsScreen({super.key});

  /// Creates the mutable state for the settings screen
  /// 创建设置屏幕的可变状态
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Builds the settings screen with all sections in a scrollable layout
  /// 构建包含所有部分的可滚动设置屏幕布局
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = context.watch<SettingsProvider>();
    final profile = settingsProvider.userProfile;
    final settings = settingsProvider.settings;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              elevation: 0,
              title: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.lightPrimaryText,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _buildProfileSection(context, profile, isDark),

                  const SizedBox(height: 8),

                  // Appearance
                  _buildSectionHeader(context, 'Appearance', isDark),
                  _buildAppearanceSection(context, settings, isDark),

                  const SizedBox(height: 24),

                  // Notifications
                  _buildSectionHeader(context, 'Notifications', isDark),
                  _buildNotificationsSection(context, settings, isDark),

                  const SizedBox(height: 24),

                  // Health Integration (only show on iOS/Android)
                  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) ...[
                    _buildSectionHeader(context, 'Health Integration', isDark),
                    _buildHealthIntegrationSection(context, isDark),
                    const SizedBox(height: 24),
                  ],

                  // Account
                  _buildSectionHeader(context, 'Account', isDark),
                  _buildAccountSection(context, profile, isDark),

                  const SizedBox(height: 24),

                  // Help & Support
                  _buildSectionHeader(context, 'Help & Support', isDark),
                  _buildHelpSection(context, isDark),

                  const SizedBox(height: 24),

                  // About
                  _buildSectionHeader(context, 'About', isDark),
                  _buildAboutSection(context, isDark),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Profile Section ====================

  /// Builds the profile section with avatar, info, stats, and upgrade banner
  /// 构建包含头像、信息、统计和升级横幅的个人资料部分
  Widget _buildProfileSection(
    BuildContext context,
    UserProfile profile,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: UIConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar and info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isDark
                              ? [AppColors.darkCoral, AppColors.darkOrange]
                              : [AppColors.lightCoral, AppColors.lightOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child:
                          profile.avatarUrl != null &&
                              profile.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                profile.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 72,
                                height: 72,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      profile.initials,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                profile.initials,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    if (profile.isPro)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkGold
                                : AppColors.lightGold,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.memberSinceText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTertiaryText
                              : AppColors.lightTertiaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit button
                IconButton(
                  onPressed: () =>
                      _showEditProfileModal(context, profile, isDark),
                  icon: Icon(
                    Icons.edit_rounded,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.darkSecondaryText.withValues(alpha: 0.1)
                      : AppColors.lightSecondaryText.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            // Uses Selector to only rebuild when stats change
            child: Selector<ProgressProvider, ({int daysTracked, int totalHabits, double completionRate})>(
              selector: (context, provider) => (
                daysTracked: provider.stats?.daysTracked ?? 0,
                totalHabits: provider.stats?.totalHabits ?? 0,
                completionRate: provider.stats?.completionRate ?? 0,
              ),
              builder: (context, stats, child) {
                return Row(
                  children: [
                    _buildStatItem(
                      context,
                      '${stats.daysTracked}',
                      'Days Tracked',
                      isDark,
                    ),
                    _buildStatDivider(isDark),
                    _buildStatItem(
                      context,
                      '${stats.totalHabits}',
                      'Active Habits',
                      isDark,
                    ),
                    _buildStatDivider(isDark),
                    _buildStatItem(
                      context,
                      '${(stats.completionRate * 100).toStringAsFixed(0)}%',
                      'Success Rate',
                      isDark,
                      tooltip: 'Based on last 7 days',
                    ),
                  ],
                );
              },
            ),
          ),

          // Upgrade to Pro (if not pro)
          if (!profile.isPro)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showUpgradeBottomSheet(context, isDark);
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.darkGold.withValues(alpha: 0.2),
                            AppColors.darkGold.withValues(alpha: 0.1),
                          ]
                        : [
                            AppColors.lightGold.withValues(alpha: 0.2),
                            AppColors.lightGold.withValues(alpha: 0.1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: UIConstants.borderRadiusMedium,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkGold.withValues(alpha: 0.3)
                        : AppColors.lightGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: isDark ? AppColors.darkGold : AppColors.lightGold,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upgrade to Pro',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightPrimaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Unlock advanced AI features & unlimited habits',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a single stat item with value, label, and optional tooltip
  /// 构建带有数值、标签和可选提示的单个统计项
  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    bool isDark, {
    String? tooltip,
  }) {
    Widget content = Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.lightPrimaryText,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
            if (tooltip != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: isDark
                    ? AppColors.darkTertiaryText
                    : AppColors.lightTertiaryText,
              ),
            ],
          ],
        ),
      ],
    );

    if (tooltip != null) {
      return Expanded(
        child: Tooltip(message: tooltip, child: content),
      );
    }

    return Expanded(child: content);
  }

  /// Builds a vertical divider between stat items
  /// 构建统计项之间的垂直分隔线
  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark
          ? AppColors.darkSecondaryText.withValues(alpha: 0.2)
          : AppColors.lightSecondaryText.withValues(alpha: 0.2),
    );
  }

  // ==================== Section Headers ====================

  /// Builds an uppercase section header label
  /// 构建大写的部分标题标签
  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isDark
              ? AppColors.darkTertiaryText
              : AppColors.lightTertiaryText,
        ),
      ),
    );
  }

  // ==================== Appearance Section ====================

  /// Builds the appearance settings section with theme selection
  /// 构建包含主题选择的外观设置部分
  Widget _buildAppearanceSection(
    BuildContext context,
    AppSettings settings,
    bool isDark,
  ) {
    return _buildSettingsCard(
      context,
      isDark,
      children: [
        _buildSettingRow(
          context,
          icon: Icons.palette_rounded,
          title: 'Theme',
          subtitle: settings.themePreference.displayName,
          isDark: isDark,
          onTap: () =>
              _showThemeSelector(context, settings.themePreference, isDark),
        ),
      ],
    );
  }

  // ==================== Notifications Section ====================

  /// Builds the notifications settings section with toggle and time picker
  /// 构建包含开关和时间选择器的通知设置部分
  Widget _buildNotificationsSection(
    BuildContext context,
    AppSettings settings,
    bool isDark,
  ) {
    return _buildSettingsCard(
      context,
      isDark,
      children: [
        _buildSwitchRow(
          context,
          icon: Icons.notifications_rounded,
          title: 'Enable Notifications',
          subtitle: 'Receive habit reminders',
          value: settings.notificationsEnabled,
          isDark: isDark,
          onChanged: (value) async {
            HapticFeedback.lightImpact();
            final settingsProvider = context.read<SettingsProvider>();
            settingsProvider.setNotificationsEnabled(value);
            final reminderTime = settings.defaultReminderTime;
            if (value) {
              // Schedule daily summary with current settings
              await NotificationService().scheduleDailySummary(
                hour: reminderTime.hour,
                minute: reminderTime.minute,
              );
            } else {
              await NotificationService().cancelDailySummary();
            }
            if (!mounted) return;
            // Sync to Firestore so Cloud Function respects the toggle
            try {
              final rawTimezone = await FlutterTimezone.getLocalTimezone();
              if (!mounted) return;
              String timezone = rawTimezone.toString();
              final match = RegExp(r'TimezoneInfo\(([^,]+)').firstMatch(timezone);
              if (match != null) {
                timezone = match.group(1)!.trim();
              }
              await FirestoreService().saveNotificationPreferences(
                enabled: value,
                hour: reminderTime.hour,
                minute: reminderTime.minute,
                timezone: timezone,
              );
            } catch (e) {
              debugPrint('Error saving notification prefs to Firestore: $e');
            }
          },
        ),
        if (settings.notificationsEnabled) ...[
          _buildDivider(isDark),
          _buildSettingRow(
            context,
            icon: Icons.wb_sunny_rounded,
            title: 'Daily Summary',
            subtitle: 'Reminder at ${settings.reminderTimeText}',
            isDark: isDark,
            onTap: () async {
              final settingsProvider = context.read<SettingsProvider>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final picked = await _showTimePicker(
                context,
                settings.defaultReminderTime,
                isDark,
              );
              if (picked != null && mounted) {
                // Save to local settings
                settingsProvider.setDefaultReminderTime(picked);

                // Schedule local notification
                await NotificationService().scheduleDailySummary(
                  hour: picked.hour,
                  minute: picked.minute,
                );
                if (!mounted) return;

                // Get timezone and save to Firestore for FCM (backup)
                try {
                  final rawTimezone = await FlutterTimezone.getLocalTimezone();
                  if (!mounted) return;
                  // Extract IANA timezone name from potential wrapper
                  String timezone = rawTimezone.toString();
                  final match = RegExp(r'TimezoneInfo\(([^,]+)').firstMatch(timezone);
                  if (match != null) {
                    timezone = match.group(1)!.trim();
                  }
                  await FirestoreService().saveNotificationPreferences(
                    enabled: true,
                    hour: picked.hour,
                    minute: picked.minute,
                    timezone: timezone,
                  );
                } catch (e) {
                  debugPrint('Error saving notification prefs to Firestore: $e');
                }

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Daily summary set for ${_formatTime(picked)}',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ],
    );
  }

  // ==================== Health Integration Section ====================

  /// Builds the health integration section with connect toggle and insights
  /// 构建包含连接开关和健康洞察的健康整合部分
  Widget _buildHealthIntegrationSection(BuildContext context, bool isDark) {
    final scoringProvider = context.watch<AIScoringProvider>();
    final isEnabled = scoringProvider.healthIntegrationEnabled;

    return _buildSettingsCard(
      context,
      isDark,
      children: [
        _buildSwitchRow(
          context,
          icon: Icons.favorite_rounded,
          title: 'Connect Health Data',
          subtitle: isEnabled
              ? 'Connected to ${!kIsWeb && Platform.isIOS ? 'Apple Health' : 'Health Connect'}'
              : 'Sync steps, sleep & activity',
          value: isEnabled,
          isDark: isDark,
          onChanged: (value) async {
            HapticFeedback.lightImpact();
            if (value) {
              // Show confirmation dialog before enabling
              final confirmed = await _showHealthPermissionDialog(context, isDark);
              if (confirmed == true) {
                final success = await scoringProvider.enableHealthIntegration();
                if (!success && context.mounted) {
                  final errorMsg = scoringProvider.errorMessage ?? 'Failed to enable health integration';
                  if (errorMsg == 'INSTALL_HEALTH_CONNECT') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Health Connect app needs to be installed',
                        ),
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: 'Install',
                          onPressed: () {
                            launchUrl(
                              Uri.parse('market://details?id=com.google.android.apps.healthdata'),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMsg),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } else if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Health data connected successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            } else {
              await scoringProvider.disableHealthIntegration();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Health data disconnected'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          },
        ),
        if (isEnabled) ...[
          _buildDivider(isDark),
          _buildSettingRow(
            context,
            icon: Icons.analytics_outlined,
            title: 'Health Correlations',
            subtitle: 'View health-habit insights',
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              // Navigate to health correlations or show info
              _showHealthCorrelationsInfo(context, isDark, scoringProvider);
            },
          ),
        ],
        _buildDivider(isDark),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: isDark
                    ? AppColors.darkTertiaryText
                    : AppColors.lightTertiaryText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Health data helps identify correlations between your physical activity, sleep, and habit completion patterns.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTertiaryText
                        : AppColors.lightTertiaryText,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Shows a confirmation dialog for health data permissions
  /// 显示健康数据权限的确认对话框
  Future<bool?> _showHealthPermissionDialog(BuildContext context, bool isDark) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.favorite_rounded,
              color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
            ),
            const SizedBox(width: 12),
            const Text('Connect Health Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aura would like to access your health data to:',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(isDark, 'Steps', 'Daily step count'),
            _buildPermissionItem(isDark, 'Sleep', 'Sleep duration & quality'),
            _buildPermissionItem(isDark, 'Activity', 'Active minutes & workouts'),
            _buildPermissionItem(isDark, 'Heart Rate', 'Average heart rate'),
            const SizedBox(height: 16),
            Text(
              'This data helps identify correlations between your health and habit patterns.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.darkCoral
                  : AppColors.lightCoral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  /// Builds a single permission item row with check icon and description
  /// 构建带有勾选图标和描述的单个权限项行
  Widget _buildPermissionItem(bool isDark, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a bottom sheet with health correlations and key findings
  /// 显示包含健康相关性和关键发现的底部弹出窗口
  void _showHealthCorrelationsInfo(
    BuildContext context,
    bool isDark,
    AIScoringProvider provider,
  ) {
    final correlations = provider.healthCorrelations;
    final summary = provider.healthSummary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(UIConstants.radiusXLarge)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Health Insights',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.lightPrimaryText,
                    ),
                  ),
                  const Spacer(),
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
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Stats
                    if (summary != null) ...[
                      Text(
                        '7-Day Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildHealthStat(
                              isDark,
                              summary.avgSteps.toStringAsFixed(0),
                              'Avg Steps',
                              Icons.directions_walk_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildHealthStat(
                              isDark,
                              '${summary.avgSleepHours.toStringAsFixed(1)}h',
                              'Avg Sleep',
                              Icons.bedtime_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Correlations
                    if (correlations != null &&
                        correlations.keyFindings.isNotEmpty) ...[
                      Text(
                        'Key Findings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...correlations.keyFindings.map(
                        (finding) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : AppColors.lightBackground,
                            borderRadius: UIConstants.borderRadiusSmall,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.insights_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkCoral
                                    : AppColors.lightCoral,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  finding,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.lightSecondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (correlations.actionPlan.isNotEmpty) ...[
                        Text(
                          'Recommendation',
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
                          correlations.actionPlan,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 48,
                              color: isDark
                                  ? AppColors.darkTertiaryText
                                  : AppColors.lightTertiaryText,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Not enough data yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Keep tracking for at least 7 days to see correlations',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTertiaryText
                                    : AppColors.lightTertiaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a health statistic card with icon, value, and label
  /// 构建带有图标、数值和标签的健康统计卡片
  Widget _buildHealthStat(
    bool isDark,
    String value,
    String label,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: UIConstants.borderRadiusMedium,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Account Section ====================

  /// Builds the account section with subscription, usage, export, and sign out
  /// 构建包含订阅、用量、导出和退出登录的账户部分
  Widget _buildAccountSection(
    BuildContext context,
    UserProfile profile,
    bool isDark,
  ) {
    return _buildSettingsCard(
      context,
      isDark,
      children: [
        _buildSettingRow(
          context,
          icon: Icons.workspace_premium_rounded,
          iconColor: profile.isPro
              ? (isDark ? AppColors.darkGold : AppColors.lightGold)
              : null,
          title: profile.isPro ? 'Pro Member' : 'Subscription',
          subtitle: profile.isPro
              ? 'Active Pro subscription'
              : 'Manage subscription',
          isDark: isDark,
          onTap: () {
            HapticFeedback.lightImpact();
            if (profile.isPro) {
              SubscriptionService().presentCustomerCenter();
            } else {
              _showUpgradeBottomSheet(context, isDark);
            }
          },
        ),
        _buildDivider(isDark),
        _buildUsageSection(context, isDark),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.download_rounded,
          title: 'Export Data',
          subtitle: 'Download your habit data',
          isDark: isDark,
          onTap: () => _showExportOptions(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.logout_rounded,
          iconColor: isDark ? AppColors.darkRed : AppColors.lightRed,
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          isDark: isDark,
          onTap: () => _showSignOutConfirmation(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.delete_forever_rounded,
          iconColor: isDark ? AppColors.darkRed : AppColors.lightRed,
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          titleColor: isDark ? AppColors.darkRed : AppColors.lightRed,
          isDark: isDark,
          onTap: () => _showDeleteAccountConfirmation(context, isDark),
        ),
      ],
    );
  }

  // ==================== Help & Support Section ====================

  /// Builds the help and support section with FAQ, tutorials, and contact
  /// 构建包含常见问题、教程和联系方式的帮助与支持部分
  Widget _buildHelpSection(BuildContext context, bool isDark) {
    return _buildSettingsCard(
      context,
      isDark,
      children: [
        _buildSettingRow(
          context,
          icon: Icons.help_rounded,
          title: 'FAQ',
          subtitle: 'Common questions and answers',
          isDark: isDark,
          onTap: () => showFAQSheet(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.school_rounded,
          title: 'Tutorials',
          subtitle: 'Learn how to use the app',
          isDark: isDark,
          onTap: () => showTutorialsSheet(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.support_agent_rounded,
          title: 'Contact Support',
          subtitle: 'Get help from our team',
          isDark: isDark,
          onTap: () => showContactSupportSheet(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.bug_report_rounded,
          title: 'Report Bug',
          subtitle: 'Help us improve',
          isDark: isDark,
          onTap: () => showReportBugSheet(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.lightbulb_rounded,
          title: 'Request Feature',
          subtitle: 'Suggest new features',
          isDark: isDark,
          onTap: () => showRequestFeatureSheet(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.security_rounded,
          title: 'AI Transparency',
          subtitle: 'How AI works in this app',
          isDark: isDark,
          onTap: () => showAITransparencySheet(context, isDark),
        ),
      ],
    );
  }

  // ==================== About Section ====================

  /// Builds the about section with version, changelog, privacy, and terms
  /// 构建包含版本、更新日志、隐私政策和服务条款的关于部分
  Widget _buildAboutSection(BuildContext context, bool isDark) {
    return _buildSettingsCard(
      context,
      isDark,
      children: [
        _buildSettingRow(
          context,
          icon: Icons.info_rounded,
          title: 'Version',
          subtitle: AppConstants.appVersion,
          isDark: isDark,
          showArrow: false,
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.update_rounded,
          title: 'Changelog',
          subtitle: 'See what\'s new',
          isDark: isDark,
          onTap: () => _showChangelog(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.privacy_tip_rounded,
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          isDark: isDark,
          onTap: () => _showPrivacyPolicy(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.description_rounded,
          title: 'Terms of Service',
          subtitle: 'User agreement',
          isDark: isDark,
          onTap: () => _showTermsOfService(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.account_balance_rounded,
          title: 'Open Source Licenses',
          subtitle: 'Third-party software',
          isDark: isDark,
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: AppConstants.appVersion,
            );
          },
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.favorite_rounded,
          title: 'Rate App',
          subtitle: 'Leave a review',
          isDark: isDark,
          onTap: () => _launchUrl(
            'https://play.google.com/store/apps/details?id=com.aura.habittracker',
          ),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.people_rounded,
          title: 'Credits',
          subtitle: 'Made by Stone',
          isDark: isDark,
          showArrow: false,
        ),
      ],
    );
  }

  // ==================== Helper Widgets ====================

  /// Builds a styled settings card container with shadow and rounded corners
  /// 构建带有阴影和圆角的样式设置卡片容器
  Widget _buildSettingsCard(
    BuildContext context,
    bool isDark, {
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: UIConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  /// Builds a tappable settings row with icon, title, subtitle, and arrow
  /// 构建带有图标、标题、副标题和箭头的可点击设置行
  Widget _buildSettingRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    Color? iconColor,
    Color? titleColor,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: UIConstants.borderRadiusLarge,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    (iconColor ??
                            (isDark
                                ? AppColors.darkCoral
                                : AppColors.lightCoral))
                        .withValues(alpha: 0.1),
                borderRadius: UIConstants.borderRadiusMedium,
              ),
              child: Icon(
                icon,
                size: 20,
                color:
                    iconColor ??
                    (isDark ? AppColors.darkCoral : AppColors.lightCoral),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          titleColor ??
                          (isDark ? Colors.white : AppColors.lightPrimaryText),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark
                    ? AppColors.darkTertiaryText
                    : AppColors.lightTertiaryText,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a settings row with a toggle switch control
  /// 构建带有切换开关控件的设置行
  Widget _buildSwitchRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                  .withValues(alpha: 0.1),
              borderRadius: UIConstants.borderRadiusMedium,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          const SizedBox(width: 8),
          trailing ??
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: isDark
                    ? AppColors.darkCoral.withValues(alpha: 0.5)
                    : AppColors.lightCoral.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return isDark ? AppColors.darkCoral : AppColors.lightCoral;
                  }
                  return null;
                }),
              ),
        ],
      ),
    );
  }

  // ==================== AI Usage Section ====================

  /// Builds the AI usage summary row with habit, suggestion, and report counts
  /// 构建包含习惯、建议和报告数量的AI用量摘要行
  Widget _buildUsageSection(BuildContext context, bool isDark) {
    final subService = SubscriptionService();
    final tier = subService.currentTier;
    final isUnlimited = tier == SubscriptionTier.mastery;

    String subtitle;
    if (isUnlimited) {
      subtitle = 'Unlimited — Pro Plan';
    } else {
      final habitProvider = context.watch<HabitProvider>();
      final habitCount = habitProvider.habits.length;
      final maxHabits = tier.maxHabits;

      final maxSuggestions = tier.maxAISuggestionsPerDay;
      final remainingSuggestions = subService.getRemainingAISuggestions();
      final usedSuggestions = maxSuggestions == -1
          ? 0
          : maxSuggestions - remainingSuggestions;

      final maxReports = tier.maxAIReportsPerMonth;
      final remainingReports = subService.getRemainingAIReports();
      final usedReports = maxReports == -1
          ? 0
          : maxReports - remainingReports;

      subtitle =
          '$habitCount/$maxHabits habits · $usedSuggestions/$maxSuggestions suggestions · $usedReports/$maxReports reports';
    }

    return _buildSettingRow(
      context,
      icon: Icons.data_usage_rounded,
      title: 'Usage',
      subtitle: subtitle,
      isDark: isDark,
      onTap: () {
        HapticFeedback.lightImpact();
        _showUsageDetailsSheet(context, isDark);
      },
    );
  }

  /// Builds a single usage row with progress bar and limit info
  /// 构建带有进度条和限制信息的单个用量行
  Widget _buildUsageRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String subtitle,
    required int used,
    required int max,
    required bool isUnlimited,
  }) {
    final coral = isDark ? AppColors.darkCoral : AppColors.lightCoral;
    final isAtLimit = !isUnlimited && max > 0 && used >= max;
    final progressColor = isAtLimit ? Colors.orange : coral;
    final progress = isUnlimited || max <= 0
        ? 0.0
        : (used / max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: progressColor.withValues(alpha: 0.1),
              borderRadius: UIConstants.borderRadiusMedium,
            ),
            child: Icon(icon, size: 20, color: progressColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 4),
                if (isUnlimited)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                  )
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isAtLimit
                          ? Colors.orange
                          : (isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a horizontal divider indented to align with setting content
  /// 构建与设置内容对齐的缩进水平分隔线
  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? AppColors.darkSecondaryText.withValues(alpha: 0.1)
            : AppColors.lightSecondaryText.withValues(alpha: 0.1),
      ),
    );
  }

  // ==================== Modals and Dialogs ====================

  /// Shows a bottom sheet with detailed usage breakdown for all limits
  /// 显示包含所有限制详细用量分析的底部弹出窗口
  void _showUsageDetailsSheet(BuildContext context, bool isDark) {
    final subService = SubscriptionService();
    final tier = subService.currentTier;
    final habitProvider = context.read<HabitProvider>();
    final habitCount = habitProvider.habits.length;
    final isUnlimited = tier == SubscriptionTier.mastery;

    final maxSuggestions = tier.maxAISuggestionsPerDay;
    final remainingSuggestions = subService.getRemainingAISuggestions();
    final usedSuggestions = maxSuggestions == -1
        ? 0
        : maxSuggestions - remainingSuggestions;

    final maxReports = tier.maxAIReportsPerMonth;
    final remainingReports = subService.getRemainingAIReports();
    final usedReports = maxReports == -1
        ? 0
        : maxReports - remainingReports;

    final maxHabits = tier.maxHabits;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(UIConstants.radiusXLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Usage Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? Colors.white : AppColors.lightPrimaryText,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? AppColors.darkCoral
                              : AppColors.lightCoral)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tier.displayName} Plan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkCoral
                            : AppColors.lightCoral,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildUsageRow(
              isDark: isDark,
              icon: Icons.bolt_rounded,
              label: 'AI Suggestions',
              subtitle: isUnlimited
                  ? 'Unlimited'
                  : '$usedSuggestions of $maxSuggestions used today',
              used: usedSuggestions,
              max: maxSuggestions,
              isUnlimited: isUnlimited,
            ),
            _buildDivider(isDark),
            _buildUsageRow(
              isDark: isDark,
              icon: Icons.bar_chart_rounded,
              label: 'AI Reports',
              subtitle: isUnlimited
                  ? 'Unlimited'
                  : '$usedReports of $maxReports used this month',
              used: usedReports,
              max: maxReports,
              isUnlimited: isUnlimited,
            ),
            _buildDivider(isDark),
            _buildUsageRow(
              isDark: isDark,
              icon: Icons.checklist_rounded,
              label: 'Habits',
              subtitle: isUnlimited
                  ? 'Unlimited'
                  : '$habitCount of $maxHabits habits',
              used: habitCount,
              max: maxHabits,
              isUnlimited: isUnlimited,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  /// Shows a modal to edit user profile name and bio
  /// 显示编辑用户个人资料名称和简介的弹窗
  void _showEditProfileModal(
    BuildContext context,
    UserProfile profile,
    bool isDark,
  ) {
    final firstNameController = TextEditingController(text: profile.firstName);
    final lastNameController = TextEditingController(text: profile.lastName);
    final bioController = TextEditingController(text: profile.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(UIConstants.radiusXLarge)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : AppColors.lightPrimaryText,
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
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(
                      borderRadius: UIConstants.borderRadiusMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(
                      borderRadius: UIConstants.borderRadiusMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: UIConstants.borderRadiusMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.read<SettingsProvider>().updateProfile(
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                        bio: bioController.text.isEmpty
                            ? null
                            : bioController.text,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkCoral
                          : AppColors.lightCoral,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: UIConstants.borderRadiusLarge,
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a bottom sheet for selecting light, dark, or system theme
  /// 显示用于选择浅色、深色或系统主题的底部弹出窗口
  void _showThemeSelector(
    BuildContext context,
    ThemePreference current,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        // Use Theme.of to get the CURRENT theme state, not the captured one
        final currentIsDark =
            Theme.of(modalContext).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: currentIsDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(UIConstants.radiusXLarge)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Theme',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: currentIsDark
                      ? Colors.white
                      : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 24),
              ...ThemePreference.values.map(
                (theme) => _buildThemeOption(
                  modalContext,
                  theme,
                  current == theme,
                  currentIsDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a single selectable theme option with icon and highlight
  /// 构建带有图标和高亮的单个可选主题选项
  Widget _buildThemeOption(
    BuildContext context,
    ThemePreference theme,
    bool isSelected,
    bool isDark,
  ) {
    IconData icon;
    switch (theme) {
      case ThemePreference.light:
        icon = Icons.light_mode_rounded;
        break;
      case ThemePreference.dark:
        icon = Icons.dark_mode_rounded;
        break;
      case ThemePreference.system:
        icon = Icons.brightness_auto_rounded;
        break;
    }

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<SettingsProvider>().setThemePreference(theme);

        // Also update the theme provider
        final themeProvider = context.read<ThemeProvider>();
        switch (theme) {
          case ThemePreference.light:
            themeProvider.setThemeMode(ThemeMode.light);
            break;
          case ThemePreference.dark:
            themeProvider.setThemeMode(ThemeMode.dark);
            break;
          case ThemePreference.system:
            themeProvider.setThemeMode(ThemeMode.system);
            break;
        }

        Navigator.pop(context);
      },
      borderRadius: UIConstants.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                    .withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: UIConstants.borderRadiusMedium,
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                  : (isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                theme.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.lightPrimaryText,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
              ),
          ],
        ),
      ),
    );
  }

  /// Shows a time picker dialog and returns the selected time
  /// 显示时间选择器对话框并返回所选时间
  Future<TimeOfDay?> _showTimePicker(
    BuildContext context,
    TimeOfDay current,
    bool isDark,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null && context.mounted) {
      HapticFeedback.lightImpact();
    }
    return picked;
  }

  /// Formats a TimeOfDay into a 12-hour AM/PM string
  /// 将TimeOfDay格式化为12小时制AM/PM字符串
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Shows a bottom sheet with the app changelog and version history
  /// 显示包含应用更新日志和版本历史的底部弹出窗口
  void _showChangelog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(UIConstants.radiusXLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s New',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChangelogVersion(
                      isDark,
                      version: '1.0.1',
                      date: 'January 2026',
                      changes: [
                        '🐛 Bug fixes and stability improvements',
                        '🎨 UI improvements and visual polish',
                        '⚡ Performance enhancements',
                      ],
                    ),
                    _buildChangelogVersion(
                      isDark,
                      version: '1.0.0',
                      date: 'December 2024',
                      changes: [
                        '🎉 Initial release',
                        '✨ AI-powered habit suggestions',
                        '📊 Progress tracking and analytics',
                        '🔔 Smart reminders',
                        '🌙 Dark mode support',
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a changelog version entry with version badge, date, and changes
  /// 构建包含版本徽章、日期和更改列表的更新日志条目
  Widget _buildChangelogVersion(
    bool isDark, {
    required String version,
    required String date,
    required List<String> changes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                borderRadius: UIConstants.borderRadiusSmall,
              ),
              child: Text(
                'v$version',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              date,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...changes.map(
          (change) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              change,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Shows a bottom sheet with the full privacy policy content
  /// 显示包含完整隐私政策内容的底部弹出窗口
  void _showPrivacyPolicy(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(UIConstants.radiusXLarge)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  ),
                ),
                const Spacer(),
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
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPolicySection(
                      isDark,
                      title: 'Information We Collect',
                      content:
                          'We collect information you provide directly, including:\n• Account information (email, name)\n• Habit data you create and track\n• Usage analytics to improve the app',
                    ),
                    _buildPolicySection(
                      isDark,
                      title: 'How We Use Your Information',
                      content:
                          'Your data is used to:\n• Provide and maintain the habit tracking service\n• Generate AI-powered insights and suggestions\n• Send notifications and reminders you configure\n• Improve the app experience',
                    ),
                    _buildPolicySection(
                      isDark,
                      title: 'Data Storage & Security',
                      content:
                          'Your data is stored securely using Firebase Cloud services with encryption at rest and in transit. We implement industry-standard security measures to protect your information.',
                    ),
                    _buildPolicySection(
                      isDark,
                      title: 'Your Rights',
                      content:
                          'You can:\n• Access and export your data anytime\n• Delete your account and all associated data\n• Opt out of AI features and analytics\n• Contact us with privacy concerns',
                    ),
                    _buildPolicySection(
                      isDark,
                      title: 'Contact Us',
                      content:
                          'For privacy questions, email us at:\nxiaostone0125@gmail.com',
                    ),
                    Text(
                      'Last updated: January 2026',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTertiaryText
                            : AppColors.lightTertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a bottom sheet with the terms of service content
  /// 显示包含服务条款内容的底部弹出窗口
  void _showTermsOfService(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(UIConstants.radiusXLarge)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  ),
                ),
                const Spacer(),
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
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPolicySection(
                      isDark,
                      title: '1. Acceptance of Terms',
                      content:
                          'By using Habit Tracker, you agree to these terms. If you do not agree, please do not use the app.',
                    ),
                    _buildPolicySection(
                      isDark,
                      title: '2. Use of Service',
                      content:
                          'You may use Habit Tracker for personal, non-commercial habit tracking purposes. You are responsible for maintaining the confidentiality of your account.',
                    ),
                    _buildPolicySection(
                      isDark,
                      title: '3. User Content',
                      content:
                          'You retain ownership of your habit data. By using our service, you grant us permission to store and process this data to provide the service.',
                    ),
                    _buildPolicySection(
                      isDark,
                      title: '4. AI Features',
                      content:
                          'AI suggestions are provided for informational purposes only. We do not guarantee the accuracy or suitability of AI-generated recommendations.',
                    ),
                    _buildPolicySection(
                      isDark,
                      title: '5. Subscriptions',
                      content:
                          'Pro features require a subscription. Subscriptions auto-renew unless cancelled. Refunds are subject to app store policies.',
                    ),
                    _buildPolicySection(
                      isDark,
                      title: '6. Limitation of Liability',
                      content:
                          'Habit Tracker is provided "as is" without warranties. We are not liable for any damages arising from use of the app.',
                    ),
                    _buildPolicySection(
                      isDark,
                      title: '7. Changes to Terms',
                      content:
                          'We may update these terms. Continued use after changes constitutes acceptance of new terms.',
                    ),
                    Text(
                      'Last updated: January 2026',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTertiaryText
                            : AppColors.lightTertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a policy section with title and content text block
  /// 构建包含标题和内容文本块的政策部分
  Widget _buildPolicySection(
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

  // ==================== Confirmation Dialogs ====================

  /// Shows a confirmation dialog for signing out of the account
  /// 显示退出账户的确认对话框
  void _showSignOutConfirmation(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final settingsProvider = context.read<SettingsProvider>();
              Navigator.pop(context);
              await settingsProvider.signOut();
              // In real app, would navigate to login screen
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog for permanently deleting the account
  /// 显示永久删除账户的确认对话框
  void _showDeleteAccountConfirmation(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone. Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final settingsProvider = context.read<SettingsProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await settingsProvider.deleteAccount();
                // Auth state listener in AuthWrapper will redirect to login
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().contains('requires-recent-login')
                          ? 'Please sign out, sign back in, and try again.'
                          : 'Failed to delete account. Please try again.',
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: isDark ? AppColors.darkRed : AppColors.lightRed,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // ==================== URL Launcher Helper ====================

  /// Launches an external URL in the default browser
  /// 在默认浏览器中打开外部URL
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  // ==================== Export Options ====================

  /// Shows a bottom sheet with CSV and JSON export format options
  /// 显示包含CSV和JSON导出格式选项的底部弹出窗口
  void _showExportOptions(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Your Data',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose an export format:',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildExportOption(
              context,
              isDark: isDark,
              icon: Icons.table_chart_rounded,
              title: 'CSV Spreadsheet',
              subtitle: 'Open in Excel or Google Sheets',
              onTap: () async {
                final habits = context.read<HabitProvider>().habits;
                Navigator.pop(context);
                await ExportService().exportAndShareCSV(habits);
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              context,
              isDark: isDark,
              icon: Icons.data_object_rounded,
              title: 'JSON Backup',
              subtitle: 'Full data backup with history',
              onTap: () async {
                final habits = context.read<HabitProvider>().habits;
                Navigator.pop(context);
                await ExportService().exportAndShareJSON(habits);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Builds a single export option row with icon, title, and description
  /// 构建带有图标、标题和描述的单个导出选项行
  Widget _buildExportOption(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      borderRadius: UIConstants.borderRadiusMedium,
      child: InkWell(
        onTap: onTap,
        borderRadius: UIConstants.borderRadiusMedium,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCoral.withValues(alpha: 0.2)
                      : AppColors.lightCoral.withValues(alpha: 0.2),
                  borderRadius: UIConstants.borderRadiusMedium,
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                        fontSize: 13,
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

  // ==================== Upgrade Bottom Sheet ====================

  /// Shows the upgrade bottom sheet with subscription tier options
  /// 显示包含订阅等级选项的升级底部弹出窗口
  void _showUpgradeBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _UpgradeBottomSheet(isDark: isDark),
    );
  }
}

/// Stateful bottom sheet for upgrade flow (needs to manage loading/purchase state)
/// 升级流程的有状态底部弹出窗口（需要管理加载/购买状态）
class _UpgradeBottomSheet extends StatefulWidget {
  final bool isDark;
  /// Creates the upgrade bottom sheet with theme mode
  /// 创建带有主题模式的升级底部弹出窗口
  const _UpgradeBottomSheet({required this.isDark});

  /// Creates the mutable state for the upgrade bottom sheet
  /// 创建升级底部弹出窗口的可变状态
  @override
  State<_UpgradeBottomSheet> createState() => _UpgradeBottomSheetState();
}

class _UpgradeBottomSheetState extends State<_UpgradeBottomSheet> {
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;
  // RevenueCat offerings mapped by tier
  Map<SubscriptionTier, dynamic> _packages = {};

  /// Returns whether the current theme is dark mode
  /// 返回当前主题是否为深色模式
  bool get isDark => widget.isDark;

  /// Initializes state and loads subscription offerings
  /// 初始化状态并加载订阅产品
  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  /// Loads available subscription offerings from RevenueCat
  /// 从RevenueCat加载可用的订阅产品
  Future<void> _loadOfferings() async {
    try {
      final offerings = await SubscriptionService().getOfferings();
      final mapped = <SubscriptionTier, dynamic>{};

      for (final pkg in offerings) {
        // Match packages to tiers by identifier
        final id = pkg.storeProduct.identifier.toLowerCase();
        if (id.contains('growth')) {
          mapped[SubscriptionTier.growth] = pkg;
        } else if (id.contains('mastery')) {
          mapped[SubscriptionTier.mastery] = pkg;
        }
      }

      if (mounted) {
        setState(() {
          _packages = mapped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load subscription options';
          _isLoading = false;
        });
      }
    }
  }

  /// Initiates a subscription purchase for the selected package
  /// 为所选套餐发起订阅购买
  Future<void> _purchase(dynamic package) async {
    setState(() => _isPurchasing = true);

    try {
      final success = await SubscriptionService().purchasePackage(package);
      if (mounted) {
        Navigator.of(context).pop();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome to Pro! Enjoy your new features.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    }
  }

  /// Restores previously purchased subscriptions
  /// 恢复之前购买的订阅
  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);
    try {
      final restored = await SubscriptionService().restorePurchases();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(restored
                ? 'Subscription restored successfully!'
                : 'No active subscription found to restore'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  /// Returns the localized price string for a subscription tier
  /// 返回订阅等级的本地化价格字符串
  String _getPriceString(SubscriptionTier tier) {
    final pkg = _packages[tier];
    if (pkg != null) {
      return pkg.storeProduct.priceString;
    }
    return tier == SubscriptionTier.growth ? '\$4.99/mo' : '\$9.99/mo';
  }

  /// Builds the upgrade bottom sheet with plan cards and restore button
  /// 构建包含计划卡片和恢复购买按钮的升级底部弹出窗口
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 48,
                    color: isDark ? AppColors.darkGold : AppColors.lightGold,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unlock your full potential',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                      ),
                    )
                  else if (_error != null)
                    _buildErrorState()
                  else ...[
                    // Starter tier (current plan reference)
                    _buildTierCard(
                      tier: SubscriptionTier.starter,
                      price: 'Free',
                      isCurrent: true,
                      isHighlighted: false,
                    ),
                    const SizedBox(height: 12),
                    // Growth tier
                    _buildTierCard(
                      tier: SubscriptionTier.growth,
                      price: _getPriceString(SubscriptionTier.growth),
                      isCurrent: false,
                      isHighlighted: false,
                    ),
                    const SizedBox(height: 12),
                    // Mastery tier (highlighted)
                    _buildTierCard(
                      tier: SubscriptionTier.mastery,
                      price: _getPriceString(SubscriptionTier.mastery),
                      isCurrent: false,
                      isHighlighted: true,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Restore purchases
                  TextButton(
                    onPressed: _isPurchasing ? null : _restorePurchases,
                    child: Text(
                      'Restore Purchases',
                      style: TextStyle(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        fontSize: 14,
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

  /// Builds the error state view with retry button when offerings fail to load
  /// 构建产品加载失败时带有重试按钮的错误状态视图
  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadOfferings();
            },
            child: Text(
              'Retry',
              style: TextStyle(
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a subscription tier card with features and subscribe button
  /// 构建包含功能列表和订阅按钮的订阅等级卡片
  Widget _buildTierCard({
    required SubscriptionTier tier,
    required String price,
    required bool isCurrent,
    required bool isHighlighted,
  }) {
    final features = _getFeaturesForTier(tier);
    final goldColor = isDark ? AppColors.darkGold : AppColors.lightGold;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isDark ? goldColor.withValues(alpha: 0.1) : goldColor.withValues(alpha: 0.08))
            : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? goldColor.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier name + badge
          Row(
            children: [
              Text(
                tier.displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
              if (isHighlighted) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: goldColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Best Value',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                price,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isHighlighted
                      ? goldColor
                      : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tier.description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 12),

          // Feature list
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: isHighlighted
                      ? goldColor
                      : (isDark ? AppColors.darkCoral : AppColors.lightCoral),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    ),
                  ),
                ),
              ],
            ),
          )),

          // Subscribe button (not for current plan)
          if (!isCurrent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPurchasing
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        final pkg = _packages[tier];
                        if (pkg != null) {
                          _purchase(pkg);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('This plan is not yet available. Please try again later.'),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHighlighted
                      ? goldColor
                      : (isDark ? AppColors.darkCoral : AppColors.lightCoral),
                  foregroundColor: isHighlighted
                      ? Colors.black
                      : (isDark ? AppColors.darkBackground : Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isPurchasing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isHighlighted ? Colors.black : Colors.white,
                        ),
                      )
                    : Text(
                        'Subscribe',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Returns the list of feature descriptions for a subscription tier
  /// 返回订阅等级的功能描述列表
  List<String> _getFeaturesForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return [
          'Up to 5 habits',
          '1 AI suggestion per day',
          '10 AI reports per month',
          'Basic progress tracking',
        ];
      case SubscriptionTier.growth:
        return [
          'Up to 10 habits',
          '5 AI suggestions per day',
          '30 AI reports per month',
          'Trend charts & analytics',
          'Daily AI coaching reports',
        ];
      case SubscriptionTier.mastery:
        return [
          'Unlimited habits',
          'Unlimited AI suggestions',
          'Unlimited AI reports',
          'Full analytics & insights',
          'Health data integration',
          'Achievement badges',
          'Priority support',
        ];
    }
  }
}
