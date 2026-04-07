# User Data Isolation Design

**Date:** 2026-04-07
**Scope:** `lib/providers/auth_provider.dart`, `lib/providers/settings_provider.dart`, `lib/providers/dashboard_provider.dart`, `lib/storage.dart`, `lib/screens/dashboard_screen.dart`, `lib/main.dart`

---

## Problem

SharedPreferences keys for dashboard layouts and app settings are global — no user ID is embedded in the key name. When a different user logs in on the same device, they inherit the previous session's dashboard configuration and settings (theme, language, currency, date/time formats, OCR mode, AI privacy level).

SQLite data (transactions, budgets, bills, investments, profiles) is already correctly isolated by `user_id` foreign key — no changes needed there.

`AuthProvider.signOut()` only removes `last_user_id` from SharedPreferences. Dashboard and settings keys are never cleared.

---

## Decision

**Approach: key prefixing**

Every SharedPreferences key gets a `user_${userId}_` prefix. Each user's data persists between their own sessions. Existing global (unscoped) keys are orphaned and never read again — no migration, fresh defaults for everyone.

On sign-out, providers are reinitialized with `userId = 0`. Key `user_0_*` has no stored data, so all settings and dashboards reset to defaults.

---

## Architecture

### Key scoping rule

All three storage sites (`SettingsProvider`, `DashboardProvider`, `MyItemStorage`) get the same private helper:

```dart
String _userKey(String key) => 'user_${_userId}_$key';
```

Every SharedPreferences read/write goes through `_userKey(...)`. The raw constant keys (`'theme_mode'`, `'dashboards_list'`, etc.) are unchanged — only their usage is wrapped.

### Coordination pattern

`AuthProvider` fires a callback whenever the active user changes. Two other providers register to this callback at app startup and reinitialize themselves with the new user ID.

```dart
// In AuthProvider:
ValueChanged<int>? onUserChanged;

// Called at end of every sign-in and sign-out:
onUserChanged?.call(userId);  // 0 on sign-out
```

`SettingsProvider` and `DashboardProvider` get:

```dart
Future<void> reinitialize(int userId) async {
  _userId = userId;
  // reset in-memory state to defaults
  // reload from SharedPreferences under user_${userId}_* keys
  notifyListeners();
}
```

### `main.dart` wiring

`_settingsProvider` and `_dashboardProvider` are promoted from inline `create:` lambdas to named fields on `_MyAppState` (matching the existing pattern for `_authProvider` and `_backupProvider`). This allows the `onUserChanged` callback to be wired before `_initializeAuth()` runs.

```dart
late SettingsProvider _settingsProvider;
late DashboardProvider _dashboardProvider;

@override
void initState() {
  super.initState();
  _authProvider = AuthProvider();
  _settingsProvider = SettingsProvider();
  _dashboardProvider = DashboardProvider();
  _backupProvider = BackupProvider(syncManager: _syncManager);

  _authProvider.onUserChanged = (userId) async {
    await _settingsProvider.reinitialize(userId);
    await _dashboardProvider.reinitialize(userId);
  };

  _initializeAuth();
}
```

Providers passed via `ChangeNotifierProvider.value(value: _settingsProvider)` instead of `create:`.

---

## File-by-File Changes

### `lib/providers/auth_provider.dart`

Add field:
```dart
ValueChanged<int>? onUserChanged;
```

Add private helper:
```dart
void _notifyUserChanged(int userId) {
  onUserChanged?.call(userId);
}
```

Call `_notifyUserChanged(user.id)` after `_currentUser = user` in each sign-in path individually:
- `initialize()` — when restoring `last_user_id` successfully
- `signInWithLocalUser()` — after setting `_currentUser`
- `signIn()` (OAuth) — after setting `_currentUser`
- `signInAsGuest()` / `continueAsGuest()` — after setting `_currentUser`

Do not rely on a single `_setCurrentUser` call site — verify each sign-in method in the file explicitly.

In `signOut()`, call `_notifyUserChanged(0)` before `notifyListeners()`.

No other changes to `auth_provider.dart`.

---

### `lib/providers/settings_provider.dart`

Add field and helper:
```dart
int _userId = 0;
String _userKey(String key) => 'user_${_userId}_$key';
```

Remove the `_loadSettings()` call from the constructor body. Constructor becomes empty (or sets `_isInitialized = false`).

Add `reinitialize`:
```dart
Future<void> reinitialize(int userId) async {
  _userId = userId;
  _isInitialized = false;
  // Reset to defaults
  _themeMode = ThemeMode.system;
  _language = AppLanguage.english;
  _currency = AppCurrency.vnd;
  _dateFormat = DateFormatType.ddMMyyyy;
  _timeFormat = TimeFormatType.format24h;
  _ocrMode = OCRMode.auto;
  _privacyLevel = PrivacyLevel.standard;
  await _loadSettings();
}
```

Change `_loadSettings()` to use `_userKey(...)` for every key:
```dart
// Before:
final storedTheme = prefs.getString(_themeModeKey);
// After:
final storedTheme = prefs.getString(_userKey(_themeModeKey));
```

Same pattern for all 7 settings reads.

