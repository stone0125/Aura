import 'package:flutter/material.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/ai_suggestion_card.dart';
import '../widgets/home/motivational_quote_card.dart';
import '../widgets/home/summary_stats_card.dart';
import '../widgets/home/habit_list.dart';
import '../config/theme/app_colors.dart';
import 'habit_creation_screen.dart';
import 'ai_coach_screen.dart';

/// Home Screen - Primary Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Define screens for each tab
  final List<Widget> _screens = [
    const _HomeTab(),
    const _ProgressTab(),
    const AICoachScreen(),
    const _SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HabitCreationScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
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
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });

            // Show placeholder messages for non-implemented tabs
            if (index == 1 || index == 3) {
              final tabNames = ['Home', 'Progress', 'AI Coach', 'Settings'];
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${tabNames[index]} screen coming soon!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_rounded),
              label: 'AI Coach',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// Home Tab Widget
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                const HomeHeader(userName: 'Lucas'),

                // AI Suggestion Card
                const AISuggestionCard(),
                const SizedBox(height: 20),

                // Motivational Quote Card
                const MotivationalQuoteCard(),
                const SizedBox(height: 24),

                // Summary Stats Card
                const SummaryStatsCard(),
                const SizedBox(height: 24),

                // Habit List Section
                const HabitList(),

                // Bottom padding for FAB and nav bar
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress Tab Placeholder
class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 80,
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
              ),
              const SizedBox(height: 20),
              Text(
                'Progress Screen',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming soon!',
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
      ),
    );
  }
}

/// Settings Tab Placeholder
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings_rounded,
                size: 80,
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
              ),
              const SizedBox(height: 20),
              Text(
                'Settings Screen',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming soon!',
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
      ),
    );
  }
}
