/// Date format utilities for Go backend interop.
///
/// The Go backend uses "DD-MM-YYYY" for exact dates.
/// Flutter uses DateTime objects and Unix timestamps.
library;

/// Converts DateTime to "DD-MM-YYYY" string for Go backend.
String toCustomDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day-$month-$year';
}
