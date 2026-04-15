import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// WidgetVisibilityState
// ---------------------------------------------------------------------------

class WidgetVisibilityState {
  final Map<String, bool> visibility;
  final bool isInitialized;

  const WidgetVisibilityState({
    required this.visibility,
    required this.isInitialized,
  });

  bool isWidgetVisible(String widgetId) => visibility[widgetId] ?? true;

  List<String> get visibleWidgets =>
      visibility.entries.where((e) => e.value).map((e) => e.key).toList();

  List<String> get allWidgetIds => visibility.keys.toList();

  List<String> get hiddenWidgetIds =>
      visibility.entries.where((e) => !e.value).map((e) => e.key).toList();

  int get visibleCount => visibility.values.where((v) => v).length;

  int get totalCount => visibility.length;
}

// ---------------------------------------------------------------------------
// WidgetVisibilityNotifier
// ---------------------------------------------------------------------------

class WidgetVisibilityNotifier extends Notifier<WidgetVisibilityState> {
  static const String _storageKey = 'widget_visibility';

  static const Map<String, bool> _defaultVisibility = {
    'profile': true,
    'budget': true,
    'categoryBudget': true,
    'history': true,
    'import': true,
    'export': true,
    'roi': true,
    'irr': true,
    'tax': true,
    'cashflow': true,
    'bills': true,
    'investment': true,
    'expenseBreakdown': true,
    'portfolioAllocation': true,
    'netWorthTrend': true,
    'spendingHeatmap': true,
    'incomeTrend': true,
    'savingsRate': true,
    'marketTrending': true,
    'insightsFeed': true,
    'healthScore': true,
    'cashFlowForecast': true,
    'coachingTips': true,
  };

  SharedPreferences? _preferences;

  @override
  WidgetVisibilityState build() {
    // Fire async initialization without blocking build().
    Future.microtask(() => _initialize());

    return const WidgetVisibilityState(
      visibility: _defaultVisibility,
      isInitialized: false,
    );
  }

  Future<void> _initialize() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      await _loadVisibility();
      // Mark as initialized — visibility was already updated in _loadVisibility.
    } catch (_) {
      // If initialization fails, keep defaults and mark as initialized.
      state = WidgetVisibilityState(
        visibility: Map<String, bool>.from(_defaultVisibility),
        isInitialized: true,
      );
    }
  }

  Future<void> _loadVisibility() async {
    if (_preferences == null) return;

    final stored = _preferences!.getString(_storageKey);
    final visibility = Map<String, bool>.from(_defaultVisibility);

    if (stored != null) {
      try {
        final parts = stored.split(',');
        for (var part in parts) {
          final pair = part.trim().split(':');
          if (pair.length == 2) {
            visibility[pair[0]] = pair[1] == 'true';
          }
        }
      } catch (_) {
        // If parsing fails, keep defaults.
      }
    }

    state = WidgetVisibilityState(
      visibility: visibility,
      isInitialized: true,
    );
  }

  Future<void> _saveVisibility() async {
    if (_preferences == null) return;
    final encoded =
        state.visibility.entries.map((e) => '${e.key}:${e.value}').join(',');
    await _preferences!.setString(_storageKey, encoded);
  }

  // ── Public methods ────────────────────────────────────────────────────

  Future<void> showWidget(String widgetId) async {
    if (state.visibility.containsKey(widgetId)) {
      state.visibility[widgetId] = true;
      await _saveVisibility();
      ref.notifyListeners();
    }
  }

  Future<void> hideWidget(String widgetId) async {
    if (state.visibility.containsKey(widgetId)) {
      state.visibility[widgetId] = false;
      await _saveVisibility();
      ref.notifyListeners();
    }
  }

  Future<void> toggleWidget(String widgetId) async {
    if (state.visibility.containsKey(widgetId)) {
      state.visibility[widgetId] = !(state.visibility[widgetId] ?? true);
      await _saveVisibility();
      ref.notifyListeners();
    }
  }

  Future<void> reset() async {
    state.visibility.updateAll((key, value) => true);
    await _saveVisibility();
    ref.notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final widgetVisibilityNotifierProvider =
    NotifierProvider<WidgetVisibilityNotifier, WidgetVisibilityState>(
      WidgetVisibilityNotifier.new,
    );
