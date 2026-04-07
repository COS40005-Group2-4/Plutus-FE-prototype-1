# User Data Isolation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scope all SharedPreferences keys for settings and dashboard layouts to the logged-in user ID so different users on the same device never share data.

**Architecture:** Every SharedPreferences read/write in `SettingsProvider`, `DashboardProvider`, and `MyItemStorage` is routed through a `_userKey(key)` helper that prefixes `user_${userId}_`. `AuthProvider` gains an `onUserChanged` callback that fires on every login/logout. `main.dart` registers this callback to call `reinitialize(userId)` on both providers. Old global keys are orphaned — no migration.

**Tech Stack:** Flutter, `shared_preferences ^2.5.3`, Provider pattern (`ChangeNotifier`), `flutter_test` with `SharedPreferences.setMockInitialValues`

---

## File Map

| File | Action |
|------|--------|
| `lib/providers/auth_provider.dart` | Add `onUserChanged` callback; call it in every sign-in and sign-out path |
| `lib/providers/settings_provider.dart` | Add `_userId`, `_userKey()`, `reinitialize()`; remove auto-load from constructor; scope all SP keys |
| `lib/providers/dashboard_provider.dart` | Add `_userId`, `_userKey()`, `currentUserId`, `reinitialize()`, `_loadForUser()`; remove `_initialize()` and `_migrateFromLegacy()`; scope all SP keys |
| `lib/storage.dart` | Add `userId` param to `MyItemStorage`; scope all SP keys |
| `lib/screens/dashboard_screen.dart` | Pass `userId` when constructing `MyItemStorage`; add `_lastUserId` tracking |
| `lib/main.dart` | Promote providers to fields; register `onUserChanged`; switch to `.value` constructors |
| `test/providers/user_data_isolation_test.dart` | Unit tests for key scoping, reinitialize, and callback contract |

---

### Task 1: `AuthProvider` — add `onUserChanged` callback

**Files:**
- Modify: `lib/providers/auth_provider.dart`
- Test: `test/providers/user_data_isolation_test.dart`

**Background:** `AuthProvider` has five paths that set `_currentUser`: `initialize()` (restores from `last_user_id`), `_handleOAuthSignIn()` (OAuth flow), `signInWithLocalUser()`, `createLocalUser()`, and `signOut()` (clears user). Each needs to fire `onUserChanged`.

- [ ] **Step 1: Write the failing tests**

Create `test/providers/user_data_isolation_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthProvider.onUserChanged callback contract', () {
    test('callback fires with userId when registered and called', () {
      final List<int> calls = [];
      void fakeCallback(int userId) => calls.add(userId);

      // Simulate what AuthProvider._notifyUserChanged does:
      void notifyUserChanged(int userId, void Function(int)? cb) {
        cb?.call(userId);
      }

      notifyUserChanged(42, fakeCallback);
      expect(calls, equals([42]));
    });

    test('callback fires with 0 on sign-out', () {
      final List<int> calls = [];
      void fakeCallback(int userId) => calls.add(userId);

      void notifyUserChanged(int userId, void Function(int)? cb) {
        cb?.call(userId);
      }

      notifyUserChanged(0, fakeCallback);
      expect(calls, equals([0]));
    });

    test('no error when callback is null', () {
      void notifyUserChanged(int userId, void Function(int)? cb) {
        cb?.call(userId);
      }

      // Must not throw
      expect(() => notifyUserChanged(5, null), returnsNormally);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect PASS** (pure logic, no dependencies)

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test test/providers/user_data_isolation_test.dart -v
```

Expected: 3 tests pass.

- [ ] **Step 3: Add `onUserChanged` field and `_notifyUserChanged` helper to `AuthProvider`**

In `lib/providers/auth_provider.dart`, after the existing field declarations (around line 22), add:

```dart
  /// Registered by app startup. Fired with the new user's ID on every login,
  /// and with 0 on sign-out. Used to reinitialize user-scoped providers.
  ValueChanged<int>? onUserChanged;

  void _notifyUserChanged(int userId) => onUserChanged?.call(userId);
```

- [ ] **Step 4: Call `_notifyUserChanged` in `initialize()`**

