# Terms & Consent for All Users Design

**Date:** 2026-04-08
**Scope:** `lib/widgets/consent_dialog.dart`, `lib/l10n/app_localizations.dart`, `lib/main.dart`, `lib/providers/auth_provider.dart`

---

## Problem

The data consent dialog only shows for OAuth (Google) users. Local accounts and guest accounts never see any T&C, even on first login. This leaves no recorded agreement for the majority of users.

---

## Decision

**Two separate consent paths:**

1. **OAuth users** — existing `checkDataConsent()` flow in `AuthProvider` is unchanged. Shows the cloud backup/sync consent dialog and records to DynamoDB + SQLite.
2. **Local/guest users** — new general T&C dialog shown on first login per user. Tracked via a user-scoped SharedPreferences key `user_${userId}_tc_shown`. No DynamoDB involved.

---

## Architecture

### Tracking "already seen" for local users

`AuthProvider` gets a new async method:

```dart
Future<bool> isLocalTcShown() async {
  final userId = _currentUser?.id;
  if (userId == null) return true;
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('user_${userId}_tc_shown') ?? false;
}

Future<void> setLocalTcShown() async {
  final userId = _currentUser?.id;
  if (userId == null) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('user_${userId}_tc_shown', true);
}
```

`user_${userId}_tc_shown` follows the same user-scoped key pattern established in the user data isolation feature. It is set to `true` after the dialog is dismissed — regardless of whether the user agreed or declined.

### Dialog outcome

| User action | `data_consent` (SQLite) | `tc_shown` (SharedPreferences) |
|---|---|---|
| Agree | Set to `true` via `_userService.setDataConsent(userId, true)` | Set to `true` |
| Decline | Unchanged (stays `false`) | Set to `true` |

The dialog does not appear again once `tc_shown = true`. `data_consent = false` remains on record as "seen but not agreed."

### New dialog: `showTermsDialog()`

Added to `lib/widgets/consent_dialog.dart`. Same visual style as the existing cloud consent dialog (`AlertDialog`, same `backgroundColor`, `shape`, `barrierDismissible: false`), but different content:

- **Title:** `Icons.gavel_outlined` + `l10n.tcTitle`
- **Content:** `l10n.tcMessage` (one paragraph — general app usage, local storage, no cloud language)
- **Actions:**
  - Decline button (grey text) — calls `Navigator.pop(false)`
  - Agree button (green) — calls `Navigator.pop(true)`

```dart
Future<bool> showTermsDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _TermsDialogContent(),
  );
  return result ?? false;
}
```

### `_initBackupAndNavigate` changes in `main.dart`

Extended to handle local/guest users. The full updated check:

```dart
if (!_consentChecked) {
  _consentChecked = true;
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  if (authProvider.currentUser?.hasOAuth == true &&
      authProvider.currentUser?.dataConsent != true) {
    // Existing OAuth consent path — unchanged
    final consented = await authProvider.checkDataConsent(context);
    if (!consented && !mounted) return;
  } else if (authProvider.currentUser?.hasOAuth == false) {
    // New: local/guest path
    final alreadyShown = await authProvider.isLocalTcShown();
    if (!alreadyShown) {
      if (!context.mounted) return;
      final agreed = await showTermsDialog(context);
      await authProvider.handleLocalTcResult(agreed);
    }
  }
}
```

`AuthProvider.handleLocalTcResult` handles the complete outcome in one call:

```dart
Future<void> handleLocalTcResult(bool agreed) async {
  if (agreed && _currentUser != null) {
    await _userService.setDataConsent(_currentUser!.id, true);
    _currentUser = await _userService.getUserById(_currentUser!.id);
    notifyListeners();
  }
  await setLocalTcShown(); // Always mark as shown, regardless of outcome
}
```

---

## Localization

Four new keys in `lib/l10n/app_localizations.dart`:

| Key | EN | VI |
|---|---|---|
| `tc_title` | `'Terms of Use'` | `'Điều khoản sử dụng'` |
| `tc_message` | `'By using Plutus, you acknowledge that your financial data is stored locally on this device. You accept responsibility for keeping your device secure. You may export or delete your data at any time.'` | `'Bằng cách sử dụng Plutus, bạn xác nhận rằng dữ liệu tài chính của bạn được lưu trữ cục bộ trên thiết bị này. Bạn chấp nhận trách nhiệm bảo mật thiết bị của mình. Bạn có thể xuất hoặc xóa dữ liệu của mình bất kỳ lúc nào.'` |
| `tc_agree_btn` | `'I Agree'` | `'Tôi đồng ý'` |
| `tc_decline_btn` | `'Decline'` | `'Từ chối'` |

Getters added after the existing `dataConsentDeclineBtn` getter.

---

## Out of Scope

- Showing T&C copy in-app on demand (settings screen link)
- Re-prompting users who previously declined
- Versioning the T&C (showing again when terms change)