Change every setter (`setThemeMode`, `setLanguage`, `setCurrency`, `setDateFormat`, `setTimeFormat`, `setOcrMode`, `setPrivacyLevel`) to use `_userKey(...)`:
```dart
// Before:
await prefs.setString(_themeModeKey, mode.name);
// After:
await prefs.setString(_userKey(_themeModeKey), mode.name);
```

---

### `lib/providers/dashboard_provider.dart`

Add fields and helper:
```dart
int _userId = 0;
String _userKey(String key) => 'user_${_userId}_$key';
int get currentUserId => _userId;
```

Remove `_initialize()` call from constructor body. Constructor becomes empty (no auto-load).

Add `reinitialize`:
```dart
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
```

Add `_loadForUser()` (replaces `_loadOrMigrate()` for the user-scoped flow):
```dart
Future<void> _loadForUser() async {
  if (_userId == 0) {
    // No user — use in-memory defaults only, do not persist
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
    // New user — create default dashboard
    _dashboards = [DashboardConfig.withDefaults('default', 'Main')];
    _activeDashboardId = 'default';
    await _saveDashboards();
    await _preferences?.setString(_userKey(_activeDashboardKey), 'default');
    await _saveVisibilitySnapshot('default');
  }
}
```

Replace all unscoped SharedPreferences key usages with `_userKey(...)`:

| Before | After |
|--------|-------|
| `_preferences?.getString(_dashboardsListKey)` | `_preferences?.getString(_userKey(_dashboardsListKey))` |
| `_preferences?.setString(_activeDashboardKey, id)` | `_preferences?.setString(_userKey(_activeDashboardKey), id)` |
| `'layout_data_${dashId}_$s'` | `_userKey('layout_data_${dashId}_$s')` |
| `'layout_saved_${dashId}_$s'` | `_userKey('layout_saved_${dashId}_$s')` |
| `'visibility_saved_$dashId'` | `_userKey('visibility_saved_$dashId')` |
| `'init_${dashId}_v4'` | `_userKey('init_${dashId}_v4')` |

The existing `_migrateFromLegacy()` method is removed — new users under user-scoped keys never need it. The old global keys are never read.

`_initialize()` is also removed (replaced by `reinitialize()`).

---

### `lib/storage.dart` (`MyItemStorage`)

Add `userId` parameter to constructor:
```dart
class MyItemStorage extends DashboardItemStorageDelegate<ColoredDashboardItem> {
  final String dashboardId;
  final int userId;

  MyItemStorage({this.dashboardId = 'default', this.userId = 0});

  String _userKey(String key) => 'user_${userId}_$key';
```

Replace all SharedPreferences key strings with `_userKey(...)`:

| Before | After |
|--------|-------|
| `"init_${dashboardId}_v4"` | `_userKey("init_${dashboardId}_v4")` |
| `"layout_data_${dashboardId}_$s"` | `_userKey("layout_data_${dashboardId}_$s")` |
| `"layout_data_${dashboardId}_$slotCount"` | `_userKey("layout_data_${dashboardId}_$slotCount")` |

(4 occurrences across `getAllItems`, `onItemsUpdated`, `onItemsAdded`, `onItemsDeleted`, `clear`)

---

### `lib/screens/dashboard_screen.dart`

**Pass `userId` when constructing `MyItemStorage`:**

```dart
// Before:
storage = MyItemStorage(dashboardId: dashProvider.activeDashboardId);

// After:
storage = MyItemStorage(
  dashboardId: dashProvider.activeDashboardId,
  userId: dashProvider.currentUserId,
);
```

Both call sites: `initState()` and `_recreateStorageAndController()`.

**Add user-change detection** to handle in-session user switches (safety net — normally full navigation handles this):

Add field `int? _lastUserId;`.

In the `Consumer<DashboardProvider>` builder, alongside the existing `_lastDashboardId` check:
```dart
if (_lastUserId != dashProvider.currentUserId) {
  _lastUserId = dashProvider.currentUserId;
  _lastVisibilityKey = [];
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _recreateStorageAndController(
      dashProvider.activeDashboardId,
      dashProvider.getVisibleWidgets(),
    );
  });
}
```

---

### `lib/main.dart`

Promote providers to named fields:
```dart
late SettingsProvider _settingsProvider;
late DashboardProvider _dashboardProvider;
```

In `initState()`, construct them and wire the callback before calling `_initializeAuth()`:
```dart
_settingsProvider = SettingsProvider();
_dashboardProvider = DashboardProvider();

_authProvider.onUserChanged = (userId) async {
  await _settingsProvider.reinitialize(userId);
  await _dashboardProvider.reinitialize(userId);
};
```

In `build()`, switch to `.value`:
```dart
ChangeNotifierProvider.value(value: _settingsProvider),
ChangeNotifierProvider.value(value: _dashboardProvider),
```

---

## Out of Scope

- Cleaning up orphaned global SharedPreferences keys (they are harmless dead data)
- Per-user backup/sync scoping (already handled by cloud storage with user credentials)
- Guest user data cleanup on account upgrade
- Web platform (uses same SharedPreferences API, fix applies automatically)
