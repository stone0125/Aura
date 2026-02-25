import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/ui_constants.dart';
import 'dart:math' as math;

/// Summary Stats Card with circular progress
class SummaryStatsCard extends StatelessWidget {
  const SummaryStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when specific stats change
    final completedCount = context.select<HabitProvider, int>(
      (provider) => provider.completedCount,
    );
    final totalCount = context.select<HabitProvider, int>(
      (provider) => provider.totalCount,
    );
    final completionRate = context.select<HabitProvider, double>(
      (provider) => provider.completionRate,
    );
    final bestStreak = context.select<HabitProvider, int>(
      (provider) => provider.bestStreak,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
        children: [
          // Circular Progress Chart - wrapped in RepaintBoundary to isolate repaints
          SizedBox(
            width: 120,
            height: 120,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: CircularProgressPainter(
                  progress: completionRate,
                  isDark: isDark,
                ),
                child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$completedCount/$totalCount',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'habits today',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.grid_view_rounded,
                  number: totalCount.toString(),
                  label: 'Total Habits',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_rounded,
                  number: completedCount.toString(),
                  label: 'Done Today',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_fire_department_rounded,
                  number: '$bestStreak days',
                  label: 'Best Streak',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String number,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder.withValues(alpha: 0.3),
          ),
          child: Icon(
            icon,
            color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          number,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for circular progress indicator
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  CircularProgressPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 12.0;

    // Background ring
    final backgroundPaint = Paint()
      ..color = isDark ? AppColors.darkBorder : AppColors.lightBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Progress ring with gradient effect
    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress > 0) {
      final progressPaint = Paint()
        ..shader = LinearGradient(
          colors: isDark
              ? [AppColors.darkCoral, AppColors.darkCoralDeep]
              : [AppColors.lightCoral, AppColors.lightCoralDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final progressAngle = 2 * math.pi * clampedProgress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -math.pi / 2, // Start from top
        progressAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
