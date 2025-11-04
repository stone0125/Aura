import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

/// Motivational Quote Card widget
class MotivationalQuoteCard extends StatelessWidget {
  const MotivationalQuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quote = _getRandomQuote();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkCoral, AppColors.darkCoralDeep]
              : [AppColors.lightCoral, AppColors.lightCoralLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Quote Icon
            Positioned(
              top: 0,
              left: 0,
              child: Icon(
                Icons.format_quote_rounded,
                color: isDark
                    ? AppColors.darkPrimaryText.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),

            // Quote Text (Centered)
            Center(
              child: Text(
                quote,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? AppColors.darkPrimaryText : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),

            // Author/Source (Optional)
            Positioned(
              bottom: 0,
              right: 0,
              child: Text(
                '— AI Coach',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get random daily quote
  String _getRandomQuote() {
    final quotes = [
      'Small steps every day lead to big changes',
      'Progress, not perfection',
      'Your only limit is you',
      'Make today count',
      'One habit at a time',
      'Consistency is key to success',
      'Believe in yourself and all that you are',
      'Every day is a fresh start',
    ];

    // Use date as seed for consistent daily quote
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    return quotes[seed % quotes.length];
  }
}
