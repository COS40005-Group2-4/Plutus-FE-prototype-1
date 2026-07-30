import 'package:flutter/material.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'plutus_tokens.dart';

/// Builds light/dark [ThemeData] from the design tokens.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final PlutusTokens t = isDark ? PlutusTokens.dark : PlutusTokens.light;
    final Color textPrimary = t.text;
    final Color textSecondary = t.textSecondary;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: t.gold,
      onPrimary: t.onGold,
      secondary: t.brandNavy,
      onSecondary: isDark ? t.bg : Colors.white,
      surface: t.surface,
      onSurface: t.text,
      error: t.error.dot,
      onError: Colors.white,
      outline: t.borderStrong,
      outlineVariant: t.border,
      surfaceContainerHighest: t.surfaceSubtle,
      shadow: Colors.black,
    );

    final TextTheme textTheme = TextTheme(
      displayLarge: AppTextStyles.displayLargeStyle.copyWith(color: textPrimary),
      displayMedium: AppTextStyles.displayMediumStyle.copyWith(color: textPrimary),
      displaySmall: AppTextStyles.displaySmallStyle.copyWith(color: textPrimary),
      headlineLarge: AppTextStyles.headlineLargeStyle.copyWith(color: textPrimary),
      headlineMedium: AppTextStyles.headlineMediumStyle.copyWith(color: textPrimary),
      headlineSmall: AppTextStyles.headlineSmallStyle.copyWith(color: textPrimary),
      titleLarge: AppTextStyles.titleLargeStyle.copyWith(color: textPrimary),
      titleMedium: AppTextStyles.titleMediumStyle.copyWith(color: textPrimary),
      titleSmall: AppTextStyles.titleSmallStyle.copyWith(color: textPrimary),
      bodyLarge: AppTextStyles.bodyLargeStyle.copyWith(color: textPrimary),
      bodyMedium: AppTextStyles.bodyMediumStyle.copyWith(color: textPrimary),
      bodySmall: AppTextStyles.bodySmallStyle.copyWith(color: textSecondary),
      labelLarge: AppTextStyles.labelLargeStyle.copyWith(color: textPrimary),
      labelMedium: AppTextStyles.labelMediumStyle.copyWith(color: textPrimary),
      labelSmall: AppTextStyles.labelSmallStyle.copyWith(color: textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[t],
      // Scaffold is transparent because AppCanvas (in main.dart's
      // MaterialApp.builder) paints the base background and a soft accent wash.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: t.bg,
      dividerColor: t.border,
      textTheme: textTheme,
      fontFamily: AppTextStyles.fontFamily,
      iconTheme: IconThemeData(color: t.text, size: 22),
      primaryIconTheme: IconThemeData(color: t.text, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: t.text,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: t.border,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: AppTextStyles.headingStyle.copyWith(color: t.text),
        iconTheme: IconThemeData(color: t.text, size: 24),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderCard,
          side: BorderSide(color: t.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSurface),
        titleTextStyle: AppTextStyles.titleStyle.copyWith(color: t.text),
        contentTextStyle: AppTextStyles.bodyStyle.copyWith(color: t.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: t.goldWeak,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            AppTextStyles.labelStyle.copyWith(
                color: s.contains(WidgetState.selected)
                    ? t.text
                    : t.textSecondary)),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            IconThemeData(
                color: s.contains(WidgetState.selected)
                    ? t.text
                    : t.textSecondary)),
      ),
      // Primary CTA: gold fill + navy ink (spec §5). 44px, radius 12.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.disabled)) return t.surfaceSubtle;
            if (s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered)) {
              return t.goldHover;
            }
            return t.gold;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.disabled) ? t.textMuted : t.onGold),
          textStyle: WidgetStatePropertyAll<TextStyle>(
              AppTextStyles.bodyStrongStyle),
          minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 44)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: AppSpacing.componentXxl)),
          shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button))),
          elevation: const WidgetStatePropertyAll<double>(0),
        ),
      ),
      // ElevatedButton mirrors FilledButton so legacy call-sites match.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.disabled)) return t.surfaceSubtle;
            if (s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered)) {
              return t.goldHover;
            }
            return t.gold;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.disabled) ? t.textMuted : t.onGold),
          textStyle: WidgetStatePropertyAll<TextStyle>(
              AppTextStyles.bodyStrongStyle),
          minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 44)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: AppSpacing.componentXxl)),
          shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button))),
          elevation: const WidgetStatePropertyAll<double>(0),
          shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        ),
      ),
      // Ghost button: surface + strong hairline + navy text.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.disabled) ? t.textMuted : t.text),
          backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.hovered) ? t.surfaceSubtle : t.surface),
          side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: t.borderStrong)),
          textStyle: WidgetStatePropertyAll<TextStyle>(
              AppTextStyles.bodyStrongStyle),
          minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 44)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: AppSpacing.componentXxl)),
          shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button))),
        ),
      ),
      // Tertiary: quiet navy text button.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? t.brandNavy : const Color(0xFF33457D),
          textStyle: AppTextStyles.bodyStrongStyle,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.componentMd),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      // Inputs: hairline borderStrong at rest, 2px gold on focus (spec §5).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        focusColor: t.gold.withValues(alpha: 0.06),
        hintStyle: AppTextStyles.bodyStyle.copyWith(color: t.textMuted),
        labelStyle: AppTextStyles.labelStyle.copyWith(color: t.textSecondary),
        helperStyle: AppTextStyles.captionStyle.copyWith(color: t.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.componentLg,
          vertical: AppSpacing.componentMd,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: t.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: t.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: t.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: t.error.dot),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: t.error.dot, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceSubtle,
        selectedColor: t.goldSelectedFill,
        labelStyle: AppTextStyles.labelStyle.copyWith(color: t.text),
        secondaryLabelStyle:
            AppTextStyles.labelStyle.copyWith(color: t.goldText),
        checkmarkColor: t.goldText,
        side: WidgetStateBorderSide.resolveWith((Set<WidgetState> s) =>
            BorderSide(
                color: s.contains(WidgetState.selected) ? t.gold : t.border)),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.componentMd,
          vertical: AppSpacing.componentXs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
      ),
      dividerTheme: DividerThemeData(
        color: t.border,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.textSecondary,
        textColor: t.text,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? t.onGold : t.surface),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? t.gold : t.borderStrong),
        trackOutlineColor:
            const WidgetStatePropertyAll<Color>(Colors.transparent),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: t.text,
        unselectedLabelColor: t.textSecondary,
        labelStyle: AppTextStyles.bodyStrongStyle,
        unselectedLabelStyle: AppTextStyles.bodyStyle,
        indicatorColor: t.gold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? t.surfaceSubtle : const Color(0xFF131C3D),
        contentTextStyle:
            AppTextStyles.bodyStyle.copyWith(color: const Color(0xFFEDF0F7)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
