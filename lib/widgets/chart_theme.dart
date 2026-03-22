import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PlutusChartColors {
  static const List<Color> palette = [
    Color(0xFF4285F4), // Blue
    Color(0xFF34A853), // Green
    Color(0xFFEA4335), // Red
    Color(0xFFFBBC05), // Yellow
    Color(0xFF5DADE2), // Light Blue
    Color(0xFFAF7AC5), // Purple
    Color(0xFF48C9B0), // Teal
    Color(0xFFF39C12), // Orange
    Color(0xFFE74C3C), // Dark Red
    Color(0xFF1ABC9C), // Cyan
  ];

  static Color get(int index) => palette[index % palette.length];
}

class PlutusChartStyle {
  static FlGridData defaultGridData({double? maxValue}) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: maxValue != null && maxValue > 0 ? maxValue / 4 : 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.white.withOpacity(0.1),
          strokeWidth: 1,
        );
      },
    );
  }

  static FlBorderData defaultBorderData() {
    return FlBorderData(show: false);
  }

  static FlBorderData lineBorderData() {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        left: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
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
}