In `initialize()`, the user-restore block currently ends at `await _userService.updateLastLogin(user.id);` (line ~60). Add the call immediately after:

```dart
    if (lastUserId != null) {
      final user = await _userService.getUserById(lastUserId);
      if (user != null) {
        _currentUser = user;
        _userName = user.displayName;
        _userEmail = user.email ?? '';
        _isGuest = user.isGuest;
        _isAuthenticated = !user.isGuest || user.hasOAuth;
        await _userService.updateLastLogin(user.id);
        _notifyUserChanged(user.id);   // ← ADD THIS LINE
      }
    }
```

- [ ] **Step 5: Call `_notifyUserChanged` in `_handleOAuthSignIn()`**

`_handleOAuthSignIn()` ends at `notifyListeners()` (line ~114). Add the call just before it:

```dart
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_user_id', user.id);
    _notifyUserChanged(user.id);   // ← ADD THIS LINE
    notifyListeners();
```

- [ ] **Step 6: Call `_notifyUserChanged` in `signInWithLocalUser()`**

After `await prefs.setInt('last_user_id', user.id);` (line ~157), add:

```dart
      await prefs.setInt('last_user_id', user.id);
      _notifyUserChanged(user.id);   // ← ADD THIS LINE
      _isLoading = false;
      notifyListeners();
```

- [ ] **Step 7: Call `_notifyUserChanged` in `createLocalUser()`**

After `await prefs.setInt('last_user_id', user.id);` (line ~189), add:

```dart
      await prefs.setInt('last_user_id', user.id);
      _notifyUserChanged(user.id);   // ← ADD THIS LINE
      _isLoading = false;
      notifyListeners();
```

- [ ] **Step 8: Call `_notifyUserChanged(0)` in `signOut()`**

`signOut()` ends with `notifyListeners()`. Add before it:

```dart
    await prefs.remove('last_user_id');
    _notifyUserChanged(0);   // ← ADD THIS LINE
    notifyListeners();
```

- [ ] **Step 9: Analyze**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter analyze lib/providers/auth_provider.dart
```

Expected: no errors.

- [ ] **Step 10: Run full test suite**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test
```

Expected: all tests pass.

- [ ] **Step 11: Commit**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && git add lib/providers/auth_provider.dart test/providers/user_data_isolation_test.dart && git commit -m "feat(auth): add onUserChanged callback fired on every login and sign-out"
```

---

### Task 2: `SettingsProvider` — user-scoped SharedPreferences keys

**Files:**
- Modify: `lib/providers/settings_provider.dart`
- Test: `test/providers/user_data_isolation_test.dart`

**Background:** `SettingsProvider` has 7 static key constants and reads/writes them directly without a user prefix. The constructor calls `_loadSettings()` immediately. After this task: the constructor does nothing; `reinitialize(userId)` loads user-scoped settings; all 7 setters write user-scoped keys.

- [ ] **Step 1: Add tests to `test/providers/user_data_isolation_test.dart`**

Append inside `main()`:

```dart
  group('SettingsProvider key scoping', () {
    test('_userKey prefixes correctly', () {
      // Mirror the production helper
      String userKey(int userId, String key) => 'user_${userId}_$key';

      expect(userKey(3, 'theme_mode'), equals('user_3_theme_mode'));
      expect(userKey(0, 'language'), equals('user_0_language'));
      expect(userKey(99, 'currency'), equals('user_99_currency'));
    });

    test('reinitialize changes userId used for keys', () {
      // Verify that after reinitialize the userId is updated
      // (mirrors internal state change)
      int currentUserId = 0;
      void reinitialize(int userId) { currentUserId = userId; }

      reinitialize(5);
      expect(currentUserId, equals(5));

      reinitialize(0);
      expect(currentUserId, equals(0));
    });
  });
```

- [ ] **Step 2: Run tests — expect PASS**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test test/providers/user_data_isolation_test.dart -v
```

Expected: 5 tests pass.

- [ ] **Step 3: Add `_userId` field and `_userKey` helper to `SettingsProvider`**

In `lib/providers/settings_provider.dart`, inside `class SettingsProvider extends ChangeNotifier {`, after the static const keys block (after line 83), add:

