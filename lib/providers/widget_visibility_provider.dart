import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetVisibilityProvider extends ChangeNotifier {
  SharedPreferences? _preferences;
  bool _isInitialized = false;
  
  final Map<String, bool> _visibleWidgets = {
    'budget': true,
    'history': true,
    'import': true,
    'export': true,
  };

  static const String _storageKey = 'widget_visibility';

  WidgetVisibilityProvider() {
    _initialize();
  }

  bool get isInitialized => _isInitialized;

  Future<void> _initialize() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      await _loadVisibility();
      _isInitialized = true;
    } catch (e) {
      // If initialization fails, keep defaults and mark as initialized
      _isInitialized = true;
    }
    notifyListeners();
  }

  Future<void> _loadVisibility() async {
    if (_preferences == null) return;
    
    final stored = _preferences!.getString(_storageKey);
    if (stored != null) {
      try {
        final parts = stored.split(',');
        for (var part in parts) {
          final pair = part.trim().split(':');
          if (pair.length == 2) {
            _visibleWidgets[pair[0]] = pair[1] == 'true';
          }
        }
      } catch (e) {
        // If parsing fails, keep defaults
      }
    }
  }

  Future<void> _saveVisibility() async {
    if (_preferences == null) return;
    
    final visibility = _visibleWidgets.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    await _preferences!.setString(_storageKey, visibility);
  }

  bool isWidgetVisible(String widgetId) {
    return _visibleWidgets[widgetId] ?? true;
  }

  List<String> getVisibleWidgets() {
    return _visibleWidgets.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
  }

  List<String> get hiddenWidgetIds {
    return _visibleWidgets.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();
  }

  int get visibleWidgetsCount {
    return _visibleWidgets.values.where((v) => v).length;
  }

  Future<void> showWidget(String widgetId) async {
    if (_visibleWidgets.containsKey(widgetId)) {
      _visibleWidgets[widgetId] = true;
      await _saveVisibility();
      notifyListeners();
    }
  }

  Future<void> hideWidget(String widgetId) async {
    if (_visibleWidgets.containsKey(widgetId)) {
      _visibleWidgets[widgetId] = false;
      await _saveVisibility();
      notifyListeners();
    }
  }

  Future<void> toggleWidget(String widgetId) async {
    if (_visibleWidgets.containsKey(widgetId)) {
      _visibleWidgets[widgetId] = !(_visibleWidgets[widgetId] ?? true);
      await _saveVisibility();
      notifyListeners();
    }
  }

  void reset() {
    _visibleWidgets.updateAll((key, value) => true);
    _saveVisibility();
    notifyListeners();
  }
}
