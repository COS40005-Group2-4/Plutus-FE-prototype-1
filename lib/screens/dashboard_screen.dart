import 'dart:ui' show PointerDeviceKind;

import 'package:dashboard/dashboard.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/data_widget.dart';
import '../widgets/sidebar_menu.dart';
import '../services/storage_service.dart';
import '../providers/dashboard_notifier.dart';
import '../providers/backup_notifier.dart';
import '../providers/budget_notifier.dart';
import '../models/backup_models.dart';
import '../widgets/backup_found_dialog.dart';
import '../providers/settings_notifier.dart';
import '../services/budget_notification_service.dart';
import '../widgets/core/app_card.dart';
import '../widgets/core/entrance_reveal.dart';
import '../widgets/dashboard/edit_mode_banner.dart';
import '../widgets/dashboard/empty_slot_tile.dart';
import '../widgets/dashboard/widget_edit_chrome.dart';
import '../widgets/create_dashboard_dialog.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';

/// On web, prevent mouse drag from scrolling so that pan gestures
/// in edit mode can move widgets instead of scrolling the viewport.
class _WebDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    // Exclude PointerDeviceKind.mouse so mouse drag goes to GestureDetector
  };
}

class DashboardWidget extends ConsumerStatefulWidget {
  const DashboardWidget({super.key});

  @override
  ConsumerState<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends ConsumerState<DashboardWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final ScrollController scrollController = ScrollController();

  late DashboardItemController<ColoredDashboardItem> _itemController;

  late MyItemStorage storage;

  DashboardItemController<ColoredDashboardItem> get itemController =>
      _itemController;

  int? slot;
  String? _selectedWidget;

  List<String> _lastVisibilityKey = [];
  String? _lastDashboardId;
  int _controllerVersion = 0;
  int? _lastUserId;
  bool _alertsDismissed = false;

