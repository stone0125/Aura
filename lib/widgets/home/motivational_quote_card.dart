import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

/// Motivational Quote Card widget
/// 励志名言卡片组件
class MotivationalQuoteCard extends StatefulWidget {
  /// Creates a motivational quote card widget
  /// 创建励志名言卡片组件
  const MotivationalQuoteCard({super.key});

  /// Creates the mutable state for this widget
  /// 创建此组件的可变状态
  @override
  State<MotivationalQuoteCard> createState() => _MotivationalQuoteCardState();
}

/// State for the motivational quote card, manages quote selection
/// 励志名言卡片的状态，管理名言选择
class _MotivationalQuoteCardState extends State<MotivationalQuoteCard> {
  late String _quote;

  final List<String> _quotes = [
    'Small steps every day lead to big changes',
    'Progress, not perfection',
    'Your only limit is you',
    'Make today count',
    'One habit at a time',
    'Consistency is key to success',
    'Believe in yourself',
    'Every day is a fresh start',
    'Discipline is choosing between what you want now and what you want most',
    'Success is the sum of small efforts repeated day in and day out',
    'Don’t watch the clock; do what it does. Keep going',
    'The secret of your future is hidden in your daily routine',
    'You don’t have to be great to start, but you have to start to be great',
    'Motivation is what gets you started. Habit is what keeps you going',
    'What you do today can improve all your tomorrows',
    'Excellence is not an act, but a habit',
  ];

  /// Initializes the state with a date-seeded random quote
  /// 使用基于日期的种子初始化随机名言
  @override
  void initState() {
    super.initState();
    _quote = _getRandomQuote();
  }

  final _random = Random();

  /// Shuffles to a different random quote, avoiding repeats when possible
  /// 随机切换到另一条名言，尽量避免重复
  void _shuffleQuote() {
    setState(() {
      final current = _quote;
      // Use dart:math Random for proper randomness
      var next = _quotes[_random.nextInt(_quotes.length)];
      if (_quotes.length > 1) {
        int attempts = 0;
        while (next == current && attempts < 3) {
          next = _quotes[_random.nextInt(_quotes.length)];
          attempts++;
        }
      }
      _quote = next;
    });
  }

  /// Get random daily quote seeded by date (initial state)
  /// 获取基于日期种子的每日随机名言（初始状态）
  String _getRandomQuote() {
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    return _quotes[seed % _quotes.length];
  }

  /// Builds the motivational quote card with gradient styling and tap-to-shuffle
  /// 构建励志名言卡片，带渐变样式和点击切换功能
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium accent gradient
    final accentGradient = LinearGradient(
      colors: isDark
          ? [
              const Color(0xFFFF8A80),
              const Color(0xFFB388FF),
            ] // Coral to Purple
          : [const Color(0xFFFF6B6B), const Color(0xFF9B59B6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        // Slightly darker/warmer background for better contrast (Reverted to Step 1028)
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E1E2E), // Darker surface
                  const Color(0xFF252538),
                ]
              : [
                  const Color(0xFFF0F4F8), // Cool light grey/blue
                  const Color(0xFFFFEBF0), // Warm light pink
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? AppColors.darkCoral : AppColors.lightCoral)
              .withValues(alpha: 0.2), // Slightly more visible border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.lightCoral).withValues(
              alpha: isDark ? 0.3 : 0.08,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _shuffleQuote,
          borderRadius: BorderRadius.circular(24),
          splashColor: (isDark ? AppColors.darkCoral : AppColors.lightCoral)
              .withValues(alpha: 0.1),
          highlightColor: (isDark ? AppColors.darkCoral : AppColors.lightCoral)
              .withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // 1. "Daily Wisdom" Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: accentGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isDark
                                    ? const Color(0xFFFF8A80)
                                    : const Color(0xFFFF6B6B))
                                .withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'DAILY WISDOM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 24), // Increased spacing

                Stack(
                  children: [
                    // Opening Quote (Gradient)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            accentGradient.createShader(bounds),
                        child: const Text(
                          '“',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            height: 1,
                            fontFamily: 'serif',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Closing Quote (Gradient)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            accentGradient.createShader(bounds),
                        child: const Text(
                          '”',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            height: 1,
                            fontFamily: 'serif',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Quote Text
                    Padding(
                      padding: const EdgeInsets.fromLTRB(36, 28, 36, 12),
                      child: Text(
                        _quote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          fontFamily: 'serif',
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20), // Increased spacing
                // Author (AI Coach) - More detailed and prominent
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.darkCoral
                                    : AppColors.lightCoral)
                                .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: isDark
                            ? AppColors.darkCoral
                            : AppColors.lightCoral,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Curated by AI Coach',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
