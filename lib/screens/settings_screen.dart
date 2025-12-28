import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme/app_colors.dart';
import '../models/settings_models.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/habit_provider.dart';
import '../services/subscription_service.dart';
import '../services/export_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Comprehensive settings and profile management screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize settings on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().initialize();
    });
  }

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
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
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

                  // AI Preferences
                  _buildSectionHeader(context, 'AI Preferences', isDark),
                  _buildAISection(context, settings, isDark),

                  const SizedBox(height: 24),

                  // Account
                  _buildSectionHeader(context, 'Account', isDark),
                  _buildAccountSection(context, profile, isDark),

                  const SizedBox(height: 24),

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

  Widget _buildProfileSection(
    BuildContext context,
    UserProfile profile,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
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
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.memberSinceText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
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
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
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
                      ? AppColors.darkTextSecondary.withValues(alpha: 0.1)
                      : AppColors.lightTextSecondary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Consumer<ProgressProvider>(
              builder: (context, progressProvider, child) {
                final stats = progressProvider.stats;
                return Row(
                  children: [
                    _buildStatItem(
                      context,
                      '${stats?.daysTracked ?? 0}',
                      'Days Tracked',
                      isDark,
                    ),
                    _buildStatDivider(isDark),
                    _buildStatItem(
                      context,
                      '${stats?.totalHabits ?? 0}',
                      'Active Habits',
                      isDark,
                    ),
                    _buildStatDivider(isDark),
                    _buildStatItem(
                      context,
                      '${((stats?.completionRate ?? 0) * 100).toStringAsFixed(0)}%',
                      'Success Rate',
                      isDark,
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
                SubscriptionService().presentPaywall();
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
                  borderRadius: BorderRadius.circular(12),
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
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Unlock advanced AI features & unlimited habits',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
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
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    bool isDark,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark
          ? AppColors.darkTextSecondary.withValues(alpha: 0.2)
          : AppColors.lightTextSecondary.withValues(alpha: 0.2),
    );
  }

  // ==================== Section Headers ====================

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
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
        ),
      ),
    );
  }

  // ==================== Appearance Section ====================

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
          onChanged: (value) {
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().setNotificationsEnabled(value);
          },
        ),
        if (settings.notificationsEnabled) ...[
          _buildDivider(isDark),
          _buildSettingRow(
            context,
            icon: Icons.access_time_rounded,
            title: 'Default Reminder Time',
            subtitle: settings.reminderTimeText,
            isDark: isDark,
            onTap: () =>
                _showTimePicker(context, settings.defaultReminderTime, isDark),
          ),
          _buildSwitchRow(
            context,
            icon: Icons.circle_rounded,
            title: 'Badge',
            subtitle: 'Show app badge count',
            value: settings.badgeEnabled,
            isDark: isDark,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              context.read<SettingsProvider>().setBadgeEnabled(value);
            },
          ),
          _buildDivider(isDark),
          _buildSwitchRow(
            context,
            icon: Icons.auto_awesome_rounded,
            title: 'Motivational Messages',
            subtitle: 'Daily inspiration',
            value: settings.motivationalMessages,
            isDark: isDark,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              context.read<SettingsProvider>().setMotivationalMessages(value);
            },
          ),
        ],
      ],
    );
  }

  // ==================== AI Preferences Section ====================

  Widget _buildAISection(
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
          icon: Icons.psychology_rounded,
          title: 'AI Suggestions',
          subtitle: 'Personalized habit recommendations',
          value: settings.aiSuggestionsEnabled,
          isDark: isDark,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().setAISuggestionsEnabled(value);
          },
        ),
        if (settings.aiSuggestionsEnabled) ...[
          _buildDivider(isDark),
          _buildSettingRow(
            context,
            icon: Icons.schedule_rounded,
            title: 'Suggestion Frequency',
            subtitle: settings.suggestionFrequency.displayName,
            isDark: isDark,
            onTap: () => _showFrequencySelector(
              context,
              settings.suggestionFrequency,
              isDark,
            ),
          ),
          _buildDivider(isDark),
          _buildSwitchRow(
            context,
            icon: Icons.timer_rounded,
            title: 'AI-Optimized Reminders',
            subtitle: 'Best times based on your patterns',
            value: settings.aiOptimizedReminders,
            isDark: isDark,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              context.read<SettingsProvider>().setAIOptimizedReminders(value);
            },
          ),
          _buildDivider(isDark),
          _buildSwitchRow(
            context,
            icon: Icons.analytics_rounded,
            title: 'Share Data for AI Improvement',
            subtitle: 'Help improve AI suggestions',
            value: settings.shareDataForAI,
            isDark: isDark,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              context.read<SettingsProvider>().setShareDataForAI(value);
            },
          ),
        ],
      ],
    );
  }

  // ==================== Account Section ====================

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
            SubscriptionService().presentCustomerCenter();
          },
        ),
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
          onTap: () => _launchUrl('https://habittracker.app/faq'),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.school_rounded,
          title: 'Tutorials',
          subtitle: 'Learn how to use the app',
          isDark: isDark,
          onTap: () => _launchUrl('https://habittracker.app/tutorials'),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.support_agent_rounded,
          title: 'Contact Support',
          subtitle: 'Get help from our team',
          isDark: isDark,
          onTap: () => _showContactSupport(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.bug_report_rounded,
          title: 'Report Bug',
          subtitle: 'Help us improve',
          isDark: isDark,
          onTap: () => _showReportBug(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.lightbulb_rounded,
          title: 'Request Feature',
          subtitle: 'Suggest new features',
          isDark: isDark,
          onTap: () => _showRequestFeature(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.security_rounded,
          title: 'AI Transparency',
          subtitle: 'How AI works in this app',
          isDark: isDark,
          onTap: () => _launchUrl('https://habittracker.app/ai-transparency'),
        ),
      ],
    );
  }

  // ==================== About Section ====================

  Widget _buildAboutSection(BuildContext context, bool isDark) {
    return _buildSettingsCard(
      context,
      isDark,
      children: [
        _buildSettingRow(
          context,
          icon: Icons.info_rounded,
          title: 'Version',
          subtitle: '1.0.0 (Build 1)',
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
              applicationName: 'Habit Tracker',
              applicationVersion: '1.0.0',
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

  Widget _buildSettingsCard(
    BuildContext context,
    bool isDark, {
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
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
      borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(10),
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
                          (isDark ? Colors.white : AppColors.lightTextPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
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
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
          ],
        ),
      ),
    );
  }

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
              borderRadius: BorderRadius.circular(10),
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
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
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

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? AppColors.darkTextSecondary.withValues(alpha: 0.1)
            : AppColors.lightTextSecondary.withValues(alpha: 0.1),
      ),
    );
  }

  // ==================== Modals and Dialogs ====================

  void _showEditProfileModal(
    BuildContext context,
    UserProfile profile,
    bool isDark,
  ) {
    final firstNameController = TextEditingController(text: profile.firstName);
    final lastNameController = TextEditingController(text: profile.lastName);
    final displayNameController = TextEditingController(
      text: profile.displayName ?? '',
    );
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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
                      displayName: displayNameController.text.isEmpty
                          ? null
                          : displayNameController.text,
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
                      borderRadius: BorderRadius.circular(16),
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
    );
  }

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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      : AppColors.lightTextPrimary,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                    .withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                theme.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
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

  void _showTimePicker(
    BuildContext context,
    TimeOfDay current,
    bool isDark,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null && context.mounted) {
      HapticFeedback.lightImpact();
      context.read<SettingsProvider>().setDefaultReminderTime(picked);
    }
  }

  void _showFrequencySelector(
    BuildContext context,
    NotificationFrequency current,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggestion Frequency',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ...NotificationFrequency.values.map(
              (freq) =>
                  _buildFrequencyOption(context, freq, current == freq, isDark),
            ),
          ],
        ),
      ),
    );
  }

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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
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
                borderRadius: BorderRadius.circular(8),
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
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
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
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
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
                          'For privacy questions, email us at:\nprivacy@habittracker.app',
                    ),
                    Text(
                      'Last updated: December 2024',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
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
                      'Last updated: December 2024',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
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
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(
    BuildContext context,
    NotificationFrequency freq,
    bool isSelected,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<SettingsProvider>().setSuggestionFrequency(freq);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                    .withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    freq.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    freq.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
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

  // ==================== Confirmation Dialogs ====================

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
              Navigator.pop(context);
              await context.read<SettingsProvider>().signOut();
              // In real app, would navigate to login screen
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

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
              Navigator.pop(context);
              await context.read<SettingsProvider>().deleteAccount();
              // In real app, would navigate to login/welcome screen
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

  void _showContactSupport(BuildContext context, bool isDark) {
    _launchEmail(
      'support@habittracker.app',
      subject: 'Habit Tracker Support Request',
      body: 'Hi, I need help with...',
    );
  }

  void _showReportBug(BuildContext context, bool isDark) {
    _launchEmail(
      'bugs@habittracker.app',
      subject: 'Habit Tracker Bug Report',
      body:
          'Bug Description:\n\nSteps to Reproduce:\n1.\n2.\n3.\n\nExpected Behavior:\n\nActual Behavior:\n',
    );
  }

  void _showRequestFeature(BuildContext context, bool isDark) {
    _launchEmail(
      'features@habittracker.app',
      subject: 'Habit Tracker Feature Request',
      body: 'Feature Description:\n\nWhy it would be useful:\n',
    );
  }

  // ==================== URL Launcher Helper ====================

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

  Future<void> _launchEmail(
    String email, {
    String? subject,
    String? body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  // ==================== Export Options ====================

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
                Navigator.pop(context);
                final habits = context.read<HabitProvider>().habits;
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
                Navigator.pop(context);
                final habits = context.read<HabitProvider>().habits;
                await ExportService().exportAndShareJSON(habits);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
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
}
