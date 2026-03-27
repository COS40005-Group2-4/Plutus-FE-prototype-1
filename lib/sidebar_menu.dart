import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/glass_container.dart';
import 'data_widget.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import 'theme/app_radius.dart';

/// Central registry: widget ID → display metadata.
/// Adding a new widget to this map is the only change needed for it to appear
/// in the sidebar automatically.
const Map<String, _WidgetMeta> _widgetRegistry = {
  'profile':            _WidgetMeta('Profile',               Icons.person,                  AppColors.profileAccent),
  'budget':             _WidgetMeta('Budget Tracking',       Icons.account_balance_wallet,  AppColors.budgetAccent),
  'categoryBudget':     _WidgetMeta('Category Budget',       Icons.category,                AppColors.categoryBudgetAccent),
  'history':            _WidgetMeta('Transaction History',   Icons.history,                 AppColors.historyAccent),
  'cashflow':           _WidgetMeta('Cash Flow',             Icons.waterfall_chart,         AppColors.cashflowAccent),
  'expenseBreakdown':   _WidgetMeta('Expense Breakdown',     Icons.pie_chart,               AppColors.expenseAccent),
  'incomeTrend':        _WidgetMeta('Income Trend',          Icons.trending_up,             AppColors.incomeAccent),
  'savingsRate':        _WidgetMeta('Savings Rate',          Icons.savings,                 AppColors.savingsAccent),
  'netWorthTrend':      _WidgetMeta('Net Worth Trend',       Icons.timeline,                AppColors.netWorthAccent),
  'spendingHeatmap':    _WidgetMeta('Spending Heatmap',      Icons.calendar_view_week,      AppColors.heatmapAccent),
  'portfolioAllocation':_WidgetMeta('Portfolio Allocation',  Icons.donut_large,             AppColors.primary),
  'investment':         _WidgetMeta('Investments',           Icons.show_chart,              AppColors.primaryDark),
  'roi':                _WidgetMeta('ROI',                   Icons.trending_up,             AppColors.accent),
  'irr':                _WidgetMeta('IRR',                   Icons.analytics,               AppColors.accent),
  'marketTrending':     _WidgetMeta('Market Trending',       Icons.candlestick_chart,       AppColors.marketAccent),
  'bills':              _WidgetMeta('Upcoming Bills',        Icons.receipt_long,            AppColors.billsAccent),
  'tax':                _WidgetMeta('Tax Estimation',        Icons.account_balance,         AppColors.taxAccent),
  'import':             _WidgetMeta('Import Report',         Icons.upload_file,             AppColors.importAccent),
  'export':             _WidgetMeta('Export Report',         Icons.download,                AppColors.exportAccent),
};

class SidebarMenu extends StatefulWidget {
  final Function(String)? onMenuItemSelected;

  const SidebarMenu({super.key, this.onMenuItemSelected});

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<DashboardProvider>(
      builder: (context, dashProvider, _) {
        final allIds = dashProvider.allWidgetIds;
        return Drawer(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            borderRadius: 0,
            color: AppColors.menuBackground,
            opacity: 0.6,
            blur: 15,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  auth.isAuthenticated ? 'Plutus Menu' : 'Plutus (Guest)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  auth.isAuthenticated
                                      ? 'Welcome, ${auth.userName}'
                                      : 'Toggle Dashboard Widgets',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.widgetDashboardWidgets} — ${dashProvider.activeDashboard.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      ...allIds.map((id) {
                        final meta = _widgetRegistry[id];
                        if (meta == null) return const SizedBox.shrink();
                        final isVisible = dashProvider.isWidgetVisible(id);
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.borderSm,
                            color: isVisible
                                ? meta.color.withValues(alpha: 0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: isVisible
                                  ? meta.color.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isVisible,
                            onChanged: (value) {
                              if (value == true) {
                                dashProvider.showWidget(id);
                              } else {
                                dashProvider.hideWidget(id);
                              }
                            },
                            title: Text(
                              meta.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isVisible ? meta.color : Colors.white,
                                fontWeight: isVisible ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            secondary: Icon(
                              meta.icon,
                              color: isVisible ? meta.color : Colors.white54,
                            ),
                            activeColor: meta.color,
                            checkColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Visible: ${dashProvider.visibleWidgetsCount} / ${dashProvider.totalWidgetsCount}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(color: Colors.white24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.settings, color: Colors.white70),
                    title: Text(
                      l10n.settings,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                    hoverColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                const Divider(color: Colors.white24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ListTile(
                        leading: Icon(
                          auth.isAuthenticated ? Icons.logout : Icons.login,
                          color: auth.isAuthenticated ? Colors.redAccent : Colors.greenAccent,
                        ),
                        title: Text(
                          auth.isAuthenticated ? l10n.signOut : l10n.signIn,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: auth.isAuthenticated ? Colors.redAccent : Colors.greenAccent,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (auth.isAuthenticated) {
                            _handleSignOut(context, l10n);
                          } else {
                            Navigator.pushNamed(context, '/login');
                          }
                        },
                        hoverColor: auth.isAuthenticated
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSignOut(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.areYouSureSignOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}

class _WidgetMeta {
  final String label;
  final IconData icon;
  final Color color;

  const _WidgetMeta(this.label, this.icon, this.color);
}

// Keep MenuItemData for any external usage
class MenuItemData {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  MenuItemData({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}
