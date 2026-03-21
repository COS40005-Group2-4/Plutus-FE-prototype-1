import 'dart:ui';

import 'package:dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data_widget.dart';
import '../sidebar_menu.dart';
import '../storage.dart';
import '../providers/widget_visibility_provider.dart';
import '../widgets/glass_container.dart';
import '../l10n/app_localizations.dart';

class MySlotBackground extends SlotBackgroundBuilder<ColoredDashboardItem> {
  @override
  Widget? buildBackground(
    BuildContext context,
    ColoredDashboardItem? item,
    int x,
    int y,
    bool editing,
  ) {
    if (item != null) {
      return GlassContainer(
        color: Colors.red,
        opacity: 0.2,
        borderRadius: 10,
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

class _DashboardWidgetState extends State<DashboardWidget> {
  final ScrollController scrollController = ScrollController();

  late DashboardItemController<ColoredDashboardItem> _itemController;

  bool refreshing = false;

  late MyItemStorage storage;

  DashboardItemController<ColoredDashboardItem> get itemController =>
      _itemController;

  int? slot;
  String? _selectedWidget;

  List<String> _lastVisibilityKey = [];

  @override
  void initState() {
    super.initState();
    storage = MyItemStorage();
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

  void _updateHiddenItems(List<String> visibleWidgets) async {
    setState(() {
      refreshing = true;
    });

    storage = MyItemStorage();
    storage.setVisibilityFilter(visibleWidgets);

    _itemController = DashboardItemController.withDelegate(
      itemStorageDelegate: storage,
    );

    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      setState(() {
        refreshing = false;
      });
    }
  }

  double _getAspectRatio(double width) {
    if (width < 600) return 0.85;
    if (width < 900) return 0.95;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    slot = w > 600
        ? w > 900
              ? 6
              : 4
        : 2;
    final aspectRatio = _getAspectRatio(w);
    return Scaffold(
      drawer: SidebarMenu(
        onMenuItemSelected: (widgetId) {
          setState(() {
            _selectedWidget = widgetId;
          });
        },
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A3A4A).withValues(alpha: 0.3)
            : const Color(0xFF4285F4).withValues(alpha: 0.2),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        automaticallyImplyLeading: true,
        title: Text(
          'PLUTUS',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF5DADE2)
                : Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              // Reset visibility checkboxes to all-visible
              final visibilityProvider = Provider.of<WidgetVisibilityProvider>(
                context, listen: false,
              );
              visibilityProvider.reset();

              await storage.clear();
              setState(() {
                refreshing = true;
              });
              storage = MyItemStorage();
              _itemController = DashboardItemController.withDelegate(
                itemStorageDelegate: storage,
              );
              Future.delayed(const Duration(milliseconds: 150)).then((value) {
                setState(() {
                  refreshing = false;
                });
              });
            },
            icon: const Icon(Icons.refresh),
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
        child: Consumer<WidgetVisibilityProvider>(
          builder: (context, visibilityProvider, _) {
            final visibleWidgets = visibilityProvider.getVisibleWidgets();
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
                : (refreshing
                      ? const Center(child: CircularProgressIndicator())
                      : Dashboard<ColoredDashboardItem>(
                          key: ValueKey(visibleWidgets.join(',')),
                          shrinkToPlace: true,
                          slideToTop: true,
                          absorbPointer: false,
                          slotBackgroundBuilder: SlotBackgroundBuilder.withFunction(
                            (context, item, x, y, editing) {
                              return const GlassContainer(
                                borderRadius: 10,
                                borderOpacity: 0.1,
                                opacity: 0.05,
                              );
                            },
                          ),
                          padding: const EdgeInsets.all(8),
                          horizontalSpace: 8,
                          verticalSpace: 8,
                          slotAspectRatio: aspectRatio,
                          animateEverytime: true,
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
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context).noWidgetsSelected,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
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
                              borderRadius: BorderRadius.circular(15),
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
                                      padding: const EdgeInsets.all(10),
                                      color: item.color,
                                      opacity: 0.3,
                                      borderRadius: 10,
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
                                        right: 5,
                                        top: 5,
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
                        ));
          },
        ),
      ),
    );
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Widget Preview: $widgetId',
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
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataWidget(item: dummyItem),
          ),
        ),
      ],
    );
  }
}
