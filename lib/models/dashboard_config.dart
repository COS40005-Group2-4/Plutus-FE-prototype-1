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

  factory DashboardConfig.withDefaults(String id, String name) {
    return DashboardConfig(
      id: id,
      name: name,
      widgetVisibility: {for (var wid in defaultWidgetIds) wid: true},
      createdAt: DateTime.now(),
    );
  }

  factory DashboardConfig.empty(String id, String name) {
    return DashboardConfig(
      id: id,
      name: name,
      widgetVisibility: {for (var wid in defaultWidgetIds) wid: false},
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'widgetVisibility': widgetVisibility,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    final vis = (json['widgetVisibility'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v as bool)) ?? {};
    // Ensure all known widget IDs exist
    for (var wid in defaultWidgetIds) {
      vis.putIfAbsent(wid, () => true);
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
