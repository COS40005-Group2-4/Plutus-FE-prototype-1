import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/glass_container.dart';
import 'data_widget.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'l10n/app_localizations.dart';

/// Central registry: widget ID → display metadata.
/// Adding a new widget to this map is the only change needed for it to appear
/// in the sidebar automatically.
const Map<String, _WidgetMeta> _widgetRegistry = {
  'profile':            _WidgetMeta('Profile',               Icons.person,                  Color(0xFFAB47BC)),
  'budget':             _WidgetMeta('Budget Tracking',       Icons.account_balance_wallet,  Color(0xFF4285F4)),
  'categoryBudget':     _WidgetMeta('Category Budget',       Icons.category,                Color(0xFF00897B)),
  'history':            _WidgetMeta('Transaction History',   Icons.history,                 Color(0xFF34A853)),
  'cashflow':           _WidgetMeta('Cash Flow',             Icons.waterfall_chart,         Color(0xFF1E88E5)),
  'expenseBreakdown':   _WidgetMeta('Expense Breakdown',     Icons.pie_chart,               Color(0xFFAF7AC5)),
  'incomeTrend':        _WidgetMeta('Income Trend',          Icons.trending_up,             Color(0xFF43A047)),
  'savingsRate':        _WidgetMeta('Savings Rate',          Icons.savings,                 Color(0xFFF39C12)),
  'netWorthTrend':      _WidgetMeta('Net Worth Trend',       Icons.timeline,                Color(0xFF1ABC9C)),
  'spendingHeatmap':    _WidgetMeta('Spending Heatmap',      Icons.calendar_view_week,      Color(0xFF48C9B0)),
  'portfolioAllocation':_WidgetMeta('Portfolio Allocation',  Icons.donut_large,             Color(0xFF4285F4)),
  'investment':         _WidgetMeta('Investments',           Icons.show_chart,              Color(0xFF4A90E2)),
  'roi':                _WidgetMeta('ROI',                   Icons.trending_up,             Color(0xFF5DADE2)),
  'irr':                _WidgetMeta('IRR',                   Icons.analytics,               Color(0xFF5DADE2)),
  'marketTrending':     _WidgetMeta('Market Trending',       Icons.candlestick_chart,       Color(0xFF26A69A)),
  'bills':              _WidgetMeta('Upcoming Bills',        Icons.receipt_long,            Color(0xFFEA4335)),
  'tax':                _WidgetMeta('Tax Estimation',        Icons.account_balance,         Color(0xFF2A5470)),
  'import':             _WidgetMeta('Import Report',         Icons.upload_file,             Color(0xFFFBBC05)),
  'export':             _WidgetMeta('Export Report',         Icons.download,                Color(0xFFEA4335)),
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
            color: const Color(0xFF2C3E50),
            opacity: 0.6,
            blur: 15,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.3),
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
                            borderRadius: BorderRadius.circular(8),
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
                    hoverColor: Colors.blue.withValues(alpha: 0.2),
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
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
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
