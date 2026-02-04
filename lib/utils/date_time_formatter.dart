import 'package:intl/intl.dart';
import '../providers/settings_provider.dart';

class DateTimeFormatter {
  static String formatDate(DateTime date, DateFormatType format) {
    switch (format) {
      case DateFormatType.yyyyMMdd:
        return DateFormat('yyyy/MM/dd').format(date);
      case DateFormatType.ddMMyyyy:
        return DateFormat('dd/MM/yyyy').format(date);
      case DateFormatType.ddMonthYyyy:
        return DateFormat('dd MMMM yyyy').format(date);
      case DateFormatType.mmDDyyyy:
        return DateFormat('MM/dd/yyyy').format(date);
      case DateFormatType.monthDDyyyy:
        return DateFormat('MMMM dd, yyyy').format(date);
    }
  }

  static String formatTime(DateTime time, TimeFormatType format) {
    switch (format) {
      case TimeFormatType.format24h:
        return DateFormat('HH:mm').format(time);
      case TimeFormatType.format12h:
        return DateFormat('hh:mm a').format(time);
    }
  }

  static String formatDateTime(
    DateTime dateTime,
    DateFormatType dateFormat,
    TimeFormatType timeFormat,
  ) {
    final date = formatDate(dateTime, dateFormat);
    final time = formatTime(dateTime, timeFormat);
    return '$date $time';
  }

  static String formatDateTimeShort(
    DateTime dateTime,
    DateFormatType dateFormat,
    TimeFormatType timeFormat, {
    bool includeTime = true,
  }) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // If today, show "Today" with time
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      if (includeTime) {
        return 'Today ${formatTime(dateTime, timeFormat)}';
      }
      return 'Today';
    }

    // If yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      if (includeTime) {
        return 'Yesterday ${formatTime(dateTime, timeFormat)}';
      }
      return 'Yesterday';
    }

    // If within last week, show day name
    if (difference.inDays < 7) {
      final dayName = DateFormat('EEEE').format(dateTime);
      if (includeTime) {
        return '$dayName ${formatTime(dateTime, timeFormat)}';
      }
      return dayName;
    }

    // Otherwise show full date
    if (includeTime) {
      return formatDateTime(dateTime, dateFormat, timeFormat);
    }
    return formatDate(dateTime, dateFormat);
  }

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
