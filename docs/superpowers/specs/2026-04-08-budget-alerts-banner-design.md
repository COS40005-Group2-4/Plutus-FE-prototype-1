# Budget Alerts Banner Design

**Date:** 2026-04-08
**Scope:** `lib/screens/dashboard_screen.dart`

---

## Problem

`BudgetProvider.alerts` is populated with `BudgetAlert` objects whenever spending in a category exceeds a configured threshold percentage, but nothing in the UI surfaces these alerts to the user. The alerts are silently computed and discarded from a UX perspective.

Additionally, `BudgetAlert.message` hardcodes the `$` currency symbol, which is incorrect for VND and other currencies.

---

## Decision

Add a dismissible warning banner at the top of the dashboard body. The banner is shown whenever `BudgetProvider.alerts.isNotEmpty` and the user has not dismissed it this session. It formats alert text using `SettingsProvider.currency.symbol` rather than the pre-built `BudgetAlert.message` string.

---

## Architecture

### State

One new field on `_DashboardWidgetState`:

```dart
bool _alertsDismissed = false;
```

This is instance state — it resets to `false` each time `_DashboardWidgetState` is created, which means the banner reappears on the next app launch (or after a user switch triggers `_recreateStorageAndController`).

### Banner placement

The `body:` `SafeArea` currently contains a single `Consumer<DashboardProvider>`. This is wrapped in a `Consumer<BudgetProvider>` and the result placed in a `Column`:

```dart
body: SafeArea(
  child: Consumer<BudgetProvider>(
    builder: (context, budgetProvider, _) {
      final alerts = budgetProvider.alerts;
      return Column(
        children: [
          if (alerts.isNotEmpty && !_alertsDismissed)
            _buildAlertsBanner(alerts),
          Expanded(
            child: Consumer<DashboardProvider>(
              // existing dashboard builder — unchanged
            ),
          ),
        ],
      );
    },
  ),
),
```

### `_buildAlertsBanner` helper

Private method on `_DashboardWidgetState`. Returns a `Container` matching the existing glass aesthetic:

```dart
Widget _buildAlertsBanner(List<BudgetAlert> alerts) {
  final currency = context.read<SettingsProvider>().currency;
  return Container(
    width: double.infinity,
    color: Colors.amber.withValues(alpha: 0.15),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.warning_amber_outlined, color: Colors.amber, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: alerts.map((alert) {
              final pct = (alert.spent / alert.budgeted * 100).round();
              final sym = currency.symbol;
              return Text(
                '${alert.category.name}: $pct% '
                '(${sym}${alert.spent.toStringAsFixed(0)} / '
                '${sym}${alert.budgeted.toStringAsFixed(0)})',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _alertsDismissed = true),
          child: const Icon(Icons.close, color: Colors.amber, size: 16),
        ),
      ],
    ),
  );
}
```

### Currency formatting

The banner ignores `BudgetAlert.message` entirely and constructs the alert text from raw fields:
- `alert.category.name` — category name
- `alert.spent / alert.budgeted * 100` — percentage
- `SettingsProvider.currency.symbol` — currency symbol from user settings

`BudgetAlert.message` is not removed (out of scope), but is no longer used by any UI.

---

## Out of Scope

- Removing `BudgetAlert.message` field (now dead code — separate cleanup)
- Tapping an alert to navigate to the budget screen
- Persistent dismissal across sessions (dismissed state is in-memory only)
- Notification badges on the budget widget itself
