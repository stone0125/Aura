import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme/app_colors.dart';
import '../models/settings_models.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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

                  // Data & Sync
                  _buildSectionHeader(context, 'Data & Sync', isDark),
                  _buildDataSyncSection(context, settings, isDark),

                  const SizedBox(height: 24),

                  // Account
                  _buildSectionHeader(context, 'Account', isDark),
                  _buildAccountSection(context, profile, isDark),

                  const SizedBox(height: 24),

                  // Accessibility
                  _buildSectionHeader(context, 'Accessibility', isDark),
                  _buildAccessibilitySection(context, settings, isDark),

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

  Widget _buildProfileSection(BuildContext context, UserProfile profile, bool isDark) {
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
                      child: Center(
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
                            color: isDark ? AppColors.darkGold : AppColors.lightGold,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.memberSinceText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit button
                IconButton(
                  onPressed: () => _showEditProfileModal(context, profile, isDark),
                  icon: Icon(
                    Icons.edit_rounded,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
            child: Row(
              children: [
                _buildStatItem(context, '42', 'Days Tracked', isDark),
                _buildStatDivider(isDark),
                _buildStatItem(context, '8', 'Active Habits', isDark),
                _buildStatDivider(isDark),
                _buildStatItem(context, '85%', 'Success Rate', isDark),
              ],
            ),
          ),

          // Upgrade to Pro (if not pro)
          if (!profile.isPro)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.darkGold.withValues(alpha: 0.2), AppColors.darkGold.withValues(alpha: 0.1)]
                      : [AppColors.lightGold.withValues(alpha: 0.2), AppColors.lightGold.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkGold.withValues(alpha: 0.3) : AppColors.lightGold.withValues(alpha: 0.3),
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
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Unlock advanced AI features & unlimited habits',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, bool isDark) {
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
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
      ),
    );
  }

  // ==================== Appearance Section ====================

  Widget _buildAppearanceSection(BuildContext context, AppSettings settings, bool isDark) {
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
          onTap: () => _showThemeSelector(context, settings.themePreference, isDark),
        ),
      ],
    );
  }

  // ==================== Notifications Section ====================

  Widget _buildNotificationsSection(BuildContext context, AppSettings settings, bool isDark) {
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
            onTap: () => _showTimePicker(context, settings.defaultReminderTime, isDark),
          ),
          _buildDivider(isDark),
          _buildSettingRow(
            context,
            icon: Icons.music_note_rounded,
            title: 'Notification Sound',
            subtitle: settings.notificationSound,
            isDark: isDark,
            onTap: () {
              // Show sound picker
            },
          ),
          _buildDivider(isDark),
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

  Widget _buildAISection(BuildContext context, AppSettings settings, bool isDark) {
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
            onTap: () => _showFrequencySelector(context, settings.suggestionFrequency, isDark),
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

  // ==================== Data & Sync Section ====================

  Widget _buildDataSyncSection(BuildContext context, AppSettings settings, bool isDark) {
    return _buildSettingsCard(
      context,
      isDark,
      children: [
        _buildSwitchRow(
          context,
          icon: Icons.cloud_rounded,
          title: 'Cloud Sync',
          subtitle: settings.cloudSyncEnabled
              ? '${settings.syncStatus.displayName}${settings.lastSyncText != null ? ' • ${settings.lastSyncText}' : ''}'
              : 'Sync across devices',
          value: settings.cloudSyncEnabled,
          isDark: isDark,
          trailing: settings.syncStatus == SyncStatus.syncing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      isDark ? AppColors.darkCoral : AppColors.lightCoral,
                    ),
                  ),
                )
              : null,
          onChanged: (value) async {
            HapticFeedback.lightImpact();
            await context.read<SettingsProvider>().setCloudSyncEnabled(value);
          },
        ),
        if (settings.cloudSyncEnabled) ...[
          _buildDivider(isDark),
          _buildSettingRow(
            context,
            icon: Icons.sync_rounded,
            title: 'Sync Now',
            subtitle: 'Manually sync your data',
            isDark: isDark,
            onTap: () async {
              HapticFeedback.lightImpact();
              await context.read<SettingsProvider>().syncNow();
            },
          ),
        ],
        _buildDivider(isDark),
        _buildSwitchRow(
          context,
          icon: Icons.backup_rounded,
          title: 'Auto Backup',
          subtitle: 'Daily automatic backups',
          value: settings.autoBackupEnabled,
          isDark: isDark,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().setAutoBackupEnabled(value);
          },
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.upload_rounded,
          title: 'Export Data',
          subtitle: 'Download your habit data',
          isDark: isDark,
          onTap: () => _showExportFormatSelector(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.download_rounded,
          title: 'Import Data',
          subtitle: 'Restore from backup',
          isDark: isDark,
          onTap: () => _showImportConfirmation(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.delete_sweep_rounded,
          iconColor: isDark ? AppColors.darkRed : AppColors.lightRed,
          title: 'Clear All Data',
          subtitle: 'Delete all habits and progress',
          titleColor: isDark ? AppColors.darkRed : AppColors.lightRed,
          isDark: isDark,
          onTap: () => _showClearDataConfirmation(context, isDark),
        ),
      ],
    );
  }

  // ==================== Account Section ====================

  Widget _buildAccountSection(BuildContext context, UserProfile profile, bool isDark) {
    return _buildSettingsCard(
      context,
      isDark,
      children: [
        _buildSettingRow(
          context,
          icon: Icons.email_rounded,
          title: 'Email Address',
          subtitle: profile.email,
          isDark: isDark,
          onTap: () => _showChangeEmail(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.lock_rounded,
          title: 'Password',
          subtitle: 'Change your password',
          isDark: isDark,
          onTap: () => _showChangePassword(context, isDark),
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.workspace_premium_rounded,
          iconColor: profile.isPro ? (isDark ? AppColors.darkGold : AppColors.lightGold) : null,
          title: profile.isPro ? 'Pro Member' : 'Subscription',
          subtitle: profile.isPro ? 'Active Pro subscription' : 'Manage subscription',
          isDark: isDark,
          onTap: () {
            // Show subscription management
          },
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.logout_rounded,
          iconColor: isDark ? AppColors.darkOrange : AppColors.lightOrange,
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

  // ==================== Accessibility Section ====================

  Widget _buildAccessibilitySection(BuildContext context, AppSettings settings, bool isDark) {
    return _buildSettingsCard(
      context,
      isDark,
      children: [
        _buildSettingRow(
          context,
          icon: Icons.text_fields_rounded,
          title: 'Text Size',
          subtitle: settings.textSize.displayName,
          isDark: isDark,
          onTap: () => _showTextSizeSelector(context, settings.textSize, isDark),
        ),
        _buildDivider(isDark),
        _buildSwitchRow(
          context,
          icon: Icons.motion_photos_off_rounded,
          title: 'Reduce Motion',
          subtitle: 'Minimize animations',
          value: settings.reduceMotion,
          isDark: isDark,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().setReduceMotion(value);
          },
        ),
        _buildDivider(isDark),
        _buildSwitchRow(
          context,
          icon: Icons.visibility_rounded,
          title: 'Color Blind Mode',
          subtitle: 'Enhanced color accessibility',
          value: settings.colorBlindMode,
          isDark: isDark,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().setColorBlindMode(value);
          },
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
          onTap: () {
            context.read<SettingsProvider>().openFAQ();
          },
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.school_rounded,
          title: 'Tutorials',
          subtitle: 'Learn how to use the app',
          isDark: isDark,
          onTap: () {
            context.read<SettingsProvider>().openTutorials();
          },
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
          onTap: () {
            context.read<SettingsProvider>().openAITransparency();
          },
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
          onTap: () {
            // Show changelog
          },
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.privacy_tip_rounded,
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          isDark: isDark,
          onTap: () {
            // Open privacy policy
          },
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.description_rounded,
          title: 'Terms of Service',
          subtitle: 'User agreement',
          isDark: isDark,
          onTap: () {
            // Open terms
          },
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
          onTap: () {
            // Open app store
          },
        ),
        _buildDivider(isDark),
        _buildSettingRow(
          context,
          icon: Icons.people_rounded,
          title: 'Credits',
          subtitle: 'Made by Sarah Mitchell',
          isDark: isDark,
          showArrow: false,
        ),
      ],
    );
  }

  // ==================== Helper Widgets ====================

  Widget _buildSettingsCard(BuildContext context, bool isDark, {required List<Widget> children}) {
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
      child: Column(
        children: children,
      ),
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
                color: (iconColor ?? (isDark ? AppColors.darkCoral : AppColors.lightCoral)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? (isDark ? AppColors.darkCoral : AppColors.lightCoral),
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
                      color: titleColor ?? (isDark ? Colors.white : AppColors.lightTextPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
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
              color: (isDark ? AppColors.darkCoral : AppColors.lightCoral).withValues(alpha: 0.1),
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
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                activeTrackColor: isDark ? AppColors.darkCoral.withValues(alpha: 0.5) : AppColors.lightCoral.withValues(alpha: 0.5),
                activeColor: isDark ? AppColors.darkCoral : AppColors.lightCoral,
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

  void _showEditProfileModal(BuildContext context, UserProfile profile, bool isDark) {
    final firstNameController = TextEditingController(text: profile.firstName);
    final lastNameController = TextEditingController(text: profile.lastName);
    final displayNameController = TextEditingController(text: profile.displayName ?? '');
    final bioController = TextEditingController(text: profile.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bio (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                          displayName: displayNameController.text.isEmpty ? null : displayNameController.text,
                          bio: bioController.text.isEmpty ? null : bioController.text,
                        );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context, ThemePreference current, bool isDark) {
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
              'Choose Theme',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ...ThemePreference.values.map((theme) => _buildThemeOption(
                  context,
                  theme,
                  current == theme,
                  isDark,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemePreference theme, bool isSelected, bool isDark) {
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
              ? (isDark ? AppColors.darkCoral : AppColors.lightCoral).withValues(alpha: 0.1)
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
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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

  void _showTimePicker(BuildContext context, TimeOfDay current, bool isDark) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null && context.mounted) {
      HapticFeedback.lightImpact();
      context.read<SettingsProvider>().setDefaultReminderTime(picked);
    }
  }

  void _showFrequencySelector(BuildContext context, NotificationFrequency current, bool isDark) {
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
            ...NotificationFrequency.values.map((freq) => _buildFrequencyOption(
                  context,
                  freq,
                  current == freq,
                  isDark,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(BuildContext context, NotificationFrequency freq, bool isSelected, bool isDark) {
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
              ? (isDark ? AppColors.darkCoral : AppColors.lightCoral).withValues(alpha: 0.1)
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
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    freq.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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

  void _showExportFormatSelector(BuildContext context, bool isDark) {
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
              'Choose Export Format',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ...ExportFormat.values.map((format) => _buildExportFormatOption(
                  context,
                  format,
                  isDark,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildExportFormatOption(BuildContext context, ExportFormat format, bool isDark) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        await context.read<SettingsProvider>().exportData(format);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported as ${format.displayName}')),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCoral : AppColors.lightCoral).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                format.icon,
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    format.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showTextSizeSelector(BuildContext context, TextSizePreference current, bool isDark) {
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
              'Text Size',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ...TextSizePreference.values.map((size) => _buildTextSizeOption(
                  context,
                  size,
                  current == size,
                  isDark,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeOption(BuildContext context, TextSizePreference size, bool isSelected, bool isDark) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<SettingsProvider>().setTextSize(size);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkCoral : AppColors.lightCoral).withValues(alpha: 0.1)
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
              child: Text(
                size.displayName,
                style: TextStyle(
                  fontSize: 16 * size.scale,
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

  // ==================== Confirmation Dialogs ====================

  void _showImportConfirmation(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text('This will merge imported data with your existing habits. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<SettingsProvider>().importData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Data imported successfully' : 'Import failed')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmation(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your habits and progress. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SettingsProvider>().clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: isDark ? AppColors.darkRed : AppColors.lightRed),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showChangeEmail(BuildContext context, bool isDark) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'New Email Address',
            hintText: 'email@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              Navigator.pop(context);
              final success = await context.read<SettingsProvider>().changeEmail(emailController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Email updated' : 'Failed to update email')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context, bool isDark) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (currentPasswordController.text.isEmpty || newPasswordController.text.isEmpty) return;
              Navigator.pop(context);
              final success = await context.read<SettingsProvider>().changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Password updated' : 'Failed to update password')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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
            style: TextButton.styleFrom(foregroundColor: isDark ? AppColors.darkRed : AppColors.lightRed),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context, bool isDark) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            labelText: 'Message',
            hintText: 'How can we help you?',
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (messageController.text.isEmpty) return;
              Navigator.pop(context);
              await context.read<SettingsProvider>().contactSupport(messageController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message sent to support')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showReportBug(BuildContext context, bool isDark) {
    final bugController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Bug'),
        content: TextField(
          controller: bugController,
          decoration: const InputDecoration(
            labelText: 'Bug Description',
            hintText: 'What went wrong?',
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (bugController.text.isEmpty) return;
              Navigator.pop(context);
              await context.read<SettingsProvider>().reportBug(bugController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bug report submitted')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showRequestFeature(BuildContext context, bool isDark) {
    final featureController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Feature'),
        content: TextField(
          controller: featureController,
          decoration: const InputDecoration(
            labelText: 'Feature Description',
            hintText: 'What would you like to see?',
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (featureController.text.isEmpty) return;
              Navigator.pop(context);
              await context.read<SettingsProvider>().requestFeature(featureController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature request submitted')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
