import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_notifier.dart';
import '../providers/dashboard_notifier.dart';
import '../router/app_router.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';
import '../models/widget_catalog.dart';

/// Fixed light ink used on the drawer header's fixed-navy surface (matches
/// HeroCard's pattern: the header does not flip with theme, so its text
/// cannot use theme-dependent tokens either). Gold is reserved for figures.
const Color _kHeaderInk = Color(0xFFEDF0F7);

class SidebarMenu extends ConsumerStatefulWidget {
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
  ConsumerState<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends ConsumerState<SidebarMenu> {
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
    final PlutusTokens t = context.tokens;
    final l10n = AppLocalizations.of(context);
    final dashNotifier = ref.read(dashboardNotifierProvider.notifier);

    final instanceCounts = dashNotifier.getInstanceCounts();
    final grouped = WidgetCatalog.grouped;

    return Drawer(
      backgroundColor: t.surface,
      shape: Border(right: BorderSide(color: t.border)),
      child: Column(
        children: [
          // ── Header ──
          _buildHeader(context, t),
          // ── Search ──
          _buildSearchBar(context, t, l10n),
          // ── Widget Categories ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              itemCount: WidgetCategory.values.length,
              itemBuilder: (context, index) {
                final cat = WidgetCategory.values[index];
                return _buildCategory(
                  context,
                  cat,
                  grouped[cat] ?? [],
                  dashNotifier,
                  instanceCounts,
                  t,
                  l10n,
                );
              },
            ),
          ),
          // ── Footer ──
          _buildFooter(context, dashNotifier, t, l10n),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, PlutusTokens t) {
    ref.watch(authNotifierProvider); // watch for rebuilds on auth changes
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final bool isAuthenticated = authNotifier.isAuthenticated;
    final String userName = authNotifier.userName;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.lg,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.md,
      ),
      color: t.heroSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _kHeaderInk,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.heroBorder),
                ),
                child: Image.asset(
                  'lib/assets/branding/plutus_icon.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  isAuthenticated ? 'Plutus' : 'Plutus (Guest)',
                  style: AppTextStyles.titleStyle.copyWith(color: _kHeaderInk),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (isAuthenticated) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Welcome, $userName',
              style: AppTextStyles.overlineStyle.copyWith(color: t.heroLabel),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context, PlutusTokens t, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: TextStyle(color: t.text, fontSize: 14),
        decoration: InputDecoration(
          filled: true,
          fillColor: t.surfaceSubtle,
          hintText: l10n.searchWidgets,
          hintStyle: TextStyle(color: t.textMuted, fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: t.textSecondary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: t.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
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
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
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
    DashboardNotifier dashNotifier,
    Map<String, int> instanceCounts,
    PlutusTokens t,
    AppLocalizations l10n,
  ) {
    // Filter widgets by search
    final filtered = _searchQuery.isEmpty
        ? widgets
        : widgets.where((m) => l10n.translate(m.label).toLowerCase().contains(_searchQuery)).toList();

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
              child: Row(
                children: [
                  Icon(
                    WidgetCatalog.categoryIcon(category),
                    size: 18,
                    color: t.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      categoryLabel.toUpperCase(),
                      style: AppTextStyles.overlineStyle.copyWith(color: t.textSecondary),
                    ),
                  ),
                  if (activeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: t.surfaceSubtle,
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        '$activeCount',
                        style: AppTextStyles.captionStyle.copyWith(
                          color: t.textSecondary,
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
                      color: t.textMuted,
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
                          dashNotifier,
                          instanceCounts[meta.widgetType] ?? 0,
                          t,
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
    DashboardNotifier dashNotifier,
    int instanceCount,
    PlutusTokens t,
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
                color: t.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                meta.icon,
                size: 18,
                color: t.brandNavy,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Label
            Expanded(
              child: Text(
                AppLocalizations.of(context).translate(meta.label),
                style: TextStyle(
                  color: t.text,
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
              dashNotifier,
              instanceCount,
              canAdd,
              t,
              l10n,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileControls(
    BuildContext context,
    WidgetMeta meta,
    DashboardNotifier dashNotifier,
    int instanceCount,
    bool canAdd,
    PlutusTokens t,
    AppLocalizations l10n,
  ) {
    // No instances — show "Add" affordance
    if (instanceCount == 0) {
      return Tooltip(
        message: l10n.addWidget,
        child: _buildIconBtn(
          icon: Icons.add_circle_outline,
          color: t.goldText,
          onTap: () => _addInstance(dashNotifier, meta),
        ),
      );
    }

    // Single instance (no duplicates allowed) — show toggle
    if (!meta.allowDuplicates) {
      return _buildToggle(dashNotifier, meta);
    }

    // Has instances — show count + add/remove
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Remove button
        _buildIconBtn(
          icon: Icons.remove_rounded,
          color: t.error.text,
          onTap: () => _removeLastInstance(dashNotifier, meta),
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
              color: t.goldWeak,
              borderRadius: AppRadius.borderSm,
            ),
            child: Text(
              '${instanceCount}x',
              style: TextStyle(
                color: t.goldText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // Add button
        _buildIconBtn(
          icon: Icons.add_rounded,
          color: canAdd ? t.goldText : t.textMuted,
          onTap: canAdd ? () => _addInstance(dashNotifier, meta) : null,
        ),
      ],
    );
  }

  Widget _buildToggle(DashboardNotifier dashNotifier, WidgetMeta meta) {
    final dashState = ref.watch(dashboardNotifierProvider);
    final instances = dashState.activeDashboard.instancesOfType(meta.widgetType);
    final instanceId = instances.isNotEmpty ? instances.first : null;
    final isVisible = instanceId != null && dashNotifier.isWidgetVisible(instanceId);

    return SizedBox(
      height: 28,
      child: Switch.adaptive(
        value: isVisible,
        onChanged: (value) {
          if (instanceId != null) {
            if (value) {
              dashNotifier.showWidget(instanceId);
            } else {
              dashNotifier.hideWidget(instanceId);
            }
          }
        },
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
    DashboardNotifier dashNotifier,
    PlutusTokens t,
    AppLocalizations l10n,
  ) {
    final totalActive = dashNotifier.getVisibleWidgets().length;
    ref.watch(authNotifierProvider); // watch for rebuilds on auth changes
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final bool isAuthenticated = authNotifier.isAuthenticated;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(color: t.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(Icons.widgets_outlined, size: 16, color: t.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$totalActive ${l10n.widgetsOnDashboard}',
                style: TextStyle(color: t.textMuted, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Divider(color: t.border),
        // Settings
        ListTile(
          dense: true,
          leading: Icon(
            Icons.settings_outlined,
            color: t.textSecondary,
            size: 20,
          ),
          title: Text(
            l10n.settings,
            style: TextStyle(
              color: t.text,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            context.pop();
            context.push(AppRoutes.settings);
          },
          hoverColor: t.gold.withValues(alpha: 0.08),
        ),
        // Sign in/out
        ListTile(
          dense: true,
          leading: Icon(
            isAuthenticated ? Icons.logout_rounded : Icons.login_rounded,
            color: isAuthenticated ? t.error.text : t.goldText,
            size: 20,
          ),
          title: Text(
            isAuthenticated ? l10n.signOut : l10n.signIn,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isAuthenticated ? t.error.text : t.goldText,
              fontSize: 14,
            ),
          ),
          onTap: () {
            context.pop();
            if (isAuthenticated) {
              _handleSignOut(context, l10n, authNotifier);
            } else {
              context.push(AppRoutes.login);
            }
          },
          hoverColor: isAuthenticated
              ? t.error.dot.withValues(alpha: 0.1)
              : t.gold.withValues(alpha: 0.08),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.xs),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _addInstance(DashboardNotifier dashNotifier, WidgetMeta meta) async {
    final instanceId = await dashNotifier.addWidgetInstance(meta.widgetType);
    widget.onWidgetAdded?.call(instanceId, meta.widgetType);
  }

  Future<void> _removeLastInstance(DashboardNotifier dashNotifier, WidgetMeta meta) async {
    final dashState = ref.read(dashboardNotifierProvider);
    final instances = dashState.activeDashboard.instancesOfType(meta.widgetType);
    if (instances.isEmpty) return;

    // Remove the last instance
    final lastInstance = instances.last;
    widget.onWidgetRemoved?.call(lastInstance);
    await dashNotifier.removeWidgetInstance(lastInstance);
  }

  void _handleSignOut(BuildContext context, AppLocalizations l10n, AuthNotifier authNotifier) {
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
              await authNotifier.signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
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
    return l10n.translate(WidgetCatalog.categoryLabelKey(cat));
  }
}
