// =============================================================================
// export_service.dart — Data Export Service
// 数据导出服务
//
// Exports habit data to external file formats:
// - CSV format (habit summary with streaks and reminders)
// - JSON format (full backup with completion history)
// Saves to Downloads (Android) or Documents (iOS), then shares via
// system share sheet. Uses singleton pattern.
//
// 将习惯数据导出为外部文件格式：
// - CSV 格式（包含连续记录和提醒的习惯摘要）
// - JSON 格式（包含完成历史的完整备份）
// 保存到下载文件夹（Android）或文档文件夹（iOS），然后通过
// 系统分享面板分享。使用单例模式。
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/habit.dart';
import 'firestore_service.dart';
import 'analytics_service.dart';
import 'notification_service.dart';

/// Service for exporting habit data to various formats
class ExportService {
  static final ExportService _instance = ExportService._internal();
  /// Factory constructor returning the singleton instance
  /// 工厂构造函数，返回单例实例
  factory ExportService() => _instance;

  /// Private internal constructor for singleton pattern
  /// 单例模式的私有内部构造函数
  ExportService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  /// Export all habit data to CSV format (saves to Downloads on Android)
  /// 将所有习惯数据导出为 CSV 格式（在 Android 上保存到下载文件夹）
  Future<String?> exportToCSV(List<Habit> habits) async {
    try {
      final buffer = StringBuffer();

      // CSV Header
      buffer.writeln(
        'Habit Name,Category,Streak,Is Completed Today,Last Completed,Reminder Enabled,Reminder Time',
      );

      // Habit data rows
      for (final habit in habits) {
        final reminderTimeStr = habit.reminderTime != null
            ? '${habit.reminderTime!.hour.toString().padLeft(2, '0')}:${habit.reminderTime!.minute.toString().padLeft(2, '0')}'
            : '';
        final lastCompletedStr =
            habit.lastCompletedDate?.toIso8601String() ?? '';

        buffer.writeln(
          '${_escapeCSV(habit.name)},'
          '${habit.category.name},'
          '${habit.streak},'
          '${habit.isCompleted},'
          '$lastCompletedStr,'
          '${habit.reminderEnabled},'
          '$reminderTimeStr',
        );
      }

      // Try to save to Downloads folder (Android) or Documents (iOS)
      Directory directory;
      if (Platform.isAndroid) {
        // Try external storage first, fall back to app documents
        final externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null && externalDirs.isNotEmpty) {
          // Navigate to Download folder from external storage path
          final pathParts = externalDirs.first.path.split('Android');
          if (pathParts.length > 1) {
            final basePath = pathParts[0];
            final downloadDir = Directory('${basePath}Download');
            if (await downloadDir.exists()) {
              directory = downloadDir;
            } else {
              directory = await getApplicationDocumentsDirectory();
            }
          } else {
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'aura_habits_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      // Verify file was written successfully
      if (!await file.exists()) {
        debugPrint('Error: CSV file was not created at ${file.path}');
        return null;
      }
      final writtenLength = await file.length();
      if (writtenLength == 0) {
        debugPrint('Error: CSV file is empty at ${file.path}');
        return null;
      }

      debugPrint('Exported ${habits.length} habits to CSV: ${file.path} ($writtenLength bytes)');
      return file.path;
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      return null;
    }
  }

  /// Export all habit data to JSON format (full backup)
  /// 将所有习惯数据导出为 JSON 格式（完整备份）
  Future<String?> exportToJSON(List<Habit> habits) async {
    try {
      // Fetch all histories in parallel (fixes N+1 query pattern)
      final historyFutures = habits.map((h) => _firestoreService.getHabitHistory(h.id)).toList();
      final allHistories = await Future.wait(historyFutures);

      // Build habits with history
      final List<Map<String, dynamic>> habitsData = [];

      for (int i = 0; i < habits.length; i++) {
        final habit = habits[i];
        final history = allHistories[i];

        habitsData.add({
          'id': habit.id,
          'name': habit.name,
          'category': habit.category.name,
          'streak': habit.streak,
          'isCompleted': habit.isCompleted,
          'lastCompletedDate': habit.lastCompletedDate?.toIso8601String(),
          'reminderEnabled': habit.reminderEnabled,
          'reminderTime': habit.reminderTime != null
              ? {
                  'hour': habit.reminderTime!.hour,
                  'minute': habit.reminderTime!.minute,
                }
              : null,
          'history': history.map((d) => d.toIso8601String()).toList(),
        });
      }

      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'appName': 'Aura Habit Tracker',
        'version': '1.0.0',
        'habitsCount': habits.length,
        'habits': habitsData,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Try to save to Downloads folder (Android) or Documents (iOS)
      Directory directory;
      if (Platform.isAndroid) {
        // Try external storage first, fall back to app documents
        final externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null && externalDirs.isNotEmpty) {
          // Navigate to Download folder from external storage path
          final pathParts = externalDirs.first.path.split('Android');
          if (pathParts.length > 1) {
            final basePath = pathParts[0];
            final downloadDir = Directory('${basePath}Download');
            if (await downloadDir.exists()) {
              directory = downloadDir;
            } else {
              directory = await getApplicationDocumentsDirectory();
            }
          } else {
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'aura_habits_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // Verify file was written successfully
      if (!await file.exists()) {
        debugPrint('Error: JSON file was not created at ${file.path}');
        return null;
      }
      final writtenLength = await file.length();
      if (writtenLength == 0) {
        debugPrint('Error: JSON file is empty at ${file.path}');
        return null;
      }

      debugPrint('Exported ${habits.length} habits to JSON: ${file.path} ($writtenLength bytes)');
      return file.path;
    } catch (e) {
      debugPrint('Error exporting to JSON: $e');
      return null;
    }
  }

  /// Share exported file using system share sheet
  /// 使用系统分享面板分享导出的文件
  Future<void> shareFile(String filePath, {String? subject}) async {
    try {
      final file = XFile(filePath);
      await SharePlus.instance.share(
        ShareParams(files: [file], subject: subject ?? 'Habit Tracker Export'),
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }

  /// Export and immediately share as CSV
  /// 导出并立即分享 CSV 文件
  Future<void> exportAndShareCSV(List<Habit> habits) async {
    final filePath = await exportToCSV(habits);
    if (filePath != null) {
      // Show download notification
      await NotificationService().show(
        title: 'Export Complete',
        body: 'aura_habits.csv saved to Downloads',
        payload: filePath,
      );
      await shareFile(filePath, subject: 'My Habits - CSV Export');
      await AnalyticsService().logDataExported(
        format: 'csv',
        habitCount: habits.length,
      );
    }
  }

  /// Export and immediately share as JSON
  /// 导出并立即分享 JSON 文件
  Future<void> exportAndShareJSON(List<Habit> habits) async {
    final filePath = await exportToJSON(habits);
    if (filePath != null) {
      // Show download notification
      await NotificationService().show(
        title: 'Export Complete',
        body: 'aura_habits_backup.json saved to Downloads',
        payload: filePath,
      );
      await shareFile(filePath, subject: 'My Habits - Full Backup');
      await AnalyticsService().logDataExported(
        format: 'json',
        habitCount: habits.length,
      );
    }
  }

  /// Escape special characters for CSV
  /// 转义 CSV 中的特殊字符
  /// Handles double quotes, newlines, and commas
  /// 处理双引号、换行符和逗号
  String _escapeCSV(String value) {
    // Replace double quotes with escaped double quotes
    var escaped = value.replaceAll('"', '""');
    // If value contains special characters, wrap in quotes
    if (escaped.contains(',') || escaped.contains('\n') || escaped.contains('\r') || escaped.contains('"')) {
      escaped = '"$escaped"';
    }
    return escaped;
  }
}
