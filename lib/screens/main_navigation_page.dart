import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:get_it/get_it.dart';
import 'transaction_history_page.dart';
import '../services/interfaces/i_transaction_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'dashboard_screen.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final GlobalKey<TransactionHistoryPageState> _historyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context);

    final List<Widget> tabs = <Widget>[
      const DashboardWidget(),
      TransactionHistoryPage(key: _historyKey),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppMotion.medium,
        switchInCurve: AppMotion.emphasized,
        switchOutCurve: AppMotion.standard,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        layoutBuilder: (currentChild, previousChildren) {
          // Stack with currentChild on top — but unlike the default, give each
          // child a non-positioned slot so the outgoing one is clipped to the
          // same bounds and tap-events don't pass through during the fade.
          return Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: tabs[_currentIndex],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated(brightness),
              borderRadius: BorderRadius.circular(AppRadius.surface),
              border: brightness == Brightness.dark
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 1,
                    )
                  : null,
              boxShadow: AppElevation.floatingNav(brightness),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_outlined,
                  iconActive: Icons.dashboard_rounded,
                  label: l10n.dashboard,
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _navDivider(brightness),
                _buildFab(brightness),
                _navDivider(brightness),
                _buildNavItem(
                  icon: Icons.history_outlined,
                  iconActive: Icons.history_rounded,
                  label: l10n.history,
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData iconActive,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    final brand = AppColors.brand(brightness);
    final inactive = AppColors.textSecondary(brightness);
    final color = isSelected ? brand : inactive;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.xs,
        ),
        child: Material(
          color: isSelected
              ? brand.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.iconButton),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isSelected ? iconActive : icon,
                      color: color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: AppTextStyles.labelStyle.copyWith(
                      color: color,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navDivider(Brightness brightness) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: AppColors.divider(brightness),
    );
  }

  Widget _buildFab(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final brand = AppColors.brand(brightness);
    final ctaBg = isDark ? null : AppColors.ctaButtonLight;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            final result = await context.push<bool>('/dashboard/import');
            if (result == true) {
              _historyKey.currentState?.refresh();
              GetIt.instance<ITransactionService>().notifyTransactionUpdate();
            }
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isDark ? AppGradients.ctaButtonDark : null,
              color: ctaBg,
              boxShadow: AppElevation.fabGlow(brand),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
