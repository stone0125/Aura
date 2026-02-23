import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/progress_models.dart';
import 'analytics_service.dart';

/// Service for sharing achievements and progress
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  final _share = SharePlus.instance;

  /// Share a text summary of progress stats
  Future<void> shareProgressSummary({
    required int daysTracked,
    required int bestStreak,
    required int totalHabits,
    required double completionRate,
  }) async {
    final text =
        '''
🏆 My Habit Tracking Progress

📅 Days Tracked: $daysTracked
🔥 Best Streak: $bestStreak days
📊 Total Habits: $totalHabits
✅ Completion Rate: ${(completionRate * 100).toStringAsFixed(1)}%

Tracked with Aura Habit Tracker 💜
''';

    await _share.share(
      ShareParams(text: text, subject: 'My Habit Tracking Progress'),
    );
    await AnalyticsService().logProgressShared();
  }

  /// Share an achievement as text
  Future<void> shareAchievement(Achievement achievement) async {
    final statusEmoji = achievement.isUnlocked ? '🏆' : '🎯';
    final progressPercent = achievement.progress * 100;

    final text =
        '''
$statusEmoji Achievement ${achievement.isUnlocked ? 'Unlocked!' : 'In Progress'}

${achievement.name}
${achievement.description}

Progress: ${progressPercent.toStringAsFixed(0)}% (${achievement.currentValue}/${achievement.targetValue})

Tracked with Aura Habit Tracker 💜
''';

    await _share.share(
      ShareParams(text: text, subject: 'Achievement: ${achievement.name}'),
    );
    await AnalyticsService().logAchievementShared(
      achievementId: achievement.id,
      isUnlocked: achievement.isUnlocked,
    );
  }

  /// Copy stats to clipboard
  Future<void> copyStatsToClipboard({
    required int daysTracked,
    required int bestStreak,
    required int totalHabits,
    required double completionRate,
  }) async {
    final text =
        '''
📅 $daysTracked days tracked
🔥 $bestStreak day streak
📊 $totalHabits habits
✅ ${(completionRate * 100).toStringAsFixed(1)}% completion rate
''';

    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Share streak milestone
  Future<void> shareStreakMilestone({
    required String habitName,
    required int streakDays,
  }) async {
    String milestone = '';
    if (streakDays >= 90) {
      milestone = '🏆 90 DAY LEGEND!';
    } else if (streakDays >= 60) {
      milestone = '💎 60 DAY DIAMOND!';
    } else if (streakDays >= 30) {
      milestone = '🥇 30 DAY MASTER!';
    } else if (streakDays >= 21) {
      milestone = '🌟 21 DAY CHAMPION!';
    } else if (streakDays >= 14) {
      milestone = '🔥 14 DAY WARRIOR!';
    } else if (streakDays >= 7) {
      milestone = '⭐ 7 DAY STREAK!';
    } else {
      milestone = '✨ $streakDays Day Streak!';
    }

    final text =
        '''
$milestone

I've maintained my "$habitName" habit for $streakDays days straight! 💪

Tracked with Aura Habit Tracker 💜
''';

    await _share.share(ShareParams(text: text, subject: milestone));
  }

  /// Share multiple achievements summary
  Future<void> shareAchievementsSummary(List<Achievement> achievements) async {
    final unlocked = achievements.where((a) => a.isUnlocked).toList();
    final total = achievements.length;

    final achievementList = unlocked.map((a) => '✅ ${a.name}').join('\n');

    final text =
        '''
🏆 My Achievements (${unlocked.length}/$total)

$achievementList

Tracked with Aura Habit Tracker 💜
''';

    await _share.share(
      ShareParams(text: text, subject: 'My Habit Achievements'),
    );
  }

  /// Share a file (e.g. CSV export)
  Future<void> shareFile(String path, String subject) async {
    // Verify file exists before attempting to share
    if (!File(path).existsSync()) {
      debugPrint('ShareService: File does not exist at path: $path');
      return;
    }
    await _share.share(ShareParams(files: [XFile(path)], subject: subject));
  }
}
