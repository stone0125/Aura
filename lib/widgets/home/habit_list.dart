import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/habit.dart';
import '../../models/habit_category.dart';
import '../../providers/habit_provider.dart';
import '../../config/theme/app_colors.dart';
import '../../screens/habit_creation_screen.dart';
import '../../screens/habit_detail_screen.dart';

/// Habit List widget with completion toggles
class HabitList extends StatelessWidget {
  const HabitList({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.todaysHabits;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Today\'s Habits',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Habit Cards List
        if (habits.isEmpty)
          _buildEmptyState(isDark)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: habits.length,
            itemBuilder: (context, index) {
              return HabitCard(
                habit: habits[index],
                onToggle: () {
                  HapticFeedback.lightImpact();
                  habitProvider.toggleHabitCompletion(habits[index].id);
                },
                onDelete: () {
                  habitProvider.removeHabit(habits[index].id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Habit removed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Builder(
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration (using icon as placeholder)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.3)
                      : AppColors.lightBorder.withValues(alpha: 0.3),
                ),
                child: Icon(
                  Icons.spa_rounded,
                  size: 60,
                  color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Start your habit journey',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Create your first habit to begin tracking',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HabitCreationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.darkCoral : AppColors.lightCoral,
                    foregroundColor:
                        isDark ? AppColors.darkBackground : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create Your First Habit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual Habit Card widget
class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = habit.category.getGradient(
      isDark ? Brightness.dark : Brightness.light,
    );

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 12,
        ),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkRed : AppColors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Habit'),
              content: Text('Are you sure you want to delete "${habit.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        onDelete();
      },
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => HabitDetailScreen(habit: habit),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 12,
          ),
          height: 80,
          decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
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
        child: Row(
          children: [
            const SizedBox(width: 16),

            // Category Icon
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
                habit.category.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Habit Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: isDark ? AppColors.darkOrange : AppColors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.streak} day streak',
                        style: TextStyle(
                          color:
                              isDark ? AppColors.darkOrange : AppColors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Completion Button
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: habit.isCompleted
                          ? (isDark
                              ? AppColors.darkCoral
                              : AppColors.lightCoral)
                          : Colors.transparent,
                      border: habit.isCompleted
                          ? null
                          : Border.all(
                              color: isDark
                                  ? AppColors.darkCoral
                                  : AppColors.lightCoral,
                              width: 2,
                            ),
                    ),
                    child: habit.isCompleted
                        ? Icon(
                            Icons.check_rounded,
                            color: isDark
                                ? AppColors.darkBackground
                                : Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