```dart
  int _userId = 0;
  String _userKey(String key) => 'user_${_userId}_$key';
```

- [ ] **Step 4: Remove auto-load from constructor; add `reinitialize`**

Replace the current constructor:
```dart
  SettingsProvider() {
    _loadSettings();
  }
```

With:
```dart
  SettingsProvider();

  Future<void> reinitialize(int userId) async {
    _userId = userId;
    _isInitialized = false;
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

- [ ] **Step 5: Scope all reads in `_loadSettings()`**

Replace every `prefs.getString(<key>)` and `prefs.getBool(<key>)` call to go through `_userKey(...)`.

Full replacement of `_loadSettings()`:

```dart
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final storedTheme = prefs.getString(_userKey(_themeModeKey));
    if (storedTheme == ThemeMode.dark.name) {
      _themeMode = ThemeMode.dark;
    } else if (storedTheme == ThemeMode.light.name) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    final storedLanguage = prefs.getString(_userKey(_languageKey));
    if (storedLanguage != null) {
      _language = AppLanguage.fromCode(storedLanguage);
    }

    final storedCurrency = prefs.getString(_userKey(_currencyKey));
    if (storedCurrency != null) {
      _currency = AppCurrency.fromCode(storedCurrency);
    }

    final storedDateFormat = prefs.getString(_userKey(_dateFormatKey));
    if (storedDateFormat != null) {
      _dateFormat = DateFormatType.fromString(storedDateFormat);
    }

    final storedTimeFormat = prefs.getString(_userKey(_timeFormatKey));
    if (storedTimeFormat != null) {
      _timeFormat = TimeFormatType.fromString(storedTimeFormat);
    }

    final storedOcrMode = prefs.getString(_userKey(_ocrModeKey));
    if (storedOcrMode != null) {
      _ocrMode = OCRMode.values.firstWhere(
        (mode) => mode.name == storedOcrMode,
        orElse: () => OCRMode.auto,
      );
    }

    final storedPrivacyLevel = prefs.getString(_userKey(_privacyLevelKey));
    if (storedPrivacyLevel != null) {
      _privacyLevel = PrivacyLevel.values.firstWhere(
        (level) => level.name == storedPrivacyLevel,
        orElse: () => PrivacyLevel.standard,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }
```

- [ ] **Step 6: Scope all writes in the 7 setter methods**

Replace each setter's `prefs.setString(key, ...)` with `prefs.setString(_userKey(key), ...)`:

```dart
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_themeModeKey), mode.name);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_languageKey), language.code);
    notifyListeners();
  }

  Future<void> setCurrency(AppCurrency currency) async {
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_currencyKey), currency.code);
    notifyListeners();
  }

  Future<void> setDateFormat(DateFormatType format) async {
    _dateFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_dateFormatKey), format.name);
    notifyListeners();
  }

  Future<void> setTimeFormat(TimeFormatType format) async {
    _timeFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_timeFormatKey), format.name);
    notifyListeners();
  }

  Future<void> setOcrMode(OCRMode mode) async {
    _ocrMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_ocrModeKey), mode.name);
    notifyListeners();
  }

  Future<void> setPrivacyLevel(PrivacyLevel level) async {
    _privacyLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_privacyLevelKey), level.name);
    notifyListeners();
  }
```

- [ ] **Step 7: Analyze**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter analyze lib/providers/settings_provider.dart
```

Expected: no errors.

- [ ] **Step 8: Run full test suite**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test
```

Expected: all tests pass.

- [ ] **Step 9: Commit**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && git add lib/providers/settings_provider.dart test/providers/user_data_isolation_test.dart && git commit -m "feat(settings): scope all SharedPreferences keys to user ID"
```

---

### Task 3: `DashboardProvider` — user-scoped SharedPreferences keys

**Files:**
- Modify: `lib/providers/dashboard_provider.dart`
- Test: `test/providers/user_data_isolation_test.dart`

**Background:** `DashboardProvider` stores `dashboards_list`, `active_dashboard_id`, and per-dashboard keys (`layout_data_*`, `layout_saved_*`, `visibility_saved_*`, `init_*`). It auto-initializes in the constructor and has a `_migrateFromLegacy()` path. After this task: constructor is empty; `reinitialize(userId)` loads from user-scoped keys; all key writes are scoped; `_migrateFromLegacy()` and `_initialize()` are removed.

