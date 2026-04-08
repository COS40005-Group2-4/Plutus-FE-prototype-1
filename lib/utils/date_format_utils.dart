/// Date format utilities for Go backend interop.
///
/// The Go backend uses "DD-MM-YYYY" for exact dates and "MM-YYYY" for monthly periods.
/// Flutter uses DateTime objects and Unix timestamps.

/// Converts DateTime to "DD-MM-YYYY" string for Go backend.
String toCustomDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day-$month-$year';
}

/// Converts DateTime to "MM-YYYY" string for Go backend.
String toMonthlyDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$month-$year';
}

/// Parses "DD-MM-YYYY" string from Go backend to DateTime.
DateTime parseCustomDate(String date) {
  final parts = date.split('-');
  final day = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final year = int.parse(parts[2]);
  return DateTime(year, month, day);
}

/// Parses "MM-YYYY" string from Go backend to DateTime.
DateTime parseMonthlyDate(String date) {
  final parts = date.split('-');
  final month = int.parse(parts[0]);
  final year = int.parse(parts[1]);
  return DateTime(year, month);
}
