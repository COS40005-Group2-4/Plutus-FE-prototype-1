import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:get_it/get_it.dart';
import 'transaction_history_page.dart';
import '../services/interfaces/i_transaction_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
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
              color: AppColors.surface(brightness),
              borderRadius: AppRadius.borderXl,
              border: Border.all(
                color: AppColors.border(brightness),
                width: 1,
              ),
              boxShadow: AppElevation.medium(brightness),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
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
                _buildFab(brightness),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? iconActive : icon, color: color, size: 24),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelStyle.copyWith(
                  color: color,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab(Brightness brightness) {
    final brand = AppColors.brand(brightness);
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
              color: brand,
              boxShadow: [
                BoxShadow(
                  color: brand.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.add_rounded,
              color: brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
