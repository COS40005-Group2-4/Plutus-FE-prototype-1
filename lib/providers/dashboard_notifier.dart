import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_config.dart';
import 'auth_notifier.dart';

// ---------------------------------------------------------------------------
// DashboardState
// ---------------------------------------------------------------------------

class DashboardState {
  final List<DashboardConfig> dashboards;
  final String activeDashboardId;
  final bool isInitialized;

  const DashboardState({
    required this.dashboards,
    required this.activeDashboardId,
    required this.isInitialized,
  });

  DashboardState copyWith({
    List<DashboardConfig>? dashboards,
    String? activeDashboardId,
    bool? isInitialized,
  }) {
    return DashboardState(
      dashboards: dashboards ?? this.dashboards,
      activeDashboardId: activeDashboardId ?? this.activeDashboardId,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  DashboardConfig get activeDashboard {
    if (dashboards.isEmpty) {
      return DashboardConfig.withDefaults('default', 'Main');
    }
    return dashboards.firstWhere(
      (d) => d.id == activeDashboardId,
      orElse: () => dashboards.first,
    );
  }

  bool get canCreateDashboard => dashboards.length < DashboardNotifier.maxDashboards;
}

// ---------------------------------------------------------------------------
// DashboardNotifier
// ---------------------------------------------------------------------------

class DashboardNotifier extends Notifier<DashboardState> {
  static const String _dashboardsListKey = 'dashboards_list';
  static const String _activeDashboardKey = 'active_dashboard_id';
  static const int maxDashboards = 5;
  static const List<int> _slotCounts = [2, 4, 6];

  int _userId = 0;
  SharedPreferences? _preferences;

  String _userKey(String key) => 'user_${_userId}_$key';

  int get currentUserId => _userId;

  @override
  DashboardState build() {
    final authState = ref.watch(authNotifierProvider);

    final int newUserId = switch (authState) {
      AuthAuthenticated(:final user) => user.id,
      _ => 0,
    };

    // Fire async initialization whenever userId changes.
    Future.microtask(() => _initialize(newUserId));

    return const DashboardState(
      dashboards: [],
      activeDashboardId: 'default',
      isInitialized: false,
    );
  }

  Future<void> _initialize(int userId) async {
    _userId = userId;
    _preferences ??= await SharedPreferences.getInstance();
    await _loadForUser();
  }

  Future<void> _loadForUser() async {
    if (_userId == 0) {
      state = DashboardState(
        dashboards: [DashboardConfig.withDefaults('default', 'Main')],
        activeDashboardId: 'default',
        isInitialized: true,
      );
      return;
    }

    final listJson = _preferences?.getString(_userKey(_dashboardsListKey));
    if (listJson != null) {
      final list = json.decode(listJson) as List<dynamic>;
      final dashboards = list
          .map((e) => DashboardConfig.fromJson(e as Map<String, dynamic>))
          .toList();

      String activeId =
          _preferences?.getString(_userKey(_activeDashboardKey)) ??
          dashboards.first.id;
      if (!dashboards.any((d) => d.id == activeId)) {
        activeId = dashboards.first.id;
      }

      state = DashboardState(
        dashboards: dashboards,
        activeDashboardId: activeId,
        isInitialized: true,
      );
    } else {
      // First login — create default dashboard.
      final defaultDashboard = DashboardConfig.withDefaults('default', 'Main');
      state = DashboardState(
        dashboards: [defaultDashboard],
        activeDashboardId: 'default',
        isInitialized: true,
      );
      await _saveDashboards();
      await _preferences?.setString(_userKey(_activeDashboardKey), 'default');
      await _saveVisibilitySnapshot('default');
    }
  }

  // ── Visibility delegates ──────────────────────────────────────────────

  bool isWidgetVisible(String widgetId) =>
      state.activeDashboard.widgetVisibility[widgetId] ?? true;

  List<String> getVisibleWidgets() =>
      state.activeDashboard.widgetVisibility.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

  List<String> get allWidgetIds =>
      state.activeDashboard.widgetVisibility.keys.toList();

  List<String> get hiddenWidgetIds =>
      state.activeDashboard.widgetVisibility.entries
          .where((e) => !e.value)
          .map((e) => e.key)
          .toList();

  Future<void> showWidget(String widgetId) async {
    if (state.activeDashboard.widgetVisibility.containsKey(widgetId)) {
      state.activeDashboard.widgetVisibility[widgetId] = true;
      await _saveDashboards();
      ref.notifyListeners();
    }
  }

  Future<void> hideWidget(String widgetId) async {
    if (state.activeDashboard.widgetVisibility.containsKey(widgetId)) {
      state.activeDashboard.widgetVisibility[widgetId] = false;
      await _saveDashboards();
      ref.notifyListeners();
    }
  }

  Future<void> toggleWidget(String widgetId) async {
    if (state.activeDashboard.widgetVisibility.containsKey(widgetId)) {
      state.activeDashboard.widgetVisibility[widgetId] =
          !(state.activeDashboard.widgetVisibility[widgetId] ?? true);
      await _saveDashboards();
      ref.notifyListeners();
    }
  }

  /// Add a new instance of a widget type to the dashboard.
  /// Returns the new instance ID.
  Future<String> addWidgetInstance(String widgetType) async {
    final index = state.activeDashboard.nextInstanceIndex(widgetType);
    final instanceId = DashboardConfig.makeInstanceId(widgetType, index);
    state.activeDashboard.widgetVisibility[instanceId] = true;
    await _saveDashboards();
    ref.notifyListeners();
    return instanceId;
  }

  /// Remove a specific widget instance from the dashboard.
  Future<void> removeWidgetInstance(String instanceId) async {
    state.activeDashboard.widgetVisibility.remove(instanceId);
    await _saveDashboards();
    ref.notifyListeners();
  }

  /// Returns a map of widget type → count of visible instances.
  Map<String, int> getInstanceCounts() {
    final counts = <String, int>{};
    for (final entry in state.activeDashboard.widgetVisibility.entries) {
      if (entry.value) {
        final type = DashboardConfig.typeFromInstanceId(entry.key);
        counts[type] = (counts[type] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Count visible instances of a specific widget type.
  int instanceCountForType(String widgetType) {
    return state.activeDashboard.widgetVisibility.entries
        .where(
          (e) =>
              e.value &&
              DashboardConfig.typeFromInstanceId(e.key) == widgetType,
        )
        .length;
  }

  // ── Dashboard CRUD ────────────────────────────────────────────────────

  Future<void> createDashboard({
    required String name,
    bool useDefaults = true,
  }) async {
    if (!state.canCreateDashboard) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final config = useDefaults
        ? DashboardConfig.withDefaults(id, name)
        : DashboardConfig.empty(id, name);

    final updatedDashboards = [...state.dashboards, config];
    state = state.copyWith(
      dashboards: updatedDashboards,
      activeDashboardId: id,
    );

    // Write initial saved snapshot so Reset has something to revert to.
    if (useDefaults) {
      await _copyLiveToSaved(id);
    } else {
      await _saveVisibilitySnapshot(id);
    }

    await _saveDashboards();
    await _preferences?.setString(_userKey(_activeDashboardKey), id);
  }

  Future<void> renameDashboard(String id, String newName) async {
    final idx = state.dashboards.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    state.dashboards[idx].name = newName;
    await _saveDashboards();
    ref.notifyListeners();
  }

  Future<void> deleteDashboard(String id) async {
    if (state.dashboards.length <= 1) return;

    final updatedDashboards =
        state.dashboards.where((d) => d.id != id).toList();
    await _cleanupDashboardKeys(id);

    String newActiveId = state.activeDashboardId;
    if (state.activeDashboardId == id) {
      newActiveId = updatedDashboards.first.id;
      await _preferences?.setString(
        _userKey(_activeDashboardKey),
        newActiveId,
      );
    }

    state = state.copyWith(
      dashboards: updatedDashboards,
      activeDashboardId: newActiveId,
    );

    await _saveDashboards();
  }

  Future<void> setActiveDashboard(String id) async {
    if (state.activeDashboardId == id) return;
    if (!state.dashboards.any((d) => d.id == id)) return;
    await _preferences?.setString(_userKey(_activeDashboardKey), id);
    state = state.copyWith(activeDashboardId: id);
  }

  // ── Save / Reset ─────────────────────────────────────────────────────

  Future<void> saveLayout() async {
    await _copyLiveToSaved(state.activeDashboardId);
    await _saveVisibilitySnapshot(state.activeDashboardId);
  }

  Future<void> resetToSaved() async {
    await _copySavedToLive(state.activeDashboardId);
    await _restoreVisibilitySnapshot(state.activeDashboardId);
    await _saveDashboards();
    ref.notifyListeners();
  }

  Future<void> hardReset() async {
    // Reset to single instance per widget type, all visible.
    state.activeDashboard.widgetVisibility = {
      for (var wid in DashboardConfig.defaultWidgetIds)
        DashboardConfig.makeInstanceId(wid, 0): true,
    };

    // Clear live layout keys so storage re-initializes from defaults.
    for (var s in _slotCounts) {
      await _preferences?.remove(
        _userKey('layout_data_${state.activeDashboardId}_$s'),
      );
    }
    await _preferences?.setBool(
      _userKey('init_${state.activeDashboardId}_v4'),
      false,
    );

    await _saveDashboards();
    ref.notifyListeners();
  }

  // ── Persistence helpers ───────────────────────────────────────────────

  Future<void> _saveDashboards() async {
    if (_userId == 0) return; // Do not persist for the no-user state.
    final list = state.dashboards.map((d) => d.toJson()).toList();
    await _preferences?.setString(
      _userKey(_dashboardsListKey),
      json.encode(list),
    );
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
    final vis = state.dashboards
        .firstWhere(
          (d) => d.id == dashId,
          orElse: () => state.activeDashboard,
        )
        .widgetVisibility;
    final encoded = vis.entries.map((e) => '${e.key}:${e.value}').join(',');
    await _preferences?.setString(
      _userKey('visibility_saved_$dashId'),
      encoded,
    );
  }

  Future<void> _restoreVisibilitySnapshot(String dashId) async {
    final stored =
        _preferences?.getString(_userKey('visibility_saved_$dashId'));
    if (stored == null) return;

    final dash = state.dashboards.firstWhere((d) => d.id == dashId);
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

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dashboardNotifierProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(
      DashboardNotifier.new,
    );