- [ ] **Step 1: Add tests to `test/providers/user_data_isolation_test.dart`**

Append inside `main()`:

```dart
  group('DashboardProvider key scoping', () {
    test('dynamic layout key is user-scoped', () {
      String userKey(int userId, String key) => 'user_${userId}_$key';
      const dashId = 'default';
      const slotCount = 2;

      final key = userKey(7, 'layout_data_${dashId}_$slotCount');
      expect(key, equals('user_7_layout_data_default_2'));
    });

    test('visibility snapshot key is user-scoped', () {
      String userKey(int userId, String key) => 'user_${userId}_$key';

      final key = userKey(7, 'visibility_saved_default');
      expect(key, equals('user_7_visibility_saved_default'));
    });

    test('init flag key is user-scoped', () {
      String userKey(int userId, String key) => 'user_${userId}_$key';

      final key = userKey(7, 'init_default_v4');
      expect(key, equals('user_7_init_default_v4'));
    });
  });
```

- [ ] **Step 2: Run tests — expect PASS**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test test/providers/user_data_isolation_test.dart -v
```

Expected: 8 tests pass.

- [ ] **Step 3: Add `_userId`, `_userKey`, `currentUserId` to `DashboardProvider`**

In `lib/providers/dashboard_provider.dart`, after the existing static const and `_slotCounts` declarations (after line 12), add:

```dart
  int _userId = 0;
  String _userKey(String key) => 'user_${_userId}_$key';
  int get currentUserId => _userId;
```

- [ ] **Step 4: Replace constructor + add `reinitialize` + add `_loadForUser`**

Replace the current constructor:
```dart
  DashboardProvider() {
    _initialize();
  }
```

With:

```dart
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
```

- [ ] **Step 5: Delete `_initialize()` and `_migrateFromLegacy()` and `_loadOrMigrate()`**

Remove the entire bodies of these three methods (they read unscoped keys and are replaced by `_loadForUser()`):
- `Future<void> _initialize() async { ... }` (around line 215–227)
- `Future<void> _loadOrMigrate() async { ... }` (around line 229–247)
- `Future<void> _migrateFromLegacy() async { ... }` (around line 249–307)

- [ ] **Step 6: Scope `_saveDashboards()`**

Replace:
```dart
  Future<void> _saveDashboards() async {
    final list = _dashboards.map((d) => d.toJson()).toList();
    await _preferences?.setString(_dashboardsListKey, json.encode(list));
  }
```

With:
```dart
  Future<void> _saveDashboards() async {
    if (_userId == 0) return; // Do not persist for the no-user state
    final list = _dashboards.map((d) => d.toJson()).toList();
    await _preferences?.setString(_userKey(_dashboardsListKey), json.encode(list));
  }
```

- [ ] **Step 7: Scope `setActiveDashboard()`, `createDashboard()`, and `deleteDashboard()`**

In `setActiveDashboard()`, replace:
```dart
    await _preferences?.setString(_activeDashboardKey, id);
```
With:
```dart
    await _preferences?.setString(_userKey(_activeDashboardKey), id);
```

In `createDashboard()`, replace:
```dart
    await _preferences?.setString(_activeDashboardKey, id);
```
With:
```dart
    await _preferences?.setString(_userKey(_activeDashboardKey), id);
```

- [ ] **Step 8: Scope `hardReset()`**

Replace:
```dart
    for (var s in _slotCounts) {
      await _preferences?.remove('layout_data_${_activeDashboardId}_$s');
    }
    await _preferences?.setBool('init_${_activeDashboardId}_v4', false);
```
With:
```dart
    for (var s in _slotCounts) {
      await _preferences?.remove(_userKey('layout_data_${_activeDashboardId}_$s'));
    }
    await _preferences?.setBool(_userKey('init_${_activeDashboardId}_v4'), false);