  /// Mirror of [_itemController.isEditing]. The package's
  /// [DashboardItemController] only attaches its `_layoutController` once
  /// the [Dashboard] widget has mounted, so reading the controller's
  /// `isEditing` getter during the first build (e.g. in the AppBar or
  /// banner) throws. We track edit state ourselves and only push it to
  /// the controller after the toggle press, by which point the grid is
  /// safely mounted.
  bool _isEditing = false;

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
    // Sync to the controller so the grid library enables drag/swap/resize.
    // Safe here because the user can only tap the toggle after the
    // Dashboard widget has rendered at least once.
    _itemController.isEditing = _isEditing;
  }

  /// Banner "Add" action — opens the sidebar so the user can pick a widget
  /// to drop onto the layout. Reuses the existing drawer flow.
  void _openSidebarForAdd() {
    Scaffold.maybeOf(context)?.openDrawer();
  }

  /// Banner "Undo" action — reverts to the last saved layout snapshot.
  Future<void> _undoLayoutChanges() async {
    final notifier = ref.read(dashboardNotifierProvider.notifier);
    _lastVisibilityKey = [];
    await notifier.resetToSaved();
    if (!mounted) return;
    final dashState = ref.read(dashboardNotifierProvider);
    _recreateStorageAndController(
      dashState.activeDashboardId,
      notifier.getVisibleWidgets(),
    );
  }

  bool _backupPromptShown = false;

  @override
  void initState() {
    super.initState();
    // Offer to restore a cloud backup once per session (was a TODO in main.dart:
    // the auth listener there has no Navigator, this screen does).
    ref.listenManual<BackupState>(backupNotifierProvider, (BackupState? prev, BackupState next) {
      if (_backupPromptShown || !next.hasRemoteBackup || !next.hasConflict || next.isLoading) return;
      _backupPromptShown = true;
      // Defer: listener may fire during initState (fireImmediately) where showDialog throws.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showBackupFoundDialog(context).then((bool? restore) {
          if (restore == true) {
            ref.read(backupNotifierProvider.notifier).resolveConflict(ConflictChoice.overrideLocal);
          }
        });
      });
    }, fireImmediately: true);
    final dashState = ref.read(dashboardNotifierProvider);
    _lastDashboardId = dashState.activeDashboardId;
    _lastUserId = ref.read(dashboardNotifierProvider.notifier).currentUserId;
    storage = MyItemStorage(
      dashboardId: dashState.activeDashboardId,
      userId: ref.read(dashboardNotifierProvider.notifier).currentUserId,
    );
    _itemController =
        DashboardItemController<ColoredDashboardItem>.withDelegate(
          itemStorageDelegate: storage,
        );
  }

  void setSlot() {
    var w = MediaQuery.of(context).size.width;
    setState(() {
      slot = w > 600
          ? w > 900
                ? 6
                : 4
          : 2;
    });
  }

  void _recreateStorageAndController(
    String dashboardId,
    List<String> visibleWidgets,
  ) {
    storage = MyItemStorage(
      dashboardId: dashboardId,
      userId: ref.read(dashboardNotifierProvider.notifier).currentUserId,
    );
    storage.setVisibilityFilter(visibleWidgets);

    _itemController = DashboardItemController.withDelegate(
      itemStorageDelegate: storage,
    );
    _controllerVersion++;

    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildAlertsBanner(List<BudgetAlert> alerts) {
    final currency = ref.read(settingsNotifierProvider).currency;
    final PlutusTokens t = context.tokens;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.warning.surface,
        border: Border.all(color: t.warning.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_amber_outlined,
              color: t.warning.text,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: alerts.map((alert) {
                final pct = (alert.spent / alert.budgeted * 100).round();
                final sym = currency.symbol;
                return Text(
                  '${alert.category.name}: $pct% '
                  '($sym${alert.spent.toStringAsFixed(0)} / '
                  '$sym${alert.budgeted.toStringAsFixed(0)})',
                  style: AppTextStyles.bodySmallStyle.copyWith(
                    color: t.warning.text,
                  ),
                );
              }).toList(),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _alertsDismissed = true),
            child: Icon(Icons.close, color: t.warning.text, size: 16),
          ),
        ],
      ),
    );
  }

  void _updateHiddenItems(List<String> visibleWidgets) {
    final dashState = ref.read(dashboardNotifierProvider);
    _recreateStorageAndController(dashState.activeDashboardId, visibleWidgets);
  }

  double _getAspectRatio(double width) {
    if (width < 600) return 0.80;
    if (width < 900) return 0.90;
    return 0.95;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var w = MediaQuery.of(context).size.width;
    slot = w > 600
        ? w > 900
              ? 6
              : 4
        : 2;
    final aspectRatio = _getAspectRatio(w);
    final l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;

    final dashState = ref.watch(dashboardNotifierProvider);
    final alerts = ref.watch(
      budgetNotifierProvider.select(
        (async) => async.valueOrNull?.alerts ?? const <BudgetAlert>[],
      ),
    );

    return Scaffold(
      drawer: SidebarMenu(
        onMenuItemSelected: (widgetId) {
          setState(() {
            _selectedWidget = widgetId;
          });
        },
        onWidgetAdded: (instanceId, widgetType) {
          final item = storage.createDefaultItem(
            instanceId,
            widgetType,
            slot ?? 2,
          );
          _itemController.add(item);
        },
        onWidgetRemoved: (instanceId) {
          _itemController.delete(instanceId);
        },
      ),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == '__new__') {
              await _showCreateDashboardDialog();
            } else {
              ref
                  .read(dashboardNotifierProvider.notifier)
                  .setActiveDashboard(value);
            }
          },
          offset: const Offset(0, 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  dashState.activeDashboard.name,
                  style: AppTextStyles.titleStyle.copyWith(color: t.text),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: t.textSecondary),
            ],
          ),
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[];
            for (final dash in dashState.dashboards) {
              items.add(
                PopupMenuItem<String>(
                  value: dash.id,
                  child: Row(
                    children: [
                      if (dash.id == dashState.activeDashboardId)
                        Icon(Icons.check_rounded, color: t.goldText, size: 18)
                      else
                        const SizedBox(width: AppSpacing.lg),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(dash.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (dashState.canCreateDashboard) {
              items.add(const PopupMenuDivider());
              items.add(
                PopupMenuItem<String>(
                  value: '__new__',
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, color: t.goldText, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n.newDashboard,
                        style: TextStyle(color: t.goldText),
                      ),
                    ],
                  ),
                ),
              );
            }
            return items;
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save',
                child: _menuItem(Icons.save, l10n.saveLayout),
              ),
              PopupMenuItem(
                value: 'reset',
                child: _menuItem(Icons.restore, l10n.resetDashboard),
              ),
              PopupMenuItem(
                value: 'hardReset',
                child: _menuItem(Icons.restart_alt, l10n.hardResetDashboard),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'rename',
                child: _menuItem(Icons.edit, l10n.renameDashboard),
              ),
              PopupMenuItem(
                enabled: dashState.dashboards.length > 1,
                value: 'delete',
                child: _menuItem(
                  Icons.delete_outline,
                  l10n.deleteDashboard,
                  color: dashState.dashboards.length > 1
                      ? t.error.text
                      : t.textMuted,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: _isEditing ? l10n.editModeDone : l10n.editLayout,
            onPressed: _toggleEditMode,
            icon: Icon(
              _isEditing ? Icons.check_rounded : Icons.tune_rounded,
              color: _isEditing ? t.goldText : null,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (alerts.isNotEmpty && !_alertsDismissed)
              EntranceReveal(index: 0, child: _buildAlertsBanner(alerts)),
            // Edit-mode banner: slides + fades into view when editing.
            AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.emphasized,
              switchOutCurve: AppMotion.standard,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: _isEditing
                  ? EditModeBanner(
                      key: const ValueKey('edit-mode-banner'),
                      onDone: _toggleEditMode,
                      onUndo: _undoLayoutChanges,
                    )
                  : const SizedBox.shrink(key: ValueKey('idle-banner')),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  // Detect dashboard switch
                  if (_lastDashboardId != dashState.activeDashboardId) {
                    _lastDashboardId = dashState.activeDashboardId;
                    _lastVisibilityKey = [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _recreateStorageAndController(
                        dashState.activeDashboardId,
                        ref
                            .read(dashboardNotifierProvider.notifier)
                            .getVisibleWidgets(),
                      );
                    });
                  }

                  // Detect user switch (safety net for in-session switches)
                  final currentUserId = ref
                      .read(dashboardNotifierProvider.notifier)
                      .currentUserId;
                  if (_lastUserId != currentUserId) {
                    _lastUserId = currentUserId;
                    _lastVisibilityKey = [];
                    _alertsDismissed = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _recreateStorageAndController(
                          dashState.activeDashboardId,
                          ref
                              .read(dashboardNotifierProvider.notifier)
                              .getVisibleWidgets(),
                        );
                      }
                    });
                  }

                  final visibleWidgets = ref
                      .read(dashboardNotifierProvider.notifier)
                      .getVisibleWidgets();
                  final visibilityKey = visibleWidgets.join(',');

                  final oldKey = _lastVisibilityKey.isNotEmpty
                      ? _lastVisibilityKey.first
                      : '';
                  if (oldKey != visibilityKey) {
                    _lastVisibilityKey = [visibilityKey];

                    if (oldKey.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _updateHiddenItems(visibleWidgets);
                      });
                    }
                  }

                  return _selectedWidget != null
                      ? _buildWidgetPreview(_selectedWidget!)
                      : EntranceReveal(
                          index: 1,
                          child: Dashboard<ColoredDashboardItem>(
                            key: ValueKey(
                              '${dashState.activeDashboardId}_${visibleWidgets.join(',')}_$_controllerVersion',
                            ),
                            shrinkToPlace: true,
                            slideToTop: true,
                            absorbPointer: false,
                            scrollBehavior: kIsWeb
                                ? _WebDragScrollBehavior()
                                : null,
                            slotBackgroundBuilder:
                                SlotBackgroundBuilder.withFunction((
                                  context,
                                  item,
                                  x,
                                  y,
                                  editing,
                                ) {
                                  final PlutusTokens slotTokens =
                                      context.tokens;
                                  final bool isDark =
                                      Theme.of(context).brightness ==
                                      Brightness.dark;
                                  // Idle: hairline outline so empty slots
                                  // still read as structure.
                                  // Editing: gold-tinted snap target —
                                  // outline + soft gold fill.
                                  if (!editing) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),
                                        border: Border.all(
                                          color: slotTokens.border,
                                          width: 1,
                                        ),
                                      ),
                                    );
                                  }
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: slotTokens.gold.withValues(
                                        alpha: isDark ? 0.22 : 0.16,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                      border: Border.all(
                                        color: slotTokens.gold.withValues(
                                          alpha: isDark ? 0.55 : 0.45,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                  );
                                }),
                            padding: const EdgeInsets.all(6.0),
                            horizontalSpace: 6.0,
                            verticalSpace: 6.0,
                            slotAspectRatio: aspectRatio,
                            animateEverytime: false,
                            dashboardItemController: itemController,
                            slotCount: slot ?? 2,
                            errorPlaceholder: (e, s) {
                              return Text("$e , $s");
                            },
                            emptyPlaceholder: _isEditing
                                ? Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 280,
                                        maxHeight: 220,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.lg,
                                        ),
                                        child: EmptySlotTile(
                                          onTap: _openSidebarForAdd,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.dashboard_customize,
                                            size: 48,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(height: AppSpacing.lg),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            ).noWidgetsSelected,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: t.textSecondary,
                                                ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            ).openMenuEnableWidgets,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(color: t.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            itemStyle: ItemStyle(
                              color: Colors.transparent,
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.card,
                                ),
                              ),
                            ),
                            physics: const RangeMaintainingScrollPhysics(),
                            editModeSettings: EditModeSettings(
                              draggableOutside: false,
                              paintBackgroundLines: true,
                              autoScroll: true,
                              resizeCursorSide: 15,
                              curve: AppMotion.emphasized,
                              duration: AppMotion.medium,
                              swapEnabled: true,
                              swapHighlightColor: t.gold,
                              backgroundStyle: EditModeBackgroundStyle(
                                lineColor: t.border,
                                fillColor: t.gold.withValues(alpha: 0.08),
                                lineWidth: 1,
                                dualLineHorizontal: false,
                                dualLineVertical: false,
                              ),
                            ),
                            itemBuilder: (ColoredDashboardItem item) {
                              var layout = item.layoutData;
                              final isEditing = _isEditing;

                              if (item.data != null) {
                                return _wrapWithEditChrome(
                                  isEditing: isEditing,
                                  item: item,
                                  child: DataWidget(item: item),
                                );
                              }

                              return LayoutBuilder(
                                builder: (_, c) {
                                  final placeholder = AppCard(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: Text(
                                        "ID: ${item.identifier}\n${["x: ${layout.startX}", "y: ${layout.startY}", "w: ${layout.width}", "h: ${layout.height}"].join("\n")}",
                                        style: TextStyle(color: t.text),
                                      ),
                                    ),
                                  );
                                  return _wrapWithEditChrome(
                                    isEditing: isEditing,
                                    item: item,
                                    child: placeholder,
                                  );
                                },
                              );
                            },
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, {Color? color}) {
    final resolved = color ?? context.tokens.text;
    return Row(
      children: [
        Icon(icon, color: resolved, size: 20),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: TextStyle(color: resolved)),
      ],
    );
  }

  /// Wraps a dashboard item with the edit-mode chrome (dashed outline,
  /// drag handle, overflow menu, resize handles) when [isEditing] is true.
  /// When idle, returns the child unchanged.
  Widget _wrapWithEditChrome({
    required bool isEditing,
    required ColoredDashboardItem item,
    required Widget child,
  }) {
    if (!isEditing) return child;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        WidgetEditChrome(
          onAction: (action) => _handleWidgetAction(action, item),
        ),
      ],
    );
  }

  Future<void> _handleWidgetAction(
    WidgetEditAction action,
    ColoredDashboardItem item,
  ) async {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case WidgetEditAction.remove:
        // Both calls are needed: delete() removes the item from the
        // in-memory grid; removeWidgetInstance() removes it from the
        // persisted widgetVisibility map.
        _itemController.delete(item.identifier);
        await ref
            .read(dashboardNotifierProvider.notifier)
            .removeWidgetInstance(item.identifier);
        break;
      case WidgetEditAction.rename:
      case WidgetEditAction.duplicate:
      case WidgetEditAction.lock:
      case WidgetEditAction.resetSize:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.editModeActionUnavailable)),
          );
        }
        break;
    }
  }

  Future<void> _handleMenuAction(String action) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(dashboardNotifierProvider.notifier);
    switch (action) {
      case 'save':
        await notifier.saveLayout();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.layoutSaved)));
        }
        break;
      case 'reset':
        _lastVisibilityKey = [];
        await notifier.resetToSaved();
        if (mounted) {
          final dashState = ref.read(dashboardNotifierProvider);
          _recreateStorageAndController(
            dashState.activeDashboardId,
            notifier.getVisibleWidgets(),
          );
        }
        break;
      case 'hardReset':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.hardResetDashboard),
            content: Text(l10n.hardResetWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n.confirm,
                  style: TextStyle(color: ctx.tokens.error.text),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            final dashState = ref.read(dashboardNotifierProvider);
            final dashId = dashState.activeDashboardId;
            _lastVisibilityKey = [];
            await notifier.hardReset();
            if (mounted) {
              _recreateStorageAndController(
                dashId,
                notifier.getVisibleWidgets(),
              );
            }
          } catch (e, stackTrace) {
            debugPrint('=== HARD RESET ERROR ===');
            debugPrint('$e');
            debugPrint('$stackTrace');
          }
        }
        break;
      case 'rename':
        await _showRenameDashboardDialog();
        break;
      case 'delete':
        final dashState = ref.read(dashboardNotifierProvider);
        if (dashState.dashboards.length <= 1) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.deleteDashboard),
            content: Text(l10n.deleteWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n.delete,
                  style: TextStyle(color: ctx.tokens.error.text),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          final currentDashState = ref.read(dashboardNotifierProvider);
          final oldId = currentDashState.activeDashboardId;
          await notifier.deleteDashboard(oldId);
          if (mounted) {
            final newDashState = ref.read(dashboardNotifierProvider);
            _recreateStorageAndController(
              newDashState.activeDashboardId,
              notifier.getVisibleWidgets(),
            );
          }
        }
        break;
    }
  }

  Future<void> _showCreateDashboardDialog() async {
    final dashState = ref.read(dashboardNotifierProvider);
    final notifier = ref.read(dashboardNotifierProvider.notifier);
    final result = await showDialog<CreateDashboardResult>(
      context: context,
      builder: (ctx) => CreateDashboardDialog(
        existingNames: dashState.dashboards.map((d) => d.name).toList(),
      ),
    );
    if (result != null) {
      await notifier.createDashboard(
        name: result.name,
        useDefaults: result.useDefaults,
      );
      if (mounted) {
        final newDashState = ref.read(dashboardNotifierProvider);
        _recreateStorageAndController(
          newDashState.activeDashboardId,
          notifier.getVisibleWidgets(),
        );
      }
    }
  }

  Future<void> _showRenameDashboardDialog() async {
    final l10n = AppLocalizations.of(context);
    final dashState = ref.read(dashboardNotifierProvider);
    final notifier = ref.read(dashboardNotifierProvider.notifier);
    final controller = TextEditingController(
      text: dashState.activeDashboard.name,
    );
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renameDashboard),
        content: TextField(
          controller: controller,
          maxLength: 20,
          decoration: InputDecoration(labelText: l10n.dashboardName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx, name);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && newName.isNotEmpty) {
      final currentDashState = ref.read(dashboardNotifierProvider);
      await notifier.renameDashboard(
        currentDashState.activeDashboardId,
        newName,
      );
    }
  }

  Widget _buildWidgetPreview(String widgetId) {
    final dummyItem = ColoredDashboardItem(
      color: context.tokens.brandNavy,
      width: 2,
      height: 2,
      startX: 0,
      startY: 0,
      identifier: 'preview',
      data: widgetId,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${AppLocalizations.of(context).widgetPreview}: $widgetId',
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedWidget = null;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: DataWidget(item: dummyItem),
          ),
        ),
      ],
    );
  }
}
