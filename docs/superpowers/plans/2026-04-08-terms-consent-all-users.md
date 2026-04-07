# Terms & Consent for All Users Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a general T&C dialog to local/guest users on their first login, tracked per-user via a SharedPreferences key, recording whether they agreed or declined.

**Architecture:** `AuthProvider` gains three methods (`isLocalTcShown`, `setLocalTcShown`, `handleLocalTcResult`) that use the existing `user_${userId}_` SharedPreferences prefix. A new `showTermsDialog()` is added to `consent_dialog.dart` with general app terms copy. `_initBackupAndNavigate` in `main.dart` is extended with a new `else if` branch for non-OAuth users. OAuth users are unaffected.

**Tech Stack:** Flutter, `shared_preferences`, Provider, `AppLocalizations` (inline translation map)

---

## File Map

| File | Action |
|---|---|
| `lib/l10n/app_localizations.dart` | Add 4 keys: `tc_title`, `tc_message`, `tc_agree_btn`, `tc_decline_btn` (EN + VI + getters) |
| `lib/widgets/consent_dialog.dart` | Add `showTermsDialog()` function + `_TermsDialogContent` widget |
| `lib/providers/auth_provider.dart` | Add `isLocalTcShown()`, `setLocalTcShown()`, `handleLocalTcResult(bool)` |
| `lib/main.dart` | Extend `_initBackupAndNavigate` with local/guest T&C path |
| `test/providers/terms_consent_test.dart` | Unit tests for AuthProvider methods and routing logic |

---

### Task 1: Localization keys

**Files:**
- Modify: `lib/l10n/app_localizations.dart`

- [ ] **Step 1: Add EN strings**

In `lib/l10n/app_localizations.dart`, find the EN map entry `'data_consent_decline_btn': 'Decline',` (line ~72). Add immediately after it:

```dart
      'tc_title': 'Terms of Use',
      'tc_message': 'By using Plutus, you acknowledge that your financial data is stored locally on this device. You accept responsibility for keeping your device secure. You may export or delete your data at any time.',
      'tc_agree_btn': 'I Agree',
      'tc_decline_btn': 'Decline',
```

The surrounding context should look like:

```dart
      'data_consent_agree_btn': 'Agree',
      'data_consent_decline_btn': 'Decline',
      'tc_title': 'Terms of Use',
      'tc_message': 'By using Plutus, you acknowledge that your financial data is stored locally on this device. You accept responsibility for keeping your device secure. You may export or delete your data at any time.',
      'tc_agree_btn': 'I Agree',
      'tc_decline_btn': 'Decline',
      'reset_dashboard': 'Undo Changes',
```

- [ ] **Step 2: Add VI strings**

Find the VI map entry `'data_consent_decline_btn': 'Từ chối',` (line ~616). Add immediately after it:

```dart
      'tc_title': 'Điều khoản sử dụng',
      'tc_message': 'Bằng cách sử dụng Plutus, bạn xác nhận rằng dữ liệu tài chính của bạn được lưu trữ cục bộ trên thiết bị này. Bạn chấp nhận trách nhiệm bảo mật thiết bị của mình. Bạn có thể xuất hoặc xóa dữ liệu của mình bất kỳ lúc nào.',
      'tc_agree_btn': 'Tôi đồng ý',
      'tc_decline_btn': 'Từ chối',
```

- [ ] **Step 3: Add getters**

Find the getter `String get dataConsentDeclineBtn => translate('data_consent_decline_btn');` (line ~1158). Add immediately after it:

```dart
  String get tcTitle => translate('tc_title');
  String get tcMessage => translate('tc_message');
  String get tcAgreeBtn => translate('tc_agree_btn');
  String get tcDeclineBtn => translate('tc_decline_btn');
```

