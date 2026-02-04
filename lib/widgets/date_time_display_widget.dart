import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/date_time_formatter.dart';

/// Example widget demonstrating date/time formatting
/// This can be used as a reference for implementing date/time display in your app
class DateTimeDisplayWidget extends StatelessWidget {
  final DateTime dateTime;
  final bool showDate;
  final bool showTime;
  final bool useRelativeTime;
  final TextStyle? textStyle;
  
  const DateTimeDisplayWidget({
    super.key,
    required this.dateTime,
    this.showDate = true,
    this.showTime = true,
    this.useRelativeTime = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        String formatted;
        
        if (useRelativeTime) {
          formatted = DateTimeFormatter.formatRelativeTime(dateTime);
        } else if (showDate && showTime) {
          formatted = DateTimeFormatter.formatDateTime(
            dateTime,
            settings.dateFormat,
            settings.timeFormat,
          );
        } else if (showDate) {
          formatted = DateTimeFormatter.formatDate(
            dateTime,
            settings.dateFormat,
          );
        } else if (showTime) {
          formatted = DateTimeFormatter.formatTime(
            dateTime,
            settings.timeFormat,
          );
        } else {
          formatted = '';
        }
        
        return Text(
          formatted,
          style: textStyle,
        );
      },
    );
  }
}

/// Smart date/time display that shows "Today", "Yesterday", or full date
class SmartDateTimeDisplay extends StatelessWidget {
  final DateTime dateTime;
  final bool includeTime;
  final TextStyle? textStyle;
  
  const SmartDateTimeDisplay({
    super.key,
    required this.dateTime,
    this.includeTime = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final formatted = DateTimeFormatter.formatDateTimeShort(
          dateTime,
          settings.dateFormat,
          settings.timeFormat,
          includeTime: includeTime,
        );
        
        return Text(
          formatted,
          style: textStyle,
        );
      },
    );
  }
}
