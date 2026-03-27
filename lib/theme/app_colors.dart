import 'package:flutter/material.dart';

/// Semantic color tokens for the Plutus app.
/// All hardcoded hex values should reference this class.
class AppColors {
  AppColors._();

  // ── Brand ──
  static const primary = Color(0xFF4285F4);
  static const primaryDark = Color(0xFF4A90E2);
  static const accent = Color(0xFF5DADE2);

  // ── Surfaces (dark mode) ──
  static const surfaceDark = Color(0xFF1A3A4A);
  static const backgroundDark = Color(0xFF0A1828);
  static const surfaceMidDark = Color(0xFF132D3F);
  static const surfaceElevatedDark = Color(0xFF1E4A5F);
  static const borderDark = Color(0xFF2A5470);

  // ── Surfaces (light mode) ──
  static const surfaceLight = Color(0xFFF5F0FF);
  static const backgroundLightStart = Color(0xFFE0C3FC);
  static const backgroundLightEnd = Color(0xFF8EC5FC);

  // ── Menu / Overlay ──
  static const menuBackground = Color(0xFF2C3E50);

  // ── Text ──
  static const textOnDark = Colors.white;
  static const textOnDarkSecondary = Colors.white70;
  static const textOnDarkTertiary = Colors.white54;
  static const textOnLight = Color(0xFF1A1A2E);
  static const textOnLightSecondary = Color(0xFF4A4A6A);
  static const textOnLightTertiary = Color(0xFF7A7A9A);

  // ── Semantic ──
  static const error = Color(0xFFEA4335);
  static const success = Color(0xFF34A853);
  static const warning = Color(0xFFFBBC05);

  // ── Chart palette ──
  static const List<Color> chartPalette = [
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

  // ── Widget accent colors (sidebar registry) ──
  static const profileAccent = Color(0xFFAB47BC);
  static const budgetAccent = Color(0xFF4285F4);
  static const categoryBudgetAccent = Color(0xFF00897B);
  static const historyAccent = Color(0xFF34A853);
  static const cashflowAccent = Color(0xFF1E88E5);
  static const expenseAccent = Color(0xFFAF7AC5);
  static const incomeAccent = Color(0xFF43A047);
  static const savingsAccent = Color(0xFFF39C12);
  static const netWorthAccent = Color(0xFF1ABC9C);
  static const heatmapAccent = Color(0xFF48C9B0);
  static const marketAccent = Color(0xFF26A69A);
  static const billsAccent = Color(0xFFEA4335);
  static const taxAccent = Color(0xFF2A5470);
  static const importAccent = Color(0xFFFBBC05);
  static const exportAccent = Color(0xFFEA4335);

  /// Returns the correct text color for the current brightness.
  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? textOnDark : textOnLight;

  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? textOnDarkSecondary : textOnLightSecondary;

  static Color textTertiary(Brightness brightness) =>
      brightness == Brightness.dark ? textOnDarkTertiary : textOnLightTertiary;

  /// Grid/border line color that adapts to theme.
  static Color gridLine(Brightness brightness) =>
      brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1);

  static Color borderLine(Brightness brightness) =>
      brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.15);

  // ── Theme-adaptive semantic colors for data display ──
  // Light mode uses darker shades to ensure contrast on glass backgrounds.

  static const _positiveLight = Color(0xFF1B7A2B); // dark green, 4.5:1+ on light glass
  static const _positiveDark = Color(0xFF4CAF50);   // standard green, readable on dark

  static const _negativeLight = Color(0xFFC62828);  // dark red, 4.5:1+ on light glass
  static const _negativeDark = Color(0xFFEF5350);   // standard red, readable on dark

  /// Green for income / positive values — adapts to theme.
  static Color positive(Brightness brightness) =>
      brightness == Brightness.dark ? _positiveDark : _positiveLight;

  /// Red for expense / negative values — adapts to theme.
  static Color negative(Brightness brightness) =>
      brightness == Brightness.dark ? _negativeDark : _negativeLight;
}
