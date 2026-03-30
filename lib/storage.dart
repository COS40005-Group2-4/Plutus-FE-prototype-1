import 'dart:async';
import 'dart:convert';

import 'package:dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/widget_catalog.dart';
import 'models/dashboard_config.dart';

class ColoredDashboardItem extends DashboardItem {
  ColoredDashboardItem({
    this.color,
    required super.width,
    required super.height,
    required super.identifier,
    this.data,
    super.startX,
    super.startY,
    super.minWidth,
    super.minHeight,
  });

  ColoredDashboardItem.fromMap(Map<String, dynamic> map)
    : color = map["color"] != null ? Color((map["color"] is int ? map["color"] : (map["color"] as double).toInt())) : null,
      data = map["data"],
      super.withLayout(map["item_id"], ItemLayout.fromMap(map["layout"]));

  Color? color;

  String? data;

  @override
  Map<String, dynamic> toMap() {
    var sup = super.toMap();
    if (color != null) {
      sup["color"] = color!.toARGB32;
    }
    if (data != null) {
      sup["data"] = data;
    }
    return sup;
  }
}

class MyItemStorage extends DashboardItemStorageDelegate<ColoredDashboardItem> {
  final String dashboardId;

  MyItemStorage({this.dashboardId = 'default'});

  late SharedPreferences _preferences;

  final List<int> _slotCounts = [2, 4, 6];

  List<String> visibilityFilter = ['profile_0', 'budget_0', 'categoryBudget_0', 'history_0', 'import_0', 'export_0', 'roi_0', 'irr_0', 'investment_0', 'cashflow_0', 'bills_0', 'tax_0', 'expenseBreakdown_0', 'portfolioAllocation_0', 'netWorthTrend_0', 'spendingHeatmap_0', 'incomeTrend_0', 'savingsRate_0', 'marketTrending_0', 'insightsFeed_0', 'healthScore_0', 'cashFlowForecast_0', 'coachingTips_0'];

