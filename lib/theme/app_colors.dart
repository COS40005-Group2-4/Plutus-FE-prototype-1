import 'package:flutter/material.dart';

/// Semantic color tokens for the Plutus app.
///
/// BudgetFlow-style palette: clean, friendly fintech.
/// Emerald-teal primary, neutral surfaces, restrained accents.
class AppColors {
  AppColors._();

  // ── Brand ──
  static const primary = Color(0xFF0E9F8A);          // emerald-teal (light)
  static const primaryDark = Color(0xFF34D2B5);      // emerald-teal (dark)
  static const accent = Color(0xFF6366F1);           // indigo accent

  // ── Neutral surfaces (light) ──
  // Background is intentionally a touch cooler than the white card surfaces
  // so foreground components pop without needing heavy borders or shadows.
  static const backgroundLight = Color(0xFFF2F4F7);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceMutedLight = Color(0xFFEDEFF3);
  static const surfaceElevatedLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE2E5EA);
  static const dividerLight = Color(0xFFE9ECF1);

  // ── Neutral surfaces (dark) ──
  static const backgroundDark = Color(0xFF0B0F12);
  static const surfaceDark = Color(0xFF141A1F);
  static const surfaceMidDark = Color(0xFF1A2128);
  static const surfaceElevatedDark = Color(0xFF1F2730);
  static const borderDark = Color(0xFF26303A);
  static const dividerDark = Color(0xFF1F2730);

  // ── Legacy aliases (kept for backwards compatibility) ──
  // ignore: deprecated_member_use_from_same_package
  static const backgroundLightStart = backgroundLight;
  // ignore: deprecated_member_use_from_same_package
  static const backgroundLightEnd = backgroundLight;
  static const menuBackground = surfaceDark;

  // ── Text (light) ──
  static const textOnLight = Color(0xFF0F1419);
  static const textOnLightSecondary = Color(0xFF5A6470);
  static const textOnLightTertiary = Color(0xFF8A94A0);

  // ── Text (dark) ──
  static const textOnDark = Color(0xFFF4F6F8);
  static const textOnDarkSecondary = Color(0xFFAEB6C0);
  static const textOnDarkTertiary = Color(0xFF7A8390);

  // ── Semantic ──
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF10A66B);
  static const warning = Color(0xFFD97706);
  static const info = Color(0xFF2563EB);

  // ── Chart palette (calmer, modern) ──
  static const List<Color> chartPalette = [
    Color(0xFF0E9F8A), // teal
    Color(0xFF6366F1), // indigo
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFF10A66B), // green
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFFF97316), // orange
    Color(0xFFEF4444), // red
    Color(0xFF14B8A6), // light teal
  ];

  // ── Widget accent colors (sidebar registry) ──
  static const profileAccent = Color(0xFF8B5CF6);
  static const budgetAccent = Color(0xFF0E9F8A);
  static const categoryBudgetAccent = Color(0xFF14B8A6);
  static const historyAccent = Color(0xFF10A66B);
  static const cashflowAccent = Color(0xFF6366F1);
  static const expenseAccent = Color(0xFFEC4899);
  static const incomeAccent = Color(0xFF10A66B);
  static const savingsAccent = Color(0xFFF59E0B);
  static const netWorthAccent = Color(0xFF06B6D4);
  static const heatmapAccent = Color(0xFF14B8A6);
  static const marketAccent = Color(0xFF0E9F8A);
  static const billsAccent = Color(0xFFEF4444);
  static const taxAccent = Color(0xFF475569);
  static const importAccent = Color(0xFFF59E0B);
  static const exportAccent = Color(0xFFEF4444);

  // ── Adaptive accessors ──
  static Color background(Brightness b) =>
      b == Brightness.dark ? backgroundDark : backgroundLight;

  static Color surface(Brightness b) =>
      b == Brightness.dark ? surfaceDark : surfaceLight;

  static Color surfaceMuted(Brightness b) =>
      b == Brightness.dark ? surfaceMidDark : surfaceMutedLight;

  static Color surfaceElevated(Brightness b) =>
      b == Brightness.dark ? surfaceElevatedDark : surfaceElevatedLight;

  static Color border(Brightness b) =>
      b == Brightness.dark ? borderDark : borderLight;

  static Color divider(Brightness b) =>
      b == Brightness.dark ? dividerDark : dividerLight;

  static Color textPrimary(Brightness b) =>
      b == Brightness.dark ? textOnDark : textOnLight;

  static Color textSecondary(Brightness b) =>
      b == Brightness.dark ? textOnDarkSecondary : textOnLightSecondary;

  static Color textTertiary(Brightness b) =>
      b == Brightness.dark ? textOnDarkTertiary : textOnLightTertiary;

  static Color brand(Brightness b) =>
      b == Brightness.dark ? primaryDark : primary;

  static Color gridLine(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.05);

  static Color borderLine(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.08);

  // ── Theme-adaptive semantic colors for data display ──
  static const _positiveLight = Color(0xFF10A66B);
  static const _positiveDark = Color(0xFF34D399);
  static const _negativeLight = Color(0xFFDC2626);
  static const _negativeDark = Color(0xFFF87171);

  static Color positive(Brightness b) =>
      b == Brightness.dark ? _positiveDark : _positiveLight;

  static Color negative(Brightness b) =>
      b == Brightness.dark ? _negativeDark : _negativeLight;
}
