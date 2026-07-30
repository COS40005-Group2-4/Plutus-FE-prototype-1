import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:get_it/get_it.dart';
import 'transaction_history_page.dart';
import '../services/interfaces/i_transaction_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';
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
    final PlutusTokens t = context.tokens;
    final l10n = AppLocalizations.of(context);

    final List<Widget> tabs = <Widget>[
      const DashboardWidget(),
      TransactionHistoryPage(key: _historyKey),
    ];

    return Scaffold(
      body: _DirectionalAxisSwitcher(
        index: _currentIndex,
        children: tabs,
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
              color: t.surface,
              borderRadius: AppRadius.borderSurface,
              border: Border.all(color: t.border),
              boxShadow: t.shadowMedium,
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
                _navDivider(t),
                _buildFab(t),
                _navDivider(t),
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
    final PlutusTokens t = context.tokens;
    final Color fg = isSelected ? t.text : t.textSecondary;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.xs,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.iconButton),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.componentLg,
                      vertical: AppSpacing.componentXs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? t.goldSelectedFill : Colors.transparent,
                      borderRadius: AppRadius.borderPill,
                    ),
                    child: Icon(
                      isSelected ? iconActive : icon,
                      color: fg,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: AppTextStyles.labelStyle.copyWith(color: fg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navDivider(PlutusTokens t) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: t.border,
    );
  }

  Widget _buildFab(PlutusTokens t) {
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
              color: t.gold,
              shape: BoxShape.circle,
              boxShadow: t.shadowMedium,
            ),
            child: Icon(
              Icons.add_rounded,
              color: t.onGold,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Directional shared-axis tab switcher
// ---------------------------------------------------------------------------

const double _kTabSlideDistance = 24.0;

/// Swaps between two tab bodies with a directional shared-axis transition.
///
/// All children are kept mounted (with their tickers paused) so per-tab scroll
/// position and widget state survive across switches. The outgoing tab fades +
/// slides ~24 px in the direction it came from over the first 40% of the
/// duration; the incoming tab fades + slides in from the opposite side over
/// the last 60%. The two never sit at meaningful opacity at the same instant.
class _DirectionalAxisSwitcher extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _DirectionalAxisSwitcher({
    required this.index,
    required this.children,
  });

  @override
  State<_DirectionalAxisSwitcher> createState() =>
      _DirectionalAxisSwitcherState();
}

class _DirectionalAxisSwitcherState extends State<_DirectionalAxisSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _previousIndex;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
      value: 1.0,
    );
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && _isAnimating) {
        setState(() {
          _isAnimating = false;
          _previousIndex = widget.index;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _DirectionalAxisSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      // Capture the old index as the outgoing tab and start a fresh transition.
      _previousIndex = oldWidget.index;
      final bool reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (reduceMotion) {
        _isAnimating = false;
        _controller.value = 1.0;
      } else {
        _isAnimating = true;
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return IndexedStack(
        index: widget.index,
        sizing: StackFit.expand,
        children: widget.children,
      );
    }

    final int direction = widget.index >= _previousIndex ? 1 : -1;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Stack(
          fit: StackFit.expand,
          children: List<Widget>.generate(widget.children.length, (int i) {
            final bool isCurrent = i == widget.index;
            final bool isOutgoing = _isAnimating && i == _previousIndex;
            final Widget tab = KeyedSubtree(
              key: ValueKey<int>(i),
              child: widget.children[i],
            );

            if (!isCurrent && !isOutgoing) {
              // Keep the tab in the tree (state preserved) but paused and
              // not painted/hit-tested.
              return Offstage(
                offstage: true,
                child: TickerMode(enabled: false, child: tab),
              );
            }

            final double t = _controller.value;

            if (isCurrent) {
              // Incoming: fades + slides in from `direction * slide` to 0
              // over the last 60% of the duration.
              final double localT = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
              final double eased = AppMotion.emphasized.transform(localT);
              final double dx = direction * _kTabSlideDistance * (1 - eased);
              return IgnorePointer(
                ignoring: !_isAnimating ? false : eased < 0.5,
                child: Opacity(
                  opacity: eased,
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: tab,
                  ),
                ),
              );
            } else {
              // Outgoing: fades + slides out from 0 to `-direction * slide`
              // over the first 40% of the duration.
              final double localT = (t / 0.4).clamp(0.0, 1.0);
              final double eased = AppMotion.emphasized.transform(localT);
              final double dx = -direction * _kTabSlideDistance * eased;
              return IgnorePointer(
                ignoring: true,
                child: Opacity(
                  opacity: 1 - eased,
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: tab,
                  ),
                ),
              );
            }
          }),
        );
      },
    );
  }
}
