import 'dart:ui';

import 'package:dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data_widget.dart';
import '../sidebar_menu.dart';
import '../storage.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/create_dashboard_dialog.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class MySlotBackground extends SlotBackgroundBuilder<ColoredDashboardItem> {
  @override
  Widget? buildBackground(
    BuildContext context,
    ColoredDashboardItem? item,
    int x,
    int y,
    bool editing,
    bool isSwapTarget,
  ) {
    if (item != null) {
      return GlassContainer(
        color: isSwapTarget ? const Color(0xFF4CAF50) : Colors.red,
        opacity: isSwapTarget ? 0.3 : 0.2,
        borderRadius: AppRadius.md,
      );
    }

    return null;
  }
}

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget>
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

  @override
  void initState() {
    super.initState();
    final dashProvider = Provider.of<DashboardProvider>(context, listen: false);
    _lastDashboardId = dashProvider.activeDashboardId;
    storage = MyItemStorage(dashboardId: dashProvider.activeDashboardId);
    _itemController = DashboardItemController<ColoredDashboardItem>.withDelegate(
      itemStorageDelegate: storage,
    );
  }

  setSlot() {
    var w = MediaQuery.of(context).size.width;
    setState(() {
      slot = w > 600
          ? w > 900
                ? 6
                : 4
          : 2;
    });
  }

  void _recreateStorageAndController(String dashboardId, List<String> visibleWidgets) {
    storage = MyItemStorage(dashboardId: dashboardId);
    storage.setVisibilityFilter(visibleWidgets);

    _itemController = DashboardItemController.withDelegate(
      itemStorageDelegate: storage,
    );
    _controllerVersion++;

    if (mounted) {
      setState(() {});
    }
  }

  void _updateHiddenItems(List<String> visibleWidgets) {
    final dashProvider = Provider.of<DashboardProvider>(context, listen: false);
    _recreateStorageAndController(dashProvider.activeDashboardId, visibleWidgets);
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

    return Scaffold(
      drawer: SidebarMenu(
        onMenuItemSelected: (widgetId) {
          setState(() {
            _selectedWidget = widgetId;
          });
        },
        onWidgetAdded: (instanceId, widgetType) {
          final item = storage.createDefaultItem(instanceId, widgetType, slot ?? 2);
          _itemController.add(item);
        },
        onWidgetRemoved: (instanceId) {
          _itemController.delete(instanceId);
        },
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark.withValues(alpha: 0.3)
            : AppColors.primary.withValues(alpha: 0.2),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        automaticallyImplyLeading: true,
        title: Consumer<DashboardProvider>(
          builder: (context, dashProvider, _) {
            return PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == '__new__') {
                  await _showCreateDashboardDialog(dashProvider);
                } else {
                  dashProvider.setActiveDashboard(value);
                }
              },
              offset: const Offset(0, 40),
              color: AppColors.menuBackground.withValues(alpha: 0.95),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      dashProvider.activeDashboard.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.0,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.accent
                            : AppColors.textOnLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.accent
                        : AppColors.textOnLight,
                  ),
                ],
              ),
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];
                for (final dash in dashProvider.dashboards) {
                  items.add(PopupMenuItem<String>(
                    value: dash.id,
                    child: Row(
                      children: [
                        if (dash.id == dashProvider.activeDashboardId)
                          const Icon(Icons.check, color: AppColors.primary, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dash.name,
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ));
                }
                if (dashProvider.canCreateDashboard) {
                  items.add(const PopupMenuDivider());
                  items.add(PopupMenuItem<String>(
                    value: '__new__',
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          l10n.newDashboard,
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ));
                }
                return items;
              },
            );
          },
        ),
        actions: [
          Consumer<DashboardProvider>(
            builder: (context, dashProvider, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                color: AppColors.menuBackground.withValues(alpha: 0.95),
                onSelected: (value) => _handleMenuAction(value, dashProvider),
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
                    enabled: dashProvider.dashboards.length > 1,
                    value: 'delete',
                    child: _menuItem(Icons.delete_outline, l10n.deleteDashboard,
                        color: dashProvider.dashboards.length > 1
                            ? Colors.redAccent
                            : Colors.grey),
                  ),
                ],
              );
            },
          ),
          IconButton(
            onPressed: () {
              _itemController.isEditing = !_itemController.isEditing;
              setState(() {});
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dashProvider, _) {
            // Detect dashboard switch
            if (_lastDashboardId != dashProvider.activeDashboardId) {
              _lastDashboardId = dashProvider.activeDashboardId;
              _lastVisibilityKey = [];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _recreateStorageAndController(
                  dashProvider.activeDashboardId,
                  dashProvider.getVisibleWidgets(),
                );
              });
            }

            final visibleWidgets = dashProvider.getVisibleWidgets();
            final visibilityKey = visibleWidgets.join(',');

            final oldKey = _lastVisibilityKey.isNotEmpty ? _lastVisibilityKey.first : '';
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
                : Dashboard<ColoredDashboardItem>(
                          key: ValueKey('${dashProvider.activeDashboardId}_${visibleWidgets.join(',')}_$_controllerVersion'),
                          shrinkToPlace: true,
                          slideToTop: true,
                          absorbPointer: false,
                          slotBackgroundBuilder: SlotBackgroundBuilder.withFunction(
                            (context, item, x, y, editing) {
                              return const GlassContainer(
                                borderRadius: AppRadius.md,
                                borderOpacity: 0.1,
                                opacity: 0.05,
                              );
                            },
                          ),
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
                          emptyPlaceholder: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                const Icon(Icons.dashboard_customize,
                                    size: 48, color: Colors.grey),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  AppLocalizations.of(context).noWidgetsSelected,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  AppLocalizations.of(context).openMenuEnableWidgets,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                              ),
                            ),
                          ),
                          itemStyle: ItemStyle(
                            color: Colors.transparent,
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          physics: const RangeMaintainingScrollPhysics(),
                          editModeSettings: EditModeSettings(
                            draggableOutside: false,
                            paintBackgroundLines: true,
                            autoScroll: true,
                            resizeCursorSide: 15,
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 150),
                            swapEnabled: true,
                            backgroundStyle: const EditModeBackgroundStyle(
                              lineColor: Colors.white24,
                              lineWidth: 1,
                              dualLineHorizontal: false,
                              dualLineVertical: false,
                            ),
                          ),
                          itemBuilder: (ColoredDashboardItem item) {
                            var layout = item.layoutData;

                            if (item.data != null) {
                              return DataWidget(item: item);
                            }

                            return LayoutBuilder(
                              builder: (_, c) {
                                return Stack(
                                  children: [
                                    GlassContainer(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      color: item.color,
                                      opacity: 0.3,
                                      borderRadius: AppRadius.md,
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: Text(
                                          "ID: ${item.identifier}\n${["x: ${layout.startX}", "y: ${layout.startY}", "w: ${layout.width}", "h: ${layout.height}"].join("\n")}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_itemController.isEditing)
                                      Positioned(
                                        right: AppSpacing.xs,
                                        top: AppSpacing.xs,
                                        child: InkResponse(
                                          radius: 20,
                                          onTap: () {
                                            _itemController.delete(item.identifier);
                                          },
                                          child: const Icon(
                                            Icons.clear,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        );
          },
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, {Color color = Colors.white}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  Future<void> _handleMenuAction(String action, DashboardProvider dashProvider) async {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case 'save':
        await dashProvider.saveLayout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.layoutSaved)),
          );
        }
        break;
      case 'reset':
        _lastVisibilityKey = [];
        await dashProvider.resetToSaved();
        if (mounted) {
          _recreateStorageAndController(
            dashProvider.activeDashboardId,
            dashProvider.getVisibleWidgets(),
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
                child: Text(l10n.confirm, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            final dashId = dashProvider.activeDashboardId;
            _lastVisibilityKey = [];
            await dashProvider.hardReset();
            if (mounted) {
              _recreateStorageAndController(
                dashId,
                dashProvider.getVisibleWidgets(),
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
        await _showRenameDashboardDialog(dashProvider);
        break;
      case 'delete':
        if (dashProvider.dashboards.length <= 1) return;
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
                child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          final oldId = dashProvider.activeDashboardId;
          await dashProvider.deleteDashboard(oldId);
          if (mounted) {
            _recreateStorageAndController(
              dashProvider.activeDashboardId,
              dashProvider.getVisibleWidgets(),
            );
          }
        }
        break;
    }
  }

  Future<void> _showCreateDashboardDialog(DashboardProvider dashProvider) async {
    final result = await showDialog<CreateDashboardResult>(
      context: context,
      builder: (ctx) => CreateDashboardDialog(
        existingNames: dashProvider.dashboards.map((d) => d.name).toList(),
      ),
    );
    if (result != null) {
      await dashProvider.createDashboard(
        name: result.name,
        useDefaults: result.useDefaults,
      );
      if (mounted) {
        _recreateStorageAndController(
          dashProvider.activeDashboardId,
          dashProvider.getVisibleWidgets(),
        );
      }
    }
  }

  Future<void> _showRenameDashboardDialog(DashboardProvider dashProvider) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: dashProvider.activeDashboard.name,
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
      await dashProvider.renameDashboard(
        dashProvider.activeDashboardId,
        newName,
      );
    }
  }

  Widget _buildWidgetPreview(String widgetId) {
    final dummyItem = ColoredDashboardItem(
      color: Colors.blue,
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: DataWidget(item: dummyItem),
          ),
        ),
      ],
    );
  }
}
