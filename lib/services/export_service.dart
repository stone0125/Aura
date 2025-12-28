import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/habit.dart';
import 'firestore_service.dart';
import 'analytics_service.dart';

/// Service for exporting habit data to various formats
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  /// Export all habit data to CSV format
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
          '"${_escapeCSV(habit.name)}",'
          '${habit.category.name},'
          '${habit.streak},'
          '${habit.isCompleted},'
          '$lastCompletedStr,'
          '${habit.reminderEnabled},'
          '$reminderTimeStr',
        );
      }

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/habits_export_$timestamp.csv');
      await file.writeAsString(buffer.toString());

      debugPrint('Exported ${habits.length} habits to CSV: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      return null;
    }
  }

  /// Export all habit data to JSON format (full backup)
  Future<String?> exportToJSON(List<Habit> habits) async {
    try {
      // Build habits with history
      final List<Map<String, dynamic>> habitsData = [];

      for (final habit in habits) {
        // Fetch history for each habit
        final history = await _firestoreService.getHabitHistory(habit.id);

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

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/habits_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      debugPrint('Exported ${habits.length} habits to JSON: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error exporting to JSON: $e');
      return null;
    }
  }

  /// Share exported file using system share sheet
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
  Future<void> exportAndShareCSV(List<Habit> habits) async {
    final filePath = await exportToCSV(habits);
    if (filePath != null) {
      await shareFile(filePath, subject: 'My Habits - CSV Export');
      await AnalyticsService().logDataExported(
        format: 'csv',
        habitCount: habits.length,
      );
    }
  }

  /// Export and immediately share as JSON
  Future<void> exportAndShareJSON(List<Habit> habits) async {
    final filePath = await exportToJSON(habits);
    if (filePath != null) {
      await shareFile(filePath, subject: 'My Habits - Full Backup');
      await AnalyticsService().logDataExported(
        format: 'json',
        habitCount: habits.length,
      );
    }
  }

  /// Escape special characters for CSV
  String _escapeCSV(String value) {
    return value.replaceAll('"', '""');
  }
}
