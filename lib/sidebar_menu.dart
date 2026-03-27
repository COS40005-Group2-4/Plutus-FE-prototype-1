import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/glass_container.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import 'theme/app_radius.dart';
import 'theme/app_spacing.dart';
import 'models/widget_catalog.dart';


class SidebarMenu extends StatefulWidget {
  final Function(String)? onMenuItemSelected;
  final void Function(String instanceId, String widgetType)? onWidgetAdded;
  final void Function(String instanceId)? onWidgetRemoved;

  const SidebarMenu({
    super.key,
    this.onMenuItemSelected,
    this.onWidgetAdded,
    this.onWidgetRemoved,
  });

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  final Map<WidgetCategory, bool> _expandedCategories = {
    for (final cat in WidgetCategory.values) cat: true,
  };

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<DashboardProvider>(
      builder: (context, dashProvider, _) {
        final instanceCounts = dashProvider.getInstanceCounts();
        final grouped = WidgetCatalog.grouped;

        return Drawer(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            borderRadius: 0,
            color: isDark ? AppColors.menuBackground : Colors.white,
            opacity: isDark ? 0.6 : 0.85,
            blur: 15,
            child: Column(
              children: [
                // ── Header ──
                _buildHeader(context, isDark),
                // ── Search ──
                _buildSearchBar(context, isDark, l10n),
                // ── Widget Categories ──
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    children: [
                      for (final cat in WidgetCategory.values)
                        _buildCategory(
                          context,
                          cat,
                          grouped[cat] ?? [],
                          dashProvider,
                          instanceCounts,
                          isDark,
                          l10n,
                        ),
                    ],
                  ),
                ),
                // ── Footer ──
                _buildFooter(context, dashProvider, isDark, l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.lg,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.accent.withValues(alpha: 0.1),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.accent.withValues(alpha: 0.06),
                ],
        ),
      ),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Icon(
                      Icons.dashboard_customize,
                      color: isDark ? AppColors.accent : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      auth.isAuthenticated ? 'Plutus' : 'Plutus (Guest)',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textOnLight,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (auth.isAuthenticated) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Welcome, ${auth.userName}',
                  style: TextStyle(
                    color: isDark ? AppColors.textOnDarkSecondary : AppColors.textOnLightSecondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textOnLight,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: l10n.searchWidgets,
            hintStyle: TextStyle(
              color: isDark ? AppColors.textOnDarkTertiary : AppColors.textOnLightTertiary,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? AppColors.textOnDarkTertiary : AppColors.textOnLightTertiary,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.textOnDarkTertiary : AppColors.textOnLightTertiary,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.sm,
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Category
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCategory(
    BuildContext context,
    WidgetCategory category,
    List<WidgetMeta> widgets,
    DashboardProvider dashProvider,
    Map<String, int> instanceCounts,
    bool isDark,
    AppLocalizations l10n,
  ) {
    // Filter widgets by search
    final filtered = _searchQuery.isEmpty
        ? widgets
        : widgets.where((m) => m.label.toLowerCase().contains(_searchQuery)).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    final isExpanded = _searchQuery.isNotEmpty || (_expandedCategories[category] ?? true);
    final activeCount = filtered.fold<int>(
      0,
      (sum, m) => sum + (instanceCounts[m.widgetType] ?? 0),
    );

    final categoryLabel = _getCategoryLabel(category, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: [
          // ── Category Header ──
          InkWell(
            borderRadius: AppRadius.borderSm,
            onTap: _searchQuery.isNotEmpty
                ? null
                : () => setState(() {
                    _expandedCategories[category] = !isExpanded;
                  }),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.borderSm,
                gradient: LinearGradient(
                  colors: [
                    _getCategoryColor(category).withValues(alpha: isDark ? 0.15 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    WidgetCatalog.categoryIcon(category),
                    size: 18,
                    color: _getCategoryColor(category).withValues(alpha: isDark ? 0.9 : 0.8),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      categoryLabel,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textOnLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (activeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withValues(alpha: 0.2),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        '$activeCount',
                        style: TextStyle(
                          color: _getCategoryColor(category),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: isExpanded ? 0.0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: isDark ? AppColors.textOnDarkTertiary : AppColors.textOnLightTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Widget Tiles ──
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Column(
                    children: [
                      for (final meta in filtered)
                        _buildWidgetTile(
                          context,
                          meta,
                          dashProvider,
                          instanceCounts[meta.widgetType] ?? 0,
                          isDark,
                          l10n,
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Widget Tile
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildWidgetTile(
    BuildContext context,
    WidgetMeta meta,
    DashboardProvider dashProvider,
    int instanceCount,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final isActive = instanceCount > 0;
    final canAdd = meta.allowDuplicates
        ? instanceCount < WidgetCatalog.maxInstancesPerType
        : instanceCount < 1;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        top: 2,
        bottom: 2,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderSm,
          color: isActive
              ? meta.color.withValues(alpha: isDark ? 0.12 : 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? meta.color : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: isActive ? 0.2 : 0.1),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(
                  meta.icon,
                  size: 18,
                  color: isActive
                      ? meta.color
                      : (isDark ? AppColors.textOnDarkTertiary : AppColors.textOnLightTertiary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Label
              Expanded(
                child: Text(
                  meta.label,
                  style: TextStyle(
                    color: isActive
                        ? (isDark ? Colors.white : AppColors.textOnLight)
                        : (isDark ? AppColors.textOnDarkTertiary : AppColors.textOnLightTertiary),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Controls
              _buildTileControls(
                context,
                meta,
                dashProvider,
                instanceCount,
                canAdd,
                isDark,
                l10n,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTileControls(
    BuildContext context,
    WidgetMeta meta,
    DashboardProvider dashProvider,
    int instanceCount,
    bool canAdd,
    bool isDark,
    AppLocalizations l10n,
  ) {
    // No instances — show "Add" button
    if (instanceCount == 0) {
      return _buildActionChip(
        label: l10n.addWidget,
        icon: Icons.add_rounded,
        color: meta.color,
        isDark: isDark,
        onTap: () => _addInstance(dashProvider, meta),
      );
    }

    // Single instance (no duplicates allowed) — show toggle
    if (!meta.allowDuplicates) {
      return _buildToggle(dashProvider, meta, isDark);
    }

    // Has instances — show count + add/remove
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Remove button
        _buildIconBtn(
          icon: Icons.remove_rounded,
          color: isDark ? AppColors.textOnDarkTertiary : AppColors.textOnLightTertiary,
          onTap: () => _removeLastInstance(dashProvider, meta),
        ),
        // Count badge
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: Container(
            key: ValueKey(instanceCount),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.2),
              borderRadius: AppRadius.borderSm,
            ),
            child: Text(
              '${instanceCount}x',
              style: TextStyle(
                color: meta.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // Add button
        _buildIconBtn(
          icon: Icons.add_rounded,
          color: canAdd ? meta.color : (isDark ? Colors.white24 : Colors.black12),
          onTap: canAdd ? () => _addInstance(dashProvider, meta) : null,
        ),
      ],
    );
  }

  Widget _buildToggle(DashboardProvider dashProvider, WidgetMeta meta, bool isDark) {
    final instances = dashProvider.activeDashboard.instancesOfType(meta.widgetType);
    final instanceId = instances.isNotEmpty ? instances.first : null;
    final isVisible = instanceId != null && dashProvider.isWidgetVisible(instanceId);

    return SizedBox(
      height: 28,
      child: Switch.adaptive(
        value: isVisible,
        onChanged: (value) {
          if (instanceId != null) {
            if (value) {
              dashProvider.showWidget(instanceId);
            } else {
              dashProvider.hideWidget(instanceId);
            }
          }
        },
        activeColor: meta.color,
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: AppRadius.borderSm,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: AppRadius.borderSm,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: AppRadius.borderSm,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Footer
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFooter(
    BuildContext context,
    DashboardProvider dashProvider,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final totalActive = dashProvider.getVisibleWidgets().length;
    final textColor = isDark ? AppColors.textOnDarkTertiary : AppColors.textOnLightTertiary;
    final primaryTextColor = isDark ? Colors.white : AppColors.textOnLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(Icons.widgets_outlined, size: 16, color: textColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$totalActive ${l10n.widgetsOnDashboard}',
                style: TextStyle(color: textColor, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Divider(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
        // Settings
        ListTile(
          dense: true,
          leading: Icon(
            Icons.settings_outlined,
            color: isDark ? AppColors.textOnDarkSecondary : AppColors.textOnLightSecondary,
            size: 20,
          ),
          title: Text(
            l10n.settings,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/settings');
          },
          hoverColor: AppColors.primary.withValues(alpha: 0.1),
        ),
        // Sign in/out
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return ListTile(
              dense: true,
              leading: Icon(
                auth.isAuthenticated ? Icons.logout_rounded : Icons.login_rounded,
                color: auth.isAuthenticated ? AppColors.error : AppColors.success,
                size: 20,
              ),
              title: Text(
                auth.isAuthenticated ? l10n.signOut : l10n.signIn,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: auth.isAuthenticated ? AppColors.error : AppColors.success,
                  fontSize: 14,
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
        SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.xs),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _addInstance(DashboardProvider dashProvider, WidgetMeta meta) async {
    final instanceId = await dashProvider.addWidgetInstance(meta.widgetType);
    widget.onWidgetAdded?.call(instanceId, meta.widgetType);
  }

  Future<void> _removeLastInstance(DashboardProvider dashProvider, WidgetMeta meta) async {
    final instances = dashProvider.activeDashboard.instancesOfType(meta.widgetType);
    if (instances.isEmpty) return;

    // Remove the last instance
    final lastInstance = instances.last;
    widget.onWidgetRemoved?.call(lastInstance);
    await dashProvider.removeWidgetInstance(lastInstance);
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

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _getCategoryLabel(WidgetCategory cat, AppLocalizations l10n) {
    switch (cat) {
      case WidgetCategory.overview:
        return l10n.categoryOverview;
      case WidgetCategory.analytics:
        return l10n.categoryAnalytics;
      case WidgetCategory.investments:
        return l10n.categoryInvestments;
      case WidgetCategory.tools:
        return l10n.categoryTools;
    }
  }

  Color _getCategoryColor(WidgetCategory cat) {
    switch (cat) {
      case WidgetCategory.overview:
        return AppColors.primary;
      case WidgetCategory.analytics:
        return AppColors.incomeAccent;
      case WidgetCategory.investments:
        return AppColors.accent;
      case WidgetCategory.tools:
        return AppColors.savingsAccent;
    }
  }
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
