import 'dart:async';
import 'dart:convert';

import 'package:dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      sup["color"] = color!.value;
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
  
  List<String> visibilityFilter = ['profile', 'budget', 'categoryBudget', 'history', 'import', 'export', 'roi', 'irr', 'investment', 'cashflow', 'bills', 'tax', 'expenseBreakdown', 'portfolioAllocation', 'netWorthTrend', 'spendingHeatmap', 'incomeTrend', 'savingsRate', 'marketTrending'];

  void setVisibilityFilter(List<String> visibleWidgets) {
    visibilityFilter = visibleWidgets;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Default layouts — one entry per column count.
  //
  // Grouping logic (top → bottom):
  //   Overview   : profile, budget, categoryBudget
  //   Metrics    : savingsRate, roi, irr, tax
  //   Activity   : history, cashflow
  //   Analysis   : expenseBreakdown, incomeTrend, portfolioAllocation
  //   Wealth     : netWorthTrend, investment
  //   Market     : marketTrending, bills, spendingHeatmap
  //   Tools      : import, export
  // ─────────────────────────────────────────────────────────────────────────
  final Map<int, List<ColoredDashboardItem>> _default = {

    // ── 2-COLUMN (mobile) ─────────────────────────────────────────────────
    // All widgets span the full 2-col width. ROI/IRR and Import/Export are
    // paired side-by-side at w=1.
    2: <ColoredDashboardItem>[
      // Overview
      ColoredDashboardItem(startX: 0, startY: 0,  width: 2, height: 2, identifier: "profile",             data: "profile"),
      ColoredDashboardItem(startX: 0, startY: 2,  width: 2, height: 3, identifier: "budget",              data: "budget"),
      ColoredDashboardItem(startX: 0, startY: 5,  width: 2, height: 3, identifier: "categoryBudget",      data: "categoryBudget"),
      // Activity
      ColoredDashboardItem(startX: 0, startY: 8,  width: 2, height: 4, identifier: "history",             data: "history"),
      ColoredDashboardItem(startX: 0, startY: 12, width: 2, height: 4, identifier: "cashflow",            data: "cashflow"),
      // Analysis
      ColoredDashboardItem(startX: 0, startY: 16, width: 2, height: 3, identifier: "expenseBreakdown",    data: "expenseBreakdown"),
      ColoredDashboardItem(startX: 0, startY: 19, width: 2, height: 3, identifier: "incomeTrend",         data: "incomeTrend"),
      ColoredDashboardItem(startX: 0, startY: 22, width: 2, height: 2, identifier: "savingsRate",         data: "savingsRate"),
      // Wealth
      ColoredDashboardItem(startX: 0, startY: 24, width: 2, height: 3, identifier: "netWorthTrend",       data: "netWorthTrend"),
      ColoredDashboardItem(startX: 0, startY: 27, width: 2, height: 3, identifier: "portfolioAllocation", data: "portfolioAllocation"),
      ColoredDashboardItem(startX: 0, startY: 30, width: 2, height: 4, identifier: "investment",          data: "investment"),
      // Metrics (compact pairs)
      ColoredDashboardItem(startX: 0, startY: 34, width: 1, height: 2, identifier: "roi",                 data: "roi"),
      ColoredDashboardItem(startX: 1, startY: 34, width: 1, height: 2, identifier: "irr",                 data: "irr"),
      // Market
      ColoredDashboardItem(startX: 0, startY: 36, width: 2, height: 3, identifier: "marketTrending",      data: "marketTrending", minWidth: 2),
      // Obligations
      ColoredDashboardItem(startX: 0, startY: 39, width: 2, height: 3, identifier: "bills",               data: "bills",           minWidth: 2),
      ColoredDashboardItem(startX: 0, startY: 42, width: 2, height: 2, identifier: "tax",                 data: "tax"),
      // Misc
      ColoredDashboardItem(startX: 0, startY: 44, width: 2, height: 2, identifier: "spendingHeatmap",     data: "spendingHeatmap"),
      // Tools (paired)
      ColoredDashboardItem(startX: 0, startY: 46, width: 1, height: 1, identifier: "import",              data: "import"),
      ColoredDashboardItem(startX: 1, startY: 46, width: 1, height: 1, identifier: "export",              data: "export"),
    ],

    // ── 4-COLUMN (tablet) ─────────────────────────────────────────────────
    // Logical pairs fill each row. Charts are sized to breathe.
    4: <ColoredDashboardItem>[
      // Overview row
      ColoredDashboardItem(startX: 0, startY: 0,  width: 2, height: 2, identifier: "profile",             data: "profile"),
      ColoredDashboardItem(startX: 2, startY: 0,  width: 2, height: 2, identifier: "budget",              data: "budget"),
      // Metrics row
      ColoredDashboardItem(startX: 0, startY: 2,  width: 2, height: 2, identifier: "categoryBudget",      data: "categoryBudget"),
      ColoredDashboardItem(startX: 2, startY: 2,  width: 2, height: 2, identifier: "savingsRate",         data: "savingsRate"),
      // Activity row (tall — needs height to show content)
      ColoredDashboardItem(startX: 0, startY: 4,  width: 2, height: 4, identifier: "history",             data: "history"),
      ColoredDashboardItem(startX: 2, startY: 4,  width: 2, height: 4, identifier: "cashflow",            data: "cashflow"),
      // Analysis row
      ColoredDashboardItem(startX: 0, startY: 8,  width: 2, height: 3, identifier: "expenseBreakdown",    data: "expenseBreakdown"),
      ColoredDashboardItem(startX: 2, startY: 8,  width: 2, height: 3, identifier: "incomeTrend",         data: "incomeTrend"),
      // Wealth (full-width net worth chart, then pair below)
      ColoredDashboardItem(startX: 0, startY: 11, width: 4, height: 3, identifier: "netWorthTrend",       data: "netWorthTrend"),
      ColoredDashboardItem(startX: 0, startY: 14, width: 2, height: 3, identifier: "portfolioAllocation", data: "portfolioAllocation"),
      ColoredDashboardItem(startX: 2, startY: 14, width: 2, height: 4, identifier: "investment",          data: "investment"),
      // Compact metrics + market (share a row)
      ColoredDashboardItem(startX: 0, startY: 17, width: 1, height: 2, identifier: "roi",                 data: "roi"),
      ColoredDashboardItem(startX: 1, startY: 17, width: 1, height: 2, identifier: "irr",                 data: "irr"),
      ColoredDashboardItem(startX: 0, startY: 19, width: 2, height: 3, identifier: "marketTrending",      data: "marketTrending", minWidth: 2),
      // Obligations
      ColoredDashboardItem(startX: 2, startY: 18, width: 2, height: 3, identifier: "bills",               data: "bills",           minWidth: 2),
      ColoredDashboardItem(startX: 0, startY: 22, width: 2, height: 2, identifier: "tax",                 data: "tax"),
      // Misc + tools
      ColoredDashboardItem(startX: 2, startY: 21, width: 2, height: 2, identifier: "spendingHeatmap",     data: "spendingHeatmap"),
      ColoredDashboardItem(startX: 0, startY: 24, width: 1, height: 1, identifier: "import",              data: "import"),
      ColoredDashboardItem(startX: 1, startY: 24, width: 1, height: 1, identifier: "export",              data: "export"),
    ],

    // ── 6-COLUMN (desktop) ────────────────────────────────────────────────
    // Full-grid utilisation. Each logical group fills exactly 6 columns.
    6: <ColoredDashboardItem>[
      // Row y=0–1: Overview (fills 6 cols)
      ColoredDashboardItem(startX: 0, startY: 0,  width: 2, height: 2, identifier: "profile",             data: "profile"),
      ColoredDashboardItem(startX: 2, startY: 0,  width: 2, height: 2, identifier: "budget",              data: "budget"),
      ColoredDashboardItem(startX: 4, startY: 0,  width: 2, height: 2, identifier: "categoryBudget",      data: "categoryBudget"),
      // Row y=2–3: Quick metrics (fills 6 cols)
      ColoredDashboardItem(startX: 0, startY: 2,  width: 2, height: 2, identifier: "savingsRate",         data: "savingsRate"),
      ColoredDashboardItem(startX: 2, startY: 2,  width: 1, height: 2, identifier: "roi",                 data: "roi"),
      ColoredDashboardItem(startX: 3, startY: 2,  width: 1, height: 2, identifier: "irr",                 data: "irr"),
      ColoredDashboardItem(startX: 4, startY: 2,  width: 2, height: 2, identifier: "tax",                 data: "tax"),
      // Row y=4–6: Activity (fills 6 cols, taller for content)
      ColoredDashboardItem(startX: 0, startY: 4,  width: 3, height: 3, identifier: "history",             data: "history"),
      ColoredDashboardItem(startX: 3, startY: 4,  width: 3, height: 3, identifier: "cashflow",            data: "cashflow"),
      // Row y=7–9: Analysis trio (fills 6 cols)
      ColoredDashboardItem(startX: 0, startY: 7,  width: 2, height: 3, identifier: "expenseBreakdown",    data: "expenseBreakdown"),
      ColoredDashboardItem(startX: 2, startY: 7,  width: 2, height: 3, identifier: "incomeTrend",         data: "incomeTrend"),
      ColoredDashboardItem(startX: 4, startY: 7,  width: 2, height: 3, identifier: "portfolioAllocation", data: "portfolioAllocation"),
      // Row y=10–12: Wealth pair (fills 6 cols)
      ColoredDashboardItem(startX: 0, startY: 10, width: 3, height: 3, identifier: "netWorthTrend",       data: "netWorthTrend"),
      ColoredDashboardItem(startX: 3, startY: 10, width: 3, height: 3, identifier: "investment",          data: "investment"),
      // Row y=13–15: Market / Obligations / Heatmap (fills 6 cols)
      ColoredDashboardItem(startX: 0, startY: 13, width: 2, height: 3, identifier: "marketTrending",      data: "marketTrending", minWidth: 2),
      ColoredDashboardItem(startX: 2, startY: 13, width: 2, height: 3, identifier: "bills",               data: "bills",           minWidth: 2),
      ColoredDashboardItem(startX: 4, startY: 13, width: 2, height: 2, identifier: "spendingHeatmap",     data: "spendingHeatmap"),
      // Tools (tucked under heatmap)
      ColoredDashboardItem(startX: 4, startY: 15, width: 1, height: 1, identifier: "import",              data: "import"),
      ColoredDashboardItem(startX: 5, startY: 15, width: 1, height: 1, identifier: "export",              data: "export"),
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
          return visibilityFilter.contains(item.data);
        }).toList();
      }

      return Future.microtask(() async {
        _preferences = await SharedPreferences.getInstance();

        var init = _preferences.getBool("init_$dashboardId") ?? false;

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

          await _preferences.setBool("init_$dashboardId", true);
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
              const minWidthConstraints = {'marketTrending': 2, 'bills': 2};
              for (var entry in minWidthConstraints.entries) {
                var item = loadedItems[entry.key];
                if (item != null && item.layoutData.minWidth < entry.value) {
                  var layout = item.layoutData;
                  loadedItems[entry.key] = ColoredDashboardItem(
                    startX: layout.startX,
                    startY: layout.startY,
                    width: layout.width < entry.value ? entry.value : layout.width,
                    height: layout.height,
                    identifier: item.identifier,
                    data: item.data,
                    color: item.color,
                    minWidth: entry.value,
                  );
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
            return visibilityFilter.contains(item.data);
          }).toList();
        }

        // Fallback to default if slot count not found
        final defaultItems = _default[slotCount] ?? [];
        return defaultItems.where((item) {
          if (item.data == null) return true;
          return visibilityFilter.contains(item.data);
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
    await _preferences.setBool("init_$dashboardId", false);
  }

  _setLocal() {
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
