import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';

class PlutusChartColors {
  static const List<Color> palette = AppColors.chartPalette;

  static Color get(int index) => palette[index % palette.length];
}

class PlutusChartStyle {
  static FlGridData defaultGridData({double? maxValue, required Brightness brightness}) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: maxValue != null && maxValue > 0 ? maxValue / 4 : 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: AppColors.gridLine(brightness),
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
        bottom: BorderSide(color: AppColors.borderLine(brightness), width: 1),
        left: BorderSide(color: AppColors.borderLine(brightness), width: 1),
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
