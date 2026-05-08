import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Builds light/dark [ThemeData] from the design tokens.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color seed = isDark ? AppColors.primaryDark : AppColors.primary;
    final Color bg = AppColors.background(brightness);
    final Color surface = AppColors.surface(brightness);
    final Color textPrimary = AppColors.textPrimary(brightness);
    final Color textSecondary = AppColors.textSecondary(brightness);
    final Color border = AppColors.border(brightness);

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      primary: seed,
      secondary: AppColors.accent,
      surface: surface,
      error: AppColors.error,
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
      // Scaffold is transparent because GlassBackground (in main.dart's
      // MaterialApp.builder) paints the base background and a soft accent wash.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: bg,
      dividerColor: AppColors.divider(brightness),
      textTheme: textTheme,
      fontFamily: AppTextStyles.fontFamily,
      iconTheme: IconThemeData(color: textPrimary, size: 22),
      primaryIconTheme: IconThemeData(color: textPrimary, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleStyle.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        titleTextStyle: AppTextStyles.titleStyle.copyWith(color: textPrimary),
        contentTextStyle:
            AppTextStyles.bodyStyle.copyWith(color: textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: seed.withValues(alpha: isDark ? 0.20 : 0.12),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.labelStyle.copyWith(color: textPrimary),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: seed);
          }
          return IconThemeData(color: textSecondary);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: AppColors.surfaceMuted(brightness),
          disabledForegroundColor: AppColors.textTertiary(brightness),
          textStyle: AppTextStyles.bodyStrongStyle,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          textStyle: AppTextStyles.bodyStrongStyle,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: AppTextStyles.bodyStrongStyle,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          side: BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seed,
          textStyle: AppTextStyles.bodyStrongStyle,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted(brightness),
        hintStyle:
            AppTextStyles.bodyStyle.copyWith(color: AppColors.textTertiary(brightness)),
        labelStyle:
            AppTextStyles.labelStyle.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: seed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted(brightness),
        labelStyle: AppTextStyles.labelStyle.copyWith(color: textPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        side: BorderSide(color: border, width: 1),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.divider(brightness),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? AppColors.textOnDarkSecondary : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return seed;
          return AppColors.surfaceMuted(brightness);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: seed,
        unselectedLabelColor: textSecondary,
        labelStyle: AppTextStyles.bodyStrongStyle,
        unselectedLabelStyle: AppTextStyles.bodyStyle,
        indicatorColor: seed,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceElevatedDark : AppColors.textOnLight,
        contentTextStyle: AppTextStyles.bodyStyle.copyWith(
          color: isDark ? AppColors.textOnDark : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
