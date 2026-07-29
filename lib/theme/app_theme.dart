import 'package:flutter/material.dart';
import 'app_colors.dart';
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
    final Color seed = AppColors.brand(brightness);
    final Color secondary = AppColors.accentColor(brightness);
    final Color bg = t.bg;
    final Color surface = t.surface;
    final Color textPrimary = AppColors.textPrimary(brightness);
    final Color textSecondary = AppColors.textSecondary(brightness);
    final Color ctaBg = AppColors.ctaButtonBackground(brightness);
    final Color ctaFg = AppColors.ctaButtonForeground(brightness);

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
        toolbarHeight: 64,
        titleTextStyle: AppTextStyles.headingStyle.copyWith(
          color: textPrimary,
          fontSize: 24,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 24),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderCard),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderCard),
        titleTextStyle: AppTextStyles.titleStyle.copyWith(color: textPrimary),
        contentTextStyle:
            AppTextStyles.bodyStyle.copyWith(color: textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.surface)),
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
      // Primary pill CTA: solid near-black on light, violet on dark
      // (widget code can override with a gradient via Container+InkWell).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ctaBg,
          foregroundColor: ctaFg,
          disabledBackgroundColor:
              AppColors.surfaceMuted(brightness),
          disabledForegroundColor: AppColors.textTertiary(brightness),
          textStyle: AppTextStyles.bodyStrongStyle.copyWith(fontSize: 16),
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ctaBg,
          foregroundColor: ctaFg,
          elevation: 0,
          textStyle: AppTextStyles.bodyStrongStyle.copyWith(fontSize: 16),
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
        ),
      ),
      // Secondary outlined button: brand-colored border + label on a soft
      // surface (no fill in light, surfaceMuted in dark).
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seed,
          backgroundColor:
              isDark ? AppColors.surfaceMuted(brightness) : Colors.transparent,
          textStyle: AppTextStyles.bodyStrongStyle.copyWith(fontSize: 16),
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          side: BorderSide(color: seed, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
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
      // Inputs: filled, radius 16, brand focus ring.
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
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: seed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.brandSoft(brightness),
        labelStyle: AppTextStyles.labelStyle.copyWith(
          color: isDark ? AppColors.accentDark : AppColors.primaryStrong,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
        side: BorderSide.none,
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
        labelStyle:
            AppTextStyles.bodyStrongStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            AppTextStyles.bodyStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderInput),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
