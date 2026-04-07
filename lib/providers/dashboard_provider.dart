import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_config.dart';

class DashboardProvider extends ChangeNotifier {
  static const String _dashboardsListKey = 'dashboards_list';
  static const String _activeDashboardKey = 'active_dashboard_id';
  static const int maxDashboards = 5;
  static const List<int> _slotCounts = [2, 4, 6];

  int _userId = 0;
  String _userKey(String key) => 'user_${_userId}_$key';
  int get currentUserId => _userId;

  SharedPreferences? _preferences;
  bool _isInitialized = false;

  List<DashboardConfig> _dashboards = [];
  String _activeDashboardId = 'default';

  DashboardProvider();

  Future<void> reinitialize(int userId) async {
    _userId = userId;
    _isInitialized = false;
    _dashboards = [];
    _activeDashboardId = 'default';
    _preferences ??= await SharedPreferences.getInstance();
    await _loadForUser();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadForUser() async {
    if (_userId == 0) {
      // No active user — use in-memory defaults, do not persist
      _dashboards = [DashboardConfig.withDefaults('default', 'Main')];
      _activeDashboardId = 'default';
      return;
    }
    final listJson = _preferences?.getString(_userKey(_dashboardsListKey));
    if (listJson != null) {
      final list = json.decode(listJson) as List<dynamic>;
      _dashboards = list
          .map((e) => DashboardConfig.fromJson(e as Map<String, dynamic>))
          .toList();
      _activeDashboardId =
          _preferences?.getString(_userKey(_activeDashboardKey)) ??
          _dashboards.first.id;
      if (!_dashboards.any((d) => d.id == _activeDashboardId)) {
        _activeDashboardId = _dashboards.first.id;
      }
    } else {
      // First login for this user — create default dashboard
      _dashboards = [DashboardConfig.withDefaults('default', 'Main')];
      _activeDashboardId = 'default';
      await _saveDashboards();
      await _preferences?.setString(_userKey(_activeDashboardKey), 'default');
      await _saveVisibilitySnapshot('default');
    }
  }

  bool get isInitialized => _isInitialized;
  List<DashboardConfig> get dashboards => List.unmodifiable(_dashboards);
  String get activeDashboardId => _activeDashboardId;
  bool get canCreateDashboard => _dashboards.length < maxDashboards;

  DashboardConfig get activeDashboard {
    if (_dashboards.isEmpty) {
      return DashboardConfig.withDefaults('default', 'Main');
    }
    return _dashboards.firstWhere(
      (d) => d.id == _activeDashboardId,
      orElse: () => _dashboards.first,
    );
  }

  // ── Visibility delegates ──────────────────────────────────────────────

  bool isWidgetVisible(String widgetId) =>
      activeDashboard.widgetVisibility[widgetId] ?? true;

  List<String> getVisibleWidgets() => activeDashboard.widgetVisibility.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toList();

  List<String> get allWidgetIds =>
      activeDashboard.widgetVisibility.keys.toList();

  List<String> get hiddenWidgetIds => activeDashboard.widgetVisibility.entries
      .where((e) => !e.value)
      .map((e) => e.key)
      .toList();

  int get visibleWidgetsCount =>
      activeDashboard.widgetVisibility.values.where((v) => v).length;

  int get totalWidgetsCount => activeDashboard.widgetVisibility.length;

  Future<void> showWidget(String widgetId) async {
    if (activeDashboard.widgetVisibility.containsKey(widgetId)) {
      activeDashboard.widgetVisibility[widgetId] = true;
      await _saveDashboards();
      notifyListeners();
    }
  }

  Future<void> hideWidget(String widgetId) async {
    if (activeDashboard.widgetVisibility.containsKey(widgetId)) {
      activeDashboard.widgetVisibility[widgetId] = false;
      await _saveDashboards();
      notifyListeners();
    }
  }

  Future<void> toggleWidget(String widgetId) async {
    if (activeDashboard.widgetVisibility.containsKey(widgetId)) {
      activeDashboard.widgetVisibility[widgetId] =
          !(activeDashboard.widgetVisibility[widgetId] ?? true);
      await _saveDashboards();
      notifyListeners();
    }
  }

  /// Add a new instance of a widget type to the dashboard.
  /// Returns the new instance ID.
  Future<String> addWidgetInstance(String widgetType) async {
    final index = activeDashboard.nextInstanceIndex(widgetType);
    final instanceId = DashboardConfig.makeInstanceId(widgetType, index);
    activeDashboard.widgetVisibility[instanceId] = true;
    await _saveDashboards();
    notifyListeners();
    return instanceId;
  }

  /// Remove a specific widget instance from the dashboard.
  Future<void> removeWidgetInstance(String instanceId) async {
    activeDashboard.widgetVisibility.remove(instanceId);
    await _saveDashboards();
    notifyListeners();
  }

  /// Returns a map of widget type → count of visible instances.
  Map<String, int> getInstanceCounts() {
    final counts = <String, int>{};
    for (final entry in activeDashboard.widgetVisibility.entries) {
      if (entry.value) {
        final type = DashboardConfig.typeFromInstanceId(entry.key);
        counts[type] = (counts[type] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Count visible instances of a specific widget type.
  int instanceCountForType(String widgetType) {
    return activeDashboard.widgetVisibility.entries
        .where((e) => e.value && DashboardConfig.typeFromInstanceId(e.key) == widgetType)
        .length;
  }

  // ── Dashboard CRUD ────────────────────────────────────────────────────

  Future<void> createDashboard({
    required String name,
    bool useDefaults = true,
  }) async {
    if (!canCreateDashboard) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final config = useDefaults
        ? DashboardConfig.withDefaults(id, name)
        : DashboardConfig.empty(id, name);
    _dashboards.add(config);

    // Write initial saved snapshot so Reset has something to revert to
    if (useDefaults) {
      await _copyLiveToSaved(id);
    } else {
      // For empty dashboards, save an empty snapshot
      await _saveVisibilitySnapshot(id);
    }

    _activeDashboardId = id;
    await _saveDashboards();
    await _preferences?.setString(_userKey(_activeDashboardKey), id);
    notifyListeners();
  }

  Future<void> renameDashboard(String id, String newName) async {
    final idx = _dashboards.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    _dashboards[idx].name = newName;
    await _saveDashboards();
    notifyListeners();
  }

  Future<void> deleteDashboard(String id) async {
    if (_dashboards.length <= 1) return;
    _dashboards.removeWhere((d) => d.id == id);

    // Clean up SharedPreferences keys for this dashboard
    await _cleanupDashboardKeys(id);

    if (_activeDashboardId == id) {
      _activeDashboardId = _dashboards.first.id;
      await _preferences?.setString(_userKey(_activeDashboardKey), _activeDashboardId);
    }
    await _saveDashboards();
    notifyListeners();
  }

  Future<void> setActiveDashboard(String id) async {
    if (_activeDashboardId == id) return;
    if (!_dashboards.any((d) => d.id == id)) return;
    _activeDashboardId = id;
    await _preferences?.setString(_userKey(_activeDashboardKey), id);
    notifyListeners();
  }

  // ── Save / Reset ─────────────────────────────────────────────────────

  Future<void> saveLayout() async {
    await _copyLiveToSaved(_activeDashboardId);
    await _saveVisibilitySnapshot(_activeDashboardId);
  }

  Future<void> resetToSaved() async {
    await _copySavedToLive(_activeDashboardId);
    await _restoreVisibilitySnapshot(_activeDashboardId);
    await _saveDashboards();
    notifyListeners();
  }

  Future<void> hardReset() async {
    // Reset to single instance per widget type, all visible
    activeDashboard.widgetVisibility = {
      for (var wid in DashboardConfig.defaultWidgetIds)
        DashboardConfig.makeInstanceId(wid, 0): true,
    };

    // Clear live layout keys so storage re-initializes from defaults
    for (var s in _slotCounts) {
      await _preferences?.remove(_userKey('layout_data_${_activeDashboardId}_$s'));
    }
    await _preferences?.setBool(_userKey('init_${_activeDashboardId}_v4'), false);

    await _saveDashboards();
    notifyListeners();
  }

  // ── Persistence helpers ───────────────────────────────────────────────

  Future<void> _saveDashboards() async {
    if (_userId == 0) return; // Do not persist for the no-user state
    final list = _dashboards.map((d) => d.toJson()).toList();
    await _preferences?.setString(_userKey(_dashboardsListKey), json.encode(list));
  }

  Future<void> _copyLiveToSaved(String dashId) async {
    for (var s in _slotCounts) {
      final liveKey = _userKey('layout_data_${dashId}_$s');
      final savedKey = _userKey('layout_saved_${dashId}_$s');
      final data = _preferences?.getString(liveKey);
      if (data != null) {
        await _preferences?.setString(savedKey, data);
      }
    }
  }

  Future<void> _copySavedToLive(String dashId) async {
    for (var s in _slotCounts) {
      final savedKey = _userKey('layout_saved_${dashId}_$s');
      final liveKey = _userKey('layout_data_${dashId}_$s');
      final data = _preferences?.getString(savedKey);
      if (data != null) {
        await _preferences?.setString(liveKey, data);
      }
    }
  }

  Future<void> _saveVisibilitySnapshot(String dashId) async {
    final vis = _dashboards
        .firstWhere((d) => d.id == dashId, orElse: () => activeDashboard)
        .widgetVisibility;
    final encoded = vis.entries.map((e) => '${e.key}:${e.value}').join(',');
    await _preferences?.setString(_userKey('visibility_saved_$dashId'), encoded);
  }

  Future<void> _restoreVisibilitySnapshot(String dashId) async {
    final stored = _preferences?.getString(_userKey('visibility_saved_$dashId'));
    if (stored == null) return;
    final dash = _dashboards.firstWhere((d) => d.id == dashId);
    final parts = stored.split(',');
    for (var part in parts) {
      final pair = part.trim().split(':');
      if (pair.length == 2) {
        dash.widgetVisibility[pair[0]] = pair[1] == 'true';
      }
    }
  }

  Future<void> _cleanupDashboardKeys(String dashId) async {
    for (var s in _slotCounts) {
      await _preferences?.remove(_userKey('layout_data_${dashId}_$s'));
      await _preferences?.remove(_userKey('layout_saved_${dashId}_$s'));
    }
    await _preferences?.remove(_userKey('init_${dashId}_v4'));
    await _preferences?.remove(_userKey('visibility_saved_$dashId'));
  }
}
