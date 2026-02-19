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
  late SharedPreferences _preferences;

  final List<int> _slotCounts = [3, 4, 6];
  
  List<String> visibilityFilter = ['profile', 'budget', 'history', 'import', 'export', 'roi', 'irr', 'investment', 'cashflow', 'bills', 'tax'];

  void setVisibilityFilter(List<String> visibleWidgets) {
    visibilityFilter = visibleWidgets;
  }

  final Map<int, List<ColoredDashboardItem>> _default = {
    3: <ColoredDashboardItem>[
      ColoredDashboardItem(
        height: 2,
        width: 2,
        startX: 0,
        startY: 0,
        identifier: "profile",
        data: "profile",
      ),
      ColoredDashboardItem(
        height: 2,
        width: 2,
        startX: 0,
        startY: 2,
        identifier: "budget",
        data: "budget",
      ),
      ColoredDashboardItem(
        startX: 0,
        startY: 4,
        height: 2,
        width: 2,
        identifier: "history",
        data: "history",
      ),
      ColoredDashboardItem(
        startX: 2,
        startY: 0,
        width: 1,
        height: 1,
        identifier: "import",
        data: "import",
      ),
      ColoredDashboardItem(
        startX: 2,
        startY: 1,
        height: 1,
        width: 1,
        identifier: "export",
        data: "export",
      ),
      ColoredDashboardItem(
        startX: 2,
        startY: 2,
        width: 1,
        height: 1,
        identifier: "roi",
        data: "roi",
      ),
      ColoredDashboardItem(
        startX: 2,
        startY: 3,
        width: 1,
        height: 1,
        identifier: "irr",
        data: "irr",
      ),
      ColoredDashboardItem(
        startX: 2,
        startY: 4,
        width: 2,
        height: 2,
        identifier: "investment",
        data: "investment",
      ),
      ColoredDashboardItem(
        startX: 2,
        startY: 6,
        width: 1,
        height: 2,
        identifier: "bills",
        data: "bills",
      ),
      ColoredDashboardItem(
        startX: 2,
        startY: 8,
        width: 2,
        height: 2,
        identifier: "tax",
        data: "tax",
      ),
      ColoredDashboardItem(
        startX: 0,
        startY: 6,
        width: 2,
        height: 2,
        identifier: "cashflow",
        data: "cashflow",
      ),
    ],
    4: <ColoredDashboardItem>[
      ColoredDashboardItem(
        height: 2,
        width: 2,
        startX: 0,
        startY: 0,
        identifier: "profile",
        data: "profile",
      ),
      ColoredDashboardItem(
        height: 2,
        width: 2,
        startX: 2,
        startY: 0,
        identifier: "budget",
        data: "budget",
      ),
      ColoredDashboardItem(
        startX: 0,
        startY: 2,
        height: 2,
        width: 3,
        identifier: "history",
        data: "history",
      ),
      ColoredDashboardItem(
        startX: 3,
        startY: 2,
        width: 1,
        height: 1,
        identifier: "import",
        data: "import",
      ),
      ColoredDashboardItem(
        startX: 3,
        startY: 3,
        height: 1,
        width: 1,
        identifier: "export",
        data: "export",
      ),
      ColoredDashboardItem(
        startX: 0,
        startY: 4,
        width: 1,
        height: 1,
        identifier: "roi",
        data: "roi",
      ),
      ColoredDashboardItem(
        startX: 1,
        startY: 4,
        width: 1,
        height: 1,
        identifier: "irr",
        data: "irr",
      ),
      ColoredDashboardItem(
        startX: 0,
        startY: 5,
        width: 2,
        height: 2,
        identifier: "investment",
        data: "investment",
      ),
      ColoredDashboardItem(
        startX: 0,
        startY: 7,
        width: 2,
        height: 2,
        identifier: "tax",
        data: "tax",
      ),
      ColoredDashboardItem(
        startX: 2,
        startY: 4,
        width: 2,
        height: 2,
        identifier: "cashflow",
        data: "cashflow",
      ),
      ColoredDashboardItem(
        startX: 2,
        startY: 5,
        width: 1,
        height: 2,
        identifier: "bills",
        data: "bills",
      ),
    ],
    6: <ColoredDashboardItem>[
      ColoredDashboardItem(
        height: 2,
        width: 2,
        startX: 0,
        startY: 0,
        identifier: "profile",
        data: "profile",
      ),
      ColoredDashboardItem(
        height: 2,
        width: 2,
        startX: 2,
        startY: 0,
        identifier: "budget",
        data: "budget",
      ),
      ColoredDashboardItem(
        startX: 4,
        startY: 0,
        height: 2,
        width: 2,
        identifier: "history",
        data: "history",
      ),
      ColoredDashboardItem(
        startX: 0,
        startY: 2,
        width: 1,
        height: 1,
        identifier: "import",
        data: "import",
      ),
      ColoredDashboardItem(
        startX: 1,
        startY: 2,
        height: 1,
        width: 1,
        identifier: "export",
        data: "export",
      ),
      ColoredDashboardItem(
        startX: 2,
        startY: 2,
        width: 1,
        height: 1,
        identifier: "roi",
        data: "roi",
      ),
      ColoredDashboardItem(
        startX: 3,
        startY: 2,
        width: 1,
        height: 1,
        identifier: "irr",
        data: "irr",
      ),
      ColoredDashboardItem(
        startX: 0,
        startY: 3,
        width: 2,
        height: 2,
        identifier: "investment",
        data: "investment",
      ),
      ColoredDashboardItem(
        startX: 2,
        startY: 3,
        width: 2,
        height: 2,
        identifier: "tax",
        data: "tax",
      ),
      ColoredDashboardItem(
        startX: 4,
        startY: 2,
        width: 2,
        height: 2,
        identifier: "cashflow",
        data: "cashflow",
      ),
      ColoredDashboardItem(
        startX: 4,
        startY: 3,
        width: 2,
        height: 2,
        identifier: "bills",
        data: "bills",
      ),
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

        var init = _preferences.getBool("init") ?? false;

        if (!init) {
          _localItems = {
            for (var s in _slotCounts)
              s: _default[s]!.asMap().map(
                (key, value) => MapEntry(value.identifier, value),
              ),
          };

          for (var s in _slotCounts) {
            await _preferences.setString(
              "layout_data_$s",
              json.encode(
                _default[s]!.asMap().map(
                  (key, value) => MapEntry(value.identifier, value.toMap()),
                ),
              ),
            );
          }

          await _preferences.setBool("init", true);
        } else {
          // Load existing layout data or use defaults
          _localItems = {};
          for (var s in _slotCounts) {
            var layoutDataStr = _preferences.getString("layout_data_$s");
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

      await _preferences.setString("layout_data_$slotCount", js);
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
        "layout_data_$s",
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
          "layout_data_$s",
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
      await _preferences.remove("layout_data_$s");
    }
    _localItems = null;
    await _preferences.setBool("init", false);
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