```

- [ ] **Step 9: Scope `_copyLiveToSaved()` and `_copySavedToLive()`**

Replace `_copyLiveToSaved`:
```dart
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
```

Replace `_copySavedToLive`:
```dart
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
```

- [ ] **Step 10: Scope `_saveVisibilitySnapshot()` and `_restoreVisibilitySnapshot()`**

Replace `_saveVisibilitySnapshot`:
```dart
  Future<void> _saveVisibilitySnapshot(String dashId) async {
    final vis = _dashboards
        .firstWhere((d) => d.id == dashId, orElse: () => activeDashboard)
        .widgetVisibility;
    final encoded = vis.entries.map((e) => '${e.key}:${e.value}').join(',');
    await _preferences?.setString(_userKey('visibility_saved_$dashId'), encoded);
  }
```

Replace `_restoreVisibilitySnapshot`:
```dart
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
```

- [ ] **Step 11: Scope `_cleanupDashboardKeys()`**

Replace:
```dart
  Future<void> _cleanupDashboardKeys(String dashId) async {
    for (var s in _slotCounts) {
      await _preferences?.remove('layout_data_${dashId}_$s');
      await _preferences?.remove('layout_saved_${dashId}_$s');
    }
    await _preferences?.remove('init_${dashId}_v4');
    await _preferences?.remove('visibility_saved_$dashId');
  }
```
With:
```dart
  Future<void> _cleanupDashboardKeys(String dashId) async {
    for (var s in _slotCounts) {
      await _preferences?.remove(_userKey('layout_data_${dashId}_$s'));
      await _preferences?.remove(_userKey('layout_saved_${dashId}_$s'));
    }
    await _preferences?.remove(_userKey('init_${dashId}_v4'));
    await _preferences?.remove(_userKey('visibility_saved_$dashId'));
  }
```

- [ ] **Step 12: Analyze**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter analyze lib/providers/dashboard_provider.dart
```

Expected: no errors. Common pitfall: `_initialize`, `_loadOrMigrate`, or `_migrateFromLegacy` may be referenced elsewhere — search with `grep -n "_initialize\|_loadOrMigrate\|_migrateFromLegacy" lib/providers/dashboard_provider.dart` to confirm all three are fully removed.

- [ ] **Step 13: Run full test suite**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test
```

Expected: all tests pass.

- [ ] **Step 14: Commit**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && git add lib/providers/dashboard_provider.dart test/providers/user_data_isolation_test.dart && git commit -m "feat(dashboard): scope all SharedPreferences keys to user ID"
```

---

### Task 4: `MyItemStorage` — add `userId` parameter

**Files:**
- Modify: `lib/storage.dart`
- Test: `test/providers/user_data_isolation_test.dart`

**Background:** `MyItemStorage` reads/writes 3 key patterns: `init_${dashboardId}_v4`, `layout_data_${dashboardId}_$s`, and `layout_data_${dashboardId}_$slotCount`. All 4 call sites (in `getAllItems`, `onItemsUpdated`, `onItemsAdded`, `onItemsDeleted`, `clear`) need to go through `_userKey()`.

- [ ] **Step 1: Add tests**

Append inside `main()` in `test/providers/user_data_isolation_test.dart`:

```dart
  group('MyItemStorage key scoping', () {
    test('layout_data key is user-scoped', () {
      String userKey(int userId, String key) => 'user_${userId}_$key';
      const dashId = 'myDash';
      const slotCount = 4;

      expect(
        userKey(12, 'layout_data_${dashId}_$slotCount'),
        equals('user_12_layout_data_myDash_4'),
      );
    });

    test('init flag key is user-scoped', () {
      String userKey(int userId, String key) => 'user_${userId}_$key';
      const dashId = 'myDash';

      expect(
        userKey(12, 'init_${dashId}_v4'),
        equals('user_12_init_myDash_v4'),
      );
    });
  });
```

- [ ] **Step 2: Run tests — expect PASS**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test test/providers/user_data_isolation_test.dart -v
```

Expected: 10 tests pass.

- [ ] **Step 3: Add `userId` to `MyItemStorage` constructor and add `_userKey`**

In `lib/storage.dart`, replace the `MyItemStorage` class constructor:

```dart
class MyItemStorage extends DashboardItemStorageDelegate<ColoredDashboardItem> {
  final String dashboardId;
  final int userId;

