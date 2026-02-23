import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/settings_models.dart';
import '../../config/theme/app_colors.dart';

/// Home screen header with profile, greeting, and theme toggle
class HomeHeader extends StatelessWidget {
  final String userName;

  const HomeHeader({super.key, this.userName = 'User'});

  @override
  Widget build(BuildContext context) {
    // Use read() for themeProvider since we only call methods, don't depend on state
    final themeProvider = context.read<ThemeProvider>();
    // Use Selector to only rebuild when profile changes
    final profile = context.select<SettingsProvider, UserProfile>((s) => s.userProfile);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateText = DateFormat('EEEE, MMMM d, yyyy').format(now);

    // Use profile firstName if available, fallback to passed userName
    final displayName =
        profile.firstName.isNotEmpty && profile.firstName != 'User'
        ? profile.firstName
        : userName;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 48, bottom: 24),
      child: Row(
        children: [
          // Profile Avatar - matches Settings screen style
          Container(
            width: 44,
            height: 44,
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
            child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      profile.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            profile.initials.isNotEmpty
                                ? profile.initials
                                : _getInitials(displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      profile.initials.isNotEmpty
                          ? profile.initials
                          : _getInitials(displayName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),

          // Greeting and Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $displayName',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateText,
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

          // Theme Toggle Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                themeProvider.toggleTheme();
                // Sync with SettingsProvider — read actual state after toggle
                final newIsDark = themeProvider.isDarkMode;
                context.read<SettingsProvider>().setThemePreference(
                  newIsDark ? ThemePreference.dark : ThemePreference.light,
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get greeting based on time of day
  String _getGreeting(int hour) {
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 18) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Get user initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      // Ensure the first part has at least one character
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
    } else {
      // Ensure both parts have at least one character
      final firstChar = parts[0].isNotEmpty ? parts[0][0] : '';
      final lastChar = parts[parts.length - 1].isNotEmpty ? parts[parts.length - 1][0] : '';
      final initials = '$firstChar$lastChar'.toUpperCase();
      return initials.isNotEmpty ? initials : 'U';
    }
  }
}
