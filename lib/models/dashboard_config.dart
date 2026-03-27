import 'dart:convert';

class DashboardConfig {
  final String id;
  String name;
  Map<String, bool> widgetVisibility;
  final DateTime createdAt;

  static const List<String> defaultWidgetIds = [
    'profile', 'budget', 'categoryBudget', 'history', 'import', 'export',
    'roi', 'irr', 'tax', 'cashflow', 'bills', 'investment',
    'expenseBreakdown', 'portfolioAllocation', 'netWorthTrend',
    'spendingHeatmap', 'incomeTrend', 'savingsRate', 'marketTrending',
  ];

  DashboardConfig({
    required this.id,
    required this.name,
    required this.widgetVisibility,
    required this.createdAt,
  });

  // ── Instance ID helpers ──

  static String makeInstanceId(String widgetType, int index) =>
      '${widgetType}_$index';

  static String typeFromInstanceId(String instanceId) {
    final lastUnderscore = instanceId.lastIndexOf('_');
    if (lastUnderscore == -1) return instanceId;
    final suffix = instanceId.substring(lastUnderscore + 1);
    // Only strip if the suffix is a number (instance index)
    if (int.tryParse(suffix) != null) {
      return instanceId.substring(0, lastUnderscore);
    }
    return instanceId;
  }

  int nextInstanceIndex(String widgetType) {
    int maxIndex = -1;
    for (final key in widgetVisibility.keys) {
      if (typeFromInstanceId(key) == widgetType) {
        final lastUnderscore = key.lastIndexOf('_');
        if (lastUnderscore != -1) {
          final idx = int.tryParse(key.substring(lastUnderscore + 1));
          if (idx != null && idx > maxIndex) maxIndex = idx;
        }
      }
    }
    return maxIndex + 1;
  }

  List<String> instancesOfType(String widgetType) {
    return widgetVisibility.keys
        .where((key) => typeFromInstanceId(key) == widgetType)
        .toList();
  }

  // ── Factories ──

  factory DashboardConfig.withDefaults(String id, String name) {
    return DashboardConfig(
      id: id,
      name: name,
      widgetVisibility: {
        for (var wid in defaultWidgetIds) makeInstanceId(wid, 0): true,
      },
      createdAt: DateTime.now(),
    );
  }

  factory DashboardConfig.empty(String id, String name) {
    return DashboardConfig(
      id: id,
      name: name,
      widgetVisibility: {
        for (var wid in defaultWidgetIds) makeInstanceId(wid, 0): false,
      },
      createdAt: DateTime.now(),
    );
  }

  // ── Serialization ──

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'widgetVisibility': widgetVisibility,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    final rawVis = (json['widgetVisibility'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v as bool)) ?? {};

    // Migrate old keys: "budget" → "budget_0"
    final vis = <String, bool>{};
    for (final entry in rawVis.entries) {
      final key = entry.key;
      if (typeFromInstanceId(key) == key) {
        // Key has no _N suffix — old format, migrate
        vis[makeInstanceId(key, 0)] = entry.value;
      } else {
        vis[key] = entry.value;
      }
    }

    // Ensure all default widget types have at least one instance
    for (var wid in defaultWidgetIds) {
      final instanceId = makeInstanceId(wid, 0);
      vis.putIfAbsent(instanceId, () => true);
    }

    return DashboardConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      widgetVisibility: vis,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String encode() => json.encode(toJson());

  factory DashboardConfig.decode(String source) =>
      DashboardConfig.fromJson(json.decode(source) as Map<String, dynamic>);
}