  void setVisibilityFilter(List<String> visibleWidgets) {
    visibilityFilter = visibleWidgets;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Default layouts — one entry per column count.
  //
  // Grouping logic (top → bottom) — Budget-First Story:
  //   Hero       : profile, budget, categoryBudget
  //   Spending   : savingsRate, expenseBreakdown, spendingHeatmap
  //   Activity   : history, cashflow
  //   Obligations: bills, tax, roi, irr
  //   Wealth     : netWorthTrend, incomeTrend
  //   Investments: investment, portfolioAllocation, marketTrending
  //   Tools      : import, export
  //   Insights   : insightsFeed, healthScore, cashFlowForecast, coachingTips
  // ─────────────────────────────────────────────────────────────────────────
  final Map<int, List<ColoredDashboardItem>> _default = {

    // ── 2-COLUMN (mobile) ─────────────────────────────────────────────────
    2: <ColoredDashboardItem>[
      // Hero
      ColoredDashboardItem(startX: 0, startY: 0,  width: 2, height: 2, identifier: "profile_0",             data: "profile"),
      ColoredDashboardItem(startX: 0, startY: 2,  width: 2, height: 1, identifier: "budget_0",              data: "budget"),
      ColoredDashboardItem(startX: 0, startY: 3,  width: 2, height: 2, identifier: "categoryBudget_0",      data: "categoryBudget"),
      // Spending
      ColoredDashboardItem(startX: 0, startY: 5,  width: 2, height: 2, identifier: "savingsRate_0",         data: "savingsRate"),
      ColoredDashboardItem(startX: 0, startY: 7,  width: 2, height: 2, identifier: "expenseBreakdown_0",    data: "expenseBreakdown"),
      ColoredDashboardItem(startX: 0, startY: 9,  width: 2, height: 2, identifier: "spendingHeatmap_0",     data: "spendingHeatmap"),
      // Activity
      ColoredDashboardItem(startX: 0, startY: 11, width: 2, height: 4, identifier: "history_0",             data: "history"),
      ColoredDashboardItem(startX: 0, startY: 15, width: 2, height: 2, identifier: "cashflow_0",            data: "cashflow"),
      // Obligations
      ColoredDashboardItem(startX: 0, startY: 17, width: 2, height: 2, identifier: "bills_0",               data: "bills",           minWidth: 2),
      ColoredDashboardItem(startX: 0, startY: 19, width: 2, height: 2, identifier: "tax_0",                 data: "tax"),
      ColoredDashboardItem(startX: 0, startY: 21, width: 1, height: 1, identifier: "roi_0",                 data: "roi"),
      ColoredDashboardItem(startX: 1, startY: 21, width: 1, height: 1, identifier: "irr_0",                 data: "irr"),
      // Wealth
      ColoredDashboardItem(startX: 0, startY: 22, width: 2, height: 2, identifier: "netWorthTrend_0",       data: "netWorthTrend",   minWidth: 2),
      ColoredDashboardItem(startX: 0, startY: 24, width: 2, height: 2, identifier: "incomeTrend_0",         data: "incomeTrend",     minWidth: 2),
      // Investments
      ColoredDashboardItem(startX: 0, startY: 26, width: 2, height: 3, identifier: "investment_0",          data: "investment"),
      ColoredDashboardItem(startX: 0, startY: 29, width: 2, height: 2, identifier: "portfolioAllocation_0", data: "portfolioAllocation"),
      ColoredDashboardItem(startX: 0, startY: 31, width: 2, height: 3, identifier: "marketTrending_0",      data: "marketTrending", minWidth: 2),
      // Tools
      ColoredDashboardItem(startX: 0, startY: 34, width: 1, height: 1, identifier: "import_0",              data: "import"),
      ColoredDashboardItem(startX: 1, startY: 34, width: 1, height: 1, identifier: "export_0",              data: "export"),
      // Insights
      ColoredDashboardItem(startX: 0, startY: 35, width: 2, height: 2, identifier: "healthScore_0",         data: "healthScore"),
      ColoredDashboardItem(startX: 0, startY: 37, width: 2, height: 3, identifier: "insightsFeed_0",        data: "insightsFeed"),
      ColoredDashboardItem(startX: 0, startY: 40, width: 2, height: 2, identifier: "cashFlowForecast_0",    data: "cashFlowForecast"),
      ColoredDashboardItem(startX: 0, startY: 42, width: 2, height: 2, identifier: "coachingTips_0",        data: "coachingTips"),
    ],

    // ── 4-COLUMN (tablet) ─────────────────────────────────────────────────
    4: <ColoredDashboardItem>[
      // Hero: profile + budget side by side, savingsRate fills under budget
      ColoredDashboardItem(startX: 0, startY: 0,  width: 2, height: 2, identifier: "profile_0",             data: "profile"),
      ColoredDashboardItem(startX: 2, startY: 0,  width: 2, height: 1, identifier: "budget_0",              data: "budget"),
      ColoredDashboardItem(startX: 2, startY: 1,  width: 2, height: 2, identifier: "savingsRate_0",         data: "savingsRate"),
      ColoredDashboardItem(startX: 0, startY: 2,  width: 2, height: 2, identifier: "categoryBudget_0",      data: "categoryBudget"),
      // Spending: stagger expenseBreakdown + spendingHeatmap so rows align cleanly
      ColoredDashboardItem(startX: 0, startY: 4,  width: 2, height: 2, identifier: "expenseBreakdown_0",    data: "expenseBreakdown"),
      ColoredDashboardItem(startX: 2, startY: 4,  width: 2, height: 2, identifier: "spendingHeatmap_0",     data: "spendingHeatmap"),
      ColoredDashboardItem(startX: 0, startY: 6,  width: 2, height: 2, identifier: "tax_0",                 data: "tax"),
      // Activity: history (3-wide) + roi/irr in last col, no gaps
      ColoredDashboardItem(startX: 0, startY: 8,  width: 3, height: 4, identifier: "history_0",             data: "history"),
      ColoredDashboardItem(startX: 3, startY: 8,  width: 1, height: 1, identifier: "roi_0",                 data: "roi"),
      ColoredDashboardItem(startX: 3, startY: 9,  width: 1, height: 1, identifier: "irr_0",                 data: "irr"),
      ColoredDashboardItem(startX: 0, startY: 12, width: 4, height: 2, identifier: "cashflow_0",            data: "cashflow"),
      // Obligations
      ColoredDashboardItem(startX: 0, startY: 14, width: 2, height: 2, identifier: "bills_0",               data: "bills",           minWidth: 2),
      ColoredDashboardItem(startX: 2, startY: 14, width: 2, height: 2, identifier: "portfolioAllocation_0", data: "portfolioAllocation"),
      // Wealth: full-width to prevent squishing
      ColoredDashboardItem(startX: 0, startY: 16, width: 4, height: 2, identifier: "netWorthTrend_0",       data: "netWorthTrend",   minWidth: 2),
      ColoredDashboardItem(startX: 0, startY: 18, width: 4, height: 2, identifier: "incomeTrend_0",         data: "incomeTrend",     minWidth: 2),
      // Investments
      ColoredDashboardItem(startX: 0, startY: 20, width: 3, height: 3, identifier: "investment_0",          data: "investment"),
      ColoredDashboardItem(startX: 0, startY: 23, width: 3, height: 3, identifier: "marketTrending_0",      data: "marketTrending", minWidth: 2),
      // Tools
      ColoredDashboardItem(startX: 0, startY: 26, width: 1, height: 1, identifier: "import_0",              data: "import"),
      ColoredDashboardItem(startX: 1, startY: 26, width: 1, height: 1, identifier: "export_0",              data: "export"),
      // Insights
      ColoredDashboardItem(startX: 0, startY: 27, width: 2, height: 2, identifier: "healthScore_0",         data: "healthScore"),
      ColoredDashboardItem(startX: 2, startY: 27, width: 2, height: 2, identifier: "coachingTips_0",        data: "coachingTips"),
      ColoredDashboardItem(startX: 0, startY: 29, width: 3, height: 3, identifier: "insightsFeed_0",        data: "insightsFeed"),
      ColoredDashboardItem(startX: 0, startY: 32, width: 4, height: 2, identifier: "cashFlowForecast_0",    data: "cashFlowForecast"),
    ],

    // ── 6-COLUMN (desktop) ────────────────────────────────────────────────
    6: <ColoredDashboardItem>[
      // Hero: profile | budget + savingsRate | categoryBudget
      ColoredDashboardItem(startX: 0, startY: 0,  width: 2, height: 2, identifier: "profile_0",             data: "profile"),
      ColoredDashboardItem(startX: 2, startY: 0,  width: 2, height: 1, identifier: "budget_0",              data: "budget"),
      ColoredDashboardItem(startX: 4, startY: 0,  width: 2, height: 2, identifier: "categoryBudget_0",      data: "categoryBudget"),
      ColoredDashboardItem(startX: 2, startY: 1,  width: 2, height: 2, identifier: "savingsRate_0",         data: "savingsRate"),
      // Spending: expenseBreakdown | roi+irr | portfolioAllocation
      ColoredDashboardItem(startX: 0, startY: 2,  width: 2, height: 2, identifier: "expenseBreakdown_0",    data: "expenseBreakdown"),
      ColoredDashboardItem(startX: 2, startY: 3,  width: 1, height: 1, identifier: "roi_0",                 data: "roi"),
      ColoredDashboardItem(startX: 3, startY: 3,  width: 1, height: 1, identifier: "irr_0",                 data: "irr"),
      ColoredDashboardItem(startX: 4, startY: 2,  width: 2, height: 2, identifier: "portfolioAllocation_0", data: "portfolioAllocation"),
      // Analytics: spendingHeatmap | tax
      ColoredDashboardItem(startX: 0, startY: 4,  width: 2, height: 2, identifier: "spendingHeatmap_0",     data: "spendingHeatmap"),
      ColoredDashboardItem(startX: 2, startY: 4,  width: 2, height: 2, identifier: "tax_0",                 data: "tax"),
      // Activity: history | cashflow
      ColoredDashboardItem(startX: 0, startY: 6,  width: 3, height: 4, identifier: "history_0",             data: "history"),
      ColoredDashboardItem(startX: 3, startY: 6,  width: 3, height: 2, identifier: "cashflow_0",            data: "cashflow"),
      // Obligations: bills
      ColoredDashboardItem(startX: 3, startY: 8,  width: 2, height: 2, identifier: "bills_0",               data: "bills",           minWidth: 2),
      // Wealth: netWorthTrend | incomeTrend (3+3 = 6 cols)
      ColoredDashboardItem(startX: 0, startY: 10, width: 3, height: 2, identifier: "netWorthTrend_0",       data: "netWorthTrend",   minWidth: 2),
      ColoredDashboardItem(startX: 3, startY: 10, width: 3, height: 2, identifier: "incomeTrend_0",         data: "incomeTrend",     minWidth: 2),
      // Investments: investment | marketTrending (3+3 = 6 cols)
      ColoredDashboardItem(startX: 0, startY: 12, width: 3, height: 3, identifier: "investment_0",          data: "investment"),
      ColoredDashboardItem(startX: 3, startY: 12, width: 3, height: 3, identifier: "marketTrending_0",      data: "marketTrending", minWidth: 2),
      // Tools
      ColoredDashboardItem(startX: 0, startY: 15, width: 1, height: 1, identifier: "import_0",              data: "import"),
      ColoredDashboardItem(startX: 1, startY: 15, width: 1, height: 1, identifier: "export_0",              data: "export"),
      // Insights
      ColoredDashboardItem(startX: 0, startY: 16, width: 3, height: 3, identifier: "insightsFeed_0",        data: "insightsFeed"),
      ColoredDashboardItem(startX: 3, startY: 16, width: 2, height: 2, identifier: "healthScore_0",         data: "healthScore"),
      ColoredDashboardItem(startX: 5, startY: 16, width: 1, height: 2, identifier: "coachingTips_0",        data: "coachingTips"),
      ColoredDashboardItem(startX: 3, startY: 18, width: 3, height: 2, identifier: "cashFlowForecast_0",    data: "cashFlowForecast"),
    ],
  };

  Map<int, Map<String, ColoredDashboardItem>>? _localItems;

  @override
  FutureOr<List<ColoredDashboardItem>> getAllItems(int slotCount) {
    try {
      if (_localItems != null) {
        final allItems = _localItems?[slotCount]?.values.toList() ?? <ColoredDashboardItem>[];
        return allItems.where((item) {
          if (item.data == null) return true;
          return visibilityFilter.contains(item.identifier);
        }).toList();
      }

      return Future.microtask(() async {
        _preferences = await SharedPreferences.getInstance();

        // v3: bump whenever _default changes to force re-initialization.
        var init = _preferences.getBool("init_${dashboardId}_v4") ?? false;

        if (!init) {
          _localItems = {
            for (var s in _slotCounts)
              s: _default[s]!.asMap().map(
                (key, value) => MapEntry(value.identifier, value),
              ),
          };

          for (var s in _slotCounts) {
            await _preferences.setString(
              "layout_data_${dashboardId}_$s",
              json.encode(
                _default[s]!.asMap().map(
                  (key, value) => MapEntry(value.identifier, value.toMap()),
                ),
              ),
            );
          }

          await _preferences.setBool("init_${dashboardId}_v4", true);
        } else {
          // Load existing layout data or use defaults
          _localItems = {};
          for (var s in _slotCounts) {
            var layoutDataStr = _preferences.getString("layout_data_${dashboardId}_$s");
            if (layoutDataStr != null) {
              var js = json.decode(layoutDataStr) as Map<String, dynamic>;
              var loadedItems = js.map<String, ColoredDashboardItem>(
                (key, value) => MapEntry(key, ColoredDashboardItem.fromMap(value)),
              );

              // Migrate old identifiers: "budget" → "budget_0"
              final migratedItems = <String, ColoredDashboardItem>{};
              for (final entry in loadedItems.entries) {
                final key = entry.key;
                final item = entry.value;
                if (DashboardConfig.typeFromInstanceId(key) == key) {
                  // Old format — migrate
                  final newId = DashboardConfig.makeInstanceId(key, 0);
                  migratedItems[newId] = ColoredDashboardItem(
                    startX: item.layoutData.startX,
                    startY: item.layoutData.startY,
                    width: item.layoutData.width,
                    height: item.layoutData.height,
                    identifier: newId,
                    data: item.data ?? key,
                    color: item.color,
                    minWidth: item.layoutData.minWidth,
                    minHeight: item.layoutData.minHeight,
                  );
                } else {
                  migratedItems[key] = item;
                }
              }
              loadedItems = migratedItems;

              // Merge with defaults to add any new widgets
              var defaultItems = _default[s]!.asMap().map(
                (key, value) => MapEntry(value.identifier, value),
              );

              // Add any new widgets from defaults that don't exist in loaded items
              for (var entry in defaultItems.entries) {
                if (!loadedItems.containsKey(entry.key)) {
                  loadedItems[entry.key] = entry.value;
                }
              }

              // Enforce minimum widths for widgets that require them
              for (var entry in loadedItems.entries) {
                final widgetType = DashboardConfig.typeFromInstanceId(entry.key);
                if (widgetType == 'marketTrending' || widgetType == 'bills') {
                  var item = entry.value;
                  if (item.layoutData.minWidth < 2) {
                    loadedItems[entry.key] = ColoredDashboardItem(
                      startX: item.layoutData.startX,
                      startY: item.layoutData.startY,
                      width: item.layoutData.width < 2 ? 2 : item.layoutData.width,
                      height: item.layoutData.height,
                      identifier: item.identifier,
                      data: item.data,
                      color: item.color,
                      minWidth: 2,
                    );
                  }
                }
              }

              _localItems![s] = loadedItems;
            } else {
              // Use default if data doesn't exist
              _localItems![s] = _default[s]!.asMap().map(
                (key, value) => MapEntry(value.identifier, value),
              );
            }
          }
        }

        var layoutData = _localItems?[slotCount];
        if (layoutData != null) {
          final allItems = layoutData.values.toList();
          return allItems.where((item) {
            if (item.data == null) return true;
            return visibilityFilter.contains(item.identifier);
          }).toList();
        }

        // Fallback to default if slot count not found
        final defaultItems = _default[slotCount] ?? [];
        return defaultItems.where((item) {
          if (item.data == null) return true;
          return visibilityFilter.contains(item.identifier);
        }).toList();
      });
    } on Exception {
      rethrow;
    }
  }

  @override
  FutureOr<void> onItemsUpdated(
    List<ColoredDashboardItem> items,
    int slotCount,
  ) async {
    _setLocal();

    for (var item in items) {
      _localItems?[slotCount]?[item.identifier] = item;
    }

    final slotItems = _localItems?[slotCount];
    if (slotItems != null) {
      var js = json.encode(
        slotItems.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
      );

      await _preferences.setString("layout_data_${dashboardId}_$slotCount", js);
    }
  }

  @override
  FutureOr<void> onItemsAdded(
    List<ColoredDashboardItem> items,
    int slotCount,
  ) async {
    _setLocal();
    for (var s in _slotCounts) {
      for (var i in items) {
        _localItems![s]?[i.identifier] = i;
      }

      await _preferences.setString(
        "layout_data_${dashboardId}_$s",
        json.encode(
          _localItems![s]!.map((key, value) => MapEntry(key, value.toMap())),
        ),
      );
    }
  }

  @override
  FutureOr<void> onItemsDeleted(
    List<ColoredDashboardItem> items,
    int slotCount,
  ) async {
    _setLocal();
    for (var s in _slotCounts) {
      for (var i in items) {
        _localItems?[s]?.remove(i.identifier);
      }

      final slotItems = _localItems?[s];
      if (slotItems != null) {
        await _preferences.setString(
          "layout_data_${dashboardId}_$s",
          json.encode(
            slotItems.map((key, value) => MapEntry(key, value.toMap())),
          ),
        );
      }
    }
  }

  Future<void> clear() async {
    for (var s in _slotCounts) {
      _localItems?[s]?.clear();
      await _preferences.remove("layout_data_${dashboardId}_$s");
    }
    _localItems = null;
    await _preferences.setBool("init_${dashboardId}_v4", false);
  }

  ColoredDashboardItem createDefaultItem(String instanceId, String widgetType, int slotCount) {
    final meta = WidgetCatalog.all[widgetType];
    final w = meta?.defaultWidth ?? 2;
    final h = meta?.defaultHeight ?? 2;
    return ColoredDashboardItem(
      startX: 0,
      startY: 9999,
      width: w.clamp(1, slotCount),
      height: h,
      identifier: instanceId,
      data: widgetType,
      minWidth: (widgetType == 'marketTrending' || widgetType == 'bills') ? 2 : 1,
    );
  }

  void _setLocal() {
    _localItems ??= {
      for (var s in _slotCounts)
        s: _default[s]!.asMap().map(
          (key, value) => MapEntry(value.identifier, value),
        ),
    };
  }

  @override
  bool get layoutsBySlotCount => true;

  @override
  bool get cacheItems => true;
}
