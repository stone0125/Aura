// =============================================================================
// date_utils.dart — Date Utility Functions
// 日期工具函数
//
// Helper functions for date formatting and comparison:
// - formatDateId() — ISO 8601 format (YYYY-MM-DD)
// - formatDateFull() — "Monday, January 15"
// - formatDateShort() — "Jan 15"
// - isSameDay(), isToday(), isYesterday()
// - getStartOfWeek(), getEndOfWeek()
//
// 日期格式化和比较的辅助函数：
// - formatDateId() — ISO 8601 格式（YYYY-MM-DD）
// - formatDateFull() — "星期一，1月15日"
// - formatDateShort() — "1月15日"
// - isSameDay()、isToday()、isYesterday()
// - getStartOfWeek()、getEndOfWeek()
// =============================================================================

/// Date utility functions for the habit tracker app
/// Centralizes date formatting and comparison logic to reduce duplication
library;

/// Formats a DateTime as YYYY-MM-DD (ISO 8601 date format)
/// Used for Firestore document IDs and consistent date storage
String formatDateId(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Formats a DateTime as a human-readable date
/// Example: "Monday, January 15"
String formatDateFull(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  return '$weekday, $month ${date.day}';
}

/// Formats a DateTime as a short date
/// Example: "Jan 15"
String formatDateShort(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

/// Gets the month name from a month number (1-12)
String getMonthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

/// Gets the short month name from a month number (1-12)
String getMonthNameShort(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

/// Gets the weekday name from a weekday number (1=Monday, 7=Sunday)
String getWeekdayName(int weekday) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  if (weekday < 1 || weekday > 7) return '';
  return weekdays[weekday - 1];
}

/// Gets the short weekday name from a weekday number (1=Monday, 7=Sunday)
String getWeekdayNameShort(int weekday) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  if (weekday < 1 || weekday > 7) return '';
  return weekdays[weekday - 1];
}

/// Gets the single-letter weekday initial from a weekday number (1=Monday, 7=Sunday)
String getWeekdayInitial(int weekday) {
  const initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  if (weekday < 1 || weekday > 7) return '';
  return initials[weekday - 1];
}

/// Checks if two dates represent the same day (ignores time)
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Checks if the given date is today
bool isToday(DateTime date) {
  final now = DateTime.now();
  return isSameDay(date, now);
}

/// Checks if the given date is yesterday
bool isYesterday(DateTime date) {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return isSameDay(date, yesterday);
}

/// Returns a normalized DateTime with only year, month, day (time set to 00:00:00)
DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Gets the start of the current week (Monday)
DateTime getStartOfWeek([DateTime? date]) {
  final d = date ?? DateTime.now();
  return DateTime(d.year, d.month, d.day - (d.weekday - 1));
}

/// Gets the end of the current week (Sunday)
DateTime getEndOfWeek([DateTime? date]) {
  final d = date ?? DateTime.now();
  return DateTime(d.year, d.month, d.day + (7 - d.weekday));
}

/// Formats a date for display in charts (e.g., "15/1")
String formatDateForChart(DateTime date) {
  return '${date.day}/${date.month}';
}

/// Formats time as HH:MM (24-hour format with zero padding)
String formatTime24h(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Formats time from DateTime as HH:MM
String formatTimeFromDate(DateTime date) {
  return formatTime24h(date.hour, date.minute);
}