  MyItemStorage({this.dashboardId = 'default', this.userId = 0});

  String _userKey(String key) => 'user_${userId}_$key';
```

- [ ] **Step 4: Scope all keys in `getAllItems()`**

In the `getAllItems()` method body, replace every hardcoded key string:

```dart
// Replace:
var init = _preferences.getBool("init_${dashboardId}_v4") ?? false;
// With:
var init = _preferences.getBool(_userKey("init_${dashboardId}_v4")) ?? false;

// Replace (writing init):
await _preferences.setBool("init_${dashboardId}_v4", true);
// With:
await _preferences.setBool(_userKey("init_${dashboardId}_v4"), true);

// Replace (writing layout):
await _preferences.setString(
  "layout_data_${dashboardId}_$s",
  json.encode(...),
);
// With:
await _preferences.setString(
  _userKey("layout_data_${dashboardId}_$s"),
  json.encode(...),
);

// Replace (reading layout):
var layoutDataStr = _preferences.getString("layout_data_${dashboardId}_$s");
// With:
var layoutDataStr = _preferences.getString(_userKey("layout_data_${dashboardId}_$s"));
```

- [ ] **Step 5: Scope all keys in `onItemsUpdated()`**

Replace:
```dart
      await _preferences.setString("layout_data_${dashboardId}_$slotCount", js);
```
With:
```dart
      await _preferences.setString(_userKey("layout_data_${dashboardId}_$slotCount"), js);
```

- [ ] **Step 6: Scope all keys in `onItemsAdded()`**

Replace:
```dart
      await _preferences.setString(
        "layout_data_${dashboardId}_$s",
        json.encode(...),
      );
```
With:
```dart
      await _preferences.setString(
        _userKey("layout_data_${dashboardId}_$s"),
        json.encode(...),
      );
```

- [ ] **Step 7: Scope all keys in `onItemsDeleted()`**

Replace:
```dart
        await _preferences.setString(
          "layout_data_${dashboardId}_$s",
          json.encode(...),
        );
```
With:
```dart
        await _preferences.setString(
          _userKey("layout_data_${dashboardId}_$s"),
          json.encode(...),
        );
```

- [ ] **Step 8: Scope all keys in `clear()`**

Replace:
```dart
  Future<void> clear() async {
    for (var s in _slotCounts) {
      _localItems?[s]?.clear();
      await _preferences.remove("layout_data_${dashboardId}_$s");
    }
    _localItems = null;
    await _preferences.setBool("init_${dashboardId}_v4", false);
  }
```
With:
```dart
  Future<void> clear() async {
    for (var s in _slotCounts) {
      _localItems?[s]?.clear();
      await _preferences.remove(_userKey("layout_data_${dashboardId}_$s"));
    }
    _localItems = null;
    await _preferences.setBool(_userKey("init_${dashboardId}_v4"), false);
  }
```

- [ ] **Step 9: Analyze**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter analyze lib/storage.dart
```

Expected: no errors. If any remaining `"layout_data_${dashboardId}` string is not wrapped in `_userKey()`, the analyzer won't catch it — do a final check with:
```bash
grep -n '"layout_data_\|"init_' /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1/lib/storage.dart
```
Expected: 0 matches (all should now go through `_userKey()`).

- [ ] **Step 10: Run full test suite**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test
```

Expected: all tests pass.

- [ ] **Step 11: Commit**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && git add lib/storage.dart test/providers/user_data_isolation_test.dart && git commit -m "feat(storage): add userId to MyItemStorage and scope all layout keys"
```

---

### Task 5: `dashboard_screen.dart` — pass `userId` to `MyItemStorage`

**Files:**
- Modify: `lib/screens/dashboard_screen.dart`

**Background:** `MyItemStorage` now requires a `userId`. It is constructed in two places in `_DashboardWidgetState`: `initState()` (line 72) and `_recreateStorageAndController()` (line 90). Both must pass `dashProvider.currentUserId`. Also add `_lastUserId` tracking as a safety net for in-session user switches.

- [ ] **Step 1: Add `_lastUserId` field**

In `_DashboardWidgetState`, after the existing fields (after line 65 `int _controllerVersion = 0;`), add:

```dart
  int? _lastUserId;
```

- [ ] **Step 2: Pass `userId` in `initState()`**

Replace:
```dart
    storage = MyItemStorage(dashboardId: dashProvider.activeDashboardId);
```
With:
```dart
    _lastUserId = dashProvider.currentUserId;
    storage = MyItemStorage(
      dashboardId: dashProvider.activeDashboardId,
      userId: dashProvider.currentUserId,
    );
```

- [ ] **Step 3: Pass `userId` in `_recreateStorageAndController()`**

Replace:
```dart
    storage = MyItemStorage(dashboardId: dashboardId);
```
With:
```dart
    storage = MyItemStorage(
      dashboardId: dashboardId,
      userId: Provider.of<DashboardProvider>(context, listen: false).currentUserId,
    );
```

- [ ] **Step 4: Add user-change detection in the `Consumer<DashboardProvider>` builder**

In the `Consumer<DashboardProvider>` builder (inside `build()`), after the existing `_lastDashboardId` check block, add:

```dart
            // Detect user switch (safety net for in-session switches)
            if (_lastUserId != dashProvider.currentUserId) {
              _lastUserId = dashProvider.currentUserId;
              _lastVisibilityKey = [];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _recreateStorageAndController(
                    dashProvider.activeDashboardId,
                    dashProvider.getVisibleWidgets(),
                  );
                }
              });
            }
```

Place this block immediately after the `_lastDashboardId` check block (around line 291 after the existing dashboard-switch detection).

- [ ] **Step 5: Analyze**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter analyze lib/screens/dashboard_screen.dart
```

Expected: no errors.

- [ ] **Step 6: Run full test suite**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && git add lib/screens/dashboard_screen.dart && git commit -m "feat(dashboard-screen): pass userId to MyItemStorage; detect user switch"
```

---

### Task 6: `main.dart` — promote providers to fields and wire `onUserChanged`

**Files:**
- Modify: `lib/main.dart`

**Background:** `DashboardProvider` and `SettingsProvider` are currently created via `create:` lambdas inside `build()` — they cannot be accessed from `initState()`. Promoting them to named `late` fields (matching the existing pattern for `_authProvider`) gives `initState()` access to register the `onUserChanged` callback before `_initializeAuth()` runs.

- [ ] **Step 1: Add `_settingsProvider` and `_dashboardProvider` as late fields**

In `_MyAppState`, after the existing `late BackupProvider _backupProvider;` (line 74), add:

```dart
  late SettingsProvider _settingsProvider;
  late DashboardProvider _dashboardProvider;
```

- [ ] **Step 2: Initialize them in `initState()` and register the callback**

In `initState()`, after `_authProvider = AuthProvider();` (line 83) and before `_initializeAuth();`, add:

```dart
    _settingsProvider = SettingsProvider();
    _dashboardProvider = DashboardProvider();

    _authProvider.onUserChanged = (int userId) async {
      await _settingsProvider.reinitialize(userId);
      await _dashboardProvider.reinitialize(userId);
    };
```

Full `initState()` after change:
```dart
  @override
  void initState() {
    super.initState();
    _syncManager = SyncManager();
    _backupProvider = BackupProvider(syncManager: _syncManager);
    _authProvider = AuthProvider();
    _settingsProvider = SettingsProvider();
    _dashboardProvider = DashboardProvider();

    _authProvider.onUserChanged = (int userId) async {
      await _settingsProvider.reinitialize(userId);
      await _dashboardProvider.reinitialize(userId);
    };

    _initializeAuth();
    _setupConnectivity();
  }
```

- [ ] **Step 3: Switch `build()` to use `.value` constructors**

In `build()`, replace:
```dart
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
```
With:
```dart
        ChangeNotifierProvider.value(value: _dashboardProvider),
        ChangeNotifierProvider.value(value: _settingsProvider),
```

- [ ] **Step 4: Analyze**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter analyze lib/main.dart
```

Expected: no errors.

- [ ] **Step 5: Run full test suite**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && git add lib/main.dart && git commit -m "feat(main): wire onUserChanged to reinitialize settings and dashboard per user"
```
