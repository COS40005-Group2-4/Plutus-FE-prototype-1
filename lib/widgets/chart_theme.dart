import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/plutus_tokens.dart';

PlutusTokens _tokensFor(Brightness b) =>
    b == Brightness.dark ? PlutusTokens.dark : PlutusTokens.light;

class PlutusChartStyle {
  static FlGridData defaultGridData({double? maxValue, required Brightness brightness}) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: maxValue != null && maxValue > 0 ? maxValue / 4 : 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: _tokensFor(brightness).border,
          strokeWidth: 1,
        );
      },
    );
  }

  static FlBorderData defaultBorderData() {
    return FlBorderData(show: false);
  }

  static FlBorderData lineBorderData({required Brightness brightness}) {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: _tokensFor(brightness).border, width: 1),
        left: BorderSide(color: _tokensFor(brightness).border, width: 1),
      ),
    );
  }

  static AxisTitles hiddenAxisTitles() {
    return const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    );
  }

  static String formatCompactCurrency(double value) {
    if (value.abs() >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}B';
    } else if (value.abs() >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  static const List<String> _monthAbbreviations = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Returns a short axis label for a YYYY-MM key.
  /// The first label in a series (prevYYYYMM == null) or any label where the
  /// year differs from the previous label gets a year suffix: "Jan '24".
  /// All other labels return only the 3-letter month abbreviation: "Feb".
  static String monthAxisLabel(String yyyyMM, String? prevYYYYMM) {
    final parts = yyyyMM.split('-');
    final year = parts[0];
    final monthIndex = int.parse(parts[1]) - 1;
    final abbr = _monthAbbreviations[monthIndex];
    if (prevYYYYMM == null || prevYYYYMM.split('-')[0] != year) {
      return "$abbr '${year.substring(2)}";
    }
    return abbr;
  }
}