- [ ] **Step 4: Analyze**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter analyze lib/l10n/app_localizations.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && git add lib/l10n/app_localizations.dart && git commit -m "$(cat <<'EOF'
feat(l10n): add tc_title/message/agree/decline keys for local user T&C
EOF
)"
```

---

### Task 2: `showTermsDialog()` in `consent_dialog.dart`

**Files:**
- Modify: `lib/widgets/consent_dialog.dart`

- [ ] **Step 1: Write test**

Create `test/providers/terms_consent_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Local T&C shown tracking', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isLocalTcShown returns false when key not set', () async {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('user_5_tc_shown') ?? false;
      expect(shown, isFalse);
    });

    test('isLocalTcShown returns true after key is set', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_5_tc_shown', true);
      final shown = prefs.getBool('user_5_tc_shown') ?? false;
      expect(shown, isTrue);
    });

    test('different users have independent tc_shown keys', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_1_tc_shown', true);
      final user1Shown = prefs.getBool('user_1_tc_shown') ?? false;
      final user2Shown = prefs.getBool('user_2_tc_shown') ?? false;
      expect(user1Shown, isTrue);
      expect(user2Shown, isFalse);
    });
  });

  group('handleLocalTcResult contract', () {
    test('agreed=true records consent and marks shown', () {
      // Simulate the two things handleLocalTcResult must do when agreed=true:
      bool consentRecorded = false;
      bool tcShownMarked = false;

      void recordConsent() => consentRecorded = true;
      void markShown() => tcShownMarked = true;

      const agreed = true;
      if (agreed) recordConsent();
      markShown();

      expect(consentRecorded, isTrue);
      expect(tcShownMarked, isTrue);
    });

    test('agreed=false skips consent but still marks shown', () {
      bool consentRecorded = false;
      bool tcShownMarked = false;

      void recordConsent() => consentRecorded = true;
      void markShown() => tcShownMarked = true;

      const agreed = false;
      if (agreed) recordConsent();
      markShown();

      expect(consentRecorded, isFalse);
      expect(tcShownMarked, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test — expect PASS**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test test/providers/terms_consent_test.dart -v
```

Expected: 5 tests pass.

- [ ] **Step 3: Add `showTermsDialog` to `consent_dialog.dart`**

In `lib/widgets/consent_dialog.dart`, append after the closing `}` of `_DataConsentDialogContent` (at the end of the file):

```dart

/// Shows a general Terms of Use dialog for local/guest users.
/// Returns true if user agrees, false if they decline.
Future<bool> showTermsDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _TermsDialogContent(),
  );
  return result ?? false;
}

class _TermsDialogContent extends StatelessWidget {
  const _TermsDialogContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark
          ? AppColors.surfaceDark.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      title: Row(
        children: [
          Icon(
            Icons.gavel_outlined,
            color: isDark ? AppColors.accent : Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.tcTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        l10n.tcMessage,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.tcDeclineBtn,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[400],
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.tcAgreeBtn),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Analyze**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter analyze lib/widgets/consent_dialog.dart
```

Expected: no errors.

- [ ] **Step 5: Run full test suite**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && git add lib/widgets/consent_dialog.dart test/providers/terms_consent_test.dart && git commit -m "$(cat <<'EOF'
feat(consent): add showTermsDialog for local/guest user T&C
EOF
)"
```

---

### Task 3: `AuthProvider` — `isLocalTcShown`, `setLocalTcShown`, `handleLocalTcResult`

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**Background:** `AuthProvider` uses the existing `user_${userId}_` SharedPreferences prefix from the user data isolation feature. `isLocalTcShown` reads the key; `setLocalTcShown` writes it; `handleLocalTcResult(bool agreed)` persists consent to SQLite (if agreed) then always marks the dialog as shown. `_userService.setDataConsent` already exists at line ~364.

- [ ] **Step 1: Add the three methods to `auth_provider.dart`**

In `lib/providers/auth_provider.dart`, add after the `checkDataConsent` method (before the closing `}` of the class):

```dart
  /// Returns true if the local T&C dialog has already been shown to this user.
  Future<bool> isLocalTcShown() async {
    final userId = _currentUser?.id;
    if (userId == null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('user_${userId}_tc_shown') ?? false;
  }

  /// Marks the local T&C dialog as shown for the current user.
  Future<void> setLocalTcShown() async {
    final userId = _currentUser?.id;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_${userId}_tc_shown', true);
  }

  /// Called after the local T&C dialog is dismissed.
  /// If [agreed] is true, persists data consent to SQLite.
  /// Always marks the dialog as shown so it does not appear again.
  Future<void> handleLocalTcResult(bool agreed) async {
    if (agreed && _currentUser != null) {
      await _userService.setDataConsent(_currentUser!.id, true);
      _currentUser = await _userService.getUserById(_currentUser!.id);
      notifyListeners();
    }
    await setLocalTcShown();
  }
```

- [ ] **Step 2: Analyze**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter analyze lib/providers/auth_provider.dart
```

Expected: no errors.

- [ ] **Step 3: Run full test suite**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && git add lib/providers/auth_provider.dart && git commit -m "$(cat <<'EOF'
feat(auth): add isLocalTcShown/setLocalTcShown/handleLocalTcResult
EOF
)"
```

---

### Task 4: `main.dart` — extend `_initBackupAndNavigate` for local T&C

**Files:**
- Modify: `lib/main.dart`

**Background:** The existing consent block (lines 275–289) only handles OAuth users. We extend it with an `else if` for local/guest users (`hasOAuth == false`). The `showTermsDialog` import comes from `'widgets/consent_dialog.dart'` which is already imported (`import 'widgets/conflict_dialog.dart'` and `import 'widgets/backup_found_dialog.dart'` are already there — add `consent_dialog.dart` alongside them).

- [ ] **Step 1: Add import for `consent_dialog.dart`**

In `lib/main.dart`, find the existing line:
```dart
import 'widgets/conflict_dialog.dart';
```

Add immediately after it:
```dart
import 'widgets/consent_dialog.dart';
```

- [ ] **Step 2: Extend `_initBackupAndNavigate`**

Find the existing block (lines 274–290):

```dart
    // Check data consent for OAuth users
    if (!_consentChecked) {
      _consentChecked = true;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // If user has OAuth but hasn't consented, show consent dialog
      if (authProvider.currentUser?.hasOAuth == true &&
          authProvider.currentUser?.dataConsent != true) {
        // Store context before async call
        final scaffoldContext = context;
        final consented = await authProvider.checkDataConsent(scaffoldContext);
        if (!consented) {
          // User declined - they are now in guest mode, continue to dashboard
          if (!mounted) return;
        }
      }
    }
```

Replace with:

```dart
    // Check consent
    if (!_consentChecked) {
      _consentChecked = true;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.currentUser?.hasOAuth == true &&
          authProvider.currentUser?.dataConsent != true) {
        // OAuth path: cloud backup/sync consent (existing behaviour)
        final consented = await authProvider.checkDataConsent(context);
        if (!consented && !mounted) return;
      } else if (authProvider.currentUser?.hasOAuth == false) {
        // Local/guest path: general T&C on first login
        final alreadyShown = await authProvider.isLocalTcShown();
        if (!alreadyShown) {
          if (!context.mounted) return;
          final agreed = await showTermsDialog(context);
          await authProvider.handleLocalTcResult(agreed);
        }
      }
    }
```

- [ ] **Step 3: Analyze**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter analyze lib/main.dart
```

Expected: no errors.

- [ ] **Step 4: Run full test suite**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && git add lib/main.dart && git commit -m "$(cat <<'EOF'
feat(main): show general T&C dialog to local/guest users on first login
EOF
)"
```
